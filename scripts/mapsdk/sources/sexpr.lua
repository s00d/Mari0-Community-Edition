--[[
  Minimal S-expression reader for SuperTux .stl / .strf.
  Format docs only — no SuperTux C++ (GPL-3) copied.
]]

local M = {}

function M.parse_sexpr(s)
	local pos = 1
	local n = #s

	local function skip()
		while pos <= n do
			local c = s:sub(pos, pos)
			if c == ";" then
				local nl = s:find("\n", pos, true)
				pos = nl and (nl + 1) or (n + 1)
			elseif c:match("%s") then
				pos = pos + 1
			else
				break
			end
		end
	end

	local function node()
		skip()
		if pos > n then
			return nil
		end
		local c = s:sub(pos, pos)
		if c == "(" then
			pos = pos + 1
			local t = {}
			while true do
				skip()
				if pos > n then
					return t
				end
				if s:sub(pos, pos) == ")" then
					pos = pos + 1
					return t
				end
				t[#t + 1] = node()
			end
		elseif c == '"' then
			pos = pos + 1
			local buf = {}
			while pos <= n do
				local ch = s:sub(pos, pos)
				if ch == "\\" and pos < n then
					buf[#buf + 1] = s:sub(pos + 1, pos + 1)
					pos = pos + 2
				elseif ch == '"' then
					pos = pos + 1
					return table.concat(buf)
				else
					buf[#buf + 1] = ch
					pos = pos + 1
				end
			end
			return table.concat(buf)
		else
			local e = s:find("[%s()]", pos) or (n + 1)
			local tok = s:sub(pos, e - 1)
			pos = e
			local num = tonumber(tok)
			if num ~= nil then
				return num
			end
			return tok
		end
	end

	return node()
end

--- First child list named `name`: returns value (node[2]), full child, or nil.
function M.field(node, name)
	if type(node) ~= "table" then
		return nil
	end
	for i = 2, #node do
		local c = node[i]
		if type(c) == "table" and c[1] == name then
			return c[2], c
		end
	end
	return nil
end

--- All children with head symbol `name`.
function M.children(node, name)
	local out = {}
	if type(node) ~= "table" then
		return out
	end
	for i = 2, #node do
		local c = node[i]
		if type(c) == "table" and (not name or c[1] == name) then
			out[#out + 1] = c
		end
	end
	return out
end

--- Unwrap (_ "text") / bare string / symbol.
function M.as_string(v)
	if type(v) == "string" then
		return v
	end
	if type(v) == "table" and v[1] == "_" and type(v[2]) == "string" then
		return v[2]
	end
	if type(v) == "number" then
		return tostring(v)
	end
	return nil
end

function M.is_true(v)
	return v == true or v == "#t"
end

--- SuperTux tile RLE: negative N = next value repeated |N| times.
-- list is the full (tiles ...) node; decoding starts at index 2.
function M.decode_tiles(list, w, h)
	local out, n = {}, 0
	local i = 2
	while i <= #list do
		local v = list[i]
		if type(v) ~= "number" then
			error("decode_tiles: non-number at " .. i)
		end
		if v < 0 then
			local val = list[i + 1]
			if type(val) ~= "number" then
				error("decode_tiles: run value missing after " .. v)
			end
			for _ = 1, -v do
				n = n + 1
				out[n] = val
			end
			i = i + 2
		else
			n = n + 1
			out[n] = v
			i = i + 1
		end
	end
	assert(n == w * h, string.format("tile count %d != %d*%d", n, w, h))
	return out
end

return M
