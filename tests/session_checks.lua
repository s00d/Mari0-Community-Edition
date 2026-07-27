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

local session_src = assert(io.open(root .. "/src/world/session.tl", "r")):read("*a")
local load_src = assert(io.open(root .. "/src/app/game_load_level.tl", "r")):read("*a")

check("push_globals removed", not session_src:find("push_globals"))
check("sync_session_from_globals defined", session_src:find("function World:sync_session_from_globals") ~= nil)
check("startlevel uses set_gamestate", load_src:find("session:set_gamestate%(\"game\"%)") ~= nil)
check("startlevel no dual gamestate assign", not load_src:match("gamestate%s*=%s*\"game\"[^\n]*\n[^\n]*session%.gamestate"))

local World = require("world.session")
local w = World.new()
w:set_gamestate("menu")
check("set_gamestate updates session", w.gamestate == "menu")
check("set_gamestate writes _G", (_G.gamestate or rawget(_G, "gamestate")) == "menu")

if select("#", ...) > 0 then
	return failed
end
