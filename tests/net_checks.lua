--[[ Net rewrite checks: schema + sync + offline Net (no ENet required). ]]

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

-- Minimal stubs for match/sync
_G.controls = {[1] = {left = {"key:a"}, jump = {"key:space"}}}
_G.players = 1
_G.playerobjs = {}
_G.ui_action_down = function() return false end
_G.mariocolors = {[1] = {{1, 0, 0}, {1, 1, 1}, {1, 0.6, 0.2}}}
_G.mariohats = {[1] = {1}}
_G.mariocharacter = {[1] = "mario"}
_G.playerconfig = 1
_G.mappack = "smb"
_G.marioworld = 1
_G.mariolevel = 1
_G.mariosublevel = 0
_G.tablecontains = function(t, v)
	for i = 1, #t do
		if t[i] == v then return true end
	end
	return false
end
_G.rawset = rawset
_G.rawget = rawget

local Schema = require("net.schema")
check("schema events", Schema.EV.INPUT == "input" and Schema.EV.SNAP == "snap")
check("schema keys", #Schema.KEYS == 10)

local h = Schema.empty_held()
h.jump = true
h.left = true
h.ang = 1.5
local packed = Schema.pack_input(3, h)
local unpacked = Schema.unpack_input(packed)
check("input roundtrip jump", unpacked.jump == true)
check("input roundtrip left", unpacked.left == true)
check("input roundtrip ang", math.abs((unpacked.ang or 0) - 1.5) < 1e-9)
check("input seq field", packed.s == 3)

local row = Schema.pack_player_row(1, {x = 10.5, y = 2.25, speedx = 1, speedy = -2, pointingangle = 0.1, dead = false})
local snap = Schema.pack_snap(7, {row})
local rows = Schema.unpack_snap_rows(snap)
check("snap one row", #rows == 1 and rows[1].i == 1)
check("snap x", math.abs(rows[1].x - 10.5) < 0.001)

-- bitser needs LuaJIT FFI (available in LÖVE; optional in headless)
local ok_b, bitser = pcall(require, "bitser")
if ok_b then
	local bin = bitser.dumps(packed)
	local back = bitser.loads(bin)
	check("bitser input", back.s == 3 and back.b[5] == 1)
else
	check("bitser skipped (no FFI)", true)
end

local Sync = require("net.sync")
Sync.set_local_slot(1)
Sync.set_held(2, {jump = true, left = false, ang = 0.2})
check("held_for remote jump", Sync.held_for(2, "jump") == true)
check("held_for missing nil", Sync.held_for(9, "jump") == nil)

local Match = require("net.match")
check("validate smb", Match.validate_mappack("smb") == "smb")
check("reject path", Match.validate_mappack("../x") == nil)

local Net = require("net.init")
check("Net offline role", Net.role() == "offline")
check("Net offline status", Net.status() == "offline")
check("Net not online", Net.is_online() == false)
check("Net not in match", Net.in_match() == false)
Net.update(0.016) -- must no-op
check("Net update offline ok", true)

-- boot require
local boot = io.open(root .. "/src/app/boot.tl", "r")
if boot then
	local src = boot:read("*a")
	boot:close()
	check("boot requires net.init", src:find('require "net.init"', 1, true) ~= nil)
	check("boot no net.session", src:find("net.session", 1, true) == nil)
	check("boot no net.facade", src:find("net.facade", 1, true) == nil)
end

local cb = io.open(root .. "/src/app/love_callbacks.tl", "r")
if cb then
	local src = cb:read("*a")
	cb:close()
	check("callbacks Net.update", src:find("Net.update", 1, true) ~= nil)
	check("callbacks no netplay_update", src:find("netplay_update", 1, true) == nil)
end

-- no leftover old modules
for _, name in ipairs({"facade", "transport", "protocol", "session", "state", "statehash"}) do
	local f = io.open(root .. "/src/net/" .. name .. ".tl", "r")
	check("removed net." .. name, f == nil)
	if f then f:close() end
end

return failed
