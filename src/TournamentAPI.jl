
const PUBLIC_DATASETS_URL = "https://numerai-public-datasets.s3-us-west-2.amazonaws.com"
const TOURNAMENT = 8

struct TournamentAPI <: BaseAPI
  public_id::Union{String,Nothing}
  secret_key::Union{String,Nothing}
  verbosity::Bool
  show_progress_bars::Bool
  public_dataset_url::String
end


function TournamentAPI(public_id::Union{String,Nothing}, 
                       secret_key::Union{String,Nothing}; 
                       verbosity::Bool=true, 
                       show_progress_bars::Bool=true)

  return TournamentAPI(public_id, 
                        secret_key, 
                        verbosity, 
                        show_progress_bars, 
                        PUBLIC_DATASETS_URL)
end


function get_dataset_url(api::TournamentAPI; tournament::Int=TOURNAMENT)::String
  query = """
    query(\$tournament: Int!) {
        dataset(tournament: \$tournament)
    }"""

  variables = Dict("tournament" => tournament)
  
  url = raw_query(api, query, variables=variables)["data"]["dataset"]

  return url
end


function download_current_dataset(api::TournamentAPI; 
                                    dest_path::String=".", 
                                    dest_filename::Union{String,Nothing}=nothing,
                                    unzip::Bool=true, 
                                    tournament::Int=TOURNAMENT,
                                    show_progress_bar::Bool=true)::String

  if isnothing(dest_filename)
    round_number = get_current_round(api, tournament=tournament)
    dest_filename = "numerai_dataset_$(round_number).zip"
  else
    if unzip & !endswith(dest_filename, ".zip")
      dest_filename += ".zip"
    end
  end
  dataset_path = joinpath(dest_path, dest_filename)

  if ispath(dataset_path)
    @warn "target file already exists"
    return dataset_path
  end

  ensure_directory_exists(dest_path)

  url = get_dataset_url(api, tournament=tournament)
  download_file(url, dataset_path, show_progress_bar=show_progress_bar)

  if unzip
    dataset_name = dest_filename[1:end-4]
    unzip_file(dataset_path, dest_path, dataset_name)
  end

  return dataset_path
end


function get_latest_data_url(api::TournamentAPI, data_type::String, extension::String)::String
  valid_extensions = ["csv", "csv.xz", "parquet"]
  valid_data_types = [
      "live",
      "training",
      "validation",
      "test",
      "max_test_era",
      "tournament",
      "tournament_ids",
      "example_predictions"
  ]

  # Allow extension to have a "." as the first character
  extension = lstrip(extension, '.')
  
  # Validate arguments
  if extension ∉ valid_extensions
    msg = "extension must be set to one of $valid_extensions"
    throw(ArgumentError(msg))
  end

  if data_type ∉ valid_data_types
    msg = "data_type must be set to one of $valid_data_types"
    throw(ArgumentError(msg))
  end

  url = "$(api.public_dataset_url)/latest_numerai_$(data_type)_data.$(extension)"

  return url
end


function download_latest_data(api::TournamentAPI, 
                              data_type::String,
                              extension::String;
                              dest_path::String=".",
                              dest_filename::Union{String,Nothing}=nothing,
                              show_progress_bar::Bool=true)::Nothing
  # set up download path
  if isnothing(dest_filename)
    dest_filename = "latest_numerai_$(data_type)_data.$(extension)"
  end

  dataset_path = joinpath(dest_path, dest_filename)

  # create parent folder if necessary
  ensure_directory_exists(dest_path)

  url = get_latest_data_url(api, data_type, extension)

  download_file(url, dataset_path, show_progress_bar=show_progress_bar)

  return nothing
end


