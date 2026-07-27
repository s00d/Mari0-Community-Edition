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

if select("#", ...) > 0 then
	return failed
end
