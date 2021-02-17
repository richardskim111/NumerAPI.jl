

struct SignalsAPI <: BaseAPI
  public_id::Union{String,Nothing}
  secret_key::Union{String,Nothing}
  verbosity::String
  show_progress_bars::Bool
  token::Union{String,Nothing}
  signals_dom::String
  ticker_universe_url::String
end


function get_leaderboard(api::SignalsAPI; limit::Int=50, offset::Int=0)::Vector{Dict}
  
end


function upload_predictions(api::SignalsAPI, file_path::String; 
                              model_id::Union{String,Nothing}=nothing)::String
  
end


function submission_status(api::SignalsAPI; model_id::Union{String,Nothing}=nothing)::Dict

end


function public_user_profile(api::SignalsAPI, username::String)::Dict

end


function daily_user_performances(api::SignalsAPI, username::String)::Vector{Dict}

end


function daily_submissions_performances(api::SignalsAPI, username::String)::Vector{Dict}

end


function ticker_universe(api::SignalsAPI)::Vector{String}

end


function stake_get(api::SignalsAPI, username::String)::Real

end