using Documenter, AutoViz

makedocs(modules = [AutoViz],
         format = :html,
         sitename="AutoViz.jl")

deploydocs(
    repo = "github.com/sisl/AutoViz.jl.git"
)