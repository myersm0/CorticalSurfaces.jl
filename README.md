# CorticalSurfaces
In working with spatial coordinates and related information in surface-space analysis of the cerebral cortex, opportunities for error can arise from the variety of ways in which you may need to index into that spatial information. For example, usually functional data in a CIFTI file will omit the medial wall vertices; but when reconciling that data with spatial information from a GIFTI file, you need to do the math and book-keeping of mapping the set of medial wall-exclusive vertices to the other set of -inclusive vertices or vice versa. Another case is when you have some data indexed per-hemisphere but other data is indexed whole-brain. Or you may face both obstacles at the same time. If you get it wrong, you may never know it.

This package provides an interface for improving safety and readability of managing such operations and for encapsulating spatial properties pertaining to a surface representation(s) of the cortex, including arbitrary user-supplied data such as distance matrices and adjacency info. It was designed with CIFTI/GIFTI files in mind and the so-called fsLR 32k coordinate space, though it should work in any context where the same basic ideas apply.

This package supplies the backbone for a set of algorithms for operating on parcels on the cortical surface, [CorticalParcels.jl](https://github.com/myersm0/CorticalParcels.jl).

## Performance and efficiency
The implementation priorities are, in order:
1. Correctness
2. Speed of *indexing* into the spatial data (rather than of struct initialization)
3. Convenience, readability in usage of this API

Where each item is assumed to be far more important than the previous. Since in-memory storage cost of structural data such as this should be negligble, redundant representations of some data are present in order to speed up indexing.

## Installation
Within Julia:
```
using Pkg
Pkg.add("CorticalSurfaces")
```

## Usage
A demo of the basic functionality is provided in `examples/demo.jl`, but see below for the main points.

### Constructors
To create a Hemisphere struct that will encapsulate spatial information, three pieces of information are required: 
- a `BrainStructure` label denoting which hemisphere is represented, either `CORTEX_LEFT` or `CORTEX_RIGHT` (or `L` and `R` for short)
- a numeric `Matrix` of coordinates having 3 rows (x, y, z) and a number of columns equaling the number of vertices
- a `BitVector`, the length of which is equal to the number of columns in the coordinate `Matrix`, indicating the presence of the medial wall (`true` if the vertex is part of the medial wall, `false` otherwise)

For example, to create two hemispheres (with nonsensical coordinate and medial wall information, in this case, but actual data for these things could come from a GIFTI file, a CSV file, etc): 
```
nverts = 32492
surf = zeros(3, nverts)
mw = rand(Bool, nverts)
hemL = Hemisphere(CORTEX_LEFT, surf, mw)
mw = rand(Bool, nverts)
hemR = Hemisphere(CORTEX_RIGHT, surf, mw)
```

And now to construct a CorticalSurface struct from the above:
```
c = CorticalSurface(hemL, hemR)
```

### Accessors
The following are some of the operations currently supported:
```
# get coordinates from both hemispheres combined
coordinates(c, Inclusive()) # including medial wall vertices
coordinates(c, Exclusive()) # not including medial wall vertices

# get coordinates from just the right hemisphere
coordinates(c[R], Inclusive()) # including medial wall vertices
coordinates(c[R], Exclusive()) # not including medial wall vertices

# as above, but don't get the coordinates, just get a vector of vertex indices
vertices(c[R], Inclusive())

# as above, but Bilateral() signals that we want index numbers that are relative
# to the whole brain, not just the Hemisphere
vertices(c[R], Bilateral(), Inclusive())

size(c, Inclusive())    # number of total vertices in both hemispheres
size(c[L], Inclusive()) # number of vertices in just the left hemisphere
```

### Supplementary spatial data
```
# create a "distance matrix" for the right hemisphere
nverts = size(c[R], Inclusive())
c[R][:distance_matrix] = nrand(UInt8, nverts, nverts)

# index into the distance matrix
c[R][:distance_matrix][10000:21000, 2001:4009]
```
Any supplementary spatial data, such as the distance matrix above, must have spatial dimension(s) that are consistent with those of the surface geometry of the Hemisphere or CorticalSurface struct to which it is "appended." (A current limitation is that these spatial data items must having indexing *inclusive* of medial wall vertices.)

### Functions to adjust for presense or absense of medial wall
To map a set of medial wall-inclusive vertices to a set of -exclusive vertices -- in other words, to shorten or collapse the indices -- a function called `collapse` is provided, as well as `expand` to handle the opposite case. For example, for a surface geometry that has 29696 or 32494 vertices (exclusive or inclusive of medial wall, respectively):
```
verts = rand(1:32492, 100)      # generate some random vertex numbers in the range [1, 32492]
new_verts = collapse(verts, c)  # result will be indices in the range [1, 29696]

verts = rand(1:29696, 100)      # generate some random vertex numbers in the range [1, 29696]
new_verts = expand(verts, c)    # result will be indices in the range [1, 32492]
```
Note that in the former case, the vector returned might be shorter than the length of the input vector, because we're mapping from a larger range down to a smaller one; any of the inputs that belong to the medial wall will necessarily be omitted.

Another pair of functions `pad` and `trim` perform a similar role but with a key difference: the input vector is a set of numbers, the values of which you *don't* want to change; instead, you want to grow its length by padding it with zeros wherever there's medial wall, or shrink it by trimming out elements that coincide with the medial wall. The numbers could be some functional or statistical data, for example. (For these operations to make sense, the size of the input vector must be equal to `size(surf, Exclusive())` in the `pad` case, or `size(surf, Inclusive())` in the `trim` case.)
```
functional_data = randn(size(c[L], Exclusive()))
padded_data = pad(functional_data, c[L])

# trimming the value returned above should get you back to the original functional data
trimmed_data = trim(padded_data, c[L])
```

## Acknowledgments
For testing and demonstration purposes, this package uses surface data from the MSC dataset (described in [Gordon et al 2017](https://www.cell.com/neuron/fulltext/S0896-6273(17)30613-X)). This data was obtained from the OpenfMRI database. Its accession number is ds000224.

[![Build Status](https://github.com/myersm0/CorticalSurfaces.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/CorticalSurfaces.jl/actions/workflows/CI.yml?query=branch%3Amain)
