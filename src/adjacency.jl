
"""
	 make_adjacency_matrix(neighbors)

Given an adjacency list -- here, a `Vector` where each element `v`  represents a vertex
and contains a `Vector{Int}` listing that vertex's neighbors -- of length `nvertices`, 
construct a `SparseMatrixCSC` adjacency matrix
"""
function make_adjacency_matrix(neighbors::AdjacencyList)
	n = length(neighbors)
	I_diag = 1:n
	J_diag = 1:n
	I_neigh = vcat(neighbors...)
	J_neigh = vcat([repeat([v], length(neighbors[v])) for v in 1:n]...)
	I = [I_diag; I_neigh]
	J = [J_diag; J_neigh]
	V = trues(length(I))
	return sparse(I, J, V)
end

"""
    make_adjacency_matrix(hem)

Make an adjacency matrix from the adjacency list `:neighbors` contained in `hem`
"""
function make_adjacency_matrix(hem::Hemisphere)
	haskey(hem.appendix, :neighbors) || error("Hemisphere must contain :neighbors")
	return make_adjacency_matrix(hem[:neighbors])
end

function make_adjacency_matrix!(hem::Hemisphere)
	hem[:A] = make_adjacency_matrix(hem)
end

"""
	 make_adjacency_list(hemisphere, triangles)

Make an adjacency list from a 3-column matrix of triangle vertices
"""
function make_adjacency_list(hem::Hemisphere, triangles::Matrix)
	size(triangles, 1) == 3 || error("Expected a 3-row matrix of triangle vertices")
	nvertices = size(hem)
	out = AdjacencyList{Int}(undef, nvertices)
	Threads.@threads for v in 1:nvertices
		out[v] =
			@chain triangles begin
				filter(x -> v in x, eachcol(_))
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

function make_adjacency_list!(hem::Hemisphere)
	hem[:neighbors] = make_adjacency_list(hem)
end

function adjacency_list(hem::Hemisphere)
	return hem[:neighbors]
end

function adjacency_matrix(hem::Hemisphere)
	return hem[:A]
end

function adjacency_list(c::CorticalSurface)
	return c[:neighbors]
end
	
function adjacency_matrix(c::CorticalSurface)
	return c[:A]
end



