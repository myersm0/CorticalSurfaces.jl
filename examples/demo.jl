
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

# get the spatial coordinates of the R hem, inclusive of medial wall by default:
coordinates(hems[R])

# or as above, but excluding medial wall:
coordinates(hems[R], Exclusive())

# get the vertex indices of the R hem, inclusive of medial wall by default:
vertices(hems[R])

# or as above, but excluding medial wall:
vertices(hems[R], Exclusive())

# ideally we'd like to also be able to index into hemispheres bilaterally sometimes;
# but this doesn't work *yet*, because while the left and right hemispheres are
# both defined already, they don't know about each other yet

# now put the two hemispheres together inside a single CorticalSurface struct:
c = CorticalSurface(hems[L], hems[R])

# Now c contains both Hemisphere structs, which are each now slightly
# modified because we have new information: the two hemispheres now know
# about each other, and so we now have the information that we need in order 
# to do things like index into the hemispheres bilaterally if needed:
vertices(c[R], Bilateral(), Exclusive()) # now it works

# You can also get vertex indices from the entire CorticalSurface struct, in which
# case the index numbering will be bilateral (i.e. both hems consecutively numbered, 
# instead of just 1:size(hem) for each hem individaully):
vertices(c)
vertices(c, Exclusive())

# note the equivalence:
vertices(c) == [vertices(c[L]); vertices(c[R], Bilateral(), Inclusive())]

# The function coordinates() works analogously:
@assert coordinates(c) == [coordinates(c[L]); coordinates(c[R])]

# similarly you can get the sizes of the hemispheres (number of vertices)
# individually or combined:
size(c)
@assert size(c) == (size(c[L]) + size(c[R]))

# or pass in optional Exclusive() arg to specify that you want the number of vertices
# exclusive of medial wall:
size(c, Exclusive())
@assert size(c, Exclusive()) == (size(c[L], Exclusive()) + size(c[R], Exclusive()))

# sometimes you want vertex indices that will map back to a medial wall-less 
# CIFTI file (containing functional data for example):
collapse(vertices(c), c)

# or, a little more concisely:
@collapse vertices(c)

# or other times you want to work in the opposite direction: you have some indices
# (say [99, 999, 9999, 59412]) from a medial wall-less CIFTI and you want to map
# those indices back to a CorticalSurface struct c to get the coordinates (for example):
verts = [99, 999, 9999, 59412]
expanded_verts = expand(verts, c)
coordinates(c)[expanded_verts, :]

# or similarly you can pass the argument Exclusive() to coordinates()
# and achieve the same thing without first transforming the vertices:
coordinates(c, Exclusive())[verts, :]

# optionally add supplementary spatial information, such as adjacency lists:
c[L][:neighbors] = make_adjacency_list(hems[L])
c[R][:neighbors] = make_adjacency_list(hems[R])

# now access the supplementary spatial data you supplied:
c[L][:neighbors]

# or, to exclude medial wall vertices:
@exclusive c[L][:neighbors]

# carefully take a look at outputs from the above and observe what @exclusive did:
# - it reduced the elements of the adjacency list to include only non-medial wall elements
# - it also modified the indices within each element by adjusting for absense of medial wall

c[L][:A] = make_adjacency_matrix(hems[L])
c[R][:A] = make_adjacency_matrix(hems[R])

# As above, you may have a square matrix of spatial data defined for each of the 
# hemispheres individually, but sometimes you'd like to access them as one big matrix
# (i.e. concatenated across both dimensions). You can simply do the below for such 
# cases; but be aware the that the I and III quadrants will be all zeros:
c[:A] 
c[:A, Exclusive()] 
@exclusive c[:A] # equivalent to the above

# In the case of an adjacency matrix, as here, that zero-padding is probably what we
# want, but if it's something else like a distance matrix, then you need to either 
# avoid accessing those quadrants or else fill them in yourself with something 
# appropriate like NaN or Inf

# This concept may also apply to Vector spatial data, such as an adjacency list:
c[:neighbors]
@exclusive c[:neighbors]

# A performance warning about accessing CorticalSurface data like this:
# if you need to *frequently* access bilateral spatial data like in the above few 
# examples, it's better to do it once and store that output in a new object, like this:
A_bilateral = c[:A]

# this is because, due to the potentially large size of things like c[:A],
# the total object itself is not stored but rather concatenated dynamically
# from each hemisphere every time it's requested


