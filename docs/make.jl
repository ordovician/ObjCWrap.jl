using ObjCWrap
using Documenter

DocMeta.setdocmeta!(ObjCWrap, :DocTestSetup, :(using ObjCWrap); recursive=true)

makedocs(;
    modules=[ObjCWrap],
    authors="Erik Engheim <erik.engheim@mac.com> and contributors",
    repo="https://github.com/ordovician/ObjCWrap.jl/blob/{commit}{path}#{line}",
    sitename="ObjCWrap.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
