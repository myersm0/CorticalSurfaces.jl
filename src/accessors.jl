
"""
    getindex(c, h)

Index into the `L` or `R` `Hemisphere` of a `CorticalSurface`
"""
function Base.getindex(c::CorticalSurface, h::BrainStructure)
	haskey(c.hems, h) || throw(KeyError)
	return c.hems[h]
end

"""
	 getindex(hem, s, Inclusive())

Access supplementary spatial data `s` for a `Hemisphere`, inclusive of medial wall
"""
function Base.getindex(hem::Hemisphere, s::Symbol, ::Inclusive)
	haskey(hem.appendix, s) || throw(KeyError)
	return hem.appendix[s].data[Inclusive()]
end

"""
	 getindex(hem, s, Exclusive())

Access supplementary spatial data `s` for a `Hemisphere`, exclusive of medial wall
"""
function Base.getindex(hem::Hemisphere, s::Symbol, ::Exclusive)
	haskey(hem.appendix, s) || throw(KeyError)
	return hem.appendix[s].data[Exclusive()]
end

Base.getindex(hem::Hemisphere, s::Symbol) =
	return getindex(hem, s, Inclusive())

"Index into a `Hemisphere`'s supplementary spatial data"
Base.getindex(x::SpatialData, mw::MedialWallIndexing, args...) =
	return getindex(x.data[mw], args...)

function Base.getindex(c::CorticalSurface, s::Symbol, args...)
	haskey(c[L].appendix, s) && haskey(c[R].appendix, s) || throw(KeyError)
	a = @views c[L][s, args...]
	b = @views c[R][s, args...]
	style = DataStyle(a)
	DataStyle(b) == style || error("SpatialData structs must have the same DataStyle")
	return cat(style, a, b)
end

Base.cat(::IsSquare, a::AbstractMatrix, b::AbstractMatrix) =
	return cat(a, b; dims = 1:2)

# TODO: take a closer look at the performance of this one;
# what's going on?
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
    size(hem, mw)

Get the number of vertices of a `Hemisphere`, `Exclusive()` or `Inclusive()` of medial wall
"""
Base.size(hem::Hemisphere, mw::MedialWallIndexing) = hem.size[mw]

"Get the number of vertices of a `Hemisphere`, `Inclusive()` of medial wall"
Base.size(hem::Hemisphere) = size(hem, Inclusive())

"Get the number of vertices of a `CorticalSurface`"
Base.size(c::CorticalSurface, args...) = size(c[L], args...) + size(c[R], args...)

"Get coordinates from a `SurfaceSpace`, `Exclusive()` or `Inclusive()` of medial wall"
coordinates(s::SurfaceSpace, mw::MedialWallIndexing) = s.coordinates[mw]

"Get coordinates from a `Hemisphere`, `Inclusive()` of medial wall"
coordinates(s::SurfaceSpace) = coordinates(s, Inclusive())

"Get coordinates from a Vector of Hemispheres"
coordinates(v::Vector{Hemisphere}, args...) = 
	hcat([coordinates(h, args...) for h in v]...)

"Get vertex numbers from a `Hemisphere`, `Inclusive()` of medial wall"
vertices(hem::Hemisphere) = hem.vertices[(Ipsilateral(), Inclusive())]

"Get vertex numbers from a `Hemisphere`, `Exclusive()` of medial wall"
vertices(hem::Hemisphere, ::Exclusive) = hem.vertices[(Ipsilateral(), Exclusive())]

"Get vertex numbers from a `Hemisphere`, `Exclusive()` of medial wall"
vertices(hem::Hemisphere, args...) = hem.vertices[args...]

"Get vertex numbers from a `CorticalSurface`, `Inclusive()` of medial wall"
vertices(c::CorticalSurface) = c.vertices[Inclusive()]

"Get vertex numbers from a `CorticalSurface`, `Exclusive()` or `Inclusive()` of medial wall"
vertices(c::CorticalSurface, mw::MedialWallIndexing) = c.vertices[mw]

"Get the medial wall `BitVector` from a `Hemisphere` or `CorticalSurface`"
medial_wall(s::SurfaceSpace) = s.medial_wall

"""
    keys(hem)

Get the names of the supplementary data elements, if any, that exist for a `Hemisphere`
"""
Base.keys(hem::Hemisphere) = keys(hem.appendix)

"""
    haskey(hem, k)

Check whether a `Hemisphere` has the symbol `k` among its supplementary spatial data
"""
Base.haskey(hem::Hemisphere, k::Symbol) = haskey(hem.appendix, k)

"""
    keys(c)

Get the names of the supplementary data that exist for both hemispheres 
of a `CorticalSurface`
"""
Base.keys(c::CorticalSurface) = intersect(keys(c[L]), keys(c[R]))

"""
    haskey(c, k)

Check whether a `CorticalSurface` has the symbol `k` among its supplementary spatial data
"""
Base.haskey(c::CorticalSurface, k::Symbol) = k in keys(c)

"""
    matches_topology(c1, c2)

Check whether `SurfaceSpace`s `c1` and `c2` share the same vertex space, medial
wall definition, and topology.
"""
function matches_topology(c1::SurfaceSpace, c2::SurfaceSpace)
	return false
end

function matches_topology(c1::CorticalSurface, c2::CorticalSurface)
	size(c1) == size(c2) || return false
	medial_wall(c1) == medial_wall(c2) || return false
	for hem in LR
		(!isnothing(c1[hem].triangles) && !isnothing(c2[hem].triangles)) ||
			error("Can't compare topology unless both surfaces have `triangles` defined")
		c1[hem].triangles == c2[hem].triangles || return false
	end
	return true
end

function matches_topology(c1::Hemisphere, c2::Hemisphere)
	size(c1) == size(c2) || return false
	medial_wall(c1) == medial_wall(c2) || return false
	(!isnothing(c1.triangles) && !isnothing(c2.triangles)) ||
		error("Can't compare topology unless both surfaces have `triangles` defined")
	c1.triangles == c2.triangles || return false
	return true
end


