
"""
    Hemisphere(coords::Matrix, medial_wall::BitVector)

Make a `Hemisphere` from a `Matrix` of xyz coordinates and a `BitVector`
denoting medial wall membership
"""
function Hemisphere(
		label::BrainStructure, coords::Matrix, medial_wall::Union{Vector{Bool}, BitVector}; 
		triangles::Union{Nothing, Matrix} = nothing
	)
	nvertices = length(medial_wall)

	# expect coords to have 3 rows and ncolumns == nvertices; otherwise, transpose
	if size(coords, 1) == nvertices && size(coords, 2) == 3
		coords = coords'
	end
	size(coords, 1) == 3 || error(DimensionMismatch)
	size(coords, 2) == length(medial_wall) || error(DimensionMismatch)

	if !isnothing(triangles)
		# expect triangle to have 3 rows and columns >= nvertices; otherwise, transpose
		if size(triangles, 1) >= nvertices && size(triangles, 2) == 3
			triangles = triangles'
		end
		size(triangles, 1) == 3 || error(DimensionMismatch)
	end

	coordinates = Dict{MedialWallIndexing, Matrix{eltype(coords)}}(
		Exclusive() => coords[:, .!medial_wall],
		Inclusive() => coords
	)
	nverts = length(medial_wall)
	surf_inds = setdiff(1:nverts, findall(medial_wall))

	# to be used below to help construct the "remap" vectors
	temp = zeros(Int, nverts)
	temp[surf_inds] .= 1:length(surf_inds)

	return Hemisphere(
		label = label,
		coordinates = coordinates, 
		triangles = triangles,
		medial_wall = convert(BitVector, medial_wall),
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
function Hemisphere(label::BrainStructure, nvertices::Int)
	coords = zeros(3, nvertices)
	medial_wall = falses(nvertices)
	return Hemisphere(label, coords, medial_wall)
end

"""
    Hemisphere(medial_wall::BitVector)

Make a placeholder `Hemisphere` struct, without meaningful coordinates,
from just a `BitVector` representing medial wall membership
"""
function Hemisphere(label::BrainStructure, medial_wall::BitVector)
	nvertices = length(medial_wall)
	coords = zeros(3, nvertices)
	return Hemisphere(label, coords, medial_wall)
end

"""
    CorticalSurface(lhem::Hemisphere, rhem::Hemisphere)

Make a `CorticalSurface` from a left and a right `Hemisphere`, in that order
"""
function CorticalSurface(lhem::Hemisphere, rhem::Hemisphere)
	brainstructure(lhem) == L && brainstructure(rhem) == R || 
		error("You must supply a left and a right Hemisphere, in that order")

	lhem.vertices[(Bilateral(), Exclusive())] = 
		lhem.vertices[(Ipsilateral(), Exclusive())]
	lhem.vertices[(Bilateral(), Inclusive())] = 
		lhem.vertices[(Ipsilateral(), Inclusive())]
	nvertsL = size(lhem)
	rhem.vertices[(Bilateral(), Exclusive())] = 
		rhem.vertices[(Ipsilateral(), Exclusive())] .+ nvertsL
	rhem.vertices[(Bilateral(), Inclusive())] = 
		rhem.vertices[(Ipsilateral(), Inclusive())] .+ nvertsL

	mw = [lhem.medial_wall; rhem.medial_wall]

	coords = Dict{MedialWallIndexing, Matrix{eltype(coordinates(lhem))}}(
		Exclusive() => hcat(lhem.coordinates[Exclusive()], rhem.coordinates[Exclusive()]),
		Inclusive() => hcat(lhem.coordinates[Inclusive()], rhem.coordinates[Inclusive()])
	)

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
		],
	)

	CorticalSurface(Dict(L => lhem, R => rhem), coords, mw, vertices, remap)
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
		data[Exclusive()] = mat[:, excl_verts]
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

