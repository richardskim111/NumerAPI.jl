module Tournament

using JSON, HTTP, Dates, TimeZones

include("Utils.jl")
include("BaseAPI.jl")


export TournamentAPI,
        get_account,
        check_new_round,
        daily_submissions_performances,
        daily_user_performances,
        download_current_dataset,
        download_latest_data,
        get_account,
        get_models,
        get_current_round,
        get_account_transactions,
        get_competitions,
        get_dataset_url,
        get_latest_data_url,
        get_leaderboard,
        get_payments,
        get_submission_filenames,
        get_tournaments,
        get_user_activities,
        public_user_profile,
        round_details,
        stake_change,
        stake_decrease,
        stake_drain,
        stake_get,
        stake_increase,
        stake_set,
        submission_status,
        tournament_name2number,
        tournament_number2name,
        upload_predictions,
        download_dataset


const PUBLIC_DATASETS_URL = "https://numerai-public-datasets.s3-us-west-2.amazonaws.com"
const TOURNAMENT = 8
const StrOrNo=Union{String,Nothing}


struct TournamentAPI <: BaseAPI
    public_id::Union{String,Nothing}
    secret_key::Union{String,Nothing}
    tournament::Int
    public_dataset_url::String
end

TournamentAPI() = TournamentAPI(nothing, nothing, TOURNAMENT, PUBLIC_DATASETS_URL)

TournamentAPI(public_id::String, secret_key::String;tournament::Int=TOURNAMENT)=
                    TournamentAPI(public_id, secret_key, tournament, PUBLIC_DATASETS_URL)


"""
get_account(api::TournamentAPI)::Dict{String,Any}

Get all information about your account
"""
get_account(api::TournamentAPI)::Dict{String,Any} = _get_account(api)


"""
get_models(api::TournamentAPI)::Dict{String,String}

Get mapping of account model names to model ids for convenience
"""
get_models(api::TournamentAPI)::Dict{String,String} = _get_models(api)


"""
get_current_round(api::TournamentAPI)::Union{Real,Nothing}

Get number of the current active round
"""
get_current_round(api::TournamentAPI)::Union{Real,Nothing} = _get_current_round(api)


"""
get_account_transactions(api::TournamentAPI)::Dict{String,Vector}

Get all your account deposits and withdrawals
"""
get_account_transactions(api::TournamentAPI)::Dict{String,Vector} = _get_account_transactions(api)


"""
    get_dataset_url(api::TournamentAPI)::String

Fetch url of the current dataset
"""
function get_dataset_url(api::TournamentAPI)::String
query = """
    query(\$tournament: Int!) {
        dataset(tournament: \$tournament)
    }"""

variables = Dict( "tournament" => api.tournament )

url = raw_query(api, query, variables=variables)["data"]["dataset"]

return url
end


"""
    download_current_dataset(api::TournamentAPI, 
                            dest_path::String=".", 
                            dest_filename::Union{String,Nothing}=nothing,
                            unzip::Bool=true,
                            show_progress_bar::Bool=true)::String

Download dataset for the current active round
"""
function download_current_dataset(api::TournamentAPI; 
                                    dest_path::String=".", 
                                    dest_filename::Union{String,Nothing}=nothing,
                                    unzip::Bool=true, 
                                    show_progress_bar::Bool=true)::String

if isnothing(dest_filename)
    round_number = get_current_round(api)
    dest_filename = "numerai_dataset_$(round_number).zip"
else
    if unzip & !endswith(dest_filename, ".zip")
    dest_filename *= ".zip"
    end
end
dataset_path = joinpath(dest_path, dest_filename)

if ispath(dataset_path)
    @warn "target file already exists"
    return dataset_path
end

ensure_directory_exists(dest_path)

url = get_dataset_url(api)
download_file(url, dataset_path, show_progress_bar=show_progress_bar)

if unzip
    dataset_name = dest_filename[1:end-4]
    unzip_file(dataset_path, dest_path, dataset_name)
end

return dataset_path
end


"""
    get_latest_data_url(api::TournamentAPI, 
                        data_type::String, 
                        extension::String)::String

Fetch url of the latest data url for a specified data type
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

""" Download specified file for the given round.

