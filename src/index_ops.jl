
"""
    expand(inds, surface)

Map a set of `Exclusive()` vertex indices to an expanded (`Inclusive()`) range
"""
function expand(inds::Union{AbstractRange, Vector}, surface::SurfaceSpace)
	return surface.remap[ExpandMW][inds]
end

"""
    collapse(inds, surface)

Map a set of `Inclusive()` vertex indices to a collapsed (`Exclusive()`) range
"""
function collapse(inds::Union{AbstractRange, Vector}, surface::SurfaceSpace)
	return filter(x -> x != 0, surface.remap[CollapseMW][inds])
end

"""
    pad(x, surface; sentinel)

Grow vector `x` to `size(surface, Inclusive())` by padding it with a provided 
`sentinel` value along the medial wall. If no sentinel value is specified, then
by default `NaN` will be used if `T <: AbstractFloat`, or `zero(T)` otherwise.
"""
function pad(
		x::Union{AbstractRange{T}, AbstractVector{T}}, surface::SurfaceSpace
	) where T <: AbstractFloat
	length(x) == size(surface, Exclusive()) || 
		error("Input length must match the size of the surface, exclusive of medial wall")
	sentinel = NaN
	out = fill(eltype(x)(sentinel), size(surface, Inclusive()))
	verts = expand(1:length(x), surface)
	out[verts] .= x
	return out
end

function pad(
		x::Union{AbstractRange{T}, AbstractVector{T}}, surface::SurfaceSpace;
		sentinel = zero(T)
	) where T
	length(x) == size(surface, Exclusive()) || 
		error("Input length must match the size of the surface, exclusive of medial wall")
	out = fill(eltype(x)(sentinel), size(surface, Inclusive()))
	verts = expand(1:length(x), surface)
	out[verts] .= x
	return out
end

function pad(
		mat::Matrix{T}, surface::SurfaceSpace; 
		sentinel = NaN
	) where T <: AbstractFloat
	all(size(mat) .== size(surface, Exclusive())) || 
		error("Matrix must be square and match size of the surface, exclusive of medial wall")
	n = size(surface, Inclusive())
	out = fill(eltype(mat)(sentinel), n, n)
	inds = .!medial_wall(surface)
	out[inds, inds] .= mat
	return out
end

function pad(
		mat::Matrix{T}, surface::SurfaceSpace; 
		sentinel::T = zero(T)
	) where T
	all(size(mat) .== size(surface, Exclusive())) || 
		error("Matrix must be square and match size of the surface, exclusive of medial wall")
	n = size(surface, Inclusive())
	out = fill(sentinel, n, n)
	inds = .!medial_wall(surface)
	out[inds, inds] .= mat
	return out
end

"""
    trim(x, surface)

Shrink `x` to `size(surface, Exclusive())` by trimming out medial wall indices
"""
function trim(x::Union{AbstractRange, Vector}, surface::SurfaceSpace)
	length(x) == size(surface, Inclusive()) || 
		error("Input length must match the size of the surface, inclusive of medial wall")
	return x[vertices(surface, Exclusive())]
end

function trim(mat::Matrix, surface::SurfaceSpace)
	inds = .!medial_wall(surface)
	return mat[inds, inds]
end


