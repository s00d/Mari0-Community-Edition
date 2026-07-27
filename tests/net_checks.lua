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

-- transport empty recv is shared / zero-alloc under no datagrams
local Transport = require("net.transport")
local empty1 = Transport.recv_burst(nil)
local empty2 = Transport.recv_burst({ sock = nil })
check("recv_burst nil is empty", type(empty1) == "table" and #empty1 == 0)
check("recv_burst no-sock is empty", type(empty2) == "table" and #empty2 == 0)
check("recv_burst empty shared", empty1 == empty2)

-- magicdns availability with stub http
_G.http_is_stub = true
_G.http = { request = function() return nil, 0 end }
_G.guielement = _G.guielement or { new = function() return {} end }
_G.scale = 1
_G.mappack = "smb"
_G.SERVER = false
_G.CLIENT = false
_G.usemagic = false
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

-- magicdns_keep must not hit http when usemagic is false (even if http works)
local http_calls = 0
_G.http_is_stub = false
_G.http = {
	request = function()
		http_calls = http_calls + 1
		return "KEPT/1", 200
	end,
}
_G.usemagic = false
_G.magicdns_identity = "id"
_G.magicdns_session = "sess"
if _G.magicdns_keep then
	magicdns_keep()
	check("magicdns_keep skipped when usemagic false", http_calls == 0)
	_G.usemagic = true
	magicdns_keep()
	check("magicdns_keep calls http when usemagic true", http_calls >= 1)
	_G.usemagic = false
end

-- session offline path: netplay_update is zero-alloc no-op
_G.menu_load = _G.menu_load or function() end
_G.lobby_load = _G.lobby_load or function() end
_G.onlinemenu_load = _G.onlinemenu_load or function() end
local ok_sess, err_sess = pcall(require, "net.session")
check("session loads", ok_sess, tostring(err_sess))
if ok_sess then
	check("net_is_active false offline", net_is_active() == false)
	check("net_in_match false offline", net_in_match() == false)
	check("net status offline", net_get_status() == "offline")
	check("SERVER false offline", SERVER == false)
	check("CLIENT false offline", CLIENT == false)

	collectgarbage("collect")
	local before = collectgarbage("count")
	for _ = 1, 2000 do
		netplay_update(1 / 60)
	end
	local after = collectgarbage("count")
	local grew = after - before
	check("offline netplay_update near-zero alloc", grew < 2, string.format("%.2f KB", grew))

	-- love_callbacks must gate netplay_update on SERVER/CLIENT (source check)
	local cb = io.open(root .. "/src/app/love_callbacks.tl", "r")
	if cb then
		local src = cb:read("*a")
		cb:close()
		check(
			"love_callbacks gates net on SERVER|CLIENT",
			src:find("SERVER or CLIENT", 1, true) ~= nil
				and src:find("netplay_update", 1, true) ~= nil
		)
	else
		check("love_callbacks readable", false)
	end

	-- lobby must not call magicdns_keep without usemagic (source check)
	local lob = io.open(root .. "/src/ui/lobby.tl", "r")
	if lob then
		local src = lob:read("*a")
		lob:close()
		check(
			"lobby magicdns_keep gated by usemagic",
			src:find("usemagic and magicdns_available", 1, true) ~= nil
		)
	end
end

-- strsplit used like magicdns path
local parts = SU.strsplit(nil, "/")
check("magicdns-style nil split no crash", type(parts) == "table")

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
