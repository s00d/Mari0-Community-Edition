--[[ Online session: host/join lobby, chat, match start, host-auth sync.
     Transport: non-blocking UDP + JSON. No LUBE.
     Hot path: only runs while Net.activate()'d — offline uses NullNet facade. ]]

local Net = require("net.facade") as {string:any}
local Transport = require("net.transport") as {string:any}
local Protocol = require("net.protocol") as {string:any}
local Sync = require("net.sync") as {string:any}
local Match = require("net.match") as {string:any}
local State = require("net.state") as {string:any}
local StateHash = require("net.statehash") as {string:any}

local HEARTBEAT_INTERVAL = 2.0
local PEER_TIMEOUT = 8.0
local MAX_CHAT = 64
local MAX_PLAYERS = (Match.MAX_PLAYERS as integer) or 4
local DEFAULT_PORT = 7331
-- Drop peer after this many consecutive frames of per-peer recv abuse.
local ABUSE_DISCONNECT_FRAMES = 3
local HASH_EVERY = 60 -- frames between hash exchange

local sock: any = nil
local role: string = "idle" -- idle | host | client
local status: string = "offline"
local local_id: string = ""
local heartbeat_t: number = 0
local connect_t: number = 0
local peers_by_key: {string:any} = {} -- host-only
local in_match: boolean = false
-- Monotonic outbound seq for input / snap / hash (UDP reorder / duplicate guard).
local send_seq: integer = 0
-- last_seen[peer_key or "_host"][opcode] = highest accepted seq
local last_seen: {string:{string:integer}} = {}
-- host: peer_key -> consecutive abuse-frame count
local abuse_strikes: {string:integer} = {}
-- Desync detector (F1)
local match_frame: integer = 0
local last_local_hash: integer = 0
local peer_hashes: {string:{string:any}} = {} -- peer_id -> {frame, h}
local desync_reported_frame: integer = -1

local SEQ_OPS: {string:boolean} = {
	input = true,
	snap = true,
	hash = true,
}

local function next_seq(): integer
	send_seq = send_seq + 1
	return send_seq
end

local function net_log(msg: string)
	if Logger and Logger.warn then
		(Logger.warn as function(...: any))("net", msg)
	else
		print("[net] " .. msg)
	end
end

local function accept_seq(peer_id: string, op: string, seq: any): boolean
	if not SEQ_OPS[op] then
		return true
	end
	local s = tonumber(seq)
	if not s then
		-- Legacy packets without seq: accept once migration peers catch up.
		return true
	end
	local n = s as integer
	local bucket = last_seen[peer_id]
	if not bucket then
		bucket = {}
		last_seen[peer_id] = bucket
	end
	local prev = bucket[op]
	if prev ~= nil and n <= prev then
		return false
	end
	bucket[op] = n
	return true
end

local function clear_seq_state()
	send_seq = 0
	for k in pairs(last_seen) do
		last_seen[k] = nil
	end
	for k in pairs(abuse_strikes) do
		abuse_strikes[k] = nil
	end
	match_frame = 0
	last_local_hash = 0
	desync_reported_frame = -1
	for k in pairs(peer_hashes) do
		peer_hashes[k] = nil
	end
end

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
	if usemagic == nil then
		rawset(_G, "usemagic", false)
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
	local t = msg.t as string
	if SEQ_OPS[t] and msg.seq == nil then
		msg.seq = next_seq()
	end
	local data = (Protocol.encode as function({string:any}): string|nil)(msg)
	if not data or not sock then
		return
	end
	local max_d = (Transport.MAX_DATAGRAM as integer) or 1200
	if #data > max_d then
		net_log("drop oversized send t=" .. tostring(t) .. " bytes=" .. tostring(#data) .. " max=" .. tostring(max_d))
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

-- Forward decl via bag so Teal/Lua can bind before the body is assigned.
local live: {string:any} = {}

local function session_get_status(): string
	return status
end

local function session_in_match(): boolean
	return in_match
end

local function session_is_active(): boolean
	return role ~= "idle" and sock ~= nil
end

local function bind_facade()
	(Net.activate as function({string:any}))({
		update = live.update,
		get_status = session_get_status,
		in_match = session_in_match,
		is_active = session_is_active,
	})
end

local function reset_session()
	close_socket()
	role = "idle"
	peers_by_key = {}
	heartbeat_t = 0
	connect_t = 0
	in_match = false
	clear_seq_state()
	(Sync.clear_held as function())()
	rawset(_G, "SERVER", false)
	rawset(_G, "CLIENT", false)
	rawset(_G, "playerlist", {})
	rawset(_G, "chatmessages", {})
	set_status("offline")
	(Net.deactivate as function())()
end

local function peer_count(): integer
	local n = 0
	for _ in pairs(peers_by_key) do
		n = n + 1
	end
	return n
end

local function report_desync(frame: integer, local_h: integer, remote_h: integer, who: string)
	if desync_reported_frame == frame then
		return
	end
	desync_reported_frame = frame
	local msg = "DESYNC frame=" .. tostring(frame) .. " local=" .. tostring(local_h) .. " peer=" .. tostring(remote_h) .. " (" .. who .. ")"
	net_log(msg)
	notice.new("desync @" .. tostring(frame), notice.red)
end

local function on_remote_hash(from_id: string, msg: {string:any})
	local frame = (tonumber(msg.frame) or -1) as integer
	local h = (tonumber(msg.h) or 0) as integer
	if frame < 0 then
		return
	end
	peer_hashes[from_id] = {frame = frame, h = h}
	-- Compare when we have a local hash for the same frame (or latest if we just computed it).
	if frame == match_frame and last_local_hash ~= 0 and h ~= last_local_hash then
		report_desync(frame, last_local_hash, h, from_id)
	elseif last_local_hash ~= 0 and frame % HASH_EVERY == 0 then
		-- Peer reported a hash boundary; if our last hash frame matches, compare.
		if (match_frame - (match_frame % HASH_EVERY)) == frame and h ~= last_local_hash then
			report_desync(frame, last_local_hash, h, from_id)
		end
	end
end

local function hash_tick()
	if not in_match or not objects then
		return
	end
	match_frame = match_frame + 1
	if match_frame % HASH_EVERY ~= 0 then
		return
	end
	local h = (StateHash.sim_hash as function(): integer)()
	last_local_hash = h
	local msg = (StateHash.pack_hash as function(integer, integer, integer|nil): {string:any})(match_frame, h, next_seq())
	if role == "host" then
		if peer_count() > 0 then
			broadcast(msg, nil)
		end
		-- Compare any peer hashes already received for this frame.
		for pid, row in pairs(peer_hashes) do
			local r = row as {string:any}
			if (tonumber(r.frame) or -1) == match_frame then
				local rh = (tonumber(r.h) or 0) as integer
				if rh ~= h then
					report_desync(match_frame, h, rh, tostring(pid))
				end
			end
		end
	elseif role == "client" then
		encode_send(msg, nil, nil)
		local host_row = peer_hashes["host"]
		if host_row then
			local r = host_row as {string:any}
			if (tonumber(r.frame) or -1) == match_frame then
				local rh = (tonumber(r.h) or 0) as integer
				if rh ~= h then
					report_desync(match_frame, h, rh, "host")
				end
			end
		end
	end
end

local function start_match_from_msg(msg: {string:any})
	(Sync.clear_held as function())()
	local slot = (Match.begin_match as function({string:any}, string): integer|nil)(msg, local_id)
	if not slot then
		-- begin_match already noticed; keep lobby / pre-match state.
		return
	end
	in_match = true
	match_frame = 0
	last_local_hash = 0
	desync_reported_frame = -1
	for k in pairs(peer_hashes) do
		peer_hashes[k] = nil
	end
	rawset(_G, "netplayernumber", slot)
	set_status(role == "host" and "in game (host)" or "in game")
	notice.new("starting game")
end

local function handle_host_msg(msg: {string:any}, from_ip: string, from_port: integer)
	local t = msg.t as string
	local key = (Transport.peer_key as function(string, integer): string)(from_ip, from_port)

	if t == "hello" then
		if in_match then
			encode_send({t = "reject", reason = "in game"}, from_ip, from_port)
			return
		end
		if peer_count() >= MAX_PLAYERS - 1 then
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
			slot = peer_count() + 2,
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
		set_status("hosting (" .. tostring(peer_count() + 1) .. "/" .. MAX_PLAYERS .. ")")
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
			if not in_match then
				rebuild_playerlist_from_peers()
			end
		end
	elseif t == "input" then
		if in_match then
			if not accept_seq(key, "input", msg.seq) then
				return
			end
			local packet_slot, h = (Sync.unpack_input as function({string:any}): integer, {string:any})(msg)
			-- Host uses ONLY peer.slot assigned at start — never trust packet slot.
			local use_slot = (tonumber(p.slot) or 0) as integer
			if use_slot < 2 then
				net_log("drop input: peer has no slot key=" .. key)
				return
			end
			if packet_slot ~= 0 and packet_slot ~= use_slot then
				net_log("drop input: slot spoof packet=" .. tostring(packet_slot) .. " peer=" .. tostring(use_slot) .. " key=" .. key)
				return
			end
			h.slot = use_slot
			(Sync.set_held as function(integer, {string:any}))(use_slot, h)
			(Sync.refresh_net_held_global as function())()
		end
	elseif t == "bye" then
		local nick = tostring(p.nick or "player")
		local leave_pid = tostring(p.id or "")
		peers_by_key[key] = nil
		broadcast({t = "peer_leave", id = leave_pid}, nil)
		rebuild_playerlist_from_peers()
		notice.new("player left: " .. nick)
		set_status("hosting (" .. tostring(peer_count() + 1) .. "/" .. MAX_PLAYERS .. ")")
		if in_match and peer_count() == 0 then
			notice.new("all clients left", notice.red)
		end
	elseif t == "hash" then
		if in_match then
			if not accept_seq(key, "hash", msg.seq) then
				return
			end
			on_remote_hash(tostring(p.id or key), msg)
		end
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
		-- RTT optional
	elseif t == "start" then
		start_match_from_msg(msg)
	elseif t == "snap" then
		if in_match and objects then
			if not accept_seq("_host", "snap", msg.seq) then
				return
			end
			(Sync.apply_snapshot as function({string:any}, boolean))(msg, true)
		end
	elseif t == "hash" then
		if in_match then
			if not accept_seq("_host", "hash", msg.seq) then
				return
			end
			on_remote_hash("host", msg)
		end
	elseif t == "host_gone" then
		notice.new("host disconnected", notice.red)
		in_match = false
		reset_session()
		menu_load()
	end
end

local function sync_tick(dt: number)
	if not in_match or not objects or not playerobjs then
		return
	end

	if role == "host" then
		-- Solo host (no clients): skip JSON snap / edge processing — zero net work.
		if peer_count() == 0 then
			return
		end
		(Sync.host_process_edges as function())()
		if (Sync.should_send_snap as function(number): boolean)(dt) then
			local snap = (Sync.pack_snapshot as function(integer|nil): {string:any})(next_seq())
			broadcast(snap, nil)
		end
	elseif role == "client" then
		-- Undo physics drift on remotes every frame using last snap.
		(Sync.reapply_last_snap as function(boolean))(true)
		if (Sync.should_send_input as function(number): boolean)(dt) then
			local slot = (netplayernumber as integer) or 1
			local h = (Sync.read_local_held as function(integer): {string:any})(slot)
			encode_send((Sync.pack_input as function(integer, {string:any}, integer|nil): {string:any})(slot, h, next_seq()), nil, nil)
		end
	end
end

--------------------------------------------------------------------------
-- Public globals (lifecycle). Queries / update go through net.facade.
--------------------------------------------------------------------------

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
	bind_facade()
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
	bind_facade()
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
	if not SERVER or role ~= "host" then
		return
	end
	if in_match then
		return
	end
	-- Solo host allowed; peers optional.
	local n = peer_count() + 1
	-- Assign slots on peers before broadcast.
	local slot = 2
	for _, p in pairs(peers_by_key) do
		(p as {string:any}).slot = slot
		slot = slot + 1
	end
	local msg = (Match.build_start_msg as function(string, {string:any}, string, any, any, any): {string:any})(
		local_id,
		peers_by_key,
		tostring(mappack or "smb"),
		marioworld or 1,
		mariolevel or 1,
		mariosublevel or 0
	)
	broadcast(msg, nil)
	start_match_from_msg(msg)
	set_status("in game (host) " .. tostring(n) .. "p")
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
	local was_match = in_match
	reset_session()
	if was_match then
		objects = nil
	end
	menu_load()
end

live.update = function(dt: number)
	-- Only reached while facade ActiveNet points here (NullNet never calls us).
	if role == "idle" or not sock then
		return
	end
	if not SERVER and not CLIENT then
		return
	end

	local packets = (Transport.recv_burst as function(any): {any})(sock)
	for i = 1, #packets do
		local pkt = packets[i] as {string:any}
		local msg = (Protocol.decode as function(any): {string:any}|nil)(pkt.data)
		if msg ~= nil and (Protocol.is_op as function(any): boolean)((msg as {string:any}).t) then
			local m = msg as {string:any}
			if role == "host" then
				handle_host_msg(m, pkt.ip as string, (pkt.port as integer) or 0)
			else
				handle_client_msg(m)
			end
		end
	end

	-- Host: disconnect peers that repeatedly exceed per-peer recv budget.
	if role == "host" then
		local abused = (Transport.last_abuse_peers as function(): {string})()
		local hit: {string:boolean} = {}
		for i = 1, #abused do
			hit[abused[i]] = true
		end
		local drop: {string} = {}
		for key in pairs(peers_by_key) do
			if hit[key] then
				local n = (abuse_strikes[key] or 0) + 1
				abuse_strikes[key] = n
				if n >= ABUSE_DISCONNECT_FRAMES then
					table.insert(drop, key)
				end
			else
				abuse_strikes[key] = nil
			end
		end
		for _, key in ipairs(drop) do
			local peer = peers_by_key[key] as {string:any}
			if peer then
				local pid = tostring(peer.id or "")
				local nick = tostring(peer.nick or "player")
				peers_by_key[key] = nil
				abuse_strikes[key] = nil
				last_seen[key] = nil
				broadcast({t = "peer_leave", id = pid}, nil)
				if not in_match then
					rebuild_playerlist_from_peers()
				end
				net_log("disconnect rate-limit abuse: " .. nick .. " key=" .. key)
				notice.new("kicked (rate): " .. nick, notice.red)
			end
		end
	end

	sync_tick(dt)
	hash_tick()

	heartbeat_t = heartbeat_t + dt
	if heartbeat_t >= HEARTBEAT_INTERVAL then
		heartbeat_t = 0
		if role == "client" then
			encode_send({t = "ping", t0 = love.timer.getTime()}, nil, nil)
		elseif role == "host" and peer_count() > 0 then
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
				if not in_match then
					rebuild_playerlist_from_peers()
				end
				notice.new("timed out: " .. nick, notice.red)
			end
			if not in_match then
				set_status("hosting (" .. tostring(peer_count() + 1) .. "/" .. MAX_PLAYERS .. ")")
			end
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

-- Init defaults at require time (before GlobalFreeze). Facade stays NullNet.
ensure_defaults()
set_status("offline")
(Net.deactivate as function())()

return {
	update = live.update,
	get_status = session_get_status,
	in_match = session_in_match,
	is_active = session_is_active,
	fsm = State,
}
