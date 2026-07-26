local function inrange(i: number, a: number, b: number, include: boolean|nil): boolean
	if a > b then
		a, b = b, a
	end
	if include then
		return i >= a and i <= b
	end
	return i > a and i < b
end

-- Uses globals mapwidth / mapheight (set by level load).
local function inmap(x: number|nil, y: number|nil): boolean
	if not x or not y then
		return false
	end
	local mw = rawget(_G, "mapwidth") as number|nil
	local mh = rawget(_G, "mapheight") as number|nil
	if not mw or not mh then
		return false
	end
	return x >= 1 and x <= mw and y >= 1 and y <= mh
end

_G.inrange = inrange
_G.inmap = inmap

return {
	inrange = inrange,
	inmap = inmap,
}
