using StableMap
using Documenter

DocMeta.setdocmeta!(StableMap, :DocTestSetup, :(using StableMap); recursive=true)

makedocs(;
    modules=[StableMap],
    authors="Chris Elrod <elrodc@gmail.com> and contributors",
    repo="https://github.com/chriselrod/StableMap.jl/blob/{commit}{path}#{line}",
    sitename="StableMap.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
