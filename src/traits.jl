
export HemisphericIndexing, Ipsilateral, Bilateral
export MedialWallIndexing, Exclusive, Inclusive
export IndexMapping, CollapseMW, ExpandMW

# ===== traits concerning indexing options =====
abstract type IndexingStyle end

abstract type HemisphericIndexing <: IndexingStyle end
struct Ipsilateral <: HemisphericIndexing end
struct Bilateral <: HemisphericIndexing end

abstract type MedialWallIndexing <: IndexingStyle end
struct Exclusive <: MedialWallIndexing end
struct Inclusive <: MedialWallIndexing end

const IndexMapping = Tuple{HemisphericIndexing, MedialWallIndexing}
const CollapseMW = (Inclusive() => Exclusive())
const ExpandMW = (Exclusive() => Inclusive())

# ===== traits concerning the shape of user-supplied supplementary data =====
abstract type DataStyle end

abstract type ListStyle <: DataStyle end
struct IsScalarList <: DataStyle end
struct IsNestedList <: DataStyle end

abstract type MatrixStyle <: DataStyle end
struct IsSquare <: MatrixStyle end
struct IsRectangular <: MatrixStyle end

DataStyle(v::AbstractVector) = ListStyle(v)
DataStyle(m::AbstractMatrix) = MatrixStyle(m)

ListStyle(v::AbstractVector) = isbitstype(eltype(v)) ? IsScalarList() : IsNestedList()
MatrixStyle(m::AbstractMatrix) = allequal(size(m)) ? IsSquare() : IsRectangular()



