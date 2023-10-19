
export expand, collapse, pad, trim

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
    pad(x, surface)

Grow `x` to `size(surface, Inclusive())` by padding it with zeros along the medial wall
"""
function pad(x::Union{AbstractRange, AbstractVector}, surface::SurfaceSpace)
	length(x) == size(surface, Exclusive()) || 
		error("Input length must match the size of the surface, exclusive of medial wall")
	out = zeros(eltype(x), size(surface, Inclusive()))
	verts = expand(1:length(x), surface)
	out[verts] .= x
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


# ===== some macros for convenience =====

macro collapse(expr)
	return :(collapse($expr, $(esc(expr.args[2]))))
end



