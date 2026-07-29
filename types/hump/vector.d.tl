global record HumpVector
	x: number
	y: number
	len: function(HumpVector): number
	normalized: function(HumpVector): HumpVector
	rotated: function(HumpVector, number): HumpVector
	dot: function(HumpVector, HumpVector): number
end

local record vector
	new: function(...: any): HumpVector
	fromPolar: function(...: any): HumpVector
end

return vector
