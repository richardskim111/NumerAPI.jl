module TestSignalsAPI

  using Test, Dates
  using NumerAPI.Signals


  public_id = ENV["NUMERAI_PUBLIC_ID"]
  secret_key = ENV["NUMERAI_SECRET_KEY"]
  username = ENV["SIGNALS_USERNAME"]
  model_id = ENV["SIGNALS_MODEL_ID"]  


  signals_api = SignalsAPI(public_id, secret_key)

  
  @testset "test get_leaderboard" begin
    data = get_leaderboard(signals_api)

    @test typeof(data) <: Vector
    @test length(data) == 50
  end


  @testset "test upload_predictions" begin
    

  end


  @testset "test daily_submissions_performances" begin
    data = submission_status(signals_api, model_id = model_id)

    @test typeof(data) <: Vector
  end


  @testset "test public_user_profile" begin
    data = public_user_profile(signals_api, username)    
    
    @test typeof(data) <: Dict
    @test haskey(data, "username")
    @test data["username"] == username
  end


  @testset "test daily_user_performances" begin
    data = daily_user_performances(signals_api, username)

    @test typeof(data) <: Vector{Dict}
  end


  @testset "test ticker_universe" begin
    tickers = ticker_universe(signals_api)

    @test typeof(tickers) == Vector{String}
  end


  @testset "test daily_submissions_performances" begin
    data = daily_submissions_performances(signals_api, username)
    
    @test typeof(data) <: Vector{Dict}
  end


  @testset "test download_validation_data" begin
    data_path = download_validation_data(signals_api)

    @test data_path === "./numerai_signals_historical.csv"
    @test isfile(data_path)

    rm(data_path, force=true)
  end


  @testset "test stake_get" begin
    data = stake_get(signals_api, username)    
    
    @test typeof(data) <: Real
  end





end # module