--[[
  Emit IR → Mari0 v1 RLE level text.
]]

local M = {}

local BLOCK = "¤"
local LAYER = "×"
local CATEGORY = "¸"
local MULTIPLY = "·"
local EQUAL = "¨"

function M.rle_encode(ir)
	local tokens = {}
	local ent_at = {}
	for _, e in ipairs(ir.entities or {}) do
		ent_at[e.x .. "," .. e.y] = e.name
	end

	for y = 1, ir.height do
		for x = 1, ir.width do
			local tid = ir.tiles[x][y]
			local ent = ent_at[x .. "," .. y]
			if ent then
				tokens[#tokens + 1] = tostring(tid) .. LAYER .. ent
			else
				tokens[#tokens + 1] = tostring(tid)
			end
		end
	end

	local parts = {}
	local i = 1
	local n = #tokens
	while i <= n do
		if tokens[i]:find(LAYER, 1, true) then
			parts[#parts + 1] = tokens[i]
			i = i + 1
		else
			local j = i + 1
			while j <= n and tokens[j] == tokens[i] and not tokens[j]:find(LAYER, 1, true) do
				j = j + 1
			end
			local run = j - i
			if run > 1 then
				parts[#parts + 1] = tokens[i] .. MULTIPLY .. tostring(run)
			else
				parts[#parts + 1] = tokens[i]
			end
			i = j
		end
	end
	return table.concat(parts, BLOCK)
end

function M.emit(ir, options)
	options = options or {}
	local body = M.rle_encode(ir)
	local opts = {}
	for k, v in pairs(options) do
		opts[#opts + 1] = k .. EQUAL .. tostring(v)
	end
	table.sort(opts)
	local head = tostring(ir.height) .. CATEGORY .. body .. CATEGORY
	if #opts > 0 then
		return head .. table.concat(opts, CATEGORY)
	end
	return head
end

M.BLOCK = BLOCK
M.LAYER = LAYER
M.CATEGORY = CATEGORY
M.MULTIPLY = MULTIPLY
M.EQUAL = EQUAL

return M
