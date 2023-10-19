
"Map a set of `Exclusive()` vertex indices to an expanded (`Inclusive()`) range"
expand(inds::Union{AbstractRange, Vector}, surf::SurfaceSpace) =
	return surf.remap[ExpandMW][inds]

"Map a set of `Inclusive()` vertex indices to a collapsed (`Exclusive()`) range"
collapse(inds::Union{AbstractRange, Vector}, surf::SurfaceSpace) =
	return filter(x -> x != 0, surf.remap[CollapseMW][inds])

"Grow `x` to `size(surf, Inclusive())` by padding it with zeros along the medial wall"
function pad(x::Union{AbstractRange, AbstractVector}, surf::SurfaceSpace)
	length(x) == size(surf, Exclusive()) || 
		error("Input length must match the size of the surface, exclusive of medial wall")
	out = zeros(eltype(x), size(surf, Inclusive()))
	verts = expand(1:length(x), surf)
	out[verts] .= x
	return out
end

"Shrink `x` to `size(surf, Exclusive())` by trimming out medial wall indices"
function trim(x::Union{AbstractRange, Vector}, surf::SurfaceSpace)
	length(x) == size(surf, Inclusive()) || 
		error("Input length must match the size of the surface, inclusive of medial wall")
	return x[vertices(surf, Exclusive())]
end

