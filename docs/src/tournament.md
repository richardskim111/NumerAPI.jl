# Tournament API

```@meta
CurrentModule = NumerAPI.Tournament
```

```@docs
get_dataset_url(api::TournamentAPI)
download_current_dataset(api::TournamentAPI)
get_latest_data_url(api::TournamentAPI, data_type::String, extension::String)
get_competitions(api::TournamentAPI)
get_tournaments(api::TournamentAPI; only_active::Bool=true)
get_user_activities(api::TournamentAPI, username::String)
get_submission_filenames(api::TournamentAPI)
get_payments(api::TournamentAPI)
submission_status(api::TournamentAPI)
upload_predictions(api::TournamentAPI, file_path::String)
check_new_round(api::TournamentAPI)
get_leaderboard(api::TournamentAPI)
stake_set(api::TournamentAPI, nmr::Union{Float64,String})
stake_get(api::TournamentAPI, username::String)
stake_change(api::TournamentAPI, nmr::Union{Float64,String})
stake_drain(api::TournamentAPI)
stake_decrease(api::TournamentAPI, nmr::Union{Float64,String})
stake_increase(api::TournamentAPI, nmr::Union{Float64,String})
public_user_profile(api::TournamentAPI, username::String)
daily_user_performances(api::TournamentAPI, username::String)
round_details(api::TournamentAPI, round_num::Int)
daily_submissions_performances(api::TournamentAPI, username::String)
```

