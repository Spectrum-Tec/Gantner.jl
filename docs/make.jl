using Documenter
using Gantner

makedocs(
    sitename = "Gantner",
    format = Documenter.HTML(),
    modules = [Gantner]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
