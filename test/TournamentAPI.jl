module TestTournamentAPI

  using Test, Dates, NumerAPI

  
  public_id = ENV["NUMERAI_PUBLIC_ID"]
  secret_key = ENV["NUMERAI_SECRET_KEY"]
  username = ENV["USERNAME"]
  model_id = ENV["MODEL_ID"]

  
  tournament_api = TournamentAPI(public_id, secret_key)
  
  @testset "test TournamentAPI instantiation" begin
    @test tournament_api.public_id === public_id
    @test tournament_api.secret_key === secret_key
    @test tournament_api.verbosity
    @test tournament_api.show_progress_bars
    @test tournament_api.public_dataset_url === PUBLIC_DATASETS_URL
  end
  

  # @testset "test get_dataset_url" begin
  #   url = get_dataset_url(tournament_api, tournament=8)

  #   @test typeof(url) === String
  #   @test occursin("numerai-datasets", url)
  # end

  
  # @testset "test download_current_url" begin
    

  # end


  # @testset "test download_latest_data" begin
    
  # end


  @testset "test get_competitions" begin
    rounds = get_competitions(tournament_api, tournament=8)

    @test typeof(rounds) <: AbstractVector
    
    round = rounds[1]
    @test haskey(round, "datasetId")
    @test haskey(round, "number")
    @test haskey(round, "openTime")
    @test haskey(round, "participants")
    @test haskey(round, "prizePoolNmr")
    @test haskey(round, "prizePoolUsd")
    @test haskey(round, "resolveTime")
    @test haskey(round, "resolvedGeneral")
    @test haskey(round, "resolvedStaking")
    @test haskey(round, "ruleset")

    @test typeof(round["openTime"]) <: Union{DateTime,Nothing}
    @test typeof(round["resolveTime"]) <: Union{DateTime,Nothing}
    @test typeof(round["prizePoolNmr"]) <: Union{Float64,Nothing}
    @test typeof(round["prizePoolUsd"]) <: Union{Float64,Nothing}
  end


  @testset "test get_current_round" begin
    round_num = get_current_round(tournament_api)

    @test typeof(round_num) <: Union{Real,Nothing}
  end


  @testset "test get_tournaments" begin
    tournaments = get_tournaments(tournament_api)

    @test typeof(tournaments) <: AbstractArray
    @test length(tournaments) === 1

    tournaments = get_tournaments(tournament_api, only_active=false)
    
    @test length(tournaments) > 1
  end


  @testset "test get_user_activities" begin
    activities = get_user_activities(tournament_api, username)

    submission_dates = map(x -> x["submission"]["date"], activities)
    submissions = isnothing.(submission_dates)
    @test all(map(x->!x,submissions))
  end


  @testset "test get_submission_filenames" begin
    filenames = get_submission_filenames(tournament_api, model_id=model_id)

    @test typeof(filenames) <: AbstractArray
    @test !isempty(filenames)
    @test typeof(filenames[1]["round_num"]) == Int
    @test typeof(filenames[1]["tournament"]) == Int
    @test typeof(filenames[1]["filename"]) <: AbstractString
  end


  @testset "test get_payments" begin
    payments = get_payments(tournament_api, model_id=model_id)

    @test typeof(payments) <: AbstractDict
    @test typeof(payments["payments"]) <: AbstractArray
    @test typeof(payments["reputationPayments"]) <: AbstractArray
    @test typeof(payments["otherUsdIssuances"]) <: AbstractArray
  end

  
  @testset "test submission_status" begin
    
  end


  @testset "test check_new_round" begin
    
  end


  @testset "test tournament_number2name" begin
    
  end


  @testset "test tournament_name2number" begin
    
  end


  @testset "test get_leaderboard" begin
    
  end


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


  @testset "test public_user_profile" begin
    
  end


  @testset "test daily_user_performances" begin
    
  end


  @testset "test round_details" begin
    
  end


  @testset "test daily_submission_performances" begin
    
  end

end # module