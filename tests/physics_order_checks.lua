--[[ Physics group order behavior checks (no LÖVE). ]]

local root = ... or "."
local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	package.path,
}, ";")

require("physics.order")

check("PHYSICS_GROUP_ORDER is table", type(PHYSICS_GROUP_ORDER) == "table")
check("PHYSICS_GROUP_ORDER has player first", PHYSICS_GROUP_ORDER[1] == "player")
check("PHYSICS_GROUP_ORDER has tile", table.concat(PHYSICS_GROUP_ORDER, ","):find("tile", 1, true) ~= nil)
check("physics_group_keys_sorted exists", type(physics_group_keys_sorted) == "function")

do
	local keys = physics_group_keys_sorted({ [3] = {}, [1] = {}, ["b"] = {}, ["a"] = {} })
	check("sorted keys numeric before string", keys[1] == 1 and keys[2] == 3 and keys[3] == "a" and keys[4] == "b")
end

do
	local dense = { {}, {}, {} }
	local keys = physics_group_keys_sorted(dense)
	check("dense array keys 1..n", keys[1] == 1 and keys[2] == 2 and keys[3] == 3 and keys[4] == nil)
end

if select("#", ...) > 0 then
	return failed
end
