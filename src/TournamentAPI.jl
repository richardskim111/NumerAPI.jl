
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


"""Fetch url of the current dataset.
  Args:
      tournament (int, optional): ID of the tournament, defaults to 8
        -- DEPRECATED there is only one tournament nowadays
  Returns:
      str: url of the current dataset
  Example:
      >>> NumerAPI().get_dataset_url()
      https://numerai-datasets.s3.amazonaws.com/t1/104/n.........
"""
function get_dataset_url(api::TournamentAPI; tournament::Int=TOURNAMENT)::String
  query = """
    query(\$tournament: Int!) {
        dataset(tournament: \$tournament)
    }"""

  variables = Dict("tournament" => tournament)
  
  url = raw_query(api, query, variables=variables)["data"]["dataset"]

  return url
end


"""Download dataset for the current active round.
  Args:
      dest_path (str, optional): destination folder, defaults to `.`
      dest_filename (str, optional): desired filename of dataset file,
          defaults to `numerai_dataset_<round number>.zip`
      unzip (bool, optional): indication of whether the training data
          should be unzipped, defaults to `True`
      tournament (int, optional): ID of the tournament, defaults to 8
          -- DEPRECATED there is only one tournament nowadays
  Returns:
      str: Path to the downloaded dataset
  Example:
      >>> NumerAPI().download_current_dataset()
      ./numerai_dataset_104.zip
"""
function download_current_dataset(api::TournamentAPI; 
                                    dest_path::String=".", 
                                    dest_filename::Union{String,Nothing}=nothing,
                                    unzip::Bool=true, 
                                    tournament::Int=TOURNAMENT,
                                    show_progress_bar::Bool=true)::String

  if isnothing(dest_filename)
    round_number = get_current_round(api, tournament)
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


"""Fetch url of the latest data url for a specified data type
  Args:
      data_type (str): type of data to return
      extension (str): file extension to get (optional, defaults to csv)
  Returns:
      str: url of the requested dataset
  Example:
      >>> url = NumerAPI().get_latest_data_url("live", "csv")
      >>> numerapi.utils.download_file(url, ".")
"""
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


"""Retrieves information about all competitions
  Args:
      tournament (int, optional): ID of the tournament, defaults to 8
          -- DEPRECATED there is only one tournament nowadays
  Returns:
      list of dicts: list of rounds
      Each round's dict contains the following items:
          * datasetId (`str`)
          * number (`int`)
          * openTime (`datetime`)
          * resolveTime (`datetime`)
          * participants (`int`): number of participants
          * prizePoolNmr (`decimal.Decimal`)
          * prizePoolUsd (`decimal.Decimal`)
          * resolvedGeneral (`bool`)
          * resolvedStaking (`bool`)
          * ruleset (`string`)
  Example:
      >>> NumerAPI().get_competitions()
      [
        {'datasetId': '59a70840ca11173c8b2906ac',
        'number': 71,
        'openTime': datetime.datetime(2017, 8, 31, 0, 0),
        'resolveTime': datetime.datetime(2017, 9, 27, 21, 0),
        'participants': 1287,
        'prizePoolNmr': Decimal('0.00'),
        'prizePoolUsd': Decimal('6000.00'),
        'resolvedGeneral': True,
        'resolvedStaking': True,
        'ruleset': 'p_auction'
        },
        ..
      ]
"""
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


"""Get user activities (works for all users!).
  Args:
      username (str): name of the user
      tournament (int): ID of the tournament (optional, defaults to 8)
          -- DEPRECATED there is only one tournament nowadays
  Returns:
      list: list of user activities (`dict`)
      Each activity in the list as the following structure:
          * resolved (`bool`)
          * roundNumber (`int`)
          * tournament (`int`)
          * submission (`dict`)
            * concordance (`bool`)
            * consistency (`float`)
            * date (`datetime`)
            * liveLogloss (`float`)
            * liveAuroc (`float`)
            * liveCorrelation (`float`)
            * validationLogloss (`float`)
            * validationAuroc (`float`)
            * validationCorrelation (`float`)
          * stake (`dict`)
            * confidence (`decimal.Decimal`)
            * date (`datetime`)
            * nmrEarned (`decimal.Decimal`)
            * staked (`bool`)
            * usdEarned (`decimal.Decimal`)
            * burned (`bool`)
  Example:
      >>> NumerAPI().get_user_activities("slyfox", 5)
      [{'tournament': 5,
        'submission': {
          'validationLogloss': 0.6928141372700635,
          'validationAuroc': 0.52,
          'validationCorrelation': 0.52,
          'liveLogloss': None,
          'liveAuroc': None,
          'liveCorrelation': None,
          'date': datetime.datetime(2018, 7, 14, 17, 5, 27, 206042),
          'consistency': 83.33333333333334,
          'concordance': True},
        'stake': {'value': Decimal('0.10'),
          'usdEarned': None,
          'staked': True,
          'nmrEarned': None,
          'date': datetime.datetime(2018, 7, 14, 17, 7, 7, 877845),
          'confidence': Decimal('0.100000000000000000')},
          'burned': False
        'roundNumber': 116,
        'resolved': False},
        {'tournament': 5,
        'submission': {'validationLogloss': 0.6928141372700635,
          ...
          ]
"""
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


