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

local World = require("world.session")
local w = World.new()
w:set_gamestate("menu")
check("set_gamestate updates session", w.gamestate == "menu")
check("set_gamestate writes _G", (_G.gamestate or rawget(_G, "gamestate")) == "menu")
check("set_gamestate _G is string", type(rawget(_G, "gamestate")) == "string")

local GS = require("app.gamestate")
rawset(_G, "Gamestate", GS)
w:set_gamestate("game")
check("set_gamestate syncs Gamestate.current", GS.current == "game")
check("set_gamestate does not store table in _G", type(rawget(_G, "gamestate")) == "string" and rawget(_G, "gamestate") == "game")

if select("#", ...) > 0 then
	return failed
end
