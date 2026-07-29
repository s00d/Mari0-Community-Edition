--[[ Public Net API: sock.lua + bitser + host-authoritative sync.

Offline: no-op update. Online requires LÖVE lua-enet (via sock).
]]

local Schema = require("net.schema")
local Sync = require("net.sync")
local Match = require("net.match")

local EV = Schema.EV

local role = "offline" -- host | client | offline
local status = "offline"
local in_match = false
local my_id = ""
local my_nick = "player"
local local_slot = 1
local input_seq = 0
local snap_seq = 0

local sock_mod: any = nil
local bitser_mod: any = nil
local server: SockServer|nil = nil
local client: SockClient|nil = nil

-- peer_index (sock client index) -> roster entry
local peers: {integer:{string:any}} = {}
local roster: {{string:any}} = {} -- UI-facing list
local chats: {{string:any}} = {}

local function new_id(): string
	return string.format("%08x", math.random(0, 0xffffffff))
end

local function load_sock(): boolean, string
	if sock_mod and bitser_mod then
		return true, ""
	end
	local ok_b, b = pcall(function(): any
		return require("bitser")
	end)
	if not ok_b then
		return false, "bitser missing"
	end
	local ok_s, s = pcall(function(): any
		return require("sock")
	end)
	if not ok_s then
		return false, "sock/enet unavailable: " .. tostring(s)
	end
	bitser_mod = b
	sock_mod = s
	return true, ""
end

local function rebuild_roster()
	roster = {}
	table.insert(roster, {
		id = my_id,
		nick = my_nick,
		slot = 1,
		connected = true,
		colors = mariocolors and (mariocolors[playerconfig as integer] or mariocolors[1]),
		hats = mariohats and (mariohats[playerconfig as integer] or mariohats[1]),
		ping = 0,
		host = role == "host",
	})
	for _, p in pairs(peers) do
		table.insert(roster, p)
	end
	-- Expose for any leftover UI that still peeks globals during transition.
	rawset(_G, "playerlist", roster)
end

local function push_chat(id: string, message: string)
	table.insert(chats, {id = id, message = message})
	if #chats > 40 then
		table.remove(chats, 1)
	end
	rawset(_G, "chatmessages", chats)
end

local function set_status(s: string)
	status = s
	rawset(_G, "netstatus", s)
end

local function reset_session()
	role = "offline"
	in_match = false
	local_slot = 1
	input_seq = 0
	snap_seq = 0
	server = nil
	client = nil
	peers = {}
	roster = {}
	chats = {}
	Sync.clear()
	Sync.set_local_slot(1)
	set_status("offline")
	rawset(_G, "playerlist", roster)
	rawset(_G, "chatmessages", chats)
end

local function peer_list_for_start(): {{string:any}}
	local list: {{string:any}} = {}
	for _, p in pairs(peers) do
		table.insert(list, p)
	end
	return list
end

local function on_start_payload(msg: {string:any})
	local slot = Match.begin(msg, my_id)
	if not slot then
		return
	end
	local_slot = slot
	Sync.set_local_slot(slot)
	in_match = true
	set_status("in_match")
end

