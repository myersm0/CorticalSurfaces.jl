using CorticalSurfaces
using CIFTI
using Test
using JLD
using Pkg.Artifacts

data_dir = artifact"CIFTI_test_files"

# load MSC01 32k fs LR files and generate some ground truth info
MSC01_file = joinpath(data_dir, "MSC01.jld")
MSC01 = load(MSC01_file)
surfL = MSC01["pointsets"]["midthickness"][L]
surfR = MSC01["pointsets"]["midthickness"][R]
mwL = MSC01["medial wall"][L]
mwR = MSC01["medial wall"][R]
trianglesL = MSC01["triangle"][L]
trianglesR = MSC01["triangle"][R]
neighbors = MSC01["adjacency list"]
surf_vertices_L = findall(.!mwL)
surf_vertices_R = findall(.!mwR)
surf_vertices_LR = [surf_vertices_L; maximum(surf_vertices_L) .+ surf_vertices_R]
c = CorticalSurface(
	Hemisphere(surfL, mwL; triangles = trianglesL), 
	Hemisphere(surfR, mwR; triangles = trianglesR)
)
nverts_mw = sum(mwL) + sum(mwR)
nverts_surface = size(surfL, 1) + size(surfR, 1) - nverts_mw
nverts_total = nverts_mw + nverts_surface

@testset "CorticalSurfaces.jl" begin
	@test size(c, Exclusive()) == nverts_surface
	@test size(c, Inclusive()) == nverts_total
	@test nverts_total == nverts_surface + sum(medial_wall(c))

	@test size(coordinates(c, Inclusive()), 2) == nverts_total
	@test size(coordinates(c, Exclusive()), 2) == nverts_surface

	@test vertices(c[L], (Ipsilateral(), Exclusive())) == surf_vertices_L
	@test vertices(c[R], (Ipsilateral(), Exclusive())) == surf_vertices_R

	for hem in [L, R]
		nverts = size(c[hem], Inclusive())
		identity = falses(nverts, nverts)
		for i in 1:nverts
			identity[i, i] = true
		end
		c[hem][:identity] = identity
		@test c[hem][:identity] == identity
		c[hem][:vertexlist] = 1:nverts
		@test c[hem][:vertexlist] == 1:nverts
		@test haskey(c[hem], :identity)
		@test haskey(c[hem], :vertexlist)
		@test length(keys(c[hem])) == 2
	end
	@test haskey(c, :identity)
	@test haskey(c, :vertexlist)
	@test length(keys(c)) == 2

	c[L][:neighbors] = neighbors
	@test :neighbors in setdiff(keys(c[L]), keys(c))

	a = vertices(c[L], (Ipsilateral(), Exclusive()))
	test_vert = 22878
	inds = c[L][:neighbors][test_vert]
	temp_inds = collapse(inds, c[L])
	@test length(temp_inds) == 6
	@test all(x in [21076, 21053, 21054, 21078, 21100, 21099] for x in temp_inds)
	@test expand(collapse(inds, c[L]), c[L]) == inds

	for hem in [L, R]
		temp_inds = collapse(1:32492, c[hem])
		@test length(temp_inds) == size(c[hem], Exclusive())
		@test maximum(temp_inds) == size(c[hem], Exclusive())
		@test length(unique(temp_inds)) == length(temp_inds)

		temp_inds = expand(temp_inds, c[hem])
		@test length(temp_inds) == size(c[hem], Exclusive())
		@test maximum(temp_inds) == size(c[hem], Inclusive())
		@test length(unique(temp_inds)) == length(temp_inds)

		sample_data = collect(1:size(c[hem], Exclusive()))
		padded_data = pad(sample_data, c[hem])
		trimmed_padded_data = trim(padded_data, c[hem])
		@test trimmed_padded_data == sample_data
	end

	temp_inds = expand(1:59412, c)
	@test length(temp_inds) == size(c, Exclusive())
	@test maximum(temp_inds) == size(c, Inclusive())
	@test length(unique(temp_inds)) == length(temp_inds)

	temp_inds = collapse(temp_inds, c)
	@test length(temp_inds) == size(c, Exclusive())
	@test maximum(temp_inds) == size(c, Exclusive())
	@test length(unique(temp_inds)) == length(temp_inds)

	temp_inds = pad(1:59412, c)
	@test length(temp_inds) == size(c)
	@test sum(temp_inds .== 0) == sum(medial_wall(c))
	@test setdiff(temp_inds, 0) == 1:59412

	temp_inds = trim(1:64984, c)
	@test length(temp_inds) == size(c, Exclusive())
	@test all(medial_wall(c)[temp_inds] .== 0)
	@test !any(medial_wall(c)[temp_inds] .== 1)

	@test medial_wall(c) == vcat(medial_wall(c[L]), medial_wall(c[R]))
	@test sum(medial_wall(c)) == size(c) - size(c, Exclusive())
end

@testset "adjacency tests" begin
	c[L][:neighbors] = make_adjacency_list(c[L])
	c[R][:neighbors] = make_adjacency_list(c[R])
	@test c[L][:neighbors] == c[R][:neighbors] == [sort(x) for x in neighbors]
	@test size(c[:neighbors], 1) == size(neighbors, 1) * 2
	@test size(c[:neighbors, Exclusive()], 1) == size(c, Exclusive())
	c[L][:A] = make_adjacency_matrix(c[L])
	c[R][:A] = make_adjacency_matrix(c[R])
	@test allequal([size(c[:A])..., size(c)])
	@test allequal([size(c[:A, Exclusive()])..., size(c, Exclusive())])
end



