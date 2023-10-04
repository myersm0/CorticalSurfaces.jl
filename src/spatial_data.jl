
export make_adjacency_matrix

using SparseArrays

struct SpatialData{T <: DataStyle} 
	data::Any
end

SpatialData(x::T) where T <: AbstractArray = SpatialData(DataStyle(x), x)
SpatialData(::T, data::AbstractArray) where T = SpatialData{T}(data)

"""
	 make_adjacency_matrix(neighbors::Vector{Vector{Int}})

Given an adjacency list -- here, a `Vector` where each element `v`  represents a vertex
and contains a `Vector{Int}` listing that vertex's neighbors -- of length `nvertices`, 
construct a SparseMatrixCSC adjacency matrix
"""
function make_adjacency_matrix(neighbors::Vector{Vector{Int}})
	nvertices = length(neighbors)
	A = spzeros(Bool, nvertices, nvertices)
	for v in 1:nvertices
		A[v, v] = true
		A[v, neighbors[v]] .= true
	end
	return A
end

"""
	 make_adjacency_list(hemisphere, triangles)

Make an adjacency list from a 3-column matrix of triangle vertex faces
"""
function make_adjacency_list(hem::Hemisphere, triangles::Matrix)
	size(triangles, 2) == 3 || error("Expected a 3-column matrix of triangle vertices")
	nvertices = size(hem)
	out = Vector{Vector{Int}}(undef, nvertices)
	Threads.@threads for v in 1:nvertices
		out[v] =
			@chain triangles begin
				filter(x -> v in x, eachrow(_))
				union(_...)
				setdiff(_, v)
				sort
			end
	end
	return out
end



