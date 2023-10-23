
export @exclusive, @collapse

macro collapse(expr)
	return :(collapse($(esc(expr)), $(esc(expr.args[2]))))
end


