-- Use-rect registry helpers (from game.lua). Depends on aabb at call time.

function adduserect(x, y, width, height, callback)
	local t = {}
	t.x = x
	t.y = y
	t.width = width
	t.height = height
	t.callback = callback
	t.delete = false

	table.insert(userects, t)
	return t
end

function userect(x, y, width, height)
	local outtable = {}

	local j

	for i, v in pairs(userects) do
		if aabb(x, y, width, height, v.x, v.y, v.width, v.height) then
			table.insert(outtable, v.callback)
			if not j then
				j = i
			end
		end
	end

	return outtable, j
end
