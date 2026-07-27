-- Ported from root userectutil.lua (Teal).

-- Use-rect registry helpers (from game.lua). Depends on aabb at call time.

local function adduserect(x: number, y: number, width: number, height: number, callback: any): {string:any}
	local t: {string:any} = {
		x = x,
		y = y,
		width = width,
		height = height,
		callback = callback,
		delete = false,
	}

	table.insert(userects, t)
	return t
end
_G.adduserect = adduserect


local function userect(x: number, y: number, width: number, height: number): {any}, any
	local outtable: {any} = {}

	local j: any

	for i, v in pairs(userects) do
		local rect = v as {string:any}
		local rx = tonumber(rect.x) or 0
		local ry = tonumber(rect.y) or 0
		local rw = tonumber(rect.width) or 0
		local rh = tonumber(rect.height) or 0
		if aabb(x, y, width, height, rx, ry, rw, rh) then
			table.insert(outtable, rect.callback)
			if not j then
				j = i
			end
		end
	end

	return outtable, j
end
_G.userect = userect

return {
	adduserect = adduserect,
	userect = userect,
}
