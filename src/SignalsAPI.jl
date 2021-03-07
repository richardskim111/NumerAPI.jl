

struct SignalsAPI <: BaseAPI
  public_id::Union{String,Nothing}
  secret_key::Union{String,Nothing}
  verbosity::String
  show_progress_bars::Bool
  token::Union{String,Nothing}
  signals_dom::String
  ticker_universe_url::String
end


"""Get the current Numerai Signals leaderboard
Args:
    limit (int): number of items to return (optional, defaults to 50)
    offset (int): number of items to skip (optional, defaults to 0)
Returns:
    list of dicts: list of leaderboard entries
    Each dict contains the following items:
        * username (`str`)
        * sharpe (`float`)
        * rank (`int`)
        * prevRank (`int`)
        * today (`float`)
        * mmc (`float`)
        * mmcRank (`int`)
        * nmrStaked (`float`)
Example:
    >>> numerapi.SignalsAPI().get_leaderboard(1)
    [{'prevRank': 1,
      'rank': 1,
      'sharpe': 2.3,
      'today': 0.01321,
      'username': 'floury_kerril_moodle',
      'mmc': -0.0101202715,
      'mmcRank': 30,
      'nmrStaked': 13.0,
     }]
"""
function get_leaderboard(api::SignalsAPI; limit::Int=50, offset::Int=0)::Vector{Dict}
  
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

end


"""fetch universe of accepted tickers
  Returns:
      list of strings: list of currently accepted tickers
  Example:
      >>> SignalsAPI().ticker_universe()
      ["MSFT", "AMZN", "APPL", ...]
"""
function ticker_universe(api::SignalsAPI)::Vector{String}

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
                                  dest_filename::Union{String,Nothing}=nothing)::String


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


end