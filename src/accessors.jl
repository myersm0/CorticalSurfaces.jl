
"""
    brainstructure(surf)

Get the `BrainStructure` designation (`CORTEX_LEFT` or `CORTEX_RIGHT`) of a
`Hemisphere` struct `surf`, or, in the event that `surf` is a `CorticalSurface`,
a `Vector` of both its left and right hemisphere labels.
"""
function brainstructure(surf::SurfaceSpace) end

brainstructure(h::Hemisphere) = h.label

brainstructure(c::CorticalSurface) = LR


"""
    medial_wall(s)

Get the medial wall `BitVector` from a `SurfaceSpace` struct, where `true` denotes
medial wall membership, `false` otherwise.
"""
medial_wall(s::SurfaceSpace) = s.medial_wall


"""
    getindex(c, h)

Index into the `L` or `R` `Hemisphere` of a `CorticalSurface`
"""
function Base.getindex(c::CorticalSurface, h::BrainStructure)
	return c.hems[h]
end

"""
	 getindex(surf, s, Inclusive())

Access supplementary spatial data `s::Symbol` for a `SurfaceSpace`. Optionally pass 
a `MedialWallIndexing` trait `Inclusive()` or `Exclusive()` to inform handling 
of medial wall (default is `Inclusive()`).
"""
function Base.getindex(surf::SurfaceSpace, s::Symbol, ::MedialWallIndexing) end

function Base.getindex(surf::SurfaceSpace, s::Symbol)
	return getindex(surf, s, Inclusive())
end

function Base.getindex(hem::Hemisphere, s::Symbol, ::Inclusive)
	haskey(hem.appendix, s) || throw(KeyError)
	return hem.appendix[s].data[Inclusive()]
end

function Base.getindex(hem::Hemisphere, s::Symbol, ::Exclusive)
	haskey(hem.appendix, s) || throw(KeyError)
	return hem.appendix[s].data[Exclusive()]
end

function Base.getindex(c::CorticalSurface, s::Symbol, mw::MedialWallIndexing)
	haskey(c[L].appendix, s) && haskey(c[R].appendix, s) || throw(KeyError)
	a = @views c[L][s, mw]
	b = @views c[R][s, mw]
	style = DataStyle(a)
	DataStyle(b) == style || error("SpatialData structs must have the same DataStyle")
	return cat(style, a, b)
end

# to be used only as a helper for public-facing getindex functions
function Base.getindex(x::SpatialData, mw::MedialWallIndexing, args...)
	return getindex(x.data[mw], args...)
end


## cat functions to be used internally as helpers in combining coordinates 
## and SpatialData across hemispheres

Base.cat(::IsSquare, a::AbstractMatrix, b::AbstractMatrix) =
	return cat(a, b; dims = 1:2)

# TODO: take a closer look at the performance of this one; what's going on?
function Base.cat(::IsSquare, a::SparseMatrixCSC, b::SparseMatrixCSC)
	size_a = size(a)
	size_b = size(b)
	return [
		a spzeros(eltype(a), size_a[1], size_b[2]);
		spzeros(eltype(b), size_b[1], size_a[2]) b
	]
end

Base.cat(::IsScalarList, a::Vector, b::Vector) = 
	return [a; b]

Base.cat(::IsNestedList, a::Vector, b::Vector) =
	return [a; [x .+ size(a, 1) for x in b]]


"""
    size(surf)

Get the number of vertices of a `SurfaceSpace`, inclusive of medial wall.
"""
Base.size(surf::SurfaceSpace)  = size(surf, Inclusive())

"""
    size(surf, mw)

Get the number of vertices of a `SurfaceSpace`, `Exclusive()` or `Inclusive()` 
of medial wall.
"""
function Base.size(surf::SurfaceSpace, mw::MedialWallIndexing) end

Base.size(hem::Hemisphere, mw::MedialWallIndexing) = hem.size[mw]

Base.size(c::CorticalSurface, mw::MedialWallIndexing) = size(c[L], mw) + size(c[R], mw)


"""
    coordinates(surf)

Get coordinates from a `SurfaceSpace`, inclusive of medial wall. Each column
of the output represents a vertex, and the rows represent x, y, and z.
"""
coordinates(s::SurfaceSpace) = coordinates(s, Inclusive())

"""
    coordinates(surf)

Get coordinates from a `SurfaceSpace`, `Inclusive()` or `Exclusive()` of medial wall. 
Each column of the output represents a vertex, and the rows represent x, y, and z.
"""
coordinates(s::SurfaceSpace, mw::MedialWallIndexing) = s.coordinates[mw]

"Get coordinates from a Vector of Hemispheres"
coordinates(v::Vector{Hemisphere}, args...) = 
	hcat([coordinates(h, args...) for h in v]...)


"""
    vertices(s)

Get vertex numbers from a `SurfaceSpace` struct, inclusive of medial wall.
"""
vertices(s::SurfaceSpace) = vertices(s, Inclusive())

vertices(h::Hemisphere) = vertices(h, Inclusive())

"""
    vertices(s, mw)

Get vertex numbers from a `SurfaceSpace` struct, `Inclusive()` or `Exclusive()`
of medial wall.
"""
function vertices(s::SurfaceSpace, mw::MedialWallIndexing) end

vertices(hem::Hemisphere, mw::MedialWallIndexing) = hem.vertices[(Ipsilateral(), mw)]

vertices(hem::Hemisphere, args...) = hem.vertices[args...]

vertices(c::CorticalSurface, mw::MedialWallIndexing) = c.vertices[mw]


"""
    keys(surf)

Get the names of the supplementary data elements, if any, that exist for a `SurfaceSpace`
"""
function Base.keys(surf::SurfaceSpace) end

Base.keys(hem::Hemisphere) = keys(hem.appendix)

Base.keys(c::CorticalSurface) = intersect(keys(c[L]), keys(c[R]))


"""
    haskey(surf, k)

Check whether a `SurfaceSpace` has the symbol `k` among its supplementary spatial data
"""
function Base.haskey(surf::SurfaceSpace, k::Symbol) end

Base.haskey(hem::Hemisphere, k::Symbol) = haskey(hem.appendix, k)

Base.haskey(c::CorticalSurface, k::Symbol) = k in keys(c)


"""
    node_correspondence(s1, s2)

Check whether `SurfaceSpace`s `s1` and `s2` share the same vertex space, medial
wall definition, and topology.
"""
function node_correspondence(s1::SurfaceSpace, s2::SurfaceSpace)
	return false
end

function node_correspondence(c1::CorticalSurface, c2::CorticalSurface)
	size(c1) == size(c2) || return false
	medial_wall(c1) == medial_wall(c2) || return false
	for hem in LR
		(!isnothing(c1[hem].triangles) && !isnothing(c2[hem].triangles)) ||
			error("Can't compare topology unless both surfaces have `triangles` defined")
		c1[hem].triangles == c2[hem].triangles || return false
	end
	return true
end

function node_correspondence(h1::Hemisphere, h2::Hemisphere)
	size(h1) == size(h2) || return false
	medial_wall(h1) == medial_wall(h2) || return false
	(!isnothing(h1.triangles) && !isnothing(h2.triangles)) ||
		error("Can't compare topology unless both surfaces have `triangles` defined")
	h1.triangles == h2.triangles || return false
	return true
end