function get_competitions(api::TournamentAPI; tournament::Int=TOURNAMENT)::Vector{Dict}
  query = """
    query(\$tournament: Int!) {
      rounds(tournament: \$tournament) {
        number
        resolveTime
        datasetId
        openTime
        resolvedGeneral
        resolvedStaking
        participants
        prizePoolNmr
        prizePoolUsd
        ruleset
      }
    }
  """
  variables = Dict("tournament" => tournament)
  result = raw_query(api, query, variables=variables)
  rounds = result["data"]["rounds"]
  for round in rounds
      round["openTime"] = parse_datetime_string(round["openTime"])
      round["resolveTime"] = parse_datetime_string(round["resolveTime"])
      round["prizePoolNmr"] = parse_float_string(round["prizePoolNmr"])
      round["prizePoolUsd"] = parse_float_string(round["prizePoolUsd"])
  end

  return rounds 
end


function get_current_round(api::TournamentAPI; tournament::Int=TOURNAMENT)::Union{Real,Nothing}
  query = """
    query(\$tournament: Int!) {
      rounds(tournament: \$tournament number: 0) {
        number
      }
    }
  """
  variables = Dict("tournament" => tournament)
  data = raw_query(api, query, variables=variables)["data"]["rounds"][1]
  round_num = isempty(data) ? nothing : data["number"]
  return round_num
end


function get_tournaments(api::TournamentAPI; only_active::Bool=true)::Vector{Dict}
  query = """
    query {
      tournaments {
        id
        name
        tournament
        active
      }
    }
  """
  data = raw_query(api, query)["data"]["tournaments"]
  if only_active
    data = filter(d -> d["active"], data)
  end
  return data
end


function get_user_activities(api::TournamentAPI, username::String; tournament::Int=TOURNAMENT)::Vector{Dict}
  query = """
      query(\$tournament: Int!
            \$username: String!) {
        userActivities(tournament: \$tournament username: \$username) {
          resolved
          roundNumber
          tournament
          submission {
              concordance
              consistency
              date
              liveLogloss
              liveAuroc
              liveCorrelation
              validationLogloss
              validationAuroc
              validationCorrelation
          }
          stake {
              confidence
              date
              nmrEarned
              staked
              usdEarned
              value
              burned
          }
        }
      }
  """
  variables = Dict("tournament" => tournament, "username" => username)
  data = raw_query(api, query, variables=variables)["data"]["userActivities"]
  # filter rounds with no activity
  data = filter(item -> !isnothing(item["submission"]["date"]), data)
  for item in data
      if isnothing(item["stake"])
        delete!(item, "stake")
      elseif isnothing(item["stake"]["date"])
        delete!(item, "stake")
      else
        item["stake"]["date"] = parse_datetime_string(item["stake"]["date"])
        for col in ["confidence", "value", "nmrEarned", "usdEarned"]
          item["stake"][col] = parse_float_string(item["stake"][col]) 
        end
      end
    item["submission"]["date"] = parse_datetime_string(item["submission"]["date"]) 
  end
  return data
end


function get_submission_filenames(api::TournamentAPI; 
                                    tournament::Int=TOURNAMENT, 
                                    round_num::Union{Int,Nothing}=nothing, 
                                    model_id::Union{String,Nothing}=nothing)::Vector{Dict}
  query = """
    query(\$modelId: String) {
      model(modelId: \$modelId) {
        submissions {
          filename
          selected
          round {
              tournament
              number
          }
        }
      }
    }
  """
  variables = Dict("modelId" =>  model_id)
  data = raw_query(api, query, variables=variables, authorization=true)["data"]["model"]

  data = filter(item -> item["selected"], data["submissions"])
  filenames = map(item -> Dict(
    "round_num" => item["round"]["number"],
    "tournament" => item["round"]["tournament"],
    "filename" => item["filename"],
  ), data) 

  if !isnothing(round_num)
    filenames = filter(f -> f["round_num"] == round_num, filenames)
  end

  if !isnothing(tournament)
    filenames = filter(f -> f["tournament"] == tournament, filenames)
  end

  sort!(filenames, by=f->(f["round_num"], f["tournament"]))
  
  return filenames
