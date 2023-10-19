
export @exclusive, @collapse

macro exclusive(expr)
	surface = expr.args[1]
	k = expr.args[2]
	return :($surface[$k, Exclusive()])
end

macro collapse(expr)
	return :(collapse($expr, $(expr.args[2])))
end


