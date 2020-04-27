A toy implementation of DLA in Julia.

# Installation

```
julia --project -O3 # start Julia REPL treating current directory as a project
julia> using Pkg; Pkg.instantiate() # ~ install dependencies of this project
```

# Run the script

```
julia> include("dla.jl")
```

First time could be pretty slow, because [Makie](https://github.com/JuliaPlots/Makie.jl), the plotting library, will have to compile.
