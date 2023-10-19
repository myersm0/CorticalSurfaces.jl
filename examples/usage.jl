
using CorticalSurfaces
using JLD

# import L, R, and LR shorthands for referring to left, right, or both hemispheres
using CIFTI: L, R, LR

# just for demonstration purposes: we can create a Hemisphere from any
# xyz coordinates and medial wall information (nonsensical in this case)
coords = randn(32492, 3)
medial_wall = rand(Bool, 32492)
hem = Hemisphere(coords, medial_wall)

# now to create a meaningful Hemisphere struct from real data, we'll first
# load in some spatial data to use:
data_dir = joinpath(dirname(@__FILE__), "..", "data")
MSC01_file = joinpath(data_dir, "MSC01.jld")
MSC01 = load(MSC01_file)

# Construct a Hemisphere object based on a matrix of coordinates
# and a BitVector denoting medial wall membership.
# Note: the `triangles` arg is optional; it's only used if you want to:
# - calculate adjacency info
# - convert Hemisphere to a GeometryBasics.Mesh (e.g. for plotting)
hems = Dict(
	hem => 
		Hemisphere(
			MSC01["pointsets"]["midthickness"][hem],
			MSC01["medial wall"][hem];
			triangles = MSC01["triangle"][hem]
		)
	for hem in LR
)

# optional: add additional spatial information, such as adjacency lists:
hems[L][:neighbors] = make_adjacency_list(hems[L])
hems[R][:neighbors] = make_adjacency_list(hems[R])

# now put the two hemispheres together inside a single CorticalSurface struct:
c = CorticalSurface(hems[L], hems[R])

c[L] == hems[L]
c[R] == hems[R]


