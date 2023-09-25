# CorticalSurfaces
In working with spatial coordinates and related information in surface-space analysis of the cerebral cortex, opportunities for error can arise from the variety of ways in which you may need to index into that spatial information. For example, usually functional data in a CIFTI file will omit the medial wall vertices; but when reconciling that data with spatial information from a GIFTI file, you need to do the math and book-keeping of mapping the set of medial wall-exclusive vertices to the other set of -inclusive vertices or vice versa. Another case is when you have some data indexed per-hemisphere but other data is indexed whole-brain. Or you may face both obstacles at the same time. If you get it wrong, you may never know it.

This package provides an interface for improving safety and readability of managing such operations and for encapsulating spatial properties pertaining to a surface representation(s) of the cortex, including arbitrary user-supplied data such as distance matrices and adjacency info. It was designed with CIFTI/GIFTI files in mind and the so-called fs_LR 32k coordinate space, though it could work in other contexts too.

This package supplies the backbone for a set of spatial algorithms for operating on [parcels](https://github.com/myersm0/Myers-Labonte_parcellation) on the cortical surface, tentatively called [ParcelOps.jl](https://github.com/myersm0/ParcelOps.jl), still under development.

An additional goal, not yet implemented, is to provide some GLMakie recipes for 3d visualization of brain surfaces, inspired by [Connectome Workbench](https://humanconnectome.org/software/connectome-workbench)'s wb_view but with a programmatic interface and the ability to add arbitrary graphical elements (such as text annotations).

## Performance and efficiency
The implementation priorities are, in order:
1. Correctness
2. Speed of *indexing* into the spatial data (rather than of struct initialization)
3. Convenience, readability in usage of this API

Where each item is assumed to be far more important than the previous. Since in-memory storage cost of structural data such as this should be negligble, redundant representations of some data are present in order to speed up indexing.

## Usage
### Constructors
To create a Hemisphere object that will encapsulate spatial information, two pieces of information are required: 
- a numeric `Matrix` of coordinates having 3 columns (x, y, z)
- a `BitVector` or `Vector{Bool}`, the length of which is equal to the number of rows in the coordinate `Matrix`, indicating the presence of the medial wall (`true` if the vertex is part of the medial wall, `false` otherwise)

For example, to create two hemispheres (with nonsensical coordinate and medial wall information, in this case, but actual data for these things could come from a GIFTI file, a CSV file, etc): 
```
nverts = 32492
surf = zeros(nverts, 3)
mw = rand(Bool, nverts)
hemL = Hemisphere(surf, mw)
mw = rand(Bool, nverts)
hemR = Hemisphere(surf, mw)
```

And now to construct a CorticalSurface object from the above:
```
c = CorticalSurface(hemL, hemR)
```

### Basic accessors for coordinates, vertex indices, and size
The following are some of the operations currently supported:
```
# get coordinates from both hemispheres combined
coordinates(c, Exclusive()) # not including medial wall vertices
coordinates(c, Inclusive()) # including medial wall vertices

# get coordinates from just the right hemisphere
coordinates(c[R], Exclusive()) # including medial wall vertices
coordinates(c[R], Inclusive()) # not including medial wall vertices

# as above, but don't get the coordinates, just get a vector of vertex indices
vertices(c[R], Inclusive())

# as above, but Bilateral() signals that we want index numbers that are relative
# to the whole brain, not just the Hemisphere
vertices(c[R], Bilateral(), Inclusive())

size(c, Inclusive())    # number of total vertices in both hemispheres
size(c[L], Inclusive()) # number of vertices in just the left hemisphere
```

### Supplementary data
```
# create a "distance matrix" for the right hemisphere
nverts = size(c[R], Inclusive())
nonsensical_distance_matrix = rand(UInt8, nverts, nverts)

# add it to the available spatial information for that hemisphere,
append!(c[R], :distance_matrix, nonsensical_distance_matrix)

# index into the distance matrix
c[R][:distance_matrix][50000:51000, 42001:42009]
```
Any supplementary spatial data, such as the distance matrix above, must have spatial dimension(s) that are consistent with those of the surface geometry of the Hemisphere or CorticalSurface object to which it is "appended." (A current limitation is that these spatial data objects must having indexing *inclusive* of medial wall vertices, but I aim to remove this limitation in a future version.)

### `collapse` and `expand` functions to remove, or add, presense of medial wall
To map a set of medial wall-inclusive vertices to a set of -exclusive vertices -- in other words, to shorten or collapse the indices -- a function called `collapse` is provided, as well as `expand` to handle the opposite case. For example, for a surface geometry that has 29696 or 32494 vertices (exclusive and inclusive of medial wall, respectively):
```
verts = rand(1:32492, 100) # generate some random vertex numbers from [1, 32492]
collapse(verts, c)         # result will be indices in the range [1, 29696]

verts = rand(1:29696, 100) # generate some random vertex numbers from [1, 29696]
expand(verts, c)           # result will be indices in the range [1, 32492]
```
Note that in the former case, the vector returned might be shorter than the length of the input vector, because we're mapping from a larger range down to a smaller one; any of the inputs that belong to the medial wall will necessarily be omitted.

[![Build Status](https://github.com/myersm0/CorticalSurfaces.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/CorticalSurfaces.jl/actions/workflows/CI.yml?query=branch%3Amain)
