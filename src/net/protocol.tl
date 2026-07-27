--[[ Compact JSON datagrams for lobby/chat MVP. Field `t` is the opcode. ]]

local VERSION = 1

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

local function decode(data: string): {string:any}|nil
	if not data or data == "" then
		return nil
	end
	local ok, decoded = pcall(function(): any
		local v = JSON.decode(data)
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
	encode = encode,
	decode = decode,
}
