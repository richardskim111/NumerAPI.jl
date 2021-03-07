module TestTournamentAPI

  using Test, Dates, NumerAPI

  
  public_id = ENV["NUMERAI_PUBLIC_ID"]
  secret_key = ENV["NUMERAI_SECRET_KEY"]
  username = ENV["TOURNAMENT_USERNAME"]
  model_id = ENV["TOURNAMENT_MODEL_ID"]

  
  tournament_api = TournamentAPI(public_id, secret_key)
  
  # @testset "test TournamentAPI instantiation" begin
  #   @test tournament_api.public_id === public_id
  #   @test tournament_api.secret_key === secret_key
  #   @test tournament_api.verbosity
  #   @test tournament_api.show_progress_bars
  #   @test tournament_api.public_dataset_url === PUBLIC_DATASETS_URL
  # end
  

  # Test Base API Functions
  @testset "test login" begin
    
  end


  @testset "test raw_query" begin
    
  end


  @testset "test get_account" begin
    

  end


  @testset "test get_models" begin
    
  end


  @testset "test get_account_transactions" begin
    
  end


  @testst "test get_transactions" begin
    
  end


  @testst "test get_current_round" begin
    
  end




  # @testset "test get_dataset_url" begin
  #   url = get_dataset_url(tournament_api, tournament=8)

  #   @test typeof(url) === String
  #   @test occursin("numerai-datasets", url)
  # end


  # @testset "test download_current_dataset" begin
  #   dataset_path = download_current_dataset(tournament_api)

  #   @test dataset_path === "./numerai_dataset_253.zip"

  #   rm(dataset_path, force=true)
  #   rm(dataset_path[1:end-4], force=true, recursive=true)
  # end  
  

  # @testset "test get_latest_data_url" begin
  #   data_type = "tournament"
  #   extension = "csv"
  #   url = get_latest_data_url(tournament_api, data_type, extension)
    
  #   @test url == "$(PUBLIC_DATASETS_URL)/latest_numerai_$(data_type)_data.$(extension)"

  #   try
  #     get_latest_data_url("not_valid_data_type", "csv")
  #   catch ArgumentError
  #     @test true
  #   end

  # end


  # @testset "test download_latest_data" begin
  #   data_type = "training"
  #   extension = "csv"
  #   download_latest_data(tournament_api, data_type, extension, show_progress_bar=true)

  #   file_path = "./latest_numerai_$(data_type)_data.$(extension)"
  #   @test isfile(file_path)

  #   rm(file_path, force=true)
  # end


  # @testset "test get_competitions" begin
  #   rounds = get_competitions(tournament_api, tournament=8)

  #   @test typeof(rounds) <: AbstractVector
    
  #   round = rounds[1]
  #   @test haskey(round, "datasetId")
  #   @test haskey(round, "number")
  #   @test haskey(round, "openTime")
  #   @test haskey(round, "participants")
  #   @test haskey(round, "prizePoolNmr")
  #   @test haskey(round, "prizePoolUsd")
  #   @test haskey(round, "resolveTime")
  #   @test haskey(round, "resolvedGeneral")
  #   @test haskey(round, "resolvedStaking")
  #   @test haskey(round, "ruleset")

  #   @test typeof(round["openTime"]) <: Union{DateTime,Nothing}
  #   @test typeof(round["resolveTime"]) <: Union{DateTime,Nothing}
  #   @test typeof(round["prizePoolNmr"]) <: Union{Float64,Nothing}
  #   @test typeof(round["prizePoolUsd"]) <: Union{Float64,Nothing}
  # end


  # @testset "test get_current_round" begin
  #   round_num = get_current_round(tournament_api)

  #   @test typeof(round_num) <: Union{Real,Nothing}
  # end


  # @testset "test get_tournaments" begin
  #   tournaments = get_tournaments(tournament_api)

  #   @test typeof(tournaments) <: AbstractArray
  #   @test length(tournaments) === 1

  #   tournaments = get_tournaments(tournament_api, only_active=false)
    
  #   @test length(tournaments) > 1
  # end


  # @testset "test get_user_activities" begin
  #   activities = get_user_activities(tournament_api, username)

  #   submission_dates = map(x -> x["submission"]["date"], activities)
  #   submissions = isnothing.(submission_dates)
  #   @test all(map(x->!x,submissions))
  # end


  # @testset "test get_submission_filenames" begin
  #   filenames = get_submission_filenames(tournament_api, model_id=model_id)

  #   @test typeof(filenames) <: AbstractArray
  #   @test !isempty(filenames)
  #   @test typeof(filenames[1]["round_num"]) == Int
  #   @test typeof(filenames[1]["tournament"]) == Int
  #   @test typeof(filenames[1]["filename"]) <: AbstractString
  # end


  # @testset "test get_payments" begin
  #   payments = get_payments(tournament_api, model_id=model_id)

  #   @test typeof(payments) <: AbstractDict
  #   @test typeof(payments["payments"]) <: AbstractArray
  #   @test typeof(payments["reputationPayments"]) <: AbstractArray
  #   @test typeof(payments["otherUsdIssuances"]) <: AbstractArray
  # end

  
  # @testset "test submission_status" begin
  #   latest_submission = submission_status(tournament_api, model_id=model_id)

  #   @test !isnothing(latest_submission)
  #   @test haskey(latest_submission, "filename")
  # end

  # @testset "test upload_predictions" begin
  #   submission_id = upload_predictions(tournament_api, "./prediction.csv"; model_id=model_id)

  #   println(submission_id)
  #   @test isa(submission_id, String)
  # end


  # @testset "test check_new_round" begin
  #   is_new_round = check_new_round(tournament_api)
  #   @test 
  # end


  # @testset "test tournament_number2name" begin
  #   tournament_name = tournament_number2name(tournament_api, 8)

  #   @test tournament_name === "kazutsugi"
  # end


  # @testset "test tournament_name2number" begin
  #   tournament_number = tournament_name2number(tournament_api, "kazutsugi")

  #   @test tournament_number === 8
  # end


  # @testset "test get_leaderboard" begin
  #   leaderboard = get_leaderboard(tournament_api)

  #   @test length(leaderboard) === 50
  # end


  # @testset "test state_set" begin
    
  # end


  # @testset "test stake_get" begin
    
  # end


  # @testset "test stake_change" begin
    
  # end


  # @testset "test stake_drain" begin
    
  # end


  # @testset "test stake_decrease" begin
    
  # end


  # @testset "test stake_increase" begin
    
  # end


  # @testset "test public_user_profile" begin
  #   user_profile = public_user_profile(tournament_api, username)

  #   @test user_profile["username"] === username
  #   @test user_profile["id"] === model_id
  # end


  # @testset "test daily_user_performances" begin
  #   performances = daily_user_performances(tournament_api, username)

  #   @test typeof(performances) === Vector{Dict}
  # end


  # @testset "test round_details" begin
  #   performances = round_details(tournament_api, 253)

  #   @test typeof(performances) === Vector{Dict}
  # end


  # @testset "test daily_submission_performances" begin
  #   performances = daily_submission_performances(tournament_api, username)

  #   @test performances[1]["date"] > performances[2]["date"] 
  # end

end # module