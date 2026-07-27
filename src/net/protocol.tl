--[[ Compact JSON datagrams. Field `t` is the opcode.

Codec stays JSON for headless tests + no FFI. Future: optional bitser behind
the same encode/decode surface (Love 12 ships enet lightuserdata send if we
move transport to ENet later).
]]

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
	hash = "hash",
}

local OP_SET: {string:boolean} = {}
for _, name in pairs(OP) do
	OP_SET[name as string] = true
end

local function is_op(t: any): boolean
	return type(t) == "string" and OP_SET[t as string] == true
end

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

-- Strict decode: known opcode + compatible version (missing v accepted as legacy).
local function decode_strict(data: any): {string:any}|nil
	local msg = decode(data)
	if msg == nil then
		return nil
	end
	local m = msg as {string:any}
	if not is_op(m.t) then
		return nil
	end
	if m.v ~= nil then
		local v = tonumber(m.v)
		if not v or v ~= VERSION then
			return nil
		end
	end
	return m
end

local function validate(msg: any): boolean
	if type(msg) ~= "table" then
		return false
	end
	local m = msg as {string:any}
	if not is_op(m.t) then
		return false
	end
	if m.v ~= nil then
		local v = tonumber(m.v)
		if not v or v ~= VERSION then
			return false
		end
	end
	return true
end

return {
	VERSION = VERSION,
	OP = OP,
	encode = encode,
	decode = decode,
	decode_strict = decode_strict,
	validate = validate,
	is_op = is_op,
}
