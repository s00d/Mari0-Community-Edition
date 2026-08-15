local function inrange(i: any, a: any, b: any, include?: boolean): boolean
	local ni = i as number
	local na = a as number
	local nb = b as number
	if na > nb then
		na, nb = nb, na
	end
	if include then
		return ni >= na and ni <= nb
	end
	return ni > na and ni < nb
end

-- Uses Session map size (set by level load).
local function inmap(x: number|nil, y: number|nil): boolean
	if not x or not y then
		return false
	end
	local s = session
	local mw = s.mapwidth as number
	local mh = s.mapheight as number
	return x >= 1 and x <= mw and y >= 1 and y <= mh
end

_G.inrange = inrange
_G.inmap = inmap

return {
	inrange = inrange,
	inmap = inmap,
}
