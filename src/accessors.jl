
export size, getindex, coordinates, vertices

"Index into the `L` or `R` `Hemisphere` of a `CorticalSurface`"
function Base.getindex(c::CorticalSurface, h::BrainStructure)
	haskey(c.hems, h) || throw(KeyError)
	return c.hems[h]
end

"Access supplementary spatial data `s` for a `Hemisphere`"
function Base.getindex(hem::Hemisphere, s::Symbol, ::Inclusive)
	haskey(hem.appendix, s) || throw(KeyError)
	return hem.appendix[s].data[Inclusive()]
end

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

"Get the number of vertices of a Hemisphere, `Exclusive()` or `Inclusive()` of medial wall"
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
	vcat([coordinates(h, args...) for h in v]...)

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

