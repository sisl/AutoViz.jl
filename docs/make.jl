using Documenter, AutoViz

makedocs(modules = [AutoViz],
         format = Documenter.HTML(),
         sitename="AutoViz.jl")

deploydocs(
    repo = "github.com/sisl/AutoViz.jl.git"
)
