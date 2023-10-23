using CorticalSurfaces
using CIFTI
using Test
using JLD

data_dir = joinpath(dirname(@__FILE__), "..", "data")

# load MSC01 32k fs LR files and generate some ground truth info
MSC01_file = joinpath(data_dir, "MSC01.jld")
MSC01 = load(MSC01_file)
surfL = MSC01["pointsets"]["midthickness"][L]
surfR = MSC01["pointsets"]["midthickness"][R]
mwL = MSC01["medial wall"][L]
mwR = MSC01["medial wall"][R]
neighbors = MSC01["adjacency list"]
surf_vertices_L = findall(.!mwL)
surf_vertices_R = findall(.!mwR)
surf_vertices_LR = [surf_vertices_L; maximum(surf_vertices_L) .+ surf_vertices_R]
test = CorticalSurface(Hemisphere(surfL, mwL), Hemisphere(surfR, mwR))
nverts_mw = sum(mwL) + sum(mwR)
nverts_surface = size(surfL, 1) + size(surfR, 1) - nverts_mw
nverts_total = nverts_mw + nverts_surface

@testset "CorticalSurfaces.jl" begin
	@test size(test, Exclusive()) == nverts_surface
	@test size(test, Inclusive()) == nverts_total
	@test nverts_total == nverts_surface + sum(medial_wall(test))

	@test size(coordinates(test, Inclusive()), 2) == nverts_total
	@test size(coordinates(test, Exclusive()), 2) == nverts_surface

	@test vertices(test[L], (Ipsilateral(), Exclusive())) == surf_vertices_L
	@test vertices(test[R], (Ipsilateral(), Exclusive())) == surf_vertices_R

	for hem in [L, R]
		nverts = size(test[hem], Inclusive())
		identity = falses(nverts, nverts)
		for i in 1:nverts
			identity[i, i] = true
		end
		test[hem][:identity] = identity
		@test test[hem][:identity] == identity
		test[hem][:vertexlist] = 1:nverts
		@test test[hem][:vertexlist] == 1:nverts
		@test haskey(test[hem], :identity)
		@test haskey(test[hem], :vertexlist)
		@test length(keys(test[hem])) == 2
	end
	@test haskey(test, :identity)
	@test haskey(test, :vertexlist)
	@test length(keys(test)) == 2

	test[L][:neighbors] = neighbors
	@test :neighbors in setdiff(keys(test[L]), keys(test))

	a = vertices(test[L], (Ipsilateral(), Exclusive()))
	test_vert = 22878
	inds = test[L][:neighbors][test_vert]
	temp_inds = collapse(inds, test[L])
	@test length(temp_inds) == 6
	@test all(x in [21076, 21053, 21054, 21078, 21100, 21099] for x in temp_inds)
	@test expand(collapse(inds, test[L]), test[L]) == inds

	for hem in [L, R]
		temp_inds = collapse(1:32492, test[hem])
		@test length(temp_inds) == size(test[hem], Exclusive())
		@test maximum(temp_inds) == size(test[hem], Exclusive())
		@test length(unique(temp_inds)) == length(temp_inds)

		temp_inds = expand(temp_inds, test[hem])
		@test length(temp_inds) == size(test[hem], Exclusive())
		@test maximum(temp_inds) == size(test[hem], Inclusive())
		@test length(unique(temp_inds)) == length(temp_inds)

		sample_data = collect(1:size(test[hem], Exclusive()))
		padded_data = pad(sample_data, test[hem])
		trimmed_padded_data = trim(padded_data, test[hem])
		@test trimmed_padded_data == sample_data
	end

	temp_inds = expand(1:59412, test)
	@test length(temp_inds) == size(test, Exclusive())
	@test maximum(temp_inds) == size(test, Inclusive())
	@test length(unique(temp_inds)) == length(temp_inds)

	temp_inds = collapse(temp_inds, test)
	@test length(temp_inds) == size(test, Exclusive())
	@test maximum(temp_inds) == size(test, Exclusive())
	@test length(unique(temp_inds)) == length(temp_inds)

	temp_inds = pad(1:59412, test)
	@test length(temp_inds) == size(test)
	@test sum(temp_inds .== 0) == sum(medial_wall(test))
	@test setdiff(temp_inds, 0) == 1:59412

	temp_inds = trim(1:64984, test)
	@test length(temp_inds) == size(test, Exclusive())
	@test all(medial_wall(test)[temp_inds] .== 0)
	@test !any(medial_wall(test)[temp_inds] .== 1)
end

