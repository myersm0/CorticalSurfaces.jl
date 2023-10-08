
module CorticalSurfaces

const AdjacencyList = Vector{Vector{T}} where T <: Integer
const AdjacencyMatrix = AbstractMatrix{Bool}
const DistanceMatrix = AbstractMatrix{T} where T <: Real

include("traits.jl")
include("surfaces.jl")
include("conversion.jl")
include("adjacency.jl")

end


