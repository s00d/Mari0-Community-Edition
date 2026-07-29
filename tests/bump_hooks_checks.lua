--[[ bump slot helpers: set_tile add/remove roundtrip via checkrect ]]

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
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	package.path,
}, ";")

require("physics.late")
require("physics.world")
require("physics.checkrect")

do
	objects = {}
	physics_world_reset()
	local key = 42
	local body = {x = 1, y = 2, width = 1, height = 1, active = true, static = true, category = 2}
	physics_world_set_tile(key, body)
	local out = checkrect(1, 2, 1, 1, {"tile"})
	check("set_tile add visible", #out == 2 and out[1] == "tile" and out[2] == key)
	physics_world_set_tile(key, nil)
	out = checkrect(1, 2, 1, 1, {"tile"})
	check("set_tile remove", #out == 0)
end

do
	objects = { screenboundary = {} }
	physics_world_reset()
	local sb = {x = 5, y = 0, width = 1, height = 10, active = true, static = true, category = 10}
	physics_world_upsert_slot("screenboundary", "right", sb)
	sb.x = 7
	physics_world_upsert_slot("screenboundary", "right", sb)
	local out = checkrect(6.5, 0, 1, 10, {"screenboundary"})
	check("upsert_slot moves index", #out == 2 and out[2] == "right")
	physics_world_remove_slot("screenboundary", "right")
	out = checkrect(6.5, 0, 1, 10, {"screenboundary"})
	check("remove_slot clears", #out == 0)
end

do
	objects = { screenboundary = {} }
	physics_world_reset()
	local sb = {x = 0, y = 0, width = 1, height = 5, active = true, static = true, category = 10}
	physics_world_upsert_slot("screenboundary", "left", sb)
	sb.height = 20
	physics_world_upsert_slot("screenboundary", "left", sb)
	local out = checkrect(0, 15, 1, 5, {"screenboundary"})
	check("upsert_slot height change", #out == 2 and out[2] == "left")
	sb.active = false
	physics_world_upsert(sb, "screenboundary", "left")
	out = checkrect(0, 0, 1, 20, {"screenboundary"})
	check("inactive removes from bump", #out == 0)
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