local function wire_server(srv: SockServer)
	local bitser = bitser_mod as BitserModule
	srv:setSerialization(bitser.dumps, bitser.loads)

	srv:on("connect", function(_data: any, _peer: SockClient)
		-- wait for hello with nick/cosmetics
	end)

	srv:on("disconnect", function(_data: any, peer: SockClient)
		local idx = peer:getIndex()
		local left = peers[idx]
		peers[idx] = nil
		rebuild_roster()
		if left then
			srv:sendToAll(EV.LEAVE, {id = left.id})
		end
	end)

	srv:on("hello", function(data: any, peer: SockClient)
		local idx = peer:getIndex()
		local count = 1
		for _ in pairs(peers) do
			count = count + 1
		end
		if count >= Schema.MAX_PLAYERS then
			peer:send(EV.REJECT, {reason = "full"})
			peer:disconnectLater()
			return
		end
		local d = (data or {}) as {string:any}
		local pid = tostring(d.id or new_id())
		local entry = {
			id = pid,
			nick = tostring(d.nick or "player"),
			colors = d.colors,
			hats = d.hats,
			connected = true,
			ping = 0,
			host = false,
			index = idx,
		}
		peers[idx] = entry
		rebuild_roster()
		peer:send(EV.WELCOME, {
			id = pid,
			slot = idx + 1,
			peers = roster,
		})
		srv:sendToAllBut(peer, EV.PEER, entry)
	end)

	srv:on(EV.CHAT, function(data: any, peer: SockClient)
		local idx = peer:getIndex()
		local p = peers[idx]
		if not p then
			return
		end
		local text = tostring(((data or {}) as {string:any}).text or "")
		if text == "" then
			return
		end
		local msg = {id = p.id, text = text}
		push_chat(p.id as string, text)
		srv:sendToAll(EV.CHAT, msg)
	end)

	srv:on(EV.INPUT, function(data: any, peer: SockClient)
		if not in_match then
			return
		end
		local idx = peer:getIndex()
		local p = peers[idx]
		if not p then
			return
		end
		local slot = (tonumber(p.slot) or (idx + 1)) as integer
		local h = Schema.unpack_input((data or {}) as {string:any})
		Sync.set_held(slot, h)
	end)
end

local function wire_client(cli: SockClient)
	local bitser = bitser_mod as BitserModule
	cli:setSerialization(bitser.dumps, bitser.loads)

	cli:on("connect", function(_data: any)
		cli:send("hello", {
			id = my_id,
			nick = my_nick,
			colors = mariocolors and (mariocolors[playerconfig as integer] or mariocolors[1]),
			hats = mariohats and (mariohats[playerconfig as integer] or mariohats[1]),
		})
		set_status("connected")
	end)

	cli:on("disconnect", function(_data: any)
		if notice and notice.new then
			notice.new("disconnected", notice.red)
		end
		reset_session()
		if menu_load then
			menu_load()
		end
	end)

	cli:on(EV.WELCOME, function(data: any)
		local d = (data or {}) as {string:any}
		my_id = tostring(d.id or my_id)
		if type(d.peers) == "table" then
			roster = d.peers as {{string:any}}
			rawset(_G, "playerlist", roster)
		end
		set_status("lobby")
		if lobby_load then
			lobby_load()
		end
	end)

	cli:on(EV.REJECT, function(data: any)
		local reason = tostring(((data or {}) as {string:any}).reason or "rejected")
		if notice and notice.new then
			notice.new(reason, notice.red)
		end
		reset_session()
	end)

	cli:on(EV.PEER, function(data: any)
		local d = (data or {}) as {string:any}
		table.insert(roster, d)
		rawset(_G, "playerlist", roster)
	end)

	cli:on(EV.LEAVE, function(data: any)
		local id = tostring(((data or {}) as {string:any}).id or "")
		local next_r: {{string:any}} = {}
		for i = 1, #roster do
			if tostring(roster[i].id or "") ~= id then
				table.insert(next_r, roster[i])
			end
		end
		roster = next_r
		rawset(_G, "playerlist", roster)
	end)

	cli:on(EV.CHAT, function(data: any)
		local d = (data or {}) as {string:any}
		push_chat(tostring(d.id or ""), tostring(d.text or ""))
	end)

	cli:on(EV.START, function(data: any)
		on_start_payload((data or {}) as {string:any})
	end)

	cli:on(EV.SNAP, function(data: any)
		if not in_match then
			return
		end
		Sync.apply_snapshot((data or {}) as {string:any}, true)
	end)
end

local Net = {} as NetModule

function Net.role(): string
	return role
end

function Net.status(): string
	return status
end

function Net.in_match(): boolean
	return in_match
end

function Net.is_online(): boolean
	return role ~= "offline"
end

function Net.local_slot(): integer
	return local_slot
end

function Net.held_for(slot: integer, action: string): boolean|nil
	if role == "offline" then
		return nil
	end
	return Sync.held_for(slot, action)
end

function Net.peers(): {{string:any}}
	return roster
end

function Net.chats(): {{string:any}}
	return chats
end

