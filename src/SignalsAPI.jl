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
      get_leaderboard(api::SignalsAPI; limit::Int=50, offset::Int=0)::Vector{Dict}
  
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


  """
      upload_predictions(api::SignalsAPI, file_path::String; 
                          model_id::Union{String,Nothing}=nothing)::String
  
  Upload predictions from file.
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


  """
      submission_status(api::SignalsAPI; model_id::Union{String,Nothing}=nothing)::Dict
  Submission status of the last submission associated with the account
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


  """
      public_user_profile(api::SignalsAPI, username::String)::Dict
  
  Fetch the public Numerai Signals profile of a user
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


  """
      daily_user_performances(api::SignalsAPI, username::String)::Vector{Dict}

  Fetch daily Numerai Signals performance of a user
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


  """
      daily_submissions_performances(api::SignalsAPI, username::String)::Vector{Dict}
  
  Fetch daily Numerai Signals performance of a user's submissions
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


  """
      ticker_universe(api::SignalsAPI)::Vector{String}

  Fetch universe of accepted tickers
  """
  function ticker_universe(api::SignalsAPI)::Vector{String}
    result = HTTP.request("GET", api.ticker_universe_url)
    tickers = String(result.body)
    tickers = split(tickers, "\n")
    tickers = [strip(ticker) for ticker in tickers 
                if (strip(ticker) ≠ "bloomberg_ticker") & (strip(ticker) ≠ "")]
    return tickers
  end


  """
      download_validation_data(api::SignalsAPI; 
                                dest_path::String=".", 
                                dest_filename::Union{String,Nothing}=nothing,
                                show_progress_bar::Bool=true)::String
  
  Download CSV file with historical targets and ticker universe
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


  """
      stake_get(api::SignalsAPI, username::String)::Real
      
  Get current stake for a given users
  """
  function stake_get(api::SignalsAPI, username::String)::Real
    data = public_user_profile(api, username)
    return data["totalStake"]
  end

end # module