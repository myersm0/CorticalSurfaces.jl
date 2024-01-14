
function Base.setindex!(hem::Hemisphere, what::T, k::Symbol) where T <: AbstractArray
	check_size(hem, what, Inclusive()) || error(DimensionMismatch)
	hem.appendix[k] = SpatialData(what, hem, Inclusive())
end

# check_size() below is simply a helper for the above fn ...

function check_size(
		::IsSquare, hem::Hemisphere, what::AbstractArray, indexing::MedialWallIndexing
	)
	return all(size(what) .== size(hem, indexing))
end

function check_size(
		::IsRectangular, hem::Hemisphere, what::AbstractArray, indexing::MedialWallIndexing
	)
	return size(what, 2) == size(hem, indexing)
end

function check_size(
		::IsScalarList, hem::Hemisphere, what::AbstractArray, indexing::MedialWallIndexing
	)
	return length(what) == size(hem, indexing)
end

function check_size(
		::IsNestedList, hem::Hemisphere, what::AbstractArray, indexing::MedialWallIndexing
	)
	hem_size = size(hem, indexing)
	return length(what) == hem_size && all([all(1 .<= x .<= hem_size) for x in what])
end

function check_size(hem::Hemisphere, what::AbstractArray, indexing::MedialWallIndexing)
	return check_size(DataStyle(what), hem, what, indexing)
end

