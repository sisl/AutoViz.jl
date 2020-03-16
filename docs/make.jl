using Documenter
using Literate
using AutoViz

# generate tutorials and how-to guides using Literate
src = joinpath(@__DIR__, "src")
lit = joinpath(@__DIR__, "lit")
notebooks = joinpath(src, "notebooks")

for (root, _, files) in walkdir(lit), file in files
    splitext(file)[2] == ".jl" || continue
    ipath = joinpath(root, file)
    opath = splitdir(replace(ipath, lit=>src))[1]
    Literate.markdown(ipath, opath, documenter = true)
    Literate.notebook(ipath, notebooks, execute = false)
end

makedocs(
    modules = [AutoViz],
    format = Documenter.HTML(),
    sitename = "AutoViz.jl",
    pages = [
        "Home" => "index.md",
        "Tutorials" => [
            "tutorials/basics.md",
            "tutorials/cameras.md",
            "tutorials/overlays.md",
        ],
        "Manual" => [
            "api.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/sisl/AutoViz.jl.git"
)
