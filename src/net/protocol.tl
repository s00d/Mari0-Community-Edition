--[[ Compact JSON datagrams. Field `t` is the opcode. ]]

local VERSION = 1

local OP = {
	hello = "hello",
	welcome = "welcome",
	reject = "reject",
	peer_join = "peer_join",
	peer_leave = "peer_leave",
	chat = "chat",
	ping = "ping",
	pong = "pong",
	bye = "bye",
	host_gone = "host_gone",
	start = "start",
	input = "input",
	snap = "snap",
}

local function encode(msg: {string:any}): string|nil
	if not msg then
		return nil
	end
	msg.v = VERSION
	local ok, encoded = pcall(function(): any
		return JSON.encode(msg)
	end)
	if ok and type(encoded) == "string" then
		return encoded as string
	end
	return nil
end

local function decode(data: any): {string:any}|nil
	if data == nil then
		return nil
	end
	if type(data) ~= "string" or (data as string) == "" then
		return nil
	end
	local ok, decoded = pcall(function(): any
		local v = JSON.decode(data as string)
		return v
	end)
	if not ok or type(decoded) ~= "table" then
		return nil
	end
	local msg = decoded as {string:any}
	if type(msg.t) ~= "string" then
		return nil
	end
	return msg
end

return {
	VERSION = VERSION,
	OP = OP,
	encode = encode,
	decode = decode,
}
