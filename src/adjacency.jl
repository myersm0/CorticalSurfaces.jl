
export make_adjacency_matrix, make_adjacency_list

"""
	 make_adjacency_matrix(neighbors)

Given an adjacency list -- here, a `Vector` where each element `v`  represents a vertex
and contains a `Vector{Int}` listing that vertex's neighbors -- of length `nvertices`, 
construct a `SparseMatrixCSC` adjacency matrix
"""
function make_adjacency_matrix(neighbors::AdjacencyList)
	nvertices = length(neighbors)
	A = spzeros(Bool, nvertices, nvertices)
	for v in 1:nvertices
		A[v, v] = true
		A[v, neighbors[v]] .= true
	end
	return A
end

"""
    make_adjacency_matrix(hem)

Make an adjacency matrix from the adjacency list `:neighbors` contained in `hem`
"""
function make_adjacency_matrix(hem::Hemisphere)
	haskey(hem.appendix, :neighbors) || error("Hemisphere must contain :neighbors")
	make_adjacency_matrix(hem[:neighbors])
end

"""
	 make_adjacency_list(hemisphere, triangles)

Make an adjacency list from a 3-column matrix of triangle vertices
"""
function make_adjacency_list(hem::Hemisphere, triangles::Matrix)
	size(triangles, 2) == 3 || error("Expected a 3-column matrix of triangle vertices")
	nvertices = size(hem)
	out = AdjacencyList{Int}(undef, nvertices)
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

"""
    make_adjacency_list(hem)

Make an adjacency list based on the `triangles` field of `hem::Hemisphere`
"""
function make_adjacency_list(hem::Hemisphere)
	!isnothing(hem.triangles) || error("Hemisphere's `triangles` field cannot be empty")
	make_adjacency_list(hem, hem.triangles)
end



