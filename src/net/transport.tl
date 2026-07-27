--[[ Non-blocking UDP via LuaSocket (Love 12 ships 3.1.0). No LUBE. ]]

local MAX_RECV_PER_FRAME = 48
local MAX_DATAGRAM = 1200

-- Reused across frames to avoid empty-table alloc when the socket has no datagrams.
local EMPTY_RECV: {{string:any}} = {}
local recv_buf: {{string:any}} = {}

local function try_socket(): any|nil, string|nil
	local req = require as function(string): any
	local ok, sockmod = pcall(req, "socket")
	if not ok or sockmod == nil then
		return nil, "luasocket unavailable"
	end
	return sockmod, nil
end

local function available(): boolean
	return try_socket() ~= nil
end

local function create_host(port: integer): any|nil, string|nil
	local socket, err = try_socket()
	if not socket then
		return nil, err
	end
	local maker = (socket as {string:any})["udp"] as function(): any
	local udp = maker()
	local udpm = udp as {string:any}
	(udpm.settimeout as function(any, number))(udp, 0)
	local bind_ok = (udpm.setsockname as function(any, string, integer): any)(udp, "*", port)
	if not bind_ok then
		(udpm.close as function(any))(udp)
		return nil, "bind failed"
	end
	return {
		sock = udp,
		mode = "host",
		local_port = port,
		peer_ip = nil,
		peer_port = nil,
	}, nil
end

local function create_client(ip: string, port: integer): any|nil, string|nil
	local socket, err = try_socket()
	if not socket then
		return nil, err
	end
	local maker = (socket as {string:any})["udp"] as function(): any
	local udp = maker()
	local udpm = udp as {string:any}
	(udpm.settimeout as function(any, number))(udp, 0)
	local peer_ok = (udpm.setpeername as function(any, string, integer): any)(udp, ip, port)
	if not peer_ok then
		(udpm.close as function(any))(udp)
		return nil, "setpeername failed"
	end
	return {
		sock = udp,
		mode = "client",
		local_port = 0,
		peer_ip = ip,
		peer_port = port,
	}, nil
end

local function close(u: any)
	if not u then
		return
	end
	local bag = u as {string:any}
	if bag.sock then
		pcall(function()
			local s = bag.sock as {string:any}
			(s.close as function(any))(bag.sock)
		end)
		bag.sock = nil
	end
end

local function send(u: any, data: string, ip: string|nil, port: integer|nil): boolean
	if not u or not data then
		return false
	end
	local bag = u as {string:any}
	if not bag.sock then
		return false
	end
	if #data > MAX_DATAGRAM then
		data = data:sub(1, MAX_DATAGRAM)
	end
	local sock = bag.sock as {string:any}
	if bag.mode == "client" then
		local ok = (sock.send as function(any, string): any)(bag.sock, data)
		return ok ~= nil
	end
	if not ip or not port then
		return false
	end
	local ok = (sock.sendto as function(any, string, string, integer): any)(bag.sock, data, ip, port)
	return ok ~= nil
end

local function recv_burst(u: any): {{string:any}}
	if not u then
		return EMPTY_RECV
	end
	local bag = u as {string:any}
	if not bag.sock then
		return EMPTY_RECV
	end
	-- Clear previous burst length (keep pooled slot tables when possible).
	local prev_n = #recv_buf
	local sock = bag.sock as {string:any}
	local mode = bag.mode as string
	local n = 0
	for _ = 1, MAX_RECV_PER_FRAME do
		if mode == "client" then
			local data = (sock.receive as function(any): any)(bag.sock)
			if type(data) ~= "string" then
				break
			end
			n = n + 1
			local slot = recv_buf[n]
			if not slot then
				slot = {}
				recv_buf[n] = slot
			end
			slot.data = data as string
			slot.ip = (bag.peer_ip as string) or ""
			slot.port = (bag.peer_port as integer) or 0
		else
			local got_data: string|nil = nil
			local got_ip: string = ""
			local got_port: integer = 0
			local ok = pcall(function()
				local a, b, c = (sock.receivefrom as function(any): any, any, any)(bag.sock)
				if type(a) == "string" then
					got_data = a as string
					got_ip = tostring(b or "")
					got_port = (tonumber(c) or 0) as integer
				end
			end)
			if not ok or not got_data then
				break
			end
			n = n + 1
			local slot = recv_buf[n]
			if not slot then
				slot = {}
				recv_buf[n] = slot
			end
			slot.data = got_data as string
			slot.ip = got_ip
			slot.port = got_port
		end
	end
	if n == 0 then
		return EMPTY_RECV
	end
	for i = n + 1, prev_n do
		recv_buf[i] = nil as {string:any}
	end
	return recv_buf
end

local function peer_key(ip: string, port: integer): string
	return ip .. ":" .. tostring(port)
end

return {
	available = available,
	create_host = create_host,
	create_client = create_client,
	close = close,
	send = send,
	recv_burst = recv_burst,
	peer_key = peer_key,
}
