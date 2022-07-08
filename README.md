# StableMap

[![Build Status](https://github.com/chriselrod/StableMap.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/chriselrod/StableMap.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/chriselrod/StableMap.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/chriselrod/StableMap.jl)


The map that preserves the relative order of inputs mapped to outputs.
So do other maps, of course.

StableMap tries to return vectors that are as concretely typed as possible.
For example:

```julia
julia> using StableMap, ForwardDiff, BenchmarkTools

julia> f(x) = x > 1 ? x : 1.0
f (generic function with 1 method)

julia> g(x) = Base.inferencebarrier(x > 1 ? x : 1.0)
g (generic function with 1 method)

julia> h(x) = Base.inferencebarrier(x)
h (generic function with 1 method)

julia> x = [ForwardDiff.Dual(0f0,1f0), ForwardDiff.Dual(2f0,1f0)];

julia> y = [ForwardDiff.Dual(2f0,1f0), ForwardDiff.Dual(0f0,1f0)];

julia> @btime map(f, $x)
  77.097 ns (4 allocations: 176 bytes)
2-element Vector{Real}:
               1.0
 Dual{Nothing}(2.0,1.0)

julia> @btime stable_map(f, $x)
  35.209 ns (1 allocation: 96 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float64, 1}}:
 Dual{Nothing}(1.0,0.0)
 Dual{Nothing}(2.0,1.0)

julia> @btime map(f, $y)
  77.901 ns (4 allocations: 176 bytes)
2-element Vector{Real}:
 Dual{Nothing}(2.0,1.0)
               1.0

julia> @btime stable_map(f, $y)
  35.114 ns (1 allocation: 96 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float64, 1}}:
 Dual{Nothing}(2.0,1.0)
 Dual{Nothing}(1.0,0.0)

julia> @btime map(g, $x)
  396.285 ns (10 allocations: 272 bytes)
2-element Vector{Real}:
               1.0
 Dual{Nothing}(2.0,1.0)

julia> @btime stable_map(g, $x)
  1.739 μs (19 allocations: 816 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float64, 1}}:
 Dual{Nothing}(1.0,0.0)
 Dual{Nothing}(2.0,1.0)

julia> @btime map(g, $y)
  387.262 ns (10 allocations: 272 bytes)
2-element Vector{Real}:
 Dual{Nothing}(2.0,1.0)
               1.0

julia> @btime stable_map(g, $y)
  1.836 μs (19 allocations: 816 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float64, 1}}:
 Dual{Nothing}(2.0,1.0)
 Dual{Nothing}(1.0,0.0)
 
julia> @btime map(h, $x)
  342.091 ns (5 allocations: 144 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float32, 1}}:
 Dual{Nothing}(0.0,1.0)
 Dual{Nothing}(2.0,1.0)

julia> @btime stable_map(h, $x)
  447.560 ns (5 allocations: 144 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float32, 1}}:
 Dual{Nothing}(0.0,1.0)
 Dual{Nothing}(2.0,1.0)

julia> @btime map(h, $y)
  347.163 ns (5 allocations: 144 bytes)
2-element Vector{ForwardDiff.Dual{Nothing, Float32, 1}}:
 Dual{Nothing}(2.0,1.0)
 Dual{Nothing}(0.0,1.0)

julia> @btime stable_map(h, $y)
  447.230 ns (5 allocations: 144 bytes)
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
  98.984 ns (4 allocations: 208 bytes)
2-element Vector{Any}:
                ForwardDiff.Dual{Nothing, Float32, 1}[Dual{Nothing}(0.0,1.0)]
 Dual{Nothing}(2.0,1.0)

julia> @btime stable_map(m, $x)
  2.410 μs (24 allocations: 1.08 KiB)
2-element Vector{Union{ForwardDiff.Dual{Nothing, Float32, 1}, Vector{ForwardDiff.Dual{Nothing, Float32, 1}}}}:
                ForwardDiff.Dual{Nothing, Float32, 1}[Dual{Nothing}(0.0,1.0)]
 Dual{Nothing}(2.0,1.0)

julia> @btime map(m, $y)
  100.428 ns (4 allocations: 224 bytes)
2-element Vector{Any}:
 Dual{Nothing}(2.0,1.0)
                ForwardDiff.Dual{Nothing, Float32, 1}[Dual{Nothing}(0.0,1.0)]

julia> @btime stable_map(m, $y)
  2.339 μs (24 allocations: 1.08 KiB)
2-element Vector{Union{ForwardDiff.Dual{Nothing, Float32, 1}, Vector{ForwardDiff.Dual{Nothing, Float32, 1}}}}:
 Dual{Nothing}(2.0,1.0)
                ForwardDiff.Dual{Nothing, Float32, 1}[Dual{Nothing}(0.0,1.0)]
```


