module TestSignalsAPI

  using Test, Dates, NumerAPI

  public_id = ENV["NUMERAI_PUBLIC_ID"]
  secret_key = ENV["NUMERAI_SECRET_KEY"]
  username = ENV["SIGNALS_USERNAME"]
  model_id = ENV["SIGNALS_MODEL_ID"]  


  signals_api = SignalsAPI(public_id, secret_key)

  
  @testset "test get_leaderboard" begin
    

  end


  @testset "test upload_predictions" begin
    

  end


  @testset "test daily_submissions_performances" begin
    
  end


  @testset "test daily_user_performances" begin
    
  end


  @testset "test ticker_universe" begin
    tickers = ticker_universe(signals_api)

    @test typeof(tickers) == Vector{String}
  end

end # module