module TestBaseAPI

  using Test, Dates, NumerAPI

  using NumerAPI.Tournament

  public_id = ENV["NUMERAI_PUBLIC_ID"]
  secret_key = ENV["NUMERAI_SECRET_KEY"]
  username = ENV["TOURNAMENT_USERNAME"]
  model_id = ENV["TOURNAMENT_MODEL_ID"]

  
  tournament_api = TournamentAPI(public_id, secret_key)


  # Test Base API Functions
  @testset "test get_account" begin
    data = get_account(tournament_api)

    @test haskey(data, "apiTokens")
    @test haskey(data, "models")
    @test haskey(data, "username")
    @test haskey(data, "walletAddress")
    @test haskey(data, "availableNmr")
    @test haskey(data, "email")
    @test haskey(data, "id")
    @test haskey(data, "mfaEnabled")
    @test haskey(data, "status")
    @test haskey(data, "insertedAt")
  end


  @testset "test get_models" begin
    models = get_models(tournament_api)    

    @test typeof(models) == Dict{String,String}
  end


  @testset "test get_account_transactions" begin
    account = get_account_transactions(tournament_api)

    @test haskey(account, "nmrDeposits")
    @test haskey(account, "nmrWithdrawals")
    @test typeof(account["nmrDeposits"]) <: Vector
    @test typeof(account["nmrWithdrawals"]) <: Vector
  end


  @testset "test get_current_round" begin
    round_number = get_current_round(tournament_api)

    @test ((typeof(round_number) == Int) || (isnothing(round_number)))
  end
  

end # module