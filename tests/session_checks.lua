--[[ Session API honesty checks (no LÖVE). ]]

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
local w = World.new()
rawset(_G, "session", w)

check("session owns map", type(w.map) == "table")
check("session owns objects", type(w.objects) == "table")
check("session owns scroll", type(w.xscroll) == "number" and type(w.yscroll) == "number")
check("_G.map absent", rawget(_G, "map") == nil)
check("_G.objects absent", rawget(_G, "objects") == nil)
check("_G.xscroll absent", rawget(_G, "xscroll") == nil)
check("no Session alias", rawget(_G, "Session") == nil)

w.xscroll = 3.5
w.yscroll = 1.25
check("direct scroll write", w.xscroll == 3.5 and w.yscroll == 1.25)

local old_map = w.map
local old_objects = w.objects
w.map["stale"] = true
w.objects["box"] = { { tag = "keep" } }
w:reset_level()
check("reset_level new map", w.map ~= old_map)
check("reset_level new objects", w.objects ~= old_objects)
check("reset_level clears map", w.map["stale"] == nil)
check("reset_level empty box group", next(w.objects["box"]) == nil)
check("reset_level scroll zero", w.xscroll == 0 and w.yscroll == 0)

check("no sync_session_from_globals", type(w.sync_session_from_globals) ~= "function")
check("no set_scroll", type(w.set_scroll) ~= "function")
check("no set_gamestate", type(w.set_gamestate) ~= "function")

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
