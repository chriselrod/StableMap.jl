# StableMap

[![Build Status](https://github.com/chriselrod/StableMap.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/chriselrod/StableMap.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/chriselrod/StableMap.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/chriselrod/StableMap.jl)


The map that preserves the relative order of inputs mapped to outputs.
So do other maps, of course.

StableMap tries to return vectors that are as concretely typed as possible.
For example:

```julia
julia> using StableMap, ForwardDiff, BenchmarkTools
[ Info: Precompiling StableMap [626594ce-0aac-4e81-a7f6-bc4bb5ff97e9]

julia> f(x) = x > 1 ? x : 1.0
f (generic function with 1 method)

julia> g(x) = Base.inferencebarrier(x > 1 ? x : 1.0)
g (generic function with 1 method)

julia> h(x) = Base.inferencebarrier(x)
h (generic function with 1 method)

julia> x = [ForwardDiff.Dual(0f0,1f0), ForwardDiff.Dual(2f0,1f0)];

julia> y = [ForwardDiff.Dual(2f0,1f0), ForwardDiff.Dual(0f0,1f0)];

julia> @btime map(f, $x)
  208.010 ns (4 allocations: 176 bytes)
2-element Vector{Real}:
               1.0
 Dual{Nothing}(2.0,1.0)

julia> @btime stable_map(f, $x)
  93.329 ns (1 allocation: 96 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float64, 1}}:
 Dual{Nothing}(1.0,0.0)
 Dual{Nothing}(2.0,1.0)

julia> @btime map(f, $y)
  210.378 ns (4 allocations: 176 bytes)
2-element Vector{Real}:
 Dual{Nothing}(2.0,1.0)
               1.0

julia> @btime stable_map(f, $y)
  94.547 ns (1 allocation: 96 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float64, 1}}:
 Dual{Nothing}(2.0,1.0)
 Dual{Nothing}(1.0,0.0)

julia> @btime map(g, $x)
  890.247 ns (10 allocations: 272 bytes)
2-element Vector{Real}:
               1.0
 Dual{Nothing}(2.0,1.0)

julia> @btime stable_map(g, $x)
  3.221 μs (18 allocations: 800 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float64, 1}}:
 Dual{Nothing}(1.0,0.0)
 Dual{Nothing}(2.0,1.0)

julia> @btime map(g, $y)
  866.372 ns (10 allocations: 272 bytes)
2-element Vector{Real}:
 Dual{Nothing}(2.0,1.0)
               1.0

julia> @btime stable_map(g, $y)
  3.357 μs (18 allocations: 800 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float64, 1}}:
 Dual{Nothing}(2.0,1.0)
 Dual{Nothing}(1.0,0.0)

julia> @btime map(h, $x)
  531.503 ns (5 allocations: 144 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float32, 1}}:
 Dual{Nothing}(0.0,1.0)
 Dual{Nothing}(2.0,1.0)

julia> @btime stable_map(h, $x)
  810.656 ns (4 allocations: 128 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float32, 1}}:
 Dual{Nothing}(0.0,1.0)
 Dual{Nothing}(2.0,1.0)

julia> @btime map(h, $y)
  535.145 ns (5 allocations: 144 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float32, 1}}:
 Dual{Nothing}(2.0,1.0)
 Dual{Nothing}(0.0,1.0)

julia> @btime stable_map(h, $y)
  816.471 ns (4 allocations: 128 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float32, 1}}:
 Dual{Nothing}(2.0,1.0)
 Dual{Nothing}(0.0,1.0)
 ```
It can be faster at handling small unions than `Base.map`, but is currently slower for functions than return `Any`. However, in both cases, it has the benefit of returning as concretely-typed arrays as possible.

It will try to promote returned objects to the same type, and if this is not possible, it will return a small union.
```julia
julia> m(x) = x > 1.0 ? x : [x]
m (generic function with 1 method)

julia> @btime map(m, $x)
  257.890 ns (4 allocations: 208 bytes)
2-element Vector{Any}:
                ForwardDiff.Dual{Nothing, Float32, 1}[Dual{Nothing}(0.0,1.0)]
 Dual{Nothing}(2.0,1.0)

julia> @btime stable_map(m, $x)
  194.158 ns (3 allocations: 144 bytes)
2-element Vector{Union{ForwardDiff.Dual{Nothing, Float32, 1}, Vector{ForwardDiff.Dual{Nothing, Float32, 1}}}}:
                ForwardDiff.Dual{Nothing, Float32, 1}[Dual{Nothing}(0.0,1.0)]
 Dual{Nothing}(2.0,1.0)

julia> @btime map(m, $y)
  260.979 ns (4 allocations: 224 bytes)
2-element Vector{Any}:
 Dual{Nothing}(2.0,1.0)
                ForwardDiff.Dual{Nothing, Float32, 1}[Dual{Nothing}(0.0,1.0)]

julia> @btime stable_map(m, $y)
  190.128 ns (3 allocations: 144 bytes)
2-element Vector{Union{ForwardDiff.Dual{Nothing, Float32, 1}, Vector{ForwardDiff.Dual{Nothing, Float32, 1}}}}:
 Dual{Nothing}(2.0,1.0)
                ForwardDiff.Dual{Nothing, Float32, 1}[Dual{Nothing}(0.0,1.0)]
```


