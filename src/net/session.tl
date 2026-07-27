--[[ Online session: host/join lobby + chat over non-blocking UDP.
     Phase 1 MVP — no entity sync yet. Path to Phase 2: host-auth input + snapshots. ]]

local Transport = require("net.transport") as {string:any}
local Protocol = require("net.protocol") as {string:any}

local HEARTBEAT_INTERVAL = 2.0
local PEER_TIMEOUT = 8.0
local MAX_CHAT = 64
local MAX_PLAYERS = 4
local DEFAULT_PORT = 7331

local sock: any = nil
local role: string = "idle" -- idle | host | client
local status: string = "offline"
local local_id: string = ""
local heartbeat_t: number = 0
local connect_t: number = 0
local peers_by_key: {string:any} = {} -- host-only: key -> {ip,port,id,nick,...}

local function gen_id(): string
	local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	local out = ""
	for _ = 1, 8 do
		local i = math.floor(love.math.random(1, #chars)) as integer
		out = out .. chars:sub(i, i)
	end
	return out
end

local function copy_colors(): {{number}}
	local src = mariocolors[playerconfig as integer] or mariocolors[1]
	local out: {{number}} = {}
	if not src then
		return {{1, 0, 0}, {1, 1, 1}, {0, 0, 0}}
	end
	for i = 1, 3 do
		local set = (src as {{number}})[i] or {1, 1, 1}
		out[i] = {set[1] or 1, set[2] or 1, set[3] or 1}
	end
	return out
end

local function copy_hats(): any
	local h = mariohats[playerconfig as integer] or mariohats[1] or {}
	local out: {number} = {}
	if type(h) == "table" then
		for i = 1, #(h as {any}) do
			out[i] = (h as {number})[i]
		end
	end
	return out
end

local function set_status(s: string)
	status = s
	rawset(_G, "netstatus", s)
end

local function ensure_defaults()
	if port == nil then
		rawset(_G, "port", DEFAULT_PORT)
	end
	if ip == nil then
		rawset(_G, "ip", "127.0.0.1")
	end
	if SERVER == nil then
		rawset(_G, "SERVER", false)
	end
	if CLIENT == nil then
		rawset(_G, "CLIENT", false)
	end
	if playerlist == nil then
		rawset(_G, "playerlist", {})
	end
	if chatmessages == nil then
		rawset(_G, "chatmessages", {})
	end
	if netplayerid == nil then
		rawset(_G, "netplayerid", "")
	end
	if netplayernumber == nil then
		rawset(_G, "netplayernumber", 1)
	end
	if localnick == nil then
		rawset(_G, "localnick", "player")
	end
	if netstatus == nil then
		rawset(_G, "netstatus", "offline")
	end
end

local function make_self_player(): OnlinePlayer
	return {
		connected = true,
		id = local_id,
		ping = 0,
		colors = copy_colors(),
		hats = copy_hats(),
		nick = localnick or "player",
	}
end

local function rebuild_playerlist_from_peers()
	local list: {OnlinePlayer} = {make_self_player()}
	for _, p in pairs(peers_by_key) do
		local peer = p as {string:any}
		table.insert(list, {
			connected = true,
			id = tostring(peer.id or ""),
			ping = (peer.ping as number) or 0,
			colors = (peer.colors as {{number}}) or copy_colors(),
			hats = peer.hats,
			nick = tostring(peer.nick or "player"),
		})
	end
	rawset(_G, "playerlist", list)
end

local function encode_send(msg: {string:any}, to_ip: string|nil, to_port: integer|nil)
	local data = (Protocol.encode as function({string:any}): string|nil)(msg)
	if not data or not sock then
		return
	end
	(Transport.send as function(any, string, string|nil, integer|nil): boolean)(sock, data, to_ip, to_port)
end

local function broadcast(msg: {string:any}, except_key: string|nil)
	if role ~= "host" then
		return
	end
	for key, p in pairs(peers_by_key) do
		if key ~= except_key then
			local peer = p as {string:any}
			encode_send(msg, peer.ip as string, peer.port as integer)
		end
	end
end

local function push_chat(id: string, message: string)
	if not chatmessages then
		rawset(_G, "chatmessages", {})
	end
	table.insert(chatmessages, {id = id, message = message})
	while #chatmessages > 40 do
		table.remove(chatmessages, 1)
	end
end

local function peer_snapshot(): {{string:any}}
	local snap: {{string:any}} = {}
	table.insert(snap, {
		id = local_id,
		nick = localnick,
		colors = copy_colors(),
		hats = copy_hats(),
		host = true,
	})
	for _, p in pairs(peers_by_key) do
		local peer = p as {string:any}
		table.insert(snap, {
			id = peer.id,
			nick = peer.nick,
			colors = peer.colors,
			hats = peer.hats,
			host = false,
		})
	end
	return snap
end

local function apply_roster(peers: any)
	if type(peers) ~= "table" then
		return
	end
	local list: {OnlinePlayer} = {}
	for i = 1, #(peers as {any}) do
		local p = (peers as {{string:any}})[i]
		if p and p.id then
			table.insert(list, {
				connected = true,
				id = tostring(p.id),
				ping = (p.ping as number) or 0,
				colors = (p.colors as {{number}}) or copy_colors(),
				hats = p.hats,
				nick = tostring(p.nick or "player"),
			})
		end
	end
	rawset(_G, "playerlist", list)
end

local function close_socket()
	(Transport.close as function(any))(sock)
	sock = nil
end

local function reset_session()
	close_socket()
	role = "idle"
	peers_by_key = {}
	heartbeat_t = 0
	connect_t = 0
	rawset(_G, "SERVER", false)
	rawset(_G, "CLIENT", false)
	rawset(_G, "playerlist", {})
	rawset(_G, "chatmessages", {})
	set_status("offline")
end

local function handle_host_msg(msg: {string:any}, from_ip: string, from_port: integer)
	local t = msg.t as string
	local key = (Transport.peer_key as function(string, integer): string)(from_ip, from_port)

	if t == "hello" then
		local count = 0
		for _ in pairs(peers_by_key) do
			count = count + 1
		end
		if count >= MAX_PLAYERS - 1 then
			encode_send({t = "reject", reason = "full"}, from_ip, from_port)
			return
		end
		local pid = tostring(msg.id or gen_id())
		peers_by_key[key] = {
			ip = from_ip,
			port = from_port,
			id = pid,
			nick = tostring(msg.nick or "player"),
			colors = msg.colors or copy_colors(),
			hats = msg.hats,
			ping = 0,
			last = love.timer.getTime(),
		}
		encode_send({
			t = "welcome",
			id = pid,
			host_id = local_id,
			peers = peer_snapshot(),
		}, from_ip, from_port)
		local joined = peers_by_key[key] as {string:any}
		broadcast({
			t = "peer_join",
			peer = {
				id = pid,
				nick = joined.nick,
				colors = joined.colors,
				hats = joined.hats,
			},
		}, key)
		rebuild_playerlist_from_peers()
		notice.new("player joined: " .. tostring(joined.nick))
		local n = 1
		for _ in pairs(peers_by_key) do n = n + 1 end
		set_status("hosting (" .. n .. "/" .. MAX_PLAYERS .. ")")
		return
	end

	local peer = peers_by_key[key]
	if not peer then
		return
	end
	local p = peer as {string:any}
	p.last = love.timer.getTime()

	if t == "chat" then
		local text = tostring(msg.message or ""):sub(1, MAX_CHAT)
		if text ~= "" then
			push_chat(tostring(p.id), text)
			broadcast({t = "chat", id = p.id, message = text}, nil)
		end
	elseif t == "ping" then
		encode_send({t = "pong", t0 = msg.t0}, from_ip, from_port)
	elseif t == "pong" then
		local t0 = tonumber(msg.t0)
		if t0 then
			p.ping = love.timer.getTime() - t0
			rebuild_playerlist_from_peers()
		end
	elseif t == "bye" then
		local nick = tostring(p.nick or "player")
		local leave_pid = tostring(p.id or "")
		peers_by_key[key] = nil
		broadcast({t = "peer_leave", id = leave_pid}, nil)
		rebuild_playerlist_from_peers()
		notice.new("player left: " .. nick)
		local n = 1
		for _ in pairs(peers_by_key) do n = n + 1 end
		set_status("hosting (" .. n .. "/" .. MAX_PLAYERS .. ")")
	end
end

local function handle_client_msg(msg: {string:any})
	local t = msg.t as string
	if t == "welcome" then
		rawset(_G, "netplayerid", tostring(msg.id or local_id))
		local_id = tostring(msg.id or local_id)
		apply_roster(msg.peers)
		set_status("connected")
		lobby_load()
		notice.new("joined lobby")
	elseif t == "reject" then
		notice.new("join rejected: " .. tostring(msg.reason or "?"), notice.red)
		reset_session()
		onlinemenu_load()
	elseif t == "peer_join" then
		local peer = msg.peer
		if type(peer) == "table" then
			local pj = peer as {string:any}
			if pj.id then
				if not playerlist then
					rawset(_G, "playerlist", {})
				end
				table.insert(playerlist, {
					connected = true,
					id = tostring(pj.id),
					ping = 0,
					colors = (pj.colors as {{number}}) or copy_colors(),
					hats = pj.hats,
					nick = tostring(pj.nick or "player"),
				})
				notice.new("player joined: " .. tostring(pj.nick or "player"))
			end
		end
	elseif t == "peer_leave" then
		local leave_id = tostring(msg.id or "")
		if playerlist then
			for i = #playerlist, 1, -1 do
				if playerlist[i].id == leave_id then
					notice.new("player left: " .. playerlist[i].nick)
					table.remove(playerlist, i)
					break
				end
			end
		end
	elseif t == "chat" then
		push_chat(tostring(msg.id or ""), tostring(msg.message or ""))
	elseif t == "ping" then
		encode_send({t = "pong", t0 = msg.t0}, nil, nil)
	elseif t == "pong" then
		-- host RTT unused on client for MVP
	elseif t == "start" then
		notice.new("host started — full sync coming soon")
	elseif t == "host_gone" then
		notice.new("host disconnected", notice.red)
		reset_session()
		menu_load()
	end
end

--------------------------------------------------------------------------
-- Public globals (match onlinemenu / lobby / menu hooks)
--------------------------------------------------------------------------

global function net_get_status(): string
	return status
end

global function server_load()
	ensure_defaults()
	reset_session()
	if not (Transport.available as function(): boolean)() then
		notice.new("networking unavailable", notice.red)
		set_status("error: no socket")
		return
	end
	local use_port = (tonumber(port) or DEFAULT_PORT) as integer
	rawset(_G, "port", use_port)
	local_id = gen_id()
	rawset(_G, "netplayerid", local_id)
	rawset(_G, "netplayernumber", 1)
	local created, err = (Transport.create_host as function(integer): any, string|nil)(use_port)
	if not created then
		notice.new("host failed: " .. tostring(err), notice.red)
		set_status("error: " .. tostring(err))
		return
	end
	sock = created
	role = "host"
	rawset(_G, "SERVER", true)
	rawset(_G, "CLIENT", false)
	rawset(_G, "chatmessages", {})
	rawset(_G, "playerlist", {make_self_player()})
	set_status("hosting (1/" .. MAX_PLAYERS .. ")")
	lobby_load()
	notice.new("hosting on port " .. tostring(use_port))
end

global function client_load()
	ensure_defaults()
	reset_session()
	if not (Transport.available as function(): boolean)() then
		notice.new("networking unavailable", notice.red)
		set_status("error: no socket")
		return
	end
	local use_ip = tostring(ip or "127.0.0.1")
	local use_port = (tonumber(port) or DEFAULT_PORT) as integer
	rawset(_G, "ip", use_ip)
	rawset(_G, "port", use_port)
	local_id = gen_id()
	rawset(_G, "netplayerid", local_id)
	local created, err = (Transport.create_client as function(string, integer): any, string|nil)(use_ip, use_port)
	if not created then
		notice.new("join failed: " .. tostring(err), notice.red)
		set_status("error: " .. tostring(err))
		return
	end
	sock = created
	role = "client"
	rawset(_G, "CLIENT", true)
	rawset(_G, "SERVER", false)
	rawset(_G, "chatmessages", {})
	rawset(_G, "playerlist", {})
	set_status("connecting…")
	connect_t = 0
	encode_send({
		t = "hello",
		id = local_id,
		nick = localnick or "player",
		colors = copy_colors(),
		hats = copy_hats(),
	}, nil, nil)
	notice.new("connecting to " .. use_ip .. ":" .. tostring(use_port))
end

global function server_start()
	if not SERVER then
		return
	end
	-- Phase 1: announce only. Phase 2 wires game sync / level load.
	broadcast({t = "start", mappack = mappack}, nil)
	notice.new("start queued — entity sync is phase 2")
end

global function net_sendchat(message: any): any
	local text = tostring(message or ""):sub(1, MAX_CHAT)
	if text == "" or role == "idle" then
		return
	end
	push_chat(local_id, text)
	if role == "host" then
		broadcast({t = "chat", id = local_id, message = text}, nil)
	else
		encode_send({t = "chat", id = local_id, message = text}, nil, nil)
	end
end

global function net_quit()
	if role == "client" and sock then
		encode_send({t = "bye", id = local_id}, nil, nil)
	elseif role == "host" and sock then
		broadcast({t = "host_gone"}, nil)
	end
	if usemagic and SERVER and magicdns_remove then
		pcall(magicdns_remove)
	end
	reset_session()
	menu_load()
end

global function netplay_update(dt: number)
	if role == "idle" or not sock then
		return
	end

	local packets = (Transport.recv_burst as function(any): {any})(sock)
	for i = 1, #packets do
		local pkt = packets[i] as {string:any}
		local msg = (Protocol.decode as function(string): {string:any}|nil)(pkt.data as string)
		if msg then
			if role == "host" then
				handle_host_msg(msg, pkt.ip as string, (pkt.port as integer) or 0)
			else
				handle_client_msg(msg)
			end
		end
	end

	heartbeat_t = heartbeat_t + dt
	if heartbeat_t >= HEARTBEAT_INTERVAL then
		heartbeat_t = 0
		if role == "client" then
			encode_send({t = "ping", t0 = love.timer.getTime()}, nil, nil)
		elseif role == "host" then
			local now = love.timer.getTime()
			local drop: {string} = {}
			for key, p in pairs(peers_by_key) do
				local peer = p as {string:any}
				local last = (peer.last as number) or now
				if now - last > PEER_TIMEOUT then
					table.insert(drop, key)
				else
					encode_send({t = "ping", t0 = now}, peer.ip as string, peer.port as integer)
				end
			end
			for _, key in ipairs(drop) do
				local peer = peers_by_key[key] as {string:any}
				local pid = tostring(peer.id or "")
				local nick = tostring(peer.nick or "player")
				peers_by_key[key] = nil
				broadcast({t = "peer_leave", id = pid}, nil)
				rebuild_playerlist_from_peers()
				notice.new("timed out: " .. nick, notice.red)
			end
			local n = 1
			for _ in pairs(peers_by_key) do n = n + 1 end
			set_status("hosting (" .. n .. "/" .. MAX_PLAYERS .. ")")
		end
	end

	if role == "client" and status == "connecting…" then
		connect_t = connect_t + dt
		if connect_t > 8 then
			notice.new("connection timed out", notice.red)
			reset_session()
			onlinemenu_load()
		end
	end
end

-- Init defaults at require time (before GlobalFreeze).
ensure_defaults()
set_status("offline")

return {
	update = netplay_update,
	get_status = net_get_status,
}
