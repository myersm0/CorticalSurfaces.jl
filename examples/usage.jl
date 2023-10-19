
using CorticalSurfaces
using JLD
using CIFTI

# CIFTI.jl supplies a shorthand we'll be using throughout: 
# constants L, R, and LR for referring to left, right, or both hemispheres

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

# get the vertex indices of the R hem, inclusive of medial wall by default:
vertices(hems[R])

# or as above, but excluding medial wall:
vertices(hems[R], Exclusive())

# ideally we'd like to also be able to index into hemispheres bilaterally sometimes;
# but this doesn't work *yet*, because while the left and right hemispheres are
# both defined, they don't know about each other yet
vertices(hems[R], Bilateral(), Exclusive()) # doesn't work yet; see below

# now put the two hemispheres together inside a single CorticalSurface struct:
c = CorticalSurface(hems[L], hems[R])

# Now c contains both Hemisphere structs, which are each now slightly
# modified because we have new information: the two hemispheres now know
# about each other, and so we now have the information that we need in order 
# to do things like index into the hemispheres bilaterally if needed:
vertices(c[R], Bilateral(), Exclusive()) # now it works

# You can also get vertex indices relative to the entire CorticalSurface struct 
# (i.e. both hems consecutively numbered, instead of just each hem individaully):
vertices(c)
vertices(c, Exclusive())

# note the equivalence:
vertices(c) == [vertices(c[L]); vertices(c[R], Bilateral(), Inclusive())]

# similarly you can get the sizes of the hemispheres (number of vertices)
# individuall or combined:
size(c)
size(c) == (size(c[L]) + size(c[R])) # true

# or pass in optional Exclusive() arg to specify that you want the number of vertices
# exclusive of medial wall:
size(c, Exclusive())
size(c, Exclusive()) == (size(c[L], Exclusive()) + size(c[R], Exclusive())) # true

# sometimes you want vertex indices that will map back to a medial wall-less 
# CIFTI file (containing functional data for example):
@collapse vertices(c)

# optionally add additional spatial information, such as adjacency lists:
c[L][:neighbors] = make_adjacency_list(hems[L])
c[R][:neighbors] = make_adjacency_list(hems[R])

@exclusive c[L][:neighbors]







