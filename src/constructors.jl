
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
