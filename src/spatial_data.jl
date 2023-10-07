
struct SpatialData{T, N}
	data::Dict{MedialWallIndexing, T′} where T′ <: AbstractArray{T, N}
end

