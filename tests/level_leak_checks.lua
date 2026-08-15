--[[ Level lifetime leak checks via Session reset (no LÖVE). ]]

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
local World = require("world.session")
local session = World.new()
rawset(_G, "session", session)

do
	session.map = { { { 99 } } }
	session.objects = fresh_objects()
	session.objects["box"] = { { tag = "level-a" } }
	local map_ref = session.map
	local box_ref = session.objects["box"]

	reset_level_state()
	check("new level new map table", session.map ~= map_ref)
	check("new level new objects table", session.objects["box"] ~= box_ref)
	check("fresh box group empty", next(session.objects["box"]) == nil)
	check("map zeroed", session.mapwidth == 0 and session.mapheight == 0)
	check("scroll zeroed", session.xscroll == 0 and session.yscroll == 0)
	check("_G.map not mirrored", rawget(_G, "map") == nil)
end

-- Double reset: no stale table identity across two loads.
do
	session.map = { { { 1 } } }
	local first = session.map
	reset_level_state()
	local mid = session.map
	session.map = { { { 2 } } }
	local second_write = session.map
	reset_level_state()
	check("double reset first identity gone", session.map ~= first and session.map ~= mid and session.map ~= second_write)
	check("double reset empty", next(session.map) == nil)
	check("double reset objects fresh", next(session.objects["enemy"]) == nil)
end

do
	local objects, playerobjs = fresh_objects()
	check("player group aliases playerobjs", objects["player"] == playerobjs)
	check("object group count", #OBJECT_GROUP_KEYS >= 51)
	for i = 1, #OBJECT_GROUP_KEYS do
		local key = OBJECT_GROUP_KEYS[i]
		check("group " .. key .. " exists", objects[key] ~= nil)
	end
end

return failed
