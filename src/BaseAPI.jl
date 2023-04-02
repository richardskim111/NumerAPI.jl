const API_TOURNAMENT_URL = "https://api-tournament.numer.ai"

abstract type BaseAPI end


function _handle_call_error()
  # TODO
end

@doc raw"""Send a raw request to the Numerai's GraphQL API.

This function allows to build your own queries and fetch results from
Numerai's GraphQL API. Checkout
https://medium.com/numerai/getting-started-with-numerais-new-tournament-api-77396e895e72
for an introduction and https://api-tournament.numer.ai/ for the
documentation.

Args:
    query (str): your query
    variables (dict, optional): dict of variables
    authorization (bool, optional): does the request require
        authorization, defaults to `False`
    retries (int): for 5XX errors, how often should numerapi retry
    delay (int): in case of retries, how many seconds to wait between tries
    backoff (int): in case of retries, multiplier to increase the delay between retries

Returns:
    dict: Result of the request

Raises:
    ValueError: if something went wrong with the requests. For example,
        this could be a wrongly formatted query or a problem at
        Numerai's end. Have a look at the error messages, in most cases
        the problem is obvious.

Example:
    >>> query = '''query($tournament: Int!)
                    {rounds(tournament: $tournament number: 0)
                    {number}}'''
    >>> args = {'tournament': 1}
    >>> NumerAPI().raw_query(query, args)
    {'data': {'rounds': [{'number': 104}]}}
"""
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