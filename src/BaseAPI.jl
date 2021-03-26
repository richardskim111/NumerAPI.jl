const API_TOURNAMENT_URL = "https://api-tournament.numer.ai"

abstract type BaseAPI end


function _handle_call_error()
  # TODO
end


function raw_query(api::BaseAPI, query::String;
                    variables::Union{Dict,Nothing}=nothing,
                    authorization::Bool=false)::Dict

  body = Dict( "query" => query, "variables" => variables )
  
  headers = Dict( 
    "Content-Type" => "application/json", 
    "Accept" => "application/json"
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



function _get_account(api::BaseAPI)::Dict{String,Any}
  query = """
    query {
      account {
        username
        walletAddress
        availableNmr
        email
        id
        mfaEnabled
        status
        insertedAt
        models {
          id
          name
          submissions {
            id
            filename
          }
          v2Stake {
            status
            txHash
          }
        }
        apiTokens {
          name
          public_id
          scopes
        }
      }
    }
  """
  data = raw_query(api, query, authorization=true)["data"]["account"]
  data["insertedAt"] = parse_datetime_string(data["insertedAt"])
  data["availableNmr"] = parse_float_string(data["availableNmr"])
  return data
end



function _get_models(api::BaseAPI)::Dict{String,String}
  query = """
    query {
      account {
        models {
          id
          name
          tournament
        }
      }
    }
  """
  data = raw_query(api, query, authorization=true)["data"]["account"]["models"]
  mapping = Dict(
    model["name"] => model["id"] 
      for model in data if model["tournament"] == api.tournament
  )
  return mapping
end


function _get_current_round(api::BaseAPI)::Union{Real,Nothing}
  query = """
    query(\$tournament: Int!) {
      rounds(tournament: \$tournament number: 0) {
        number
      }
    }
  """
  variables = Dict( "tournament" => api.tournament )
  data = raw_query(api, query, variables=variables)["data"]["rounds"][1]
  round_num = isempty(data) ? nothing : data["number"]
  return round_num
end


function _get_account_transactions(api::BaseAPI)::Dict{String,Vector}
  query = """
    query {
      account {
        nmrDeposits {
          from
          posted
          status
          to
          txHash
          value
          insertedAt
        }
        nmrWithdrawals {
          from
          posted
          status
          to
          txHash
          value
          insertedAt
        }
      }
    }
  """
  account = raw_query(api, query, authorization=true)["data"]["account"]

  for transaction in account["nmrWithdrawals"]
    transaction["value"] = parse_float_string(transaction["value"])
    transaction["insertedAt"] = parse_datetime_string(transaction["insertedAt"])
  end

  for transaction in account["nmrDeposits"]
    transaction["value"] = parse_float_string(transaction["value"])
    transaction["insertedAt"] = parse_datetime_string(transaction["insertedAt"])
  end

  return account
end


"""
    set_submission_webhook(api::BaseAPI, 
                            model_id::String, 
                            webook::String)

Set a model's submission webhook used in Numerai Compute

"""
function _set_submission_webhook(api::BaseAPI, model_id::String, webook::String)::Bool
  # TODO   
  query = """
    mutation (
      \$modelId: String!
      \$newSubmissionWebhook: String
    ) {
      setSubmissionWebhook(
        modelId: \$modelId
        newSubmissionWebhook: \$newSubmissionWebhook
      )
    }
  """
  variables = Dict(
    "modelId" => model_id,
    "newSubmissionWebhook" => webook
  )
  res = raw_query(api, query, variables=variables, authorization=true)
  return res["data"]["setSubmissionWebhook"] == "true"
end