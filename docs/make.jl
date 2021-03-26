push!(LOAD_PATH, "../")

using Documenter, NumerAPI


makedocs(
    sitename = "NumerAPI.jl",
    format = Documenter.HTML(),
    modules = [NumerAPI],
    pages = [
      "Home" => "index.md",
			"tournament.md",
			"signals.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
