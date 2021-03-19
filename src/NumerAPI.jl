module NumerAPI
  
  using JSON, HTTP, Dates, TimeZones

  export Tournament,
         Signals,
         TournamentAPI,
         SignalsAPI,
         get_dataset_url,
         download_current_dataset,
         get_latest_data_url,
         download_latest_data,
         get_competitions,
         get_current_round,
         get_tournaments,
         get_user_activities,
         get_submission_filenames,
         get_submission_ids,
         get_user,
         get_payments,
         get_stakes,
         submission_status,
         upload_predictions,
         check_new_round,
         tournament_number2name,
         tournament_name2number,
         get_leaderboard,
         state_set,
         stake_get,
         stake_change,
         stake_drain,
         stake_decrease,
         stake_increase,
         public_user_profile,
         daily_user_performances,
         round_details,
         daily_submission_performances,
         ticker_universe,
         ensure_directory_exists,
         download_file
         
         

  include("Utils.jl")

  include("BaseAPI.jl")

  include("TournamentAPI.jl")
  using .Tournament

  include("SignalsAPI.jl")
  using .Signals

end # module