end


function get_payments(api::TournamentAPI; model_id::Union{String,Nothing}=nothing)::Dict{String,Array}
  # Todo add stakeBonusPayments?
  query = """
    query(\$modelId: String) {
      model(modelId: \$modelId) {
        reputationPayments {
          insertedAt
          nmrAmount
        }
        otherUsdIssuances {
          insertedAt
          usdAmount
        }
        payments {
          nmrAmount
          usdAmount
          tournament
          round {
            number
            openTime
            resolveTime
            resolvedGeneral
            resolvedStaking
          }
        }
      }
    }
  """
  variables = Dict("modelId" => model_id)
  data = raw_query(api, query, variables=variables, authorization=true)["data"]
  payments = data["model"]
  # convert strings to python objects
  for payment in payments["payments"]
    payment["round"]["openTime"] = parse_datetime_string(payment["round"]["openTime"])
    payment["round"]["resolveTime"] = parse_datetime_string(payment["round"]["resolveTime"])
    payment["usdAmount"] = parse_float_string(payment["usdAmount"])
    payment["nmrAmount"] = parse_float_string(payment["nmrAmount"])
  end

  for payment in payments["reputationPayments"]
    payment["nmrAmount"] = parse_float_string(payment["nmrAmount"])
    payment["insertedAt"] = parse_float_string(payment["insertedAt"])
  end

  for payment in payments["otherUsdIssuances"]
    payment["usdAmount"] = parse_float_string(payment["usdAmount"])
    payment["insertedAt"] = parse_float_string(payment["insertedAt"])
  end
  return payments
end


function submission_status(api::TournamentAPI; model_id::Union{String,Nothing}=nothing)::Union{Dict,Nothing}
  query = """
    query(\$modelId: String) {
        model(modelId: \$modelId) {
          latestSubmission {
            concordance {
              pending
              value
            }
            consistency
            filename
            corrWithExamplePreds
            validationCorrelation
            validationSharpe
            validationFeatureExposure
            validationCorrelation
            validationCorrelationRating
            validationSharpe
            validationSharpeRating
            validationFeatureNeutralMean
            validationFeatureNeutralMeanRating
            validationStd
            validationStdRating
            validationMaxFeatureExposure
            validationMaxFeatureExposureRating
            validationMaxDrawdown
            validationMaxDrawdownRating
            validationCorrPlusMmcSharpe
            validationCorrPlusMmcSharpeRating
            validationMmcMean
            validationMmcMeanRating
            validationCorrPlusMmcSharpeDiff
            validationCorrPlusMmcSharpeDiffRating
          }
        }
      }
  """

  variables = Dict("modelId" => model_id)
  data = raw_query(api, query, variables=variables, authorization=true)
  latestSubmission = data["data"]["model"]["latestSubmission"]
  if isempty(latestSubmission)
    return nothing
  end
  return latestSubmission[1]
end


function upload_predictions(api::TournamentAPI, file_path::String; 
                              tournament::Int=TOURNAMENT, model_id::Union{String,Nothing}=nothing)::String
  @info "uploading predictions..."
  auth_query = """
    query(\$filename: String! \$tournament: Int! \$modelId: String) {
      submission_upload_auth(filename: \$filename
                            tournament: \$tournament
                            modelId: \$modelId) {
          filename
          url
      }
    }
  """
  variables = Dict(
    "filename" => basename(file_path),
    "tournament" => tournament,
    "modelId" => model_id
  )
  submission_resp = raw_query(api, auth_query, variables=variables, authorization=true)
  submission_auth = submission_resp["data"]["submission_upload_auth"]
  headers = haskey(ENV, "NUMERAI_COMPUTE_ID") ? ["x_compute_id"=>ENV["NUMERAI_COMPUTE_ID"],] : []
  
  open(file_path, "r") do io
    body = read(io)
    HTTP.request("PUT", submission_auth["url"], headers, body)
  end

  create_query = """
    mutation(\$filename: String! \$tournament: Int! \$modelId: String) {
      create_submission(filename: \$filename
                        tournament: \$tournament
                        modelId: \$modelId) {
        id
      }
    }
  """
  variables = Dict(
    "filename" => submission_auth["filename"],
    "tournament" => tournament,
    "modelId" => model_id
  )
  create = raw_query(api, create_query, variables=variables, authorization=true)
  submission_id = create["data"]["create_submission"]["id"]

  return submission_id
