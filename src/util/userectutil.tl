-- Ported from root userectutil.lua (Teal).

-- Use-rect registry helpers (from game.lua). Depends on aabb at call time.

local function adduserect(x: any, y: any, width: any, height: any, callback: any): any
	local t: {any:any} = {}
	t.x = x
	t.y = y
	t.width = width
	t.height = height
	t.callback = callback
	t.delete = false

	table.insert(userects, t)
	return t
end
_G.adduserect = adduserect


local function userect(x: any, y: any, width: any, height: any): {any}, any
	local outtable: {any} = {}

	local j: any

	for i, v in pairs(userects) do
		local rect = v as {any:any}
		if aabb(x, y, width, height, rect.x, rect.y, rect.width, rect.height) then
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
