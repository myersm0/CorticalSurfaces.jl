
function make_graph(c::SurfaceSpace)
	make_adjacency_list!(c)
	make_adjacency_matrix!(c)
	return Graphs.Graph(adjacency_matrix(c))
end

function initialize_graph!(h::Hemisphere)
	isnothing(h.graph[]) && (h.graph[] = make_graph(h))
	return
end

function initialize_graph!(c::CorticalSurface)
	initialize_graph!(c[L])
	initialize_graph!(c[R])
	return
end

function graph(hem::Hemisphere)
	return hem.graph[]
end

function graph(c::CorticalSurface)
	return make_graph(c)
end

