
module CorticalSurfaces

using CIFTI
using Chain
using SparseArrays

const AdjacencyList = Vector{Vector{T}} where T <: Integer
const AdjacencyMatrix = AbstractMatrix{Bool}
const DistanceMatrix = AbstractMatrix{T} where T <: Real

include("traits.jl")
include("types.jl")
include("constructors.jl")
include("accessors.jl")
include("mutators.jl")
include("index_ops.jl")
include("macros.jl")
include("show.jl")
include("conversion.jl")
include("adjacency.jl")

end


