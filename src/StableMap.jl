module StableMap

using ArrayInterfaceCore
using LinearAlgebra

export stable_map, stable_map!

function stable_map!(f, dst::AbstractArray{T}, args::Vararg{Any,K}) where {K,T}
  N = length(dst)
  all(==(Base.oneto(N)), map(eachindex, args)) ||
    throw(ArgumentError("All args must have same axes."))
  @inbounds for i = 1:N
    fᵢ = f(map(Base.Fix2(Base.unsafe_getindex, i), args)...)
    dst[i] = convert(T, fᵢ)::T
  end
  return dst
end
function narrowing_map!(
  f,
  dst::AbstractArray{T},
  start::Int,
  args::Vararg{Any,K},
) where {K,T}
  N = length(dst)
  all(==(Base.oneto(N)), map(eachindex, args)) ||
    throw(ArgumentError("All args must have same axes."))
  @inbounds for i = start:N
    xi = f(map(Base.Fix2(Base.unsafe_getindex, i), args)...)
    if xi isa T
      dst[i] = xi
    else
      Ti = typeof(xi)
      PT = promote_type(Ti, T)
      if PT === T
        dst[i] = convert(T, xi)
      elseif Base.isconcretetype(PT)
        dst_promote = Array{PT}(undef, size(dst))
        copyto!(view(dst_promote, Base.OneTo(i - 1)), view(dst, Base.OneTo(i - 1)))
        dst_promote[i] = convert(PT, xi)::PT
        return narrowing_map!(f, dst_promote, i + 1, args...)
      else
        dst_union = Array{Union{T,Ti}}(undef, size(dst))
        copyto!(view(dst_union, Base.OneTo(i - 1)), view(dst, Base.OneTo(i - 1)))
        dst_union[i] = xi
        return narrowing_map!(f, dst_union, i + 1, args...)
      end
    end
  end
  return dst
end

function isconcreteunion(TU)
  if TU isa Union
    isconcretetype(TU.a) && isconcreteunion(TU.b)
  else
    isconcretetype(TU)
  end
end

function promote_return(f::F, args...) where {F}
  T = Base.promote_op(f, map(eltype, args)...)
  Base.isconcretetype(T) && return T
  TU = Base.promote_union(T)
  Base.isconcretetype(TU) && return TU
  isconcreteunion(T) && return T
  nothing
end
function stable_map(f, args::Vararg{AbstractArray,K}) where {K}
  # assume specialized implementation
  all(ArrayInterfaceCore.ismutable, args) || return map(f, args...)
  T = promote_return(f, args...)
  first_arg = first(args)
  T === nothing || return stable_map!(f, Array{T}(undef, size(first_arg)), args...)
  x = f(map(first, args)...)
  dst = similar(first_arg, typeof(x))
  @inbounds dst[1] = x
  narrowing_map!(f, dst, 2, args...)
end
function stable_map(f, A::Diagonal{T}) where {T}
  B = Matrix{promote_type(T, Float32)}(undef, size(A))
  @inbounds for i in eachindex(A)
    B[i] = f(A[i])
  end
  return B
end
@inline stable_map(f::F, arg1::A, args::Vararg{A,K}) where {F,K,A} =
  map(f, arg1, args...)


end
