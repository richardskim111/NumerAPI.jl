using ProgressMeter, InfoZIP
using HTTP.IOExtras
using Base.Filesystem: IOError

"send `post` request and handle (some) errors that might occur"
function post_with_err_handling(url, body, headers;timeout::Int = 10,
  retries::Int = 3, delay::Int = 1, backoff::Int = 2)::Dict
  try
    resp = HTTP.post(url,headers,body=JSON.json(body),readtimeout =timeout,retries,retry_delay=ExponentialBackOff(;n=retries, first_delay=delay,jitter=backoff))
    return JSON.parse(String(resp.body))
  catch e
    return Dict()
  end
end


function parse_datetime_string(datetime_string; datetime_format="yyyy-mm-ddTHH:MM:SS")
  return isnothing(datetime_string) ? datetime_string : DateTime(datetime_string[1:end-1], datetime_format)
end


function parse_float_string(float_string)
  return isnothing(float_string) ? float_string : tryparse(Float64, float_string)
end


function ensure_directory_exists(path)
  try
    mkdir(path)
  catch e
    if !isa(e, IOError)
      throw(e)
    end
  end
end


function download_file(url, dest_path; show_progress_bar=true)

  HTTP.open("GET", url) do http
    r = startread(http)
    l = parse(Int, HTTP.header(r, "Content-Length"))
    
    if show_progress_bar
      prog = Progress(l, dt=0.1, desc="Downloading:", barglyphs=BarGlyphs("[=> ]"), barlen=25, color=:white)
    end

    io = open(dest_path, "w")
    n_bytes = 0   
    while !eof(http)
      bytes = readavailable(http)
      n_bytes += length(bytes)
      write(io, bytes)
      if show_progress_bar
        ProgressMeter.update!(prog, n_bytes)
      end
    end
    close(io)
  end

end

function unzip_file(src_path::String, dest_path::String, filename::String)
  @info "unzipping file..."

  unzip_path = joinpath(dest_path, filename)
  ensure_directory_exists(unzip_path)

  InfoZIP.unzip(src_path, unzip_path)

end
