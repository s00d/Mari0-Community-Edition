--[[ Level lifetime leak checks via _G reset (no LÖVE). ]]

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

require("world.level")

do
	map = { { { 99 } } }
	objects = fresh_objects()
	objects["box"] = { { tag = "level-a" } }
	local map_ref = map
	local box_ref = objects["box"]

	reset_level_state()
	check("new level new map table", map ~= map_ref)
	check("new level new objects table", objects["box"] ~= box_ref)
	check("fresh box group empty", next(objects["box"]) == nil)
	check("map zeroed", mapwidth == 0 and mapheight == 0)
	check("scroll zeroed", xscroll == 0 and yscroll == 0)
end

do
	local objects, playerobjs = fresh_objects()
	check("player group aliases playerobjs", objects["player"] == playerobjs)
	check("object group count", #OBJECT_GROUP_KEYS == 51)
	for i = 1, #OBJECT_GROUP_KEYS do
		local key = OBJECT_GROUP_KEYS[i]
		check("group " .. key .. " exists", objects[key] ~= nil)
	end
end

return failed
