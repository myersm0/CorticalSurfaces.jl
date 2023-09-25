
using Cifti2

export Hemisphere, CorticalSurface
export size, getindex, append!, coordinates, vertices, remap, expand, collapse

struct SpatialData{T <: DataStyle} 
	data::Any
end

SpatialData(x::T) where T <: AbstractArray = SpatialData(DataStyle(x), x)
SpatialData(::T, data::AbstractArray) where T = SpatialData{T}(data)

@kwdef struct Hemisphere
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
		(Inclusive() => Exclusive()) => [
			lhem.remap[(Inclusive() => Exclusive())];
			rhem.remap[(Inclusive() => Exclusive())] .+ size(lhem, Exclusive())
		],
		(Exclusive() => Inclusive()) => [
			lhem.remap[(Exclusive() => Inclusive())];
			rhem.remap[(Exclusive() => Inclusive())] .+ size(lhem, Inclusive())
		],
	)
	CorticalSurface(Dict(L => lhem, R => rhem), vertices, remap)
end

Base.getindex(c::CorticalSurface, h::BrainStructure) =
	return haskey(c.hems, h) ? c.hems[h] : nothing
Base.getindex(hem::Hemisphere, s::Symbol) =
	return haskey(hem.appendix, s) ? hem.appendix[s].data : nothing

Base.getindex(x::SpatialData, args...) =
	return getindex(x.data, args...)

Base.size(hem::Hemisphere, mw::MedialWallIndexing) = hem.size[mw]
Base.size(hem::Hemisphere) = size(hem, Inclusive())
Base.size(c::CorticalSurface, args...) = size(c[L], args...) + size(c[R], args...)

coordinates(hem::Hemisphere, mw::MedialWallIndexing) = hem.coordinates[mw]
coordinates(hem::Hemisphere) = coordinates(hem, Inclusive())
coordinates(c::CorticalSurface, args...) = 
	vcat([coordinates(c[hem], args...) for hem in LR]...)
coordinates(v::Vector{Hemisphere}, args...) = 
	vcat([coordinates(h, args...) for h in v]...)

vertices(hem::Hemisphere) = hem.vertices[(Ipsilateral(), Inclusive())]
vertices(hem::Hemisphere, args...) = hem.vertices[args...]

vertices(c::CorticalSurface) = c.vertices[Inclusive()]
vertices(c::CorticalSurface, mw::MedialWallIndexing) = c.vertices[mw]

remap(h::Hemisphere, inds::Vector, p::Pair{I1, I2}) where {I1, I2} =
	return filter(x -> x != 0, h.remap[p][inds])

remap(c::CorticalSurface, inds::Vector, p::Pair{I1, I2}) where {I1, I2} =
	return filter(x -> x != 0, c.remap[p][inds])

# TODO: why is this slow? (195 ns versus 70 ns above)
remap(
		inds::Vector; surf::Union{Hemisphere, CorticalSurface}, dir::Pair{I1, I2}
	) where {I1, I2} =
	return filter(x -> x != 0, surf.remap[dir][inds])

expand(inds::Union{UnitRange, Vector}, surf::Union{Hemisphere, CorticalSurface}) =
	return surf.remap[ExpandMW][inds]

collapse(inds::Union{UnitRange, Vector}, surf::Union{Hemisphere, CorticalSurface}) =
	return filter(x -> x != 0, surf.remap[CollapseMW][inds])

check_conformity(hem::Hemisphere, x::Any) = size(hem) == size(x, 1)

Base.append!(hem::Hemisphere, k::Symbol, x::AbstractArray) = 
	check_conformity(hem, x) ? 
		hem.appendix[k] = SpatialData(x) : 
		error(DimensionMismatch)

function Base.show(io::IO, ::MIME"text/plain", h::Hemisphere)
	print(
		"Hemisphere with $(size(h)) vertices \
		($(size(h, Exclusive())) without medial wall)"
	)
end

function Base.show(io::IO, ::MIME"text/plain", c::CorticalSurface)
	print("CORTEX_LEFT  => ")
	display(c[L])
	print("CORTEX_RIGHT => ")
	display(c[R])
	print("Total vertices: $(size(c)) ($(size(c, Exclusive())))")
end

Base.show(io::IO, ::MIME"text/plain", x::SpatialData) = display(x.data)




