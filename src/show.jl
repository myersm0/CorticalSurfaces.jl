
function Base.show(io::IO, ::MIME"text/plain", h::Hemisphere)
	print("Hemisphere ($(brainstructure(h))) with $(size(h)) vertices ")
	print("($(size(h, Exclusive())) without medial wall)")
end

function Base.show(io::IO, ::MIME"text/plain", c::CorticalSurface)
	print("CORTEX_LEFT  => ")
	display(c[L])
	print("CORTEX_RIGHT => ")
	display(c[R])
	print("Total vertices: $(size(c)) ($(size(c, Exclusive())))")
end

Base.show(io::IO, ::MIME"text/plain", x::SpatialData) = display(x.data)