function Net.host(port: number, nick: string): boolean
	Net.quit()
	local ok, err = load_sock()
	if not ok then
		if notice and notice.new then
			notice.new(err, notice.red)
		end
		return false
	end
	my_id = new_id()
	my_nick = nick ~= "" and nick or "host"
	local_slot = 1
	Sync.set_local_slot(1)
	local p = tonumber(port) or Schema.DEFAULT_PORT
	local sock = sock_mod as SockModule
	local ok_s, srv_or_err = pcall(function(): SockServer
		return sock.newServer("*", p, Schema.MAX_PLAYERS)
	end)
	if not ok_s or not srv_or_err then
		if notice and notice.new then
			notice.new("host failed: " .. tostring(srv_or_err), notice.red)
		end
		return false
	end
	server = srv_or_err as SockServer
	role = "host"
	wire_server(server as SockServer)
	rebuild_roster()
	set_status("lobby")
	rawset(_G, "port", p)
	if lobby_load then
		lobby_load()
	end
	return true
end

function Net.join(addr: string, port: number, nick: string): boolean
	Net.quit()
	local ok, err = load_sock()
	if not ok then
		if notice and notice.new then
			notice.new(err, notice.red)
		end
		return false
	end
	my_id = new_id()
	my_nick = nick ~= "" and nick or "player"
	local p = tonumber(port) or Schema.DEFAULT_PORT
	local sock = sock_mod as SockModule
	local ok_c, cli_or_err = pcall(function(): SockClient
		return sock.newClient(addr, p)
	end)
	if not ok_c or not cli_or_err then
		if notice and notice.new then
			notice.new("join failed: " .. tostring(cli_or_err), notice.red)
		end
		return false
	end
	client = cli_or_err as SockClient
	role = "client"
	wire_client(client as SockClient)
	set_status("connecting")
	pcall(function()
		(client as SockClient):connect()
	end)
	rawset(_G, "ip", addr)
	rawset(_G, "port", p)
	return true
end

function Net.quit()
	if usemagic and role == "host" and magicdns_remove then
		pcall(magicdns_remove)
	end
	if server then
		pcall(function()
			(server as SockServer):destroy()
		end)
	end
	if client then
		pcall(function()
			(client as SockClient):disconnectNow(nil)
		end)
	end
	reset_session()
end

function Net.chat(text: string)
	if text == "" then
		return
	end
	if role == "host" and server then
		push_chat(my_id, text)
		(server as SockServer):sendToAll(EV.CHAT, {id = my_id, text = text})
	elseif role == "client" and client then
		(client as SockClient):send(EV.CHAT, {text = text})
	end
end

function Net.start_match()
	if role ~= "host" or not server then
		return
	end
	local list = peer_list_for_start()
	local slot = 2
	for i = 1, #list do
		list[i].slot = slot
		for idx, p in pairs(peers) do
			if p.id == list[i].id then
				p.slot = slot
				peers[idx] = p
			end
		end
		slot = slot + 1
	end
	local msg = Match.build_start(
		my_id,
		my_nick,
		list,
		tostring(mappack or "smb"),
		marioworld,
		mariolevel,
		mariosublevel
	)
	(server as SockServer):sendToAll(EV.START, msg)
	on_start_payload(msg)
end

function Net.update(dt: number)
	if role == "offline" then
		return
	end
	if server then
		local srv = server as SockServer
		srv:update()
		if in_match then
			Sync.host_process_edges()
			if Sync.should_send_snap(dt) then
				snap_seq = snap_seq + 1
				srv:setSendMode("unreliable")
				srv:sendToAll(EV.SNAP, Sync.pack_snapshot(snap_seq))
				srv:resetSendSettings()
			end
		end
	elseif client then
		local cli = client as SockClient
		cli:update()
		if in_match then
			Sync.reapply_last_snap(true)
			if Sync.should_send_input(dt) then
				input_seq = input_seq + 1
				local h = Sync.read_local_held(local_slot)
				cli:setSendMode("unreliable")
				cli:send(EV.INPUT, Schema.pack_input(input_seq, h))
				cli:resetSendSettings()
			end
		end
	end
end

-- Module + global
rawset(_G, "Net", Net)
reset_session()

return Net
