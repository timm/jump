

# 

#!/usr/bin/env julia
using Test
using Random
using Parameters
using ResumableFunctions

no = nothing

want(x) = begin println("# ",x); 
                include("./"*x*".jl") end

want("it")
it=It()

Random.seed!(it.seed)

want("lib")
want("col")
want("tests")

go() = want("nb")
```

say(Some(w=2))
