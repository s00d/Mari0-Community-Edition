--[[ Non-blocking UDP via LuaSocket (Love 12 ships 3.1.0). No LUBE. ]]

local MAX_RECV_PER_FRAME = 48
local MAX_DATAGRAM = 1200

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
	local out: {{string:any}} = {}
	if not u then
		return out
	end
	local bag = u as {string:any}
	if not bag.sock then
		return out
	end
	local sock = bag.sock as {string:any}
	local mode = bag.mode as string
	for _ = 1, MAX_RECV_PER_FRAME do
		if mode == "client" then
			local data = (sock.receive as function(any): any)(bag.sock)
			if type(data) ~= "string" then
				break
			end
			table.insert(out, {
				data = data as string,
				ip = (bag.peer_ip as string) or "",
				port = (bag.peer_port as integer) or 0,
			})
		else
			local got: {string:any}|nil = nil
			local ok = pcall(function()
				local a, b, c = (sock.receivefrom as function(any): any, any, any)(bag.sock)
				if type(a) == "string" then
					got = {
						data = a as string,
						ip = tostring(b or ""),
						port = (tonumber(c) or 0) as integer,
					}
				end
			end)
			if not ok or not got then
				break
			end
			table.insert(out, got)
		end
	end
	return out
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
