module Signals
  
  using JSON, HTTP, Dates, TimeZones
  include("BaseAPI.jl")

  export SignalsAPI, 
         get_leaderboard,
         upload_predictions,
         submission_status,
         public_user_profile,
         daily_user_performances,
         daily_submissions_performances,
         download_validation_data
         

  const SIGNALS_DOM = "https://numerai-signals-public-data.s3-us-west-2.amazonaws.com"
  const TOURNAMENT = 11


  struct SignalsAPI <: BaseAPI
    public_id::Union{String,Nothing}
    secret_key::Union{String,Nothing}
    tournament::Int
    signals_dom::String
    ticker_universe_url::String
    historical_data_url::String
  end


  function SignalsAPI(public_id::Union{String,Nothing}, 
                      secret_key::Union{String,Nothing};
                      tournament=TOURNAMENT)
    return SignalsAPI(public_id, secret_key, tournament, SIGNALS_DOM, 
                                    "$(SIGNALS_DOM)/latest_universe.csv",
                                    "$(SIGNALS_DOM)/signals_train_val_bbg.csv")
  end


  """
    get_leaderboard(api::SignalsAPI[, limit::Int[, offset::Int]]) -> Vector{Dict}
  
  Get the current Numerai Signals leaderboard

  # Arguments
  - `limit::Int=50`: number of items to return (optional, defaults to 50)
  - `offset::Int=0`: number of items to skip (optional, defaults to 0)
  
  # Example
  ```julia-repl
  julia> get_leaderboard(signal_api)
  ````
  """
  function get_leaderboard(api::SignalsAPI; limit::Int=50, offset::Int=0)::Vector{Dict}
    query = """
      query(\$limit: Int! \$offset: Int!) {
        signalsLeaderboard(limit: \$limit offset: \$offset) {
          prevRank
          rank
          sharpe
          today
          username
          mmc
          mmcRank
          nmrStaked
        }
      }
    """
    variables = Dict( "limit" => limit, "offset" => offset )
    data = raw_query(api, query, variables=variables)["data"]["signalsLeaderboard"]
    return data
  end


  """Upload predictions from file.
    Args:
        file_path (str): CSV file with predictions that will get uploaded
        model_id (str): Target model UUID (required for accounts
                        with multiple models)
    Returns:
        str: submission_id
    Example:
        >>> api = SignalsAPI(secret_key="..", public_id="..")
        >>> model_id = api.get_models()['uuazed']
        >>> api.upload_predictions("prediction.cvs", model_id=model_id)
        '93c46857-fed9-4594-981e-82db2b358daf'
  """
  function upload_predictions(api::SignalsAPI, file_path::String; 
                                model_id::Union{String,Nothing}=nothing)::String
    @info "uploading predictions..."
    auth_query = """
      query(\$filename: String! \$modelId: String) {
        submissionUploadSignalsAuth(filename: \$filename modelId: \$modelId) {
              filename
              url
          }
      }
    """
    variables = Dict( "filename" => basename(file_path), "modelId" => model_id )
    submission_resp = raw_query(api, auth_query, variables=variables, authorization=true)
    submission_auth = submission_resp["data"]["submissionUploadSignalsAuth"]
    headers = haskey(ENV, "NUMERAI_COMPUTE_ID") ? ["x_compute_id"=>ENV["NUMERAI_COMPUTE_ID"],] : []

    open(file_path, "r") do io
      HTTP.request("PUT", submission_auth["url"], headers, read(io))
    end

    create_query = """
      mutation(\$filename: String! \$modelId: String) {
        createSignalsSubmission(filename: \$filename modelId: \$modelId) {
          id
          firstEffectiveDate
        }
      }
    """
    variables = Dict( "filename" => submission_auth["filename"], "modelId" => model_id )
    create = raw_query(api, create_query, variables=variables, authorization=true)
    return create["data"]["createSignalsSubmission"]["id"]
  end


  """submission status of the last submission associated with the account
    Args:
        model_id (str)
    Returns:
        dict: submission status with the following content:
            * firstEffectiveDate (`datetime.datetime`):
            * userId (`string`)
            * filename (`string`)
            * id (`string`)
            * submissionIp (`string`)
            * submittedCount (`int`)
            * filteredCount (`int`)
            * invalidTickers (`string`)
            * hasHistoric (`bool`)
            * historicMean (`float`)
            * historicStd (`float`)
            * historicSharpe (`float`)
            * historicMaxDrawdown (`float`)
    Example:
        >>> api = SignalsAPI(secret_key="..", public_id="..")
        >>> model_id = api.get_models()['uuazed']
        >>> api.submission_status(model_id)
        {'firstEffectiveDate': datetime.datetime(2020, 5, 12, 1, 23),
          'userId': "slyfox",
          'filename': 'model57-HPzOyr56TPaD.csv',
          'id': '1234'
          'submissionIp': "102.142.12.12",
          'submittedCount': 112,
          'filteredCount': 12,
          'invalidTickers': 'AAAPL,GOOOG',
          'hasHistoric': true,
          'historicMean': 1.23,
          'historicStd': 2.34,
          'historicSharpe': 3.45,
          'historicMaxDrawdown': 4.56}
  """
  function submission_status(api::SignalsAPI; model_id::Union{String,Nothing}=nothing)::Dict
    query = """
      query(\$modelId: String) {
          model(modelId: \$modelId) {
            latestSignalsSubmission {
              id
              filename
              firstEffectiveDate
              userId
              submissionIp
              submittedCount
              filteredCount
              invalidTickers
              hasHistoric
              historicMean
              historicStd
              historicSharpe
              historicMaxDrawdown
            }
          }
        }
    """
    variables = Dict( "modelId" =>  model_id )
    data = raw_query(api, query, variables=variables, authorization=true)
    return data["data"]["model"]["latestSignalsSubmission"]
  end


  """Fetch the public Numerai Signals profile of a user.
    Args:
        username (str)
    Returns:
        dict: user profile including the following fields:
            * username (`str`)
            * startDate (`datetime`)
            * id (`string`)
            * rank (`int`)
            * bio (`str`)
            * sharpe (`float`)
            * totalStake (`decimal.Decimal`)
    Example:
        >>> api = SignalsAPI()
        >>> api.public_user_profile("floury_kerril_moodle")
        {'bio': None,
          'id': '635db2a4-bdc6-4e5d-b515-f5120392c8c9',
          'rank': 1,
          'sharpe': 2.35,
          'startDate': datetime.datetime(2019, 3, 26, 0, 43),
          'username': 'floury_kerril_moodle',
          'totalStake': Decimal('14.630994874320760131')}
  """
  function public_user_profile(api::SignalsAPI, username::String)::Dict
    query = """
      query(\$username: String!) {
        signalsUserProfile(username: \$username) {
          rank
          id
          startDate
          username
          bio
          sharpe
          totalStake
        }
      }
    """
    variables = Dict( "username" => username )
    profile = raw_query(api, query, variables=variables)["data"]["signalsUserProfile"]
    profile["startDate"] = parse_datetime_string(profile["startDate"])
    profile["totalStake"] = parse_float_string(profile["totalStake"])
    return profile
  end


  """Fetch daily Numerai Signals performance of a user.
    Args:
        username (str)
    Returns:
        list of dicts: list of daily user performance entries
        For each entry in the list, there is a dict with the following
        content:
            * rank (`int`)
            * date (`datetime`)
            * sharpe (`float`)
            * mmcRep (`float`)
            * reputation (`float`)
    Example:
        >>> api = SignalsAPI()
        >>> api.daily_user_performances("floury_kerril_moodle")
        [{'date': datetime.datetime(2020, 5, 16, 0, 0,
          'rank': 1,
          'sharpe': 2.35,
          'mmcRep': 0.35,
          'reputation': 1.35
          },
          ...]
  """
  function daily_user_performances(api::SignalsAPI, username::String)::Vector{Dict}
    query = """
      query(\$username: String!) {
        signalsUserProfile(username: \$username) {
          dailyUserPerformances {
            rank
            date
            sharpe
            mmcRep
            reputation
          }
        }
      }
    """
    variables = Dict( "username" => username )
    data = raw_query(api, query, variables=variables)["data"]["signalsUserProfile"]
    performances = data["dailyUserPerformances"]
    for perf in performances
      perf["date"] = parse_datetime_string(perf["date"])
    end
    return performances
  end


  """Fetch daily Numerai Signals performance of a user's submissions.
    Args:
        username (str)
    Returns:
        list of dicts: list of daily submission performance entries
        For each entry in the list, there is a dict with the following
        content:
            * date (`datetime`)
            * returns (`float`)
            * submission_time (`datetime`)
            * correlation (`float`)
            * mmc (`float`)
            * roundNumber (`int`)
            * corrRep (`float`)
            * mmcRep (`float`)
    Example:
        >>> api = SignalsAPI()
        >>> api.daily_submissions_performances("uuazed")
        [{'date': datetime.datetime(2020, 5, 16, 0, 0),
          'returns': 1.256,
          'submissionTime': datetime.datetime(2020, 5, 12, 1, 23)},
          'corrRep': None,
          'mmc': None,
          'mmcRep': None,
          'roundNumber': 226,
          'correlation': 0.03}
          ...
          ]
  """
  function daily_submissions_performances(api::SignalsAPI, username::String)::Vector{Dict}
    query = """
      query(\$username: String!) {
        signalsUserProfile(username: \$username) {
          dailySubmissionPerformances {
            date
            returns
            submissionTime
            correlation
            mmc
            roundNumber
            corrRep
            mmcRep
          }
        }
      }
    """
    variables = Dict( "username" => username )
    data = raw_query(api, query, variables=variables)["data"]["signalsUserProfile"]
    performances = data["dailySubmissionPerformances"]
    for perf in performances
      perf["date"] = parse_datetime_string(perf["date"])
      perf["submissionTime"] = parse_datetime_string(perf["submissionTime"])
    end
    return performances
  end


  """fetch universe of accepted tickers
    Returns:
        list of strings: list of currently accepted tickers
    Example:
        >>> SignalsAPI().ticker_universe()
        ["MSFT", "AMZN", "APPL", ...]
  """
  function ticker_universe(api::SignalsAPI)::Vector{String}
    result = HTTP.request("GET", api.ticker_universe_url)
    tickers = String(result.body)
    tickers = split(tickers, "\n")
    tickers = [strip(ticker) for ticker in tickers 
                if (strip(ticker) ≠ "bloomberg_ticker") & (strip(ticker) ≠ "")]
    return tickers
  end


  """download CSV file with historical targets and ticker universe
    Returns:
        str: path to csv file
    Example:
        >>> SignalsAPI().download_validation_data()
        signals_train_val_bbg.csv
  """
  function download_validation_data(api::SignalsAPI; 
                                    dest_path::String=".", 
                                    dest_filename::Union{String,Nothing}=nothing,
                                    show_progress_bar::Bool=true)::String
    if isnothing(dest_filename)
      dest_filename = "numerai_signals_historical.csv"
    end
    dataset_path = joinpath(dest_path, dest_filename)

    ensure_directory_exists(dest_path)
    download_file(api.historical_data_url, dataset_path, show_progress_bar=show_progress_bar)

    return dataset_path
  end


  """get current stake for a given users
    Args:
        username (str)
    Returns:
        decimal.Decimal: current stake
    Example:
        >>> SignalsAPI().stake_get("uuazed")
        Decimal('14.63')
  """
  function stake_get(api::SignalsAPI, username::String)::Real
    data = public_user_profile(api, username)
    return data["totalStake"]
  end

end # module