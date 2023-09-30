
using SparseArrays

struct SpatialData{T <: DataStyle} 
	data::Any
end

SpatialData(x::T) where T <: AbstractArray = SpatialData(DataStyle(x), x)
SpatialData(::T, data::AbstractArray) where T = SpatialData{T}(data)

function make_adjacency_matrix(neighbors::Vector{Vector})
	n = length(neighbors)
	A = spzeros(Bool, n, n)
	for vertex in 1:n
		A[vertex, vertex] = true
		A[vertex, neighbors[vertex]] .= true
	end
	return A
end


