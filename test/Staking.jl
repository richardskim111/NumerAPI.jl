module TestStaking

  using Test, Dates
  using NumerAPI.Tournament

  public_id = ENV["NUMERAI_PUBLIC_ID"]
  secret_key = ENV["NUMERAI_SECRET_KEY"]

  username = ENV["TOURNAMENT_USERNAME"]
  model_id = ENV["TOURNAMENT_MODEL_ID"]

  tournament_api = TournamentAPI(public_id, secret_key)

  
  # @testset "test state_set" begin
  #   nmr = 0.01
  #   stake = stake_set(tournament_api, username, nmr)

  #   println(stake)

  # end


  @testset "test stake_get" begin
    stake = stake_get(tournament_api, username)

    @test stake === 0.01
  end


  @testset "test stake_drain" begin
    
  end


  @testset "test stake_decrease" begin
    
  end


  @testset "test stake_increase" begin
    
  end


end # module