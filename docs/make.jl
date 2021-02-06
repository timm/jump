using Documenter
Documenter.makedocs(root="/",
  source="../src",
  build="build",
  clean= true,
  doctest=Module[all],
  repo="",
  highlightsig="true",
  sitename="col",
  expandfirst=[],
  pages=[
         "Index" => "index.md"
        ]
  )
