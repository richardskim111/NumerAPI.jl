# Numerai Julia API


Julia API to programmatically download and upload data for the Numerai machine learning competition. 

This library is inspired by Numerai Python API by [uuazed/numerapi](https://github.com/uuazed/numerapi).


## Installation

```julia-repl
(@v1.5) pkg> add NumerAPI
```


## Usage Example - Tournament
```julia
using NumerAPI

# Download Current Dataset
tapi = TournamentAPI()
file_path = download_latest_data(tapi)

# Get Current Leaderboard
leaderboard = get_leaderboard(tpi, limit=25)


# Provide API Token 
public_id = "NUMERAI_PUBLIC_ID"
secret_key = "NUMERAI_SECRET_KEY"
tapi = TournamentAPI(public_id, secret_key)

filenames = get_submission_filenames(tapi, model_id="your model id")


# Upload Predictions


```


## Usage Example - Numerai Signals

```julia
using SignalsAPI
sapi = SignalsAPI()

# Provide API Token 
public_id = "NUMERAI_PUBLIC_ID"
secret_key = "NUMERAI_SECRET_KEY"
sapi = SignalsAPI(public_id, secret_key)

# Upload Predictions
 

```

## Contributions