end


function check_new_round(api::TournamentAPI; hours::Int=24, tournament::Int=TOURNAMENT)::Bool
  query = """
    query(\$tournament: Int!) {
      rounds(tournament: \$tournament number: 0) {
        number
        openTime
      }
    }
  """
  variables = Dict("tournament" => tournament)
  rounds = raw_query(api, query, variables=variables)["data"]["rounds"]
  if isempty(rounds)
    return false
  end
  round = rounds[1]
  open_time = parse_datetime_string(round["openTime"])
  now = now(tz"UTC")
  is_new_round = open_time > now - Dates.Hour(hours)
  return is_new_round
end


function tournament_number2name(api::TournamentAPI, number::Int)::Union{String,Nothing}
  tournaments = get_tournaments(api, only_active=false)
  dict = Dict(tournament["tournament"] => tournament["name"] for tournament in tournaments)
  return get(dict, number, nothing)
end


function tournament_name2number(api::TournamentAPI, name::String)::Union{Int,Nothing}
  tournaments = get_tournaments(api, only_active=false)
  dict = Dict(tournament["name"] => tournament["tournament"] for tournament in tournaments)
  return get(dict, name, nothing)
end


function get_leaderboard(api::TournamentAPI; limit::Int=50, offset::Int=0)::Vector{Dict}
  query = """
    query(\$limit: Int! \$offset: Int!) {
      v2Leaderboard(limit: \$limit offset: \$offset) {
        bonusPerc
        nmrStaked
        oldStakeValue
        prevRank
        prevStakedRank
        rank
        stakedRank
        reputation
        rolling_score_rep
        tier
        username
        leaderboardBonus
        averageCorrelationPayout
        payoutPending
        payoutSettled
        badges
      }
    }
  """
  variables = Dict("limit" => limit, "offset" => offset)
  data = raw_query(api, query, variables=variables)["data"]["v2Leaderboard"]
  for item in data
    item["nmrStaked"] = parse_float_string(item["nmrStaked"])
  end
  return data
end


function stake_set(api::TournamentAPI, nmr::Union{Float64,String})::Union{Dict,Nothing}
  username = get_account(api)["username"]

  # fetch current stake
  current = stake_get(api, username)

  # convert everything to decimals
  if isnothing(current)
    current = 0.
  end

  if nmr isa String
    nmr = parse(Float64, nmr)
  end
  
  if nmr === current
    @info "Stake already at desired value. Nothing to do."
    return nothing
  elseif nmr < current
    return stake_decrease(api, current - nmr)
  elseif nmr > current
    return stake_increase(api, nmr - current)
  end
end


function stake_get(api::TournamentAPI, username::String)::Float64
  query = """
    query(\$username: String!) {
      v2UserProfile(username: \$username) {
        dailyUserPerformances {
          stakeValue
        }
      }
    }
  """
  variables = Dict("username" => username)

  data = raw_query(api, query, variables=variables)["data"]["v2UserProfile"]
  stake = data["dailyUserPerformances"][1]["stakeValue"]

  return stake
end


