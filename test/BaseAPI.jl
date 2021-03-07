module TestBaseAPI

  using Test, Dates, NumerAPI

  public_id = ENV["NUMERAI_PUBLIC_ID"]
  secret_key = ENV["NUMERAI_SECRET_KEY"]
  username = ENV["TOURNAMENT_USERNAME"]
  model_id = ENV["TOURNAMENT_MODEL_ID"]

  
  tournament_api = TournamentAPI(public_id, secret_key)


  @test "test login" begin
    
    
  end
  

end # module