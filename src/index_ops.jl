
"""
	expand(inds, surface)

Map a set of `Exclusive()` vertex indices to an expanded (`Inclusive()`) range
"""
function expand(inds::AbstractVector, surface::SurfaceSpace)
	return surface.remap[ExpandMW][inds]
end

"""
	collapse(inds, surface)

Map a set of `Inclusive()` vertex indices to a collapsed (`Exclusive()`) range
"""
function collapse(inds::AbstractVector, surface::SurfaceSpace)
	return filter(x -> x != 0, surface.remap[CollapseMW][inds])
end

"""
	pad(x, surface, with)

Grow array `x` by padding it with value `with` along the medial wall.

For vectors: pads to `size(surface, Inclusive())`
For matrices: pads to `size(surface, Inclusive()) × size(surface, Inclusive())`
"""
function pad(x::AbstractArray, surface::SurfaceSpace, with) end

# helper to determine default fill value
default_with(::AbstractArray{T}) where T <: AbstractFloat = NaN
default_with(::AbstractArray{T}) where T = zero(T)

function pad(x::AbstractVector{T}, surface::SurfaceSpace, with) where T
	length(x) == size(surface, Exclusive()) || 
		error("Input length $(length(x)) must match surface exclusive size $(size(surface, Exclusive()))")
		out = fill(T(with), size(surface, Inclusive()))
	verts = expand(1:length(x), surface)
	out[verts] .= x
	return out
end

function pad(x::AbstractVector, surface::SurfaceSpace)
	return pad(x, surface, default_with(x))
end

function pad(mat::AbstractMatrix{T}, surface::SurfaceSpace, with) where T
	all(size(mat) .== size(surface, Exclusive())) || 
		error("Matrix dimensions $(size(mat)) must match surface exclusive size $(size(surface, Exclusive()))")
	m = n = size(surface, Inclusive())
	out = fill(T(with), m, n)
	indices = .!medial_wall(surface)
	out[indices, indices] .= mat
	return out
end

function pad(mat::AbstractMatrix, surface::SurfaceSpace)
	return pad(mat, surface, default_with(mat))
end

# backward compatibility with keyword argument
function pad(x::AbstractArray, surface::SurfaceSpace; with = default_with(x))
	return pad(x, surface, with)
end

"""
	trim(x, surface)

Shrink array `x` to exclusive size by removing medial wall positions.

For vectors: returns elements at non-medial-wall positions
For matrices: returns submatrix at non-medial-wall row/column positions
"""
function trim(x::AbstractArray, surface::SurfaceSpace) end

function trim(x::AbstractVector, surface::SurfaceSpace)
	length(x) == size(surface, Inclusive()) || 
		error("Input length $(length(x)) must match surface inclusive size $(size(surface, Inclusive()))")
	return x[vertices(surface, Exclusive())]
end

function trim(mat::AbstractMatrix, surface::SurfaceSpace)
	all(size(mat) .== size(surface, Inclusive())) ||
		error("Matrix dimensions $(size(mat)) must match surface inclusive size $(size(surface, Inclusive()))")
	indices = .!medial_wall(surface)
	return mat[indices, indices]
end
