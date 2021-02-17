

const PUBLIC_DATASETS_URL = "https://numerai-public-datasets.s3-us-west-2.amazonaws.com"


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


function get_dataset_url(api::TournamentAPI; tournament::Int=8)::String
  query = """
    query(\$tournament: Int!) {
        dataset(tournament: \$tournament)
    }"""

  variables = Dict("tournament" => tournament)
  
  url = raw_query(api, query, variables=variables)["data"]["dataset"]

  return url
end


function _unzip_file(src_path::String, dest_path::String, filename::String)::Bool

  return true
end


function download_current_dataset(api::TournamentAPI; 
                                    dest_path::String=".", 
                                    dest_filename::Union{String,Nothing}=nothing,
                                    unzip::Bool=true, 
                                    tournament::Int=8)::String
  
end


function get_latest_data_url(api::TournamentAPI;
                              data_type::DataType=String,
                              extension::String="csv")::String

end


function download_latest_data(api::TournamentAPI, data_type::String;
                              extension::String="csv",
                              dest_path::String=".",
                              dest_filename::Union{String,Nothing}=nothing)::Nothing

end


function get_competitions(api::TournamentAPI; tournament::Int=8)::Vector{Dict}
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


function get_current_round(api::TournamentAPI; tournament::Int=8)::Union{Real,Nothing}
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


function get_user_activities(api::TournamentAPI, username::String; tournament::Int=8)::Vector{Dict}
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
                                    tournament::Int=8, 
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


function submission_status(api::TournamentAPI; model_id::Union{String,Nothing}=nothing)::Dict

end


function upload_predictions(api::TournamentAPI, file_path::String; 
                              tournament::Int=8, model_id::Union{String,Nothing}=nothing)::String
  
end


function check_new_round(api::TournamentAPI; hours::Int=24, tournament::Int=8)::Bool

end


function tournament_number2name(api::TournamentAPI, number::Int)::String

end


function tournament_name2number(api::TournamentAPI, name::String)::Int

end


function get_leaderboard(api::TournamentAPI; limit::Int=50, offset::Int=0)::Vector{Dict}
  
end


function state_set(api::TournamentAPI, nmr::Union{Float64,String})::Dict

end


function stake_get(api::TournamentAPI, username::String)::Float64

end


function stake_change(api::TournamentAPI, nmr::Union{Float64,String};
                       action::String="decrease", 
                       model_id::Union{String,Nothing}=nothing,
                       tournament::Int=8)::Dict

end


function stake_drain(api::TournamentAPI; 
                      model_id::Union{String,Nothing}=nothing, 
                      tournament::Int=8)::Dict
  
end


function stake_decrease(api::TournamentAPI, nmr::Union{Float64,String};
                        model_id::Union{String,Nothing}=nothing,
                        tournament::Int=8)::Dict

end


function stake_increase(api::TournamentAPI, nmr::Union{Float64,String};
                        model_id::Union{String,Nothing}=nothing,
                        tournament::Int=8)::Dict

end


function public_user_profile(api::TournamentAPI, username::String)::Dict

end


function daily_user_performances(api::TournamentAPI, username::String)::Vector{Dict}

end


function round_details(api::TournamentAPI, round_num::Int)::Vector{Dict}

end


function daily_submission_performances(api::TournamentAPI, username::String)::Vector{Dict}

end
