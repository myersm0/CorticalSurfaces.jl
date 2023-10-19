
export SurfaceSpace, Hemisphere, CorticalSurface

struct SpatialData{T, N}
	data::Dict{MedialWallIndexing, T′} where T′ <: AbstractArray{T, N}
end

abstract type SurfaceSpace end

Base.@kwdef struct Hemisphere <: SurfaceSpace
	coordinates::Dict{MedialWallIndexing, Matrix{T}} where T <: Real
	triangles::Union{Nothing, Matrix{Int}}
	medial_wall::BitVector
	vertices::Dict{IndexMapping, Vector{Int}}
	appendix::Dict{Symbol, SpatialData} = 
		Dict{Symbol, SpatialData}()
	size::Dict{MedialWallIndexing, Int} = Dict(
		Exclusive() => sum(.!medial_wall),
		Inclusive() => length(medial_wall)
	)
	remap::Dict{Pair{MedialWallIndexing, MedialWallIndexing}, Vector{Int}}
end

struct CorticalSurface <: SurfaceSpace
	hems::Dict{BrainStructure, Hemisphere}
	vertices::Dict{MedialWallIndexing, Vector}
	remap::Dict{Pair{MedialWallIndexing, MedialWallIndexing}, Vector{Int}}
end

