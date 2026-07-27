--[[ Net protocol / session / stringutil / magicdns guards (no LÖVE window). ]]

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

-- Minimal stubs so modules can load without Love.
_G.JSON = require("dkjson")
_G.love = _G.love or {
	math = { random = function(a, b)
		if b then return math.random(a, b) end
		return math.random(a)
	end },
	timer = { getTime = function() return 0 end },
	keyboard = {},
}
_G.notice = _G.notice or { new = function() end, red = {1, 0, 0} }
_G.tablecontains = _G.tablecontains or function(t, v)
	for i = 1, #t do
		if t[i] == v then return true end
	end
	return false
end

-- stringutil nil-safety
local SU = require("core.stringutil")
check("strsplit nil returns empty", #SU.strsplit(nil, "/") == 0)
check("strsplit empty string", #SU.split("", "/") == 1 and SU.split("", "/")[1] == "")
check("strsplit normal", SU.strsplit("a/b/c", "/")[2] == "b")
check("strsplit plain delim", SU.strsplit("a.b", ".")[1] == "a")

-- protocol encode/decode
local Protocol = require("net.protocol")
local enc = Protocol.encode({t = "hello", nick = "pip"})
check("protocol encode string", type(enc) == "string" and #enc > 0)
local dec = Protocol.decode(enc)
check("protocol decode roundtrip", dec and dec.t == "hello" and dec.nick == "pip")
check("protocol decode nil", Protocol.decode(nil) == nil)
check("protocol decode empty", Protocol.decode("") == nil)
check("protocol decode garbage", Protocol.decode("{not json") == nil)
check("protocol decode missing t", Protocol.decode('{"v":1}') == nil)
check("protocol version stamped", dec.v == Protocol.VERSION)

-- sync helpers (no playerobjs)
local Sync = require("net.sync")
local h = Sync.empty_held()
check("sync empty_held jump false", h.jump == false)
local packed = Sync.pack_input(2, {left = true, right = false, jump = true, ang = 1.5})
check("sync pack_input opcode", packed.t == "input" and packed.slot == 2 and packed.left == true)
local slot, uh = Sync.unpack_input(packed)
check("sync unpack_input", slot == 2 and uh.left == true and uh.jump == true)
Sync.set_held(2, uh)
check("sync is_held", Sync.is_held(2, "left") == true)
Sync.clear_held()
check("sync clear_held", Sync.is_held(2, "left") == nil)

-- match slot finder
local Match = require("net.match")
local found = Match.find_local_slot({
	{slot = 1, id = "aaa"},
	{slot = 2, id = "bbb"},
}, "bbb")
check("match find_local_slot", found == 2)
check("match find missing -> 1", Match.find_local_slot({{slot = 1, id = "x"}}, "nope") == 1)

-- magicdns availability with stub http
_G.http_is_stub = true
_G.http = { request = function() return nil, 0 end }
-- Load onlinemenu functions by evaluating the built file's globals carefully:
-- magicdns_available is defined in ui.onlinemenu; require may need more globals.
_G.guielement = _G.guielement or { new = function() return {} end }
_G.scale = 1
_G.mappack = "smb"
_G.SERVER = false
_G.CLIENT = false
_G.playerconfig = 1
_G.mariocolors = {{{1,0,0},{1,1,1},{1,1,1}}}
_G.mariohats = {{1}}
_G.properprint = function() end
_G.properprintbackground = function() end
_G.drawplayercard = function() end
_G.remove_indices_desc = function() end
_G.magic = { new = function() return { update = function() return true end, draw = function() end } end }
_G.love.filesystem = _G.love.filesystem or {
	getInfo = function() return nil end,
	read = function() return nil end,
	write = function() end,
}

local ok_om, err_om = pcall(require, "ui.onlinemenu")
check("onlinemenu loads", ok_om, tostring(err_om))
if ok_om and _G.magicdns_available then
	check("magicdns_available false on stub", magicdns_available() == false)
	-- keep must not throw on nil
	local ok_keep = pcall(magicdns_keep)
	check("magicdns_keep safe on stub", ok_keep)
	local a, b = magicdns_make()
	check("magicdns_make empty on stub", a == "" and b == "")
end

-- strsplit used like magicdns path
local parts = SU.strsplit(nil, "/")
check("magicdns-style nil split no crash", type(parts) == "table")

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
