
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
	A = spzeros(Bool, n, n)
	for v in 1:nvertices
		A[v, v] = true
		A[v, neighbors[v]] .= true
	end
	return A
end


