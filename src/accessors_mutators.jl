
export size, getindex, append!, coordinates, vertices, expand, collapse, pad, trim

"Index into the `L` or `R` `Hemisphere` of a `CorticalSurface`"
Base.getindex(c::CorticalSurface, h::BrainStructure) =
	return haskey(c.hems, h) ? c.hems[h] : nothing

"Access supplementary spatial data `s` for a `Hemisphere`"
Base.getindex(hem::Hemisphere, s::Symbol) =
	return haskey(hem.appendix, s) ? hem.appendix[s].data[Inclusive()] : nothing

Base.getindex(hem::Hemisphere, s::Symbol, mw::MedialWallIndexing) =
	return haskey(hem.appendix, s) ? hem.appendix[s].data[mw] : nothing

"Index into a `Hemisphere`'s supplementary spatial data"
Base.getindex(x::SpatialData, mw::MedialWallIndexing, args...) =
	return getindex(x.data[mw], args...)

"Get the number of vertices of a Hemisphere, `Exclusive()` or `Inclusive()` of medial wall"
Base.size(hem::Hemisphere, mw::MedialWallIndexing) = hem.size[mw]

"Get the number of vertices of a `Hemisphere`, `Inclusive()` of medial wall"
Base.size(hem::Hemisphere) = size(hem, Inclusive())

"Get the number of vertices of a `Hemisphere`"
Base.size(c::CorticalSurface, args...) = size(c[L], args...) + size(c[R], args...)

"Get coordinates from a `Hemisphere`, `Exclusive()` or `Inclusive()` of medial wall"
coordinates(hem::Hemisphere, mw::MedialWallIndexing) = hem.coordinates[mw]

"Get coordinates from a `Hemisphere`, `Inclusive()` of medial wall"
coordinates(hem::Hemisphere) = coordinates(hem, Inclusive())

"Get coordinates from a `CorticalSurface`, `Exclusive()` or `Inclusive()` of medial wall"
coordinates(c::CorticalSurface, args...) = 
	vcat([coordinates(c[hem], args...) for hem in LR]...)

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

function check_size(
		::IsSquare, hem::Hemisphere, what::AbstractArray, indexing::MedialWallIndexing
	)
	return all(size(what) .== size(hem, indexing))
end

function check_size(
		::IsRectangular, hem::Hemisphere, what::AbstractArray, indexing::MedialWallIndexing
	)
	return size(what, 1) == size(hem, indexing)
end

function check_size(
		::IsScalarList, hem::Hemisphere, what::AbstractArray, indexing::MedialWallIndexing
	)
	return length(what) == size(hem, indexing)
end

function check_size(
		::IsNestedList, hem::Hemisphere, what::AbstractArray, indexing::MedialWallIndexing
	)
	hem_size = size(hem, indexing)
	return length(what) == hem_size && all([all(1 .<= x .<= hem_size) for x in what])
end

function check_size(hem::Hemisphere, what::AbstractArray, indexing::MedialWallIndexing)
	return check_size(DataStyle(what), hem, what, indexing)
end

"Add a spatial data representation to a `Hemisphere`"
function Base.append!(hem::Hemisphere, k::Symbol, what::T) where T <: AbstractArray
	check_size(hem, what, Inclusive()) || error(DimensionMismatch)
	hem.appendix[k] = SpatialData(what, hem, Inclusive())
end

