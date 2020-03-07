using Documenter
using AutoViz

makedocs(
    modules = [AutoViz],
    sitename="AutoViz.jl",
    format = Documenter.HTML()
)

deploydocs(
    repo = "github.com/sisl/AutoViz.jl.git"
)