Args:
    filename (str): file to be downloaded, defaults to live data
    dest_path (str, optional): complete path where the file should be
        stored, defaults to the same name as the source file
    round_num (int, optional): tournament round you are interested in.
        defaults to the current round

Example:
    >>> tournament_api = TournamentAPI()
    >>> download_dataset(tournament_api,filenames[0])
"""
function download_dataset(api::TournamentAPI,filename::String = "numerai_live_data.csv",
                            dest_path::String = filename,
                            round_num::StrOrNo = nothing,show_progress_bar::Bool=true)
    # if directories are used, ensure they exist
    dirs=dirname(dest_path) 
    if !isdir(dirs) && dirs!=""
        mkdir(dirs)
    end
    
    query = raw"""
    query ($filename: String!
            $round: Int) {
        dataset(filename: $filename
                round: $round)
    }
    """
    args = Dict("filename"=>filename,"round"=>round_num)
    dataset_url = raw_query(api,query;variables=args)["data"]["dataset"]
    download_file(dataset_url, dest_path; show_progress_bar)
end

"""
    get_competitions(api::TournamentAPI)::Vector{Dict}

Retrieves information about all competitions
"""
function get_competitions(api::TournamentAPI)::Vector{Dict}
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
variables = Dict("tournament" => api.tournament)
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



"""
    get_tournaments(api::TournamentAPI; only_active::Bool=true)::Vector{Dict}

Retrieves information about all competitions
"""  
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


"""
    get_user_activities(api::TournamentAPI, 
                        username::String)::Vector{Dict}

Get user activities (works for all users!)
"""
function get_user_activities(api::TournamentAPI, username::String)::Vector{Dict}
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
variables = Dict( "tournament" => api.tournament, "username" => username )
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


"""
    get_submission_filenames(api::TournamentAPI;
                            round_num::Union{Int,Nothing}=nothing, 
                            model_id::Union{String,Nothing}=nothing)::Vector{Dict}

Get filenames of the submission of the user
"""
function get_submission_filenames(api::TournamentAPI;
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
variables = Dict( "modelId" =>  model_id )
data = raw_query(api, query, variables=variables, authorization=true)["data"]["model"]

data = filter(item -> item["selected"], data["submissions"])
filenames = map(item -> Dict(
    "round_num" => item["round"]["number"],
    "tournament" => item["round"]["tournament"],
    "filename" => item["filename"],
), data) 

filenames = filter(f -> f["tournament"] == api.tournament, filenames)

if !isnothing(round_num)
    filenames = filter(f -> f["round_num"] == round_num, filenames)
end

sort!(filenames, by=f -> f["round_num"])

return filenames
end


"""
    get_payments(api::TournamentAPI; 
                model_id::Union{String,Nothing}=nothing)::Dict{String,Array}

Get all your payments  
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


"""
    submission_status(api::TournamentAPI, 
                    model_id::Union{String,Nothing}=nothing)::Union{Dict,Nothing}

Submission status of the last submission associated with the account 
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
variables = Dict( "modelId" => model_id )
data = raw_query(api, query, variables=variables, authorization=true)
latestSubmission = data["data"]["model"]["latestSubmission"]
if isempty(latestSubmission)
    return nothing
end
return latestSubmission[1]
end


"""
    upload_predictions(api::TournamentAPI, file_path::String, model_id::Union{String,Nothing}=nothing) -> String

Upload predictions from file  
"""
function upload_predictions(api::TournamentAPI, file_path::String; 
                            model_id::Union{String,Nothing}=nothing)::String
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
    "tournament" => api.tournament,
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
    "tournament" => api.tournament,
    "modelId" => model_id
)
create = raw_query(api, create_query, variables=variables, authorization=true)
submission_id = create["data"]["create_submission"]["id"]

return submission_id
end


"""
    check_new_round(api::TournamentAPI; hours::Int=24)

Check if a new round has started within the last `hours`     
"""
function check_new_round(api::TournamentAPI; hours::Int=24)::Bool
query = """
    query(\$tournament: Int!) {
    rounds(tournament: \$tournament number: 0) {
        number
        openTime
    }
    }
