using Documenter
using AutoViz

makedocs(
    modules = [AutoViz],
    format = Documenter.HTML(),
    sitename = "AutoViz.jl",
    pages = [
        "Home" => "index.md",
        "Examples" => [
            # "examples/auto_viz.md",
            "examples/cameras.md",
            # "examples/tutorial.md",
            # "examples/overlay_tutorial.md",
        ],
        "Manual" => [
            "api.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/sisl/AutoViz.jl.git"
)
