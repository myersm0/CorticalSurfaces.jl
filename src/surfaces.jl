
using CIFTI

export Hemisphere, CorticalSurface, SurfaceSpace
export size, getindex, append!, coordinates, vertices, expand, collapse, pad, trim

struct SpatialData{T <: DataStyle} 
	data::Any
end

SpatialData(x::T) where T <: AbstractArray = SpatialData(DataStyle(x), x)
SpatialData(::T, data::AbstractArray) where T = SpatialData{T}(data)

Base.@kwdef struct Hemisphere
	coordinates::Dict{MedialWallIndexing, Matrix{Float64}}
	medial_wall::Union{BitVector, Vector{Bool}}
	vertices::Dict{IndexMapping, Vector}
	appendix::Dict{Symbol, SpatialData} = Dict{Symbol, SpatialData}()
	size::Dict{MedialWallIndexing, Int} = Dict(
		Exclusive() => sum(.!medial_wall),
		Inclusive() => length(medial_wall)
	)
	remap::Dict{Pair{MedialWallIndexing, MedialWallIndexing}, Vector{Int}}
end

function Hemisphere(coords::Matrix, medial_wall::BitVector)
	size(coords, 1) == length(medial_wall) || error(DimensionMismatch)
	coordinates = Dict(
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
		medial_wall = medial_wall,
		vertices = Dict(
			(Ipsilateral(), Inclusive()) => 1:nverts,
			(Ipsilateral(), Exclusive()) => surf_inds
		),
		remap = Dict(
			(Inclusive() => Exclusive()) => temp,
			(Exclusive() => Inclusive()) => surf_inds
		)
	)
end

struct CorticalSurface
	hems::Dict{BrainStructure, Hemisphere}
	vertices::Dict{MedialWallIndexing, Vector}
	remap::Dict{Pair{MedialWallIndexing, MedialWallIndexing}, Vector{Int}}
end

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
			rhem.remap[CollapseMW] .+ size(lhem, Exclusive())
		],
		ExpandMW => [
			lhem.remap[ExpandMW];
			rhem.remap[ExpandMW] .+ size(lhem, Inclusive())
		],
	)
	CorticalSurface(Dict(L => lhem, R => rhem), vertices, remap)
end

# define a shorthand for convenience in other packages; not used here
const SurfaceSpace = Union{Hemisphere, CorticalSurface}

Base.getindex(c::CorticalSurface, h::BrainStructure) =
	return haskey(c.hems, h) ? c.hems[h] : nothing

Base.getindex(hem::Hemisphere, s::Symbol) =
	return haskey(hem.appendix, s) ? hem.appendix[s].data : nothing

Base.getindex(x::SpatialData, args...) =
	return getindex(x.data, args...)

"Get the number of vertices, `Exclusive()` or `Inclusive()` of medial wall"
Base.size(hem::Hemisphere, mw::MedialWallIndexing) = hem.size[mw]
Base.size(hem::Hemisphere) = size(hem, Inclusive())
Base.size(c::CorticalSurface, args...) = size(c[L], args...) + size(c[R], args...)

"Get coordinates from a `Hemisphere`, `Exclusive()` or `Inclusive()` of medial wall"
coordinates(hem::Hemisphere, mw::MedialWallIndexing) = hem.coordinates[mw]
coordinates(hem::Hemisphere) = coordinates(hem, Inclusive())

"Get coordinates from a `CorticalSurface`, `Exclusive()` or `Inclusive()` of medial wall"
coordinates(c::CorticalSurface, args...) = 
	vcat([coordinates(c[hem], args...) for hem in LR]...)
coordinates(v::Vector{Hemisphere}, args...) = 
	vcat([coordinates(h, args...) for h in v]...)

"Get vertex numbers from a `Hemisphere`, `Exclusive()` or `Inclusive()` of medial wall"
vertices(hem::Hemisphere) = hem.vertices[(Ipsilateral(), Inclusive())]
vertices(hem::Hemisphere, args...) = hem.vertices[args...]

"Get vertex numbers from a `CorticalSurface`, `Exclusive()` or `Inclusive()` of medial wall"
vertices(c::CorticalSurface) = c.vertices[Inclusive()]
vertices(c::CorticalSurface, mw::MedialWallIndexing) = c.vertices[mw]

"Map a set of `Exclusive()` vertex indices to an expanded (`Inclusive()`) range"
expand(inds::Union{UnitRange, Vector}, surf::Hemisphere) =
	return surf.remap[ExpandMW][inds]

"Map a set of `Inclusive()` vertex indices to a collapsed (`Exclusive()`) range"
collapse(inds::Union{UnitRange, Vector}, surf::Hemisphere) =
	return filter(x -> x != 0, surf.remap[CollapseMW][inds])

"Grow `x` to `size(surf, Exclusive())` and pad it with zeros along the medial wall"
function pad(x::Vector, surf::Hemisphere)
	length(x) == size(surf, Exclusive()) || 
		error("Input length must match the size of the surface, exclusive of medial wall")
	out = zeros(eltype(x), size(surf, Inclusive()))
	verts = expand(1:length(x), surf)
	out[verts] .= x
	return out
end

"Shrink `x` to `size(surf, Inclusive())` by trimming out medial wall indices"
function trim(x::Vector, surf::Hemisphere)
	length(x) == size(surf, Inclusive()) || 
		error("Input length must match the size of the surface, inclusive of medial wall")
	return x[collapse(1:length(x), surf)]
end

check_size(hem::Hemisphere, x::Any) = size(hem) == size(x, 1)

"Add a spatial data representation to a `Hemisphere`"
Base.append!(hem::Hemisphere, k::Symbol, x::AbstractArray) = 
	check_size(hem, x) ? 
		hem.appendix[k] = SpatialData(x) : 
		error(DimensionMismatch)

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




