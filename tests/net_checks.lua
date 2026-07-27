--[[ Net protocol / facade / state / session / magicdns guards (no LÖVE window). ]]

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

--------------------------------------------------------------------------
-- Facade: NullNet isolation
--------------------------------------------------------------------------
local Net = require("net.facade")
check("facade exports NullNet", Net.NullNet ~= nil)
check("facade starts null", Net.is_null() == true)
check("facade status offline", Net.get_status() == "offline")
check("facade not active", Net.is_active() == false)
check("facade not in match", Net.in_match() == false)

collectgarbage("collect")
local before_facade = collectgarbage("count")
for _ = 1, 5000 do
	Net.update(1 / 60)
	netplay_update(1 / 60)
end
local grew_facade = collectgarbage("count") - before_facade
check("NullNet.update near-zero alloc", grew_facade < 2, string.format("%.2f KB", grew_facade))

-- activate / deactivate swap
local ticks = 0
Net.activate({
	update = function() ticks = ticks + 1 end,
	get_status = function() return "hosting" end,
	in_match = function() return false end,
	is_active = function() return true end,
})
check("facade not null after activate", Net.is_null() == false)
check("facade status hosting", net_get_status() == "hosting")
check("facade is_active after activate", net_is_active() == true)
netplay_update(0)
check("facade delegates update", ticks == 1)
Net.deactivate()
check("facade null after deactivate", Net.is_null() == true)
check("facade offline after deactivate", net_get_status() == "offline")
netplay_update(0)
check("NullNet ignores after deactivate", ticks == 1)

--------------------------------------------------------------------------
-- Protocol encode/decode + strict / validate
--------------------------------------------------------------------------
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
check("protocol is_op hello", Protocol.is_op("hello") == true)
check("protocol is_op bogus", Protocol.is_op("nope") == false)
check("protocol validate ok", Protocol.validate({t = "snap", v = Protocol.VERSION}) == true)
check("protocol validate bad op", Protocol.validate({t = "wat"}) == false)
check("protocol validate bad ver", Protocol.validate({t = "ping", v = 999}) == false)
check("protocol decode_strict known", Protocol.decode_strict(enc) ~= nil)
check("protocol decode_strict unknown op", Protocol.decode_strict('{"t":"wat","v":1}') == nil)
check("protocol decode_strict bad ver", Protocol.decode_strict('{"t":"ping","v":99}') == nil)
check("protocol decode_strict legacy no v", Protocol.decode_strict('{"t":"pong"}') ~= nil)

-- All OP values are unique strings
local seen_ops = {}
local op_count = 0
for _, name in pairs(Protocol.OP) do
	check("op unique " .. tostring(name), seen_ops[name] == nil)
	seen_ops[name] = true
	op_count = op_count + 1
end
check("protocol op count >= 13", op_count >= 13)

