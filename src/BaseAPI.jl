
const API_TOURNAMENT_URL = "https://api-tournament.numer.ai"

abstract type BaseAPI end


function _handle_call_error()

end


function raw_query(api::BaseAPI, query::String;
                    variables::Union{Dict,Nothing}=nothing,
                    authorization::Bool=false)::Dict

  body = Dict( "query" => query, "variables" => variables )
  
  headers = Dict(
      "Content-Type" => "application/json", 
      "Accept" => "application/json",
  )
  
  if authorization
    public_id = api.public_id
    secret_key = api.secret_key
    headers["Authorization"] = "Token $public_id\$$secret_key"
  end

  result = post_with_err_handling(API_TOURNAMENT_URL, body, headers)

  # if result and "errors" in result:
  #     err = self._handle_call_error(result['errors'])
  #     # fail!
  #     raise ValueError(err)
  # end

  return result
end


function get_account(api::BaseAPI)::Dict{String,Any}
  
end


function get_models(api::BaseAPI)::Dict{String,String}

end


function get_account_transactions(api::BaseAPI)::Dict{String,Vector}

end


function get_transactions(api::BaseAPI; model_id::Union{String,Nothing}=nothing)::Dict{String,Vector}
  
end


function get_current_round(api::BaseAPI, tournament::Int)::Union{Real,Nothing}
  query = """
    query(\$tournament: Int!) {
      rounds(tournament: \$tournament number: 0) {
        number
      }
    }
  """
  variables = Dict("tournament" => tournament)
  data = raw_query(api, query, variables=variables)["data"]["rounds"][1]
  round_num = isempty(data) ? nothing : data["number"]
  return round_num
end