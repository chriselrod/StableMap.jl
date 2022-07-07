using StableMap
using Test
using ForwardDiff



@testset "StableMap.jl" begin

  x = rand(10);
  @test stable_map(exp, x) ≈ map(exp, x)

  unstablemax(x,y) = Base.inferencebarrier(x > y ? x : y)
  y = rand(-10:10, 10);
  res = stable_map(unstablemax, x, y)
  @test res isa Vector{Float64}
  @test res == map(unstablemax, x, y)

  f(x) = Base.inferencebarrier(x > 1 ? x : 1.0)
  @test stable_map(f, [ForwardDiff.Dual(0f0,1f0), ForwardDiff.Dual(2f0,1f0)]) isa Vector{ForwardDiff.Dual{Nothing,Float64,1}}

end