-- Transport size / rate constants
local Transport = require("net.transport")
check("transport MAX_DATAGRAM 1200", Transport.MAX_DATAGRAM == 1200)
check("transport MAX_RECV_PER_PEER", Transport.MAX_RECV_PER_PEER ~= nil and Transport.MAX_RECV_PER_PEER > 0)
check("transport last_abuse_peers empty", type(Transport.last_abuse_peers()) == "table" and #Transport.last_abuse_peers() == 0)

-- Oversized send refused (no truncate)
do
	local fake = {
		sock = {
			send = function() return 1 end,
			sendto = function() return 1 end,
		},
		mode = "client",
	}
	local big = string.rep("x", Transport.MAX_DATAGRAM + 1)
	check("transport refuse oversized send", Transport.send(fake, big) == false)
	local ok_small = Transport.send(fake, string.rep("y", 10))
	check("transport accept small send", ok_small == true)
end

--------------------------------------------------------------------------
-- State machine
--------------------------------------------------------------------------
local State = require("net.state")
check("state offline->hosting", State.can_transition("offline", "hosting"))
check("state offline->connecting", State.can_transition("offline", "connecting"))
check("state hosting->in_match", State.can_transition("hosting", "in_match"))
check("state hosting->offline", State.can_transition("hosting", "offline"))
check("state reject hosting->connecting", not State.can_transition("hosting", "connecting"))
check("state reject in_match->hosting", not State.can_transition("in_match", "hosting"))
check("state transition ok", State.transition("connecting", "connected") == "connected")
check("state transition nil", State.transition("offline", "in_match") == nil)
check("state classify idle", State.classify("idle", "offline", false) == "offline")
check("state classify host", State.classify("host", "hosting (1/4)", false) == "hosting")
check("state classify connecting", State.classify("client", "connecting…", false) == "connecting")
check("state classify match", State.classify("host", "in game", true) == "in_match")
check("state classify error", State.classify("idle", "error: no socket", false) == "error")

--------------------------------------------------------------------------
-- Sync helpers
--------------------------------------------------------------------------
local Sync = require("net.sync")
local h = Sync.empty_held()
check("sync empty_held jump false", h.jump == false)
local packed = Sync.pack_input(2, {left = true, right = false, jump = true, ang = 1.5}, 7)
check("sync pack_input opcode", packed.t == "input" and packed.slot == 2 and packed.left == true)
check("sync pack_input seq", packed.seq == 7)
local slot, uh = Sync.unpack_input(packed)
check("sync unpack_input", slot == 2 and uh.left == true and uh.jump == true)
Sync.set_held(2, uh)
check("sync is_held", Sync.is_held(2, "left") == true)
Sync.clear_held()
check("sync clear_held", Sync.is_held(2, "left") == nil)

-- Rate limiters fire on schedule
Sync.clear_held()
local sent_in = 0
for _ = 1, 60 do
	if Sync.should_send_input(1 / 60) then sent_in = sent_in + 1 end
end
check("sync input ~30Hz over 1s", sent_in >= 28 and sent_in <= 32, tostring(sent_in))
Sync.clear_held()
local sent_snap = 0
for _ = 1, 60 do
	if Sync.should_send_snap(1 / 60) then sent_snap = sent_snap + 1 end
end
check("sync snap ~20Hz over 1s", sent_snap >= 18 and sent_snap <= 22, tostring(sent_snap))

-- Snapshot pack with stub playerobjs
_G.players = 2
_G.playerobjs = {
	{ x = 1.23456, y = 2.5, speedx = 0.1, speedy = -0.2, pointingangle = 0.3333, size = 1, dead = false },
	{ x = 3, y = 4, speedx = 0, speedy = 0, pointingangle = 0, size = 2, dead = true },
}
local snap = Sync.pack_snapshot(42)
check("sync pack_snapshot opcode", snap.t == "snap" and type(snap.p) == "table" and #snap.p == 2)
check("sync pack_snapshot seq", snap.seq == 42)
check("sync pack_snapshot round3", snap.p[1].x == 1.235)
Sync.apply_snapshot(snap, false)
check("sync apply_snapshot pos", playerobjs[2].x == 3 and playerobjs[2].dead == true)
_G.netplayernumber = 1
Sync.apply_snapshot(snap, true) -- soft local
check("sync soft apply keeps local if close", type(playerobjs[1].x) == "number")

--------------------------------------------------------------------------
-- Match
--------------------------------------------------------------------------
local Match = require("net.match")
local found = Match.find_local_slot({
	{slot = 1, id = "aaa"},
	{slot = 2, id = "bbb"},
}, "bbb")
check("match find_local_slot", found == 2)
check("match find missing -> 1", Match.find_local_slot({{slot = 1, id = "x"}}, "nope") == 1)

_G.localnick = "host"
_G.playerconfig = 1
_G.mariocolors = {{{1, 0, 0}, {1, 1, 1}, {1, 0.6, 0.2}}}
_G.mariohats = {{1}}
_G.mappack = "smb"
local start_msg = Match.build_start_msg("hid", {
	["127.0.0.1:1"] = { id = "cid", nick = "guest", colors = mariocolors[1], hats = {1} },
}, "smb", 1, 2, 0)
check("match start players", start_msg.players == 2 and start_msg.t == "start")
check("match start slots", #start_msg.slots == 2 and start_msg.slots[2].id == "cid")

--------------------------------------------------------------------------
-- Transport empty recv shared / zero-alloc
--------------------------------------------------------------------------
-- Transport already required above for MAX_DATAGRAM checks
local empty1 = Transport.recv_burst(nil)
local empty2 = Transport.recv_burst({ sock = nil })
check("recv_burst nil is empty", type(empty1) == "table" and #empty1 == 0)
check("recv_burst no-sock is empty", type(empty2) == "table" and #empty2 == 0)
check("recv_burst empty shared", empty1 == empty2)
check("transport peer_key", Transport.peer_key("1.2.3.4", 9) == "1.2.3.4:9")
check("transport send nil fails", Transport.send(nil, "x") == false)
check("transport send no data fails", Transport.send({}, nil) == false)

--------------------------------------------------------------------------
-- magicdns availability with stub http
--------------------------------------------------------------------------
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
	local ok_keep = pcall(magicdns_keep)
	check("magicdns_keep safe on stub", ok_keep)
	local a, b = magicdns_make()
	check("magicdns_make empty on stub", a == "" and b == "")
end

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

--------------------------------------------------------------------------
-- Session + facade offline path
--------------------------------------------------------------------------
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
	check("facade still null with session loaded", Net.is_null() == true)

	collectgarbage("collect")
	local before = collectgarbage("count")
	for _ = 1, 2000 do
		netplay_update(1 / 60)
	end
	local after = collectgarbage("count")
	local grew = after - before
	check("offline netplay_update near-zero alloc", grew < 2, string.format("%.2f KB", grew))

	-- love_callbacks must call netplay_update via facade (no SERVER|CLIENT gate required)
	local cb = io.open(root .. "/src/app/love_callbacks.tl", "r")
	if cb then
		local src = cb:read("*a")
		cb:close()
		check(
			"love_callbacks calls netplay_update",
			src:find("netplay_update", 1, true) ~= nil
		)
		check(
			"love_callbacks no SERVER|CLIENT net gate",
			src:find("netplay_update and (SERVER or CLIENT)", 1, true) == nil
		)
		check(
			"love_callbacks mentions Net facade",
			src:find("NullNet", 1, true) ~= nil or src:find("facade", 1, true) ~= nil
		)
	else
		check("love_callbacks readable", false)
	end

	-- boot requires facade before session
	local boot = io.open(root .. "/src/app/boot.tl", "r")
	if boot then
		local src = boot:read("*a")
		boot:close()
		local i_facade = src:find('require "net.facade"', 1, true)
		local i_sess = src:find('require "net.session"', 1, true)
		check("boot requires net.facade", i_facade ~= nil)
		check("boot requires facade before session", i_facade ~= nil and i_sess ~= nil and i_facade < i_sess)
	end

	local lob = io.open(root .. "/src/ui/lobby.tl", "r")
	if lob then
		local src = lob:read("*a")
		lob:close()
		check(
			"lobby magicdns_keep gated by usemagic",
			src:find("usemagic and magicdns_available", 1, true) ~= nil
		)
	end

	-- Module layout present
	for _, name in ipairs({"facade", "transport", "protocol", "session", "sync", "match", "state"}) do
		local p = root .. "/src/net/" .. name .. ".tl"
		local f = io.open(p, "r")
		check("src/net/" .. name .. ".tl exists", f ~= nil)
		if f then f:close() end
		check("build/net/" .. name .. ".lua exists", io.open(root .. "/build/net/" .. name .. ".lua", "r") ~= nil)
	end

	-- F0: slot spoofing removed (host uses peer.slot only)
	local sess_src = io.open(root .. "/src/net/session.tl", "r")
	if sess_src then
		local src = sess_src:read("*a")
		sess_src:close()
		check("session no packet-slot fallback", src:find("fall back to packet slot", 1, true) == nil)
		check("session mentions slot spoof", src:find("slot spoof", 1, true) ~= nil)
		check("session has accept_seq", src:find("accept_seq", 1, true) ~= nil)
	end
end

local parts = SU.strsplit(nil, "/")
check("magicdns-style nil split no crash", type(parts) == "table")

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
