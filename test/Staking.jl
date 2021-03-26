module TestStaking

  using Test, Dates, NumerAPI

  public_id = ENV["NUMERAI_PUBLIC_ID"]
  secret_key = ENV["NUMERAI_SECRET_KEY"]
  username = ENV["TOURNAMENT_USERNAME"]
  model_id = ENV["TOURNAMENT_MODEL_ID"]

  tournament_api = TournamentAPI(public_id, secret_key)

  
  @testset "test state_set" begin
    
  end


  @testset "test stake_get" begin
    
  end


  @testset "test stake_change" begin
    
  end


  @testset "test stake_drain" begin
    
  end


  @testset "test stake_decrease" begin
    
  end


  @testset "test stake_increase" begin
    
  end

end # module