"""Get filenames of the submission of the user.
  Args:
      tournament (int): optionally filter by ID of the tournament
          -- DEPRECATED there is only one tournament nowadays
      round_num (int): optionally filter round number
      model_id (str): Target model UUID (required for accounts with
          multiple models)
  Returns:
      list: list of user filenames (`dict`)
      Each filenames in the list as the following structure:
          * filename (`str`)
          * round_num (`int`)
          * tournament (`int`)
  Example:
      >>> api = NumerAPI(secret_key="..", public_id="..")
      >>> model = api.get_models()['uuazed']
      >>> api.get_submission_filenames(3, 111, model)
      [{'filename': 'model57-dMpHpYMPIUAF.csv',
        'round_num': 111,
        'tournament': 3}]
"""
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


"""Get all your payments.
  Args:
      model_id (str): Target model UUID (required for accounts with
          multiple models)
  Returns:
      dict of lists: payments & reputationPayments
      A dict containing the following items:
        * payments (`list`)
          * nmrAmount (`decimal.Decimal`)
          * usdAmount (`decimal.Decimal`)
          * tournament (`str`)
          * round (`dict`)
            * number (`int`)
            * openTime (`datetime`)
            * resolveTime (`datetime`)
            * resolvedGeneral (`bool`)
            * resolvedStaking (`bool`)
        * reputationPayment (`list`)
          * nmrAmount (`decimal.Decimal`)
          * insertedAt (`datetime`)
  Example:
      >>> api = NumerAPI(secret_key="..", public_id="..")
      >>> model = api.get_models()['uuazed']
      >>> api.get_payments(model)
      {'payments': [
          {'nmrAmount': Decimal('0.00'),
          'round': {'number': 84,
          'openTime': datetime.datetime(2017, 12, 2, 18, 0),
          'resolveTime': datetime.datetime(2018, 1, 1, 18, 0),
          'resolvedGeneral': True,
          'resolvedStaking': True},
          'tournament': 'staking',
          'usdAmount': Decimal('17.44')},
          ...
          ],
      'reputationPayments': [
        {'nmrAmount': Decimal('0.1'),
          'insertedAt': datetime.datetime(2017, 12, 2, 18, 0)},
          ...
          ],
      'otherUsdIssuances': [
          {'usdAmount': Decimal('0.1'),
          'insertedAt': datetime.datetime(2017, 12, 2, 18, 0)},
          ...
      ]
      }
"""
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


"""submission status of the last submission associated with the account
  Args:
      model_id (str)
  Returns:
      dict: submission status with the following content:
          * concordance (`dict`):
          * pending (`bool`)
          * value (`bool`): whether the submission is concordant
          * consistency (`float`): consistency of the submission
          * filename (`string`)
          * corrWithExamplePreds (`float`)
          * validationCorrelation (`float`)
          * validationCorrelationRating (`float`)
          * validationSharpe (`float`)
          * validationSharpeRating  (`float`)
          * validationFeatureNeutralMean (`float`)
          * validationFeatureNeutralMeanRating (`float`)
          * validationStd (`float`)
          * validationStdRating (`float`)
          * validationMaxFeatureExposure (`float`)
          * validationMaxFeatureExposureRating (`float`)
          * validationMaxDrawdown (`float`)
          * validationMaxDrawdownRating (`float`)
          * validationCorrPlusMmcSharpe (`float`)
          * validationCorrPlusMmcSharpeRating (`float`)
          * validationMmcMean (`float`)
          * validationMmcMeanRating (`float`)
          * validationCorrPlusMmcSharpeDiff (`float`)
          * validationCorrPlusMmcSharpeDiffRating (`float`)
  Example:
      >>> api = NumerAPI(secret_key="..", public_id="..")
      >>> model_id = api.get_models()['uuazed']
      >>> api.submission_status(model_id)
      {'concordance': None,
      'consistency': None,
      'corrWithExamplePreds': 0.7217288907243551,
      'filename': 'model57-HPzOyr56TPaD.csv',
      'validationCorrPlusMmcSharpe': 1.0583461013814541,
      'validationCorrPlusMmcSharpeDiff': -0.23505145970149166,
      'validationCorrPlusMmcSharpeDiffRating': 0.02989708059701668,
      'validationCorrPlusMmcSharpeRating': 0.7123167873588739,
      'validationCorrelation': 0.023244452475027225,
      'validationCorrelationRating': 0.6026148514721896,
      'validationFeatureExposure': None,
      'validationFeatureNeutralMean': 0.019992061095211483,
      'validationFeatureNeutralMeanRating': 0.7689254267389032,
      'validationMaxDrawdown': -0.03710774157542396,
      'validationMaxDrawdownRating': 0.8099139824952893,
      'validationMaxFeatureExposure': 0.17339716040222303,
      'validationMaxFeatureExposureRating': 0.9200079988669775,
      'validationMmcMean': 0.0027797270044420106,
      'validationMmcMeanRating': 0.615821958518417,
      'validationSharpe': 1.2933975610829458,
      'validationSharpeRating': 0.9921399536701735,
      'validationStd': 0.017971622318171787,
      'validationStdRating': 0.9842992879669488}
"""
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


"""Upload predictions from file.
Args:
    file_path (str): CSV file with predictions that will get uploaded
    tournament (int): ID of the tournament (optional, defaults to 8)
        -- DEPRECATED there is only one tournament nowadays
    model_id (str): Target model UUID (required for accounts with
        multiple models)
Returns:
    str: submission_id
Example:
    >>> api = NumerAPI(secret_key="..", public_id="..")
    >>> model_id = api.get_models()['uuazed']
    >>> api.upload_predictions("prediction.cvs", model_id=model_id)
    '93c46857-fed9-4594-981e-82db2b358daf'
"""
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


"""Check if a new round has started within the last `hours`.
  Args:
      hours (int, optional): timeframe to consider, defaults to 24
      tournament (int): ID of the tournament (optional, defaults to 8)
          -- DEPRECATED there is only one tournament nowadays
  Returns:
      bool: True if a new round has started, False otherwise.
  Example:
      >>> NumerAPI().check_new_round()
      False
"""
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


"""Get the current leaderboard
  Args:
      limit (int): number of items to return (optional, defaults to 50)
      offset (int): number of items to skip (optional, defaults to 0)
  Returns:
      list of dicts: list of leaderboard entries
      Each dict contains the following items:
          * username (`str`)
          * tier (`str`)
          * reputation (`float`) -- DEPRECATED since 2020-04-05
          * rolling_score_rep (`float`)
          * rank (`int`)
          * prevRank (`int`)
          * stakedRank (`int`)
          * prevStakedRank (`int`)
          * nmrStaked (`decimal.Decimal`)
          * oldStakeValue (`decimal.Decimal`)
          * leaderboardBonus (`decimal.Decimal`)
          * averageCorrelationPayout (`decimal.Decimal`)
          * payoutPending (`decimal.Decimal`)
          * payoutSettled (`decimal.Decimal`)
          * bonusPerc (`float`)
          * badges (`list of str`)
  Example:
      >>> numerapi.NumerAPI().get_leaderboard(1)
      [{'username': 'anton',
        'tier': 'C',
        'reputation': -0.00499721,
        'rolling_score_rep': -0.00499721,
        'rank': 143,
        'prevRank': 116,
        'stakedRank': 103,
        'prevStakedRank': 102,
        'nmrStaked': Decimal('12'),
        'oldStakeValue': Decimal('12'),
        `leaderboardBonus`: Decimal('0.1')
        `averageCorrelationPayout`: Decimal('0.1')
        `payoutPending`: Decimal('0.1')
        `payoutSettled`: Decimal('0.1')
        'bonusPerc': 0.5,
        'badges': ['submission-streak_1', 'burned_2']}]
"""
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


