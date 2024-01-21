
module CorticalSurfaces

using CIFTI
using Chain
using SparseArrays

const AdjacencyList = Vector{Vector{T}} where T <: Integer
const AdjacencyMatrix = AbstractMatrix{Bool}
const DistanceMatrix = AbstractMatrix{T} where T <: Real

include("traits.jl")
export HemisphericIndexing, Ipsilateral, Bilateral
export MedialWallIndexing, Exclusive, Inclusive
export IndexMapping, CollapseMW, ExpandMW

include("types.jl")
export SurfaceSpace, Hemisphere, CorticalSurface

include("constructors.jl")

include("accessors.jl")
export size, getindex, coordinates, vertices, medial_wall, keys, haskey, brainstructure

include("mutators.jl")
export setindex!

include("index_ops.jl")
export expand, collapse, pad, trim

include("macros.jl")
export @collapse

include("show.jl")

include("conversion.jl")

include("adjacency.jl")
export initialize_adjacency_matrix!, initialize_adjacency_list!, initialize_adjacencies!
export adjacency_matrix, adjacency_list

end


