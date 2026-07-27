--[[
  Generate minimal 16×15 endless room templates (pure Lua, no LÖVE).
  Run: lua scripts/endless/make_rooms.lua
]]

local ROOT = arg[0]:match("^(.*)/scripts/endless/") or "."
local OUT = ROOT .. "/mappacks/endless/rooms"

local BLOCK, LAYER, CATEGORY, MULTIPLY, EQUAL = "¤", "×", "¸", "·", "¨"
local EMPTY, GROUND, BRICK, HARD = 1, 2, 7, 78
local ENT_SPAWN, ENT_FLAG = 8, 11
local W, H = 16, 15

local function ensure_dir(path)
	local ok = os.execute("mkdir -p '" .. path .. "'")
	assert(ok == true or ok == 0, "mkdir failed: " .. path)
end

local function copy_cell(c)
	local n = {}
	for i = 1, #c do n[i] = c[i] end
	return n
end

local function blank()
	local cells, coin = {}, {}
	for x = 1, W do
		cells[x], coin[x] = {}, {}
		for y = 1, H do
			cells[x][y] = {EMPTY}
			coin[x][y] = false
		end
	end
	return cells, coin
end

-- Openings align across rooms so stitches connect.
local function open_exits(cells, exits)
	-- L/R corridor: cols 1/16, rows 11-13 empty; floor stays at 14-15
	if exits.l then
		for y = 11, 13 do cells[1][y] = {EMPTY} end
	end
	if exits.r then
		for y = 11, 13 do cells[W][y] = {EMPTY} end
	end
	-- U/D shaft: cols 7-10
	if exits.u then
		for x = 7, 10 do
			cells[x][1] = {EMPTY}
			cells[x][2] = {EMPTY}
		end
	end
	if exits.d then
		for x = 7, 10 do
			cells[x][H] = {EMPTY}
			cells[x][H - 1] = {EMPTY}
		end
	end
end

local function base_room(exits)
	local cells, coin = blank()
	-- floor
	for x = 1, W do
		cells[x][H - 1] = {GROUND}
		cells[x][H] = {GROUND}
	end
	-- side walls (may be opened)
	for y = 1, H - 2 do
		cells[1][y] = {HARD}
		cells[W][y] = {HARD}
	end
	-- ceiling
	for x = 2, W - 1 do
		cells[x][1] = {HARD}
	end
	-- mid platforms
	for x = 4, 7 do cells[x][9] = {BRICK} end
	for x = 10, 13 do cells[x][7] = {BRICK} end

	open_exits(cells, exits)

	-- ensure floor openings for down exit (already emptied H and H-1 in shaft)
	if exits.d then
		for x = 7, 10 do
			cells[x][H] = {EMPTY}
			cells[x][H - 1] = {EMPTY}
		end
	end
	if exits.u then
		for x = 7, 10 do
			cells[x][1] = {EMPTY}
		end
	end

	return cells, coin
end

local function cell_token(cell, iscoin)
	local t = tostring(cell[1]) .. (iscoin and "c" or "")
	if #cell == 1 then return t, false end
	local parts = {t}
	for i = 2, #cell do parts[#parts + 1] = tostring(cell[i]) end
	return table.concat(parts, LAYER), true
end

local function serialize(cells, coin)
	local out, prev, mul, layered_prev = {}, nil, 0, false
	local function flush()
		if prev == nil then return end
		if mul > 1 and not layered_prev then
			out[#out + 1] = prev .. MULTIPLY .. tostring(mul)
		else
			out[#out + 1] = prev
		end
	end
	for y = 1, H do
		for x = 1, W do
			local tok, layered = cell_token(cells[x][y], coin[x][y])
			if (not layered) and tok == prev and not layered_prev then
				mul = mul + 1
			else
				flush()
				prev, mul, layered_prev = tok, 1, layered
			end
		end
	end
	flush()
	local body = table.concat(out, BLOCK)
	return tostring(H) .. CATEGORY .. body
		.. CATEGORY .. "backgroundr" .. EQUAL .. "92"
		.. CATEGORY .. "backgroundg" .. EQUAL .. "148"
		.. CATEGORY .. "backgroundb" .. EQUAL .. "252"
		.. CATEGORY .. "spriteset" .. EQUAL .. "1"
		.. CATEGORY .. "music" .. EQUAL .. "overworld.ogg"
		.. CATEGORY .. "timelimit" .. EQUAL .. "400"
		.. CATEGORY .. "scrollfactor" .. EQUAL .. "0"
		.. CATEGORY .. "fscrollfactor" .. EQUAL .. "0"
end

local function write_room(name, exits, decorate)
	local cells, coin = base_room(exits)
	if decorate then decorate(cells, coin, exits) end
	local text = serialize(cells, coin)
	local path = OUT .. "/" .. name .. ".txt"
	local f = assert(io.open(path, "w"))
	f:write(text)
	f:close()
	print("wrote " .. path)
end

ensure_dir(OUT)

-- start: spawn near left, exits right+down
write_room("start_rd", {r = true, d = true}, function(cells)
	cells[3][H - 2] = {EMPTY, ENT_SPAWN, "true", "false", "false", "false", "false"}
end)

-- end: flag on right solid, exits left+up
write_room("end_lu", {l = true, u = true}, function(cells)
	cells[W - 2][H - 1] = {HARD, ENT_FLAG}
end)

write_room("hall_lr", {l = true, r = true}, function(cells)
	cells[8][H - 2] = {EMPTY, "goomba"}
	cells[11][H - 2] = {EMPTY, "koopa"}
end)

write_room("hall_lr2", {l = true, r = true}, function(cells)
	cells[6][6] = {BRICK}
	cells[7][6] = {BRICK}
	cells[8][6] = {BRICK}
	cells[10][H - 2] = {EMPTY, "goomba"}
end)

write_room("shaft_ud", {u = true, d = true}, function(cells)
	-- ledges for climbing down
	for x = 3, 5 do cells[x][5] = {BRICK} end
	for x = 11, 13 do cells[x][8] = {BRICK} end
	for x = 3, 5 do cells[x][11] = {BRICK} end
	cells[12][10] = {EMPTY, "goomba"}
end)

write_room("shaft_ud2", {u = true, d = true}, function(cells)
	for x = 12, 14 do cells[x][6] = {BRICK} end
	for x = 2, 4 do cells[x][9] = {BRICK} end
	cells[5][H - 2] = {EMPTY, "koopa"}
end)

write_room("corner_ld", {l = true, d = true}, function(cells)
	cells[9][H - 2] = {EMPTY, "goomba"}
end)

write_room("corner_rd", {r = true, d = true}, function(cells)
	cells[6][H - 2] = {EMPTY, "goomba"}
end)

write_room("corner_lu", {l = true, u = true}, function(cells)
	cells[10][H - 2] = {EMPTY, "koopa"}
end)

write_room("corner_ru", {r = true, u = true}, function(cells)
	cells[7][H - 2] = {EMPTY, "koopa"}
end)

write_room("room_lrud", {l = true, r = true, u = true, d = true}, function(cells)
	cells[5][H - 2] = {EMPTY, "goomba"}
	cells[12][H - 2] = {EMPTY, "goomba"}
end)

write_room("room_lrd", {l = true, r = true, d = true}, function(cells)
	cells[8][H - 2] = {EMPTY, "koopa"}
end)

write_room("filler", {}, function(cells)
	-- sealed pocket; optional coin
	cells[8][10] = {EMPTY}
	-- coin via coinmap not easy here; leave empty chamber
end)

print("done")