"""Set stake to value by decreasing or increasing your current stake
  Args:
      nmr (float or str): amount of NMR you want to stake
  Returns:
      dict: stake information with the following content:
        * insertedAt (`datetime`)
        * status (`str`)
        * txHash (`str`)
        * value (`decimal.Decimal`)
        * source (`str`)
        * to (`str`)
        * from (`str`)
        * posted (`bool`)
  Example:
      >>> api = NumerAPI(secret_key="..", public_id="..")
      >>> api.stake_set(10)
      {'from': None,
      'insertedAt': None,
      'status': None,
      'txHash': '0x76519...2341ca0',
      'from': '',
      'to': '',
      'posted': True,
      'value': '10'}
"""
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


"""Get your current stake amount.
  Args:
      username (str)
  Returns:
      float: current stake (including projected NMR earnings from open
            rounds)
  Example:
      >>> api = NumerAPI()
      >>> api.stake_get("uuazed")
      1.1
"""
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


"""Change stake by `value` NMR.
  Args:
      nmr (float or str): amount of NMR you want to increase/decrease
      action (str): `increase` or `decrease`
      model_id (str): Target model UUID (required for accounts with
          multiple models)
      tournament (int): ID of the tournament (optional, defaults to 8)
          -- DEPRECATED there is only one tournament nowadays
  Returns:
      dict: stake information with the following content:
        * dueDate (`datetime`)
        * status (`str`)
        * requestedAmount (`decimal.Decimal`)
        * type (`str`)
  Example:
      >>> api = NumerAPI(secret_key="..", public_id="..")
      >>> model = api.get_models()['uuazed']
      >>> api.stake_change(10, "decrease", model)
      {'dueDate': None,
      'requestedAmount': decimal.Decimal('10'),
      'type': 'decrease',
      'status': ''}
"""
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


"""Completely remove your stake.
  Args:
      model_id (str): Target model UUID (required for accounts with
          multiple models)
      tournament (int): ID of the tournament (optional, defaults to 8)
          -- DEPRECATED there is only one tournament nowadays
  Returns:
      dict: stake information with the following content:
        * dueDate (`datetime`)
        * status (`str`)
        * requestedAmount (`decimal.Decimal`)
        * type (`str`)
  Example:
      >>> api = NumerAPI(secret_key="..", public_id="..")
      >>> model = api.get_models()['uuazed']
      >>> api.stake_drain(model)
      {'dueDate': None,
      'requestedAmount': decimal.Decimal('11000000'),
      'type': 'decrease',
      'status': ''}
"""
function stake_drain(api::TournamentAPI; 
                      model_id::Union{String,Nothing}=nothing, 
                      tournament::Int=TOURNAMENT)::Dict
  return stake_decrease(api, 11000000, model_id=model_id, tournament=tournament)
end


"""Decrease your stake by `value` NMR.
  Args:
      nmr (float or str): amount of NMR you want to reduce
      model_id (str): Target model UUID (required for accounts with
          multiple models)
      tournament (int): ID of the tournament (optional, defaults to 8)
          -- DEPRECATED there is only one tournament nowadays
  Returns:
      dict: stake information with the following content:
        * dueDate (`datetime`)
        * status (`str`)
        * requestedAmount (`decimal.Decimal`)
        * type (`str`)
  Example:
      >>> api = NumerAPI(secret_key="..", public_id="..")
      >>> model = api.get_models()['uuazed']
      >>> api.stake_decrease(10, model)
      {'dueDate': None,
      'requestedAmount': decimal.Decimal('10'),
      'type': 'decrease',
      'status': ''}
"""
function stake_decrease(api::TournamentAPI, nmr::Union{Float64,String};
                        model_id::Union{String,Nothing}=nothing,
                        tournament::Int=TOURNAMENT)::Dict
  return stake_change(api, nmr, action="decrease", model_id=model_id, tournament=tournament)
end