"""
variables = Dict("tournament" => api.tournament)
rounds = raw_query(api, query, variables=variables)["data"]["rounds"]
if isempty(rounds)
    return false
end
round = rounds[1]
open_time = parse_datetime_string(round["openTime"])
now_ = now(tz"UTC")
is_new_round = open_time > DateTime(now_,UTC) - Dates.Hour(hours)
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


"""
    get_leaderboard(api::TournamentAPI; limit::Int=50, offset::Int=0)::Vector{Dict}

Get the current leaderboard  
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
variables = Dict( "limit" => limit, "offset" => offset )
data = raw_query(api, query, variables=variables)["data"]["v2Leaderboard"]
for item in data
    item["nmrStaked"] = parse_float_string(item["nmrStaked"])
end
return data
end


"""
    stake_set(api::TournamentAPI, username::String, nmr::Union{Float64,String})::Union{Dict,Nothing}

Set stake to value by decreasing or increasing your current stake  
"""
function stake_set(api::TournamentAPI, username::String, nmr::Union{Float64,String})::Union{Dict,Nothing}
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


"""
    stake_get(api::TournamentAPI, username::String)::Float64

Get your current stake amount
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

data = raw_query(api, query, variables=variables)["data"]["v2UserProfile"]["dailyUserPerformances"]

stake = isempty(data) ? 0.0 : parse_float_string(data[1]["stakeValue"])

return stake
end


"""
    stake_change(api::TournamentAPI, 
                nmr::Union{Float64,String};
                action::String="decrease", 
                model_id::Union{String,Nothing}=nothing)::Dict

Change stake by `value` NMR
"""
function stake_change(api::TournamentAPI, nmr::Union{Float64,String};
                    action::String="decrease", 
                    model_id::Union{String,Nothing}=nothing)::Dict
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
    "tournamentNumber" => api.tournament
)
result = raw_query(api, query, variables=variables, authorization=true)
stake = result["data"]["v2ChangeStake"]
stake["requestedAmount"] = parse_float_string(stake["requestedAmount"])
stake["dueDate"] = parse_datetime_string(stake["dueDate"])
return stake
end


"""
    stake_drain(api::TournamentAPI; 
                model_id::Union{String,Nothing}=nothing)::Dict

Completely remove your stake
"""
function stake_drain(api::TournamentAPI; 
                    model_id::Union{String,Nothing}=nothing)::Dict
return stake_decrease(api, 11000000, model_id=model_id)
end


"""
    stake_decrease(api::TournamentAPI, nmr::Union{Float64,String};
                    model_id::Union{String,Nothing}=nothing)::Dict

Decrease your stake by `value` NMR
"""
function stake_decrease(api::TournamentAPI, nmr::Union{Float64,String};
                        model_id::Union{String,Nothing}=nothing)::Dict
return stake_change(api, nmr, action="decrease", model_id=model_id)
end


"""
    stake_increase(api::TournamentAPI, nmr::Union{Float64,String};
                    model_id::Union{String,Nothing}=nothing)::Dict

Increase your stake by `value` NMR
"""
function stake_increase(api::TournamentAPI, nmr::Union{Float64,String};
                        model_id::Union{String,Nothing}=nothing)::Dict
return stake_change(api, nmr, action="increase", model_id=model_id)
end


"""
    public_user_profile(api::TournamentAPI, username::String)::Dict

Fetch the public profile of a user
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


"""
    daily_user_performances(api::TournamentAPI, username::String)::Vector{Dict}

Fetch daily performance of a user
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


"""
    round_details(api::TournamentAPI, round_num::Int)::Vector{Dict}

Fetch all correlation scores of a round
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


"""
    daily_submissions_performances(api::TournamentAPI, username::String)::Vector{Dict}

Fetch daily performance of a user's submissions
"""
function daily_submissions_performances(api::TournamentAPI, username::String)::Vector{Dict}
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

performances = filter(perf -> !isnothing(perf["date"]), performances)

sort!(performances, by=x -> (x["roundNumber"], x["date"]), rev=true)

return performances
end
end # module
