
using CIFTI

export SurfaceSpace, Hemisphere, CorticalSurface
export size, getindex, append!, coordinates, vertices, expand, collapse, pad, trim

struct SpatialData{T, N}
	data::Dict{MedialWallIndexing, T′} where T′ <: AbstractArray{T, N}
end

abstract type SurfaceSpace end

@kwdef struct Hemisphere <: SurfaceSpace
	coordinates::Dict{MedialWallIndexing, Matrix{T}} where T <: Real
	triangles::Union{Nothing, Matrix{Int}}
	medial_wall::BitVector
	vertices::Dict{IndexMapping, Vector{Int}}
	appendix::Dict{Symbol, SpatialData} = 
		Dict{Symbol, SpatialData}()
	size::Dict{MedialWallIndexing, Int} = Dict(
		Exclusive() => sum(.!medial_wall),
		Inclusive() => length(medial_wall)
	)
	remap::Dict{Pair{MedialWallIndexing, MedialWallIndexing}, Vector{Int}}
end

"""
    Hemisphere(coords::Matrix, medial_wall::BitVector)

Make a `Hemisphere` from a `Matrix` of xyz coordinates and a `BitVector`
denoting medial wall membership
"""
function Hemisphere(
		coords::Matrix, medial_wall::BitVector; triangles::Union{Nothing, Matrix} = nothing
	)
	size(coords, 1) == length(medial_wall) || error(DimensionMismatch)
	coordinates = Dict{MedialWallIndexing, Matrix{eltype(coords)}}(
		Exclusive() => coords[.!medial_wall, :],
		Inclusive() => coords
	)
	nverts = length(medial_wall)
	surf_inds = setdiff(1:nverts, findall(medial_wall))

	# to be used below to help construct the "remap" vectors
	temp = zeros(Int, nverts)
	temp[surf_inds] .= 1:length(surf_inds)

	return Hemisphere(
		coordinates = coordinates, 
		triangles = triangles,
		medial_wall = medial_wall,
		vertices = Dict{IndexMapping, Vector{Int}}(
			(Ipsilateral(), Inclusive()) => 1:nverts,
			(Ipsilateral(), Exclusive()) => surf_inds
		),
		remap = Dict{Pair{MedialWallIndexing, MedialWallIndexing}, Vector{Int}}(
			(Inclusive() => Exclusive()) => temp,
			(Exclusive() => Inclusive()) => surf_inds
		)
	)
end

"""
    Hemisphere(nvertices::Int)

Make a meaningless, but functional, placeholder `Hemisphere` of a certain size
"""
function Hemisphere(nvertices::Int)
	coords = zeros(nvertices, 3)
	medial_wall = falses(nvertices)
	return Hemisphere(coords, medial_wall)
end

"""
    Hemisphere(medial_wall::BitVector)

Make a placeholder `Hemisphere` struct, without meaningful coordinates,
from just a `BitVector` representing medial wall membership
"""
function Hemisphere(medial_wall::BitVector)
	nvertices = length(medial_wall)
	coords = zeros(nvertices, 3)
	return Hemisphere(coords, medial_wall)
end

struct CorticalSurface <: SurfaceSpace
	hems::Dict{BrainStructure, Hemisphere}
	vertices::Dict{MedialWallIndexing, Vector}
	remap::Dict{Pair{MedialWallIndexing, MedialWallIndexing}, Vector{Int}}
end

"""
    CorticalSurface(lhem::Hemisphere, rhem::Hemisphere)

Make a `CorticalSurface` from a left and a right `Hemisphere`, in that order
"""
function CorticalSurface(lhem::Hemisphere, rhem::Hemisphere)
	lhem.vertices[(Bilateral(), Exclusive())] = 
		lhem.vertices[(Ipsilateral(), Exclusive())]
	lhem.vertices[(Bilateral(), Inclusive())] = 
		lhem.vertices[(Ipsilateral(), Inclusive())]
	nvertsL = size(lhem)
	rhem.vertices[(Bilateral(), Exclusive())] = 
		rhem.vertices[(Ipsilateral(), Exclusive())] .+ nvertsL
	rhem.vertices[(Bilateral(), Inclusive())] = 
		rhem.vertices[(Ipsilateral(), Inclusive())] .+ nvertsL
	vertices = Dict(
		Inclusive() => union(
			lhem.vertices[(Bilateral(), Inclusive())],
			rhem.vertices[(Bilateral(), Inclusive())]
		),
		Exclusive() => union(
			lhem.vertices[(Bilateral(), Exclusive())],
			rhem.vertices[(Bilateral(), Exclusive())]
		)
	)
	remap = Dict(
		CollapseMW => [
			lhem.remap[CollapseMW];
			rhem.remap[CollapseMW] .+ 
				[x == 0 ? 0 : size(lhem, Exclusive()) for x in rhem.remap[CollapseMW]]
		],
		ExpandMW => [
			lhem.remap[ExpandMW];
			rhem.remap[ExpandMW] .+ size(lhem, Inclusive())
				[x == 0 ? 0 : size(lhem, Inclusive()) for x in rhem.remap[ExpandMW]]
		],
	)
	CorticalSurface(Dict(L => lhem, R => rhem), vertices, remap)
end

function SpatialData(mat::AbstractMatrix, hem::Hemisphere, ::Inclusive)
	T = eltype(mat)
	N = 2
	data = Dict{MedialWallIndexing, AbstractArray{T, N}}()
	data[Inclusive()] = mat
	excl_verts = vertices(hem, Exclusive())
	if MatrixStyle(mat) == IsSquare()
		data[Exclusive()] = mat[excl_verts, excl_verts]
	else
		data[Exclusive()] = mat[excl_verts, :]
	end
	return SpatialData{T, N}(data)
end

function SpatialData(v::AbstractVector, hem::Hemisphere, ::Inclusive)
	T = eltype(v)
	N = 1
	data = Dict{MedialWallIndexing, AbstractArray{T, N}}()
	data[Inclusive()] = v
	excl_verts = vertices(hem, Exclusive())
	if ListStyle(v) == IsScalarList()
		data[Exclusive()] = v[excl_verts]
	else
		data[Exclusive()] = [collapse(x, hem) for x in v[excl_verts]]
	end
	return SpatialData{T, N}(data)
end

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

function Base.show(io::IO, ::MIME"text/plain", h::Hemisphere)
	print("Hemisphere with $(size(h)) vertices ($(size(h, Exclusive())) without medial wall)")
end

function Base.show(io::IO, ::MIME"text/plain", c::CorticalSurface)
	print("CORTEX_LEFT  => ")
	display(c[L])
	print("CORTEX_RIGHT => ")
	display(c[R])
	print("Total vertices: $(size(c)) ($(size(c, Exclusive())))")
end

Base.show(io::IO, ::MIME"text/plain", x::SpatialData) = display(x.data)