"""Increase your stake by `value` NMR.
  Args:
      nmr (float or str): amount of additional NMR you want to stake
      model_id (str): Target model UUID (required for accounts with
          multiple models)
      tournament (int): ID of the tournament (optional, defaults to 8)
          -- DEPRECATED there is only one tournament nowadays
  Returns:
      dict: stake information with the following content:
        * dueDate (`datetime`)
        * status (`str`)
        * requestedAmount (`decimal.Decimal`)
        * type (`str`)
  Example:
      >>> api = NumerAPI(secret_key="..", public_id="..")
      >>> model = api.get_models()['uuazed']
      >>> api.stake_increase(10, model)
      {'dueDate': None,
      'requestedAmount': decimal.Decimal('10'),
      'type': 'increase',
      'status': ''}
"""
function stake_increase(api::TournamentAPI, nmr::Union{Float64,String};
                        model_id::Union{String,Nothing}=nothing,
                        tournament::Int=TOURNAMENT)::Dict
  return stake_change(api, nmr, action="increase", model_id=model_id, tournament=tournament)
end


"""Fetch the public profile of a user.
  Args:
      username (str)
  Returns:
      dict: user profile including the following fields:
          * username (`str`)
          * startDate (`datetime`)
          * netEarnings (`float`)
          * id (`string`)
          * historicalNetUsdEarnings (`float`)
          * historicalNetNmrEarnings (`float`)
          * badges (`list of str`)
          * bio (`str`)
          * totalStake (`float`)
  Example:
      >>> api = NumerAPI()
      >>> api.public_user_profile("niam")
      {'username': 'niam',
      'startDate': datetime.datetime(2018, 6, 14, 22, 58, 2, 186221),
      'netEarnings': None,
      'id': '024c9bb9-77af-4b3f-91c7-63062fce2b80',
      'historicalNetUsdEarnings': '3669.41',
      'historicalNetNmrEarnings': '1094.247665827645663410',
      'badges': ['burned_3', 'compute_0', 'submission-streak_1'],
      'bio': 'blabla',
      'totalStake': 12.2}
"""
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


"""Fetch daily performance of a user.
  Args:
      username (str)
  Returns:
      list of dicts: list of daily user performance entries
      For each entry in the list, there is a dict with the following
      content:
          * tier (`str`)
          * stakeValue (`float` or none)
          * reputation (`float`) -- DEPRECATED since 2020-04-05
          * rolling_score_rep (`float`)
          * rank (`int`)
          * leaderboardBonus (`float` or None)
          * date (`datetime`)
          * averageCorrelationPayout (`float` or None)
          * averageCorrelation (`float`)
          * sumDeltaCorrelation (`float`)
          * finalCorrelation (`float`)
          * payoutPending (`float` or None)
          * payoutSettled (`float` or None)
  Example:
      >>> api = NumerAPI()
      >>> api.daily_user_performances("uuazed")
      [{'tier': 'A',
        'stakeValue': None,
        'reputation': 0.0017099,
        'rolling_score_rep': 0.0111,
        'rank': 32,
        'leaderboardBonus': None,
        'date': datetime.datetime(2019, 10, 16, 0, 0),
        'averageCorrelationPayout': None,
        'averageCorrelation': -0.000983637,
        'sumDeltaCorrelation': -0.000983637,
        'finalCorrelation': -0.000983637,
        'payoutPending': None,
        'payoutSettled': None},
        ...
      ]
"""
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


"""Fetch all correlation scores of a round.
  Args:
      round_num (int)
  Returns:
      list of dicts: list containing scores for each user
      For each entry in the list, there is a dict with the following
      content:
          * date (`datetime`)
          * correlation (`float`)
          * username (`str`)
  Example:
      >>> api = NumerAPI()
      >>> api.round_details(180)
      [{'username': 'abcd',
        'date': datetime.datetime(2019, 11, 15, 0, 0),
        'correlation': 0.02116131087},
        ...
      ]
"""
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
    perf["date"] = DateTime(perf["date"], "yyyy-mm-dd")
  end
  return performances
end


"""Fetch daily performance of a user's submissions.
  Args:
      username (str)
  Returns:
      list of dicts: list of daily submission performance entries
      For each entry in the list, there is a dict with the following
      content:
          * date (`datetime`)
          * correlation (`float`)
          * roundNumber (`int`)
          * mmc (`float`): metamodel contribution
          * fnc (`float`): feature neutral correlation
          * correlationWithMetamodel (`float`)
  Example:
      >>> api = NumerAPI()
      >>> api.daily_user_performances("uuazed")
      [{'roundNumber': 181,
        'correlation': -0.011765912,
        'date': datetime.datetime(2019, 10, 16, 0, 0),
        'mmc': 0.3,
        'fnc': 0.1,
        'correlationWithMetamodel': 0.87},
        ...
      ]
"""
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
