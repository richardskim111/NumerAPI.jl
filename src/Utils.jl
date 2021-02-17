


function post_with_err_handling(url, body, headers; timeout=0)
  try
    resp = HTTP.post(url, headers=headers, body=JSON.json(body), readtimeout=timeout)
    return JSON.parse(String(resp.body))
  catch e
    return Dict()
  end
end


function parse_datetime_string(datetime_string; datetime_format="yyyy-mm-ddTHH:MM:SSZ")
  return isnothing(datetime_string) ? datetime_string : DateTime(datetime_string, datetime_format)
end


function parse_float_string(float_string)
  return isnothing(float_string) ? float_string : tryparse(Float64, float_string)
end
