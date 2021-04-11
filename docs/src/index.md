# NumerAPI.jl

Julia API to programmatically download and upload data for the Numerai machine learning competition. This library was inspired by Numerai Python API by [uuazed/numerapi](https://github.com/uuazed/numerapi).


## Installation

```julia-repl
(@v1.5) pkg> add NumerAPI
```


## Example - Tournament
```julia
using NumerAPI.Tournament

# Download Current Dataset
tournament_api = TournamentAPI()
file_path = download_latest_data(tournament_api)

# Get Current Leaderboard
leaderboard = get_leaderboard(tournament_api, limit=25)


# Provide API Token 
public_id = "NUMERAI_PUBLIC_ID"
secret_key = "NUMERAI_SECRET_KEY"
tournament_api = TournamentAPI(public_id, secret_key)

# Upload Predictions
model_id = get_models(tournament_api)['pacio']
upload_predictions(tournament_api, "predictions.csv", model_id=model_id)

# check submission status
submission_status(tournament_api, model_id)

# increase your stake by 1.2 NMR
stake_increase(tournament_api, 1.2)
```


## Example - Signals

```julia
using NumerAPI.SignalsAPI

signals_api = SignalsAPI()
leaderboard = get_leaderboard(signals_api, limit=25)

# Provide API Token 
public_id = "NUMERAI_PUBLIC_ID"
secret_key = "NUMERAI_SECRET_KEY"
signals_api = SignalsAPI(public_id, secret_key)

# Upload Predictions
model_id = get_models(tournament_api)['pacio']
upload_predictions(signals_api, "signals.csv", model_id=model_id)

status = submission_status(signals_api, model_id)
```

## Contributions
Contributions are always welcome.  Please report any issues and bugs that you encounter in [issues](https://github.com/richardskim111/NumerAPI/issues).