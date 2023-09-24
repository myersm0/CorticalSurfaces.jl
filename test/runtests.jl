using CorticalSurfaces
using Cifti2
using Test
using JLD

data_dir = joinpath(dirname(@__FILE__), "../", "data")

# load Conte69 midthickness files and generate some ground truth info
conte_file = joinpath(data_dir, "conte69.32k_fs_LR.jld")
conte = load(conte_file)
surfL = conte["pointsets"]["midthickness"][Cifti2.L]
surfR = conte["pointsets"]["midthickness"][Cifti2.R]
mwL = conte["medial wall"][Cifti2.L]
mwR = conte["medial wall"][Cifti2.R]
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

	@test size(coordinates(test, Inclusive()), 1) == nverts_total
	@test size(coordinates(test, Exclusive()), 1) == nverts_surface

	@test vertices(test[L], (Ipsilateral(), Exclusive())) == surf_vertices_L
	@test vertices(test[R], (Ipsilateral(), Exclusive())) == surf_vertices_R

	for hem in [L, R]
		nverts = size(test[hem], Inclusive())
		identity = falses(nverts, nverts)
		for i in 1:nverts
			identity[i, i] = true
		end
		append!(test[hem], :identity, identity)
		@test test[hem][:identity] == identity
		append!(test[hem], :vertexlist, 1:nverts)
		@test test[hem][:vertexlist] == 1:nverts
	end
end