function stake_change(api::TournamentAPI, nmr::Union{Float64,String};
                       action::String="decrease", 
                       model_id::Union{String,Nothing}=nothing,
                       tournament::Int=TOURNAMENT)::Dict
  query = """
    mutation(\$value: String! \$type: String! \$tournamentNumber: Int! \$modelId: String) {
        v2ChangeStake(value: \$value type: \$type modelId: \$modelId tournamentNumber: \$tournamentNumber) {
          dueDate
          requestedAmount
          status
          type
        }
  }
  """
  variables = Dict(
    "value" => string(nmr),
    "type" => action,
    "modelId" => model_id,
    "tournamentNumber" => tournament
  )
  result = raw_query(api, query, variables=variables, authorization=true)
  stake = result["data"]["v2ChangeStake"]
  stake["requestedAmount"] = parse_float_string(stake["requestedAmount"])
  stake["dueDate"] = parse_datetime_string(stake["dueDate"])
  return stake
end


function stake_drain(api::TournamentAPI; 
                      model_id::Union{String,Nothing}=nothing, 
                      tournament::Int=TOURNAMENT)::Dict
  return stake_decrease(api, 11000000, model_id=model_id, tournament=tournament)
end


function stake_decrease(api::TournamentAPI, nmr::Union{Float64,String};
                        model_id::Union{String,Nothing}=nothing,
                        tournament::Int=TOURNAMENT)::Dict
  return stake_change(api, nmr, action="decrease", model_id=model_id, tournament=tournament)
end


function stake_increase(api::TournamentAPI, nmr::Union{Float64,String};
                        model_id::Union{String,Nothing}=nothing,
                        tournament::Int=TOURNAMENT)::Dict
  return stake_change(api, nmr, action="increase", model_id=model_id, tournament=tournament)
end


function public_user_profile(api::TournamentAPI, username::String)::Dict
  query = """
    query(\$username: String!) {
      v2UserProfile(username: \$username) {
        badges
        historicalNetNmrEarnings
        historicalNetUsdEarnings
        id
        netEarnings
        startDate
        username
        bio
        totalStake
      }
    }
  """
  variables = Dict("username" => username)
  data = raw_query(api, query, variables=variables)["data"]["v2UserProfile"]
  data["startDate"] = parse_datetime_string(data["startDate"])
  
  return data
end


function daily_user_performances(api::TournamentAPI, username::String)::Vector{Dict}
  query = """
    query(\$username: String!) {
      v2UserProfile(username: \$username) {
        dailyUserPerformances {
          averageCorrelation
          averageCorrelationPayout
          sumDeltaCorrelation
          finalCorrelation
          payoutPending
          payoutSettled
          date
          leaderboardBonus
          rank
          reputation
          rolling_score_rep
          stakeValue
          tier
        }
      }
    }
  """
  variables = Dict("username" => username)
  data = raw_query(api, query, variables=variables)["data"]["v2UserProfile"]
  performances = data["dailyUserPerformances"]
  
  for perf in performances
    perf["date"] = parse_datetime_string(perf["date"])
  end

  return performances
end


function round_details(api::TournamentAPI, round_num::Int)::Vector{Dict}
  query = """
    query(\$roundNumber: Int!) {
      v2RoundDetails(roundNumber: \$roundNumber) {
        userPerformances {
          date
          correlation
          username
        }
      }
    }
  """
  variables = Dict("roundNumber" => round_num)
  data = raw_query(api, query, variables=variables)["data"]["v2RoundDetails"]
  performances = data["userPerformances"]

  for perf in performances
    perf["date"] = parse_datetime_string(perf["date"])
  end
  return performances
end


function daily_submission_performances(api::TournamentAPI, username::String)::Vector{Dict}
  query = """
    query(\$username: String!) {
      v2UserProfile(username: \$username) {
        dailySubmissionPerformances {
          date
          correlation
          roundNumber
          mmc
          correlationWithMetamodel
        }
      }
    }
  """
  variables = Dict("username" => username)
  data = raw_query(api, query, variables=variables)["data"]["v2UserProfile"]
  performances = data["dailySubmissionPerformances"]

  for perf in performances
    perf["date"] = parse_datetime_string(perf["date"])
  end
  return performances
end
