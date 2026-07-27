--[[
  VGLC → Mari0 mappack converter (pure Lua, no LÖVE).

  Algorithms:
    A  pad/trim height to 15 from TOP only (never cut non-empty tops)
    B  smb2 p/P pipe stacks → mouth + body tiles
    C  deterministic enemy classify
    D  spawn + flag placement
    E  RLE serialize with mw*mh assert
    F  legend tables (legend_smb / legend_smb2)
]]

local M = {}

local function script_dir()
	local src = debug.getinfo(1, "S").source
	if src:sub(1, 1) == "@" then
		return src:sub(2):match("^(.*)/") or "."
	end
	return "."
end

local DIR = script_dir()
local T = dofile(DIR .. "/tiles.lua")
M.T = T
M.legend_smb = dofile(DIR .. "/legend_smb.lua")(T)
M.legend_smb2 = dofile(DIR .. "/legend_smb2.lua")(T)

-- v1 delimiters (variables.tl)
local BLOCK = "¤"
local LAYER = "×"
local CATEGORY = "¸"
local MULTIPLY = "·"
local EQUAL = "¨"

local SOLID_TILES = {
	[T.GROUND] = true,
	[T.BRICK] = true,
	[T.QUESTION] = true,
	[T.QUESTION_EMPTY] = true,
	[T.PIPE_TL] = true,
	[T.PIPE_TR] = true,
	[T.PIPE_L] = true,
	[T.PIPE_R] = true,
	[T.HARD] = true,
	[T.CANNON_TOP] = true,
	[T.CANNON_BODY] = true,
}

local function is_solid_char(ch, legend)
	if ch == "p" or ch == "P" then
		return true
	end
	local e = legend.map[ch]
	if not e then
		return false
	end
	return e.tile ~= T.EMPTY or e.enemy ~= nil
end

local function row_has_content(row)
	for i = 1, #row do
		if row:sub(i, i) ~= "-" then
			return true
		end
	end
	return false
end

------------------------------------------------------------------------
-- A: read + normalize height
------------------------------------------------------------------------

function M.read_level(path)
	local f, err = io.open(path, "r")
	if not f then
		error("read_level: " .. tostring(err))
	end
	local rows = {}
	for rawline in f:lines() do
		rows[#rows + 1] = rawline:gsub("\r$", "")
	end
	f:close()
	if #rows == 0 then
		error("read_level: empty " .. path)
	end
	local w = 0
	for i = 1, #rows do
		if #rows[i] > w then
			w = #rows[i]
		end
	end
	for i = 1, #rows do
		if #rows[i] < w then
			rows[i] = rows[i] .. string.rep("-", w - #rows[i])
		end
	end
	return rows, w, #rows
end

--- Pad/trim to target from TOP only.
--- If trimming would discard non-'-' cells, refuses to cut (keeps tall height).
function M.normalize_height(rows, w, target)
	target = target or 15
	local h = #rows
	if h == target then
		return rows, h, false
	end
	if h < target then
		local pad = {}
		for _ = 1, target - h do
			pad[#pad + 1] = string.rep("-", w)
		end
		for i = 1, h do
			pad[#pad + 1] = rows[i]
		end
		return pad, target, false
	end
	-- h > target: cut top only if empty
	local cut = h - target
	for i = 1, cut do
		if row_has_content(rows[i]) then
			-- Algorithm A assert: do not silently cut content
			return rows, h, true -- kept_tall
		end
	end
	local out = {}
	for i = cut + 1, h do
		out[#out + 1] = rows[i]
	end
	return out, target, false
end

------------------------------------------------------------------------
-- B: smb2 pipes
------------------------------------------------------------------------

function M.detect_pipes(rows, w, h)
	local pipes = {}
	for x = 1, w - 1 do
		local y = 1
		while y <= h do
			local left = rows[y]:sub(x, x)
			local right = rows[y]:sub(x + 1, x + 1)
			if left == "p" and right == "P" then
				local top = y
				local bottom = y
				while bottom + 1 <= h and rows[bottom + 1]:sub(x, x) == "p" do
					bottom = bottom + 1
				end
				pipes[#pipes + 1] = { x = x, top = top, bottom = bottom }
				y = bottom + 1
			else
				y = y + 1
			end
		end
	end
	return pipes
end

function M.pipe_height_sum(pipes)
	local sum = 0
	for i = 1, #pipes do
		sum = sum + (pipes[i].bottom - pipes[i].top + 1)
	end
	return sum
end

------------------------------------------------------------------------
-- C: deterministic enemy classify
------------------------------------------------------------------------

local function empty_below(rows, x, y, n)
	local h = #rows
	for dy = 1, n do
		local yy = y + dy
		if yy > h then
			return false
		end
		if rows[yy]:sub(x, x) ~= "-" then
			return false
		end
	end
	return true
end

local function pipe_within(rows, x, y, dist)
	local h = #rows
	local w = #rows[1]
	for dy = -dist, dist do
		for dx = -dist, dist do
			local xx, yy = x + dx, y + dy
			if xx >= 1 and xx <= w and yy >= 1 and yy <= h then
				local ch = rows[yy]:sub(xx, xx)
				if ch == "p" or ch == "P" or ch == "<" or ch == ">" or ch == "[" or ch == "]" then
					return true
				end
			end
		end
	end
	return false
end

function M.classify_enemy(rows, x, y, h, level_ctx, index)
	local below = (y + 1 <= h) and rows[y + 1]:sub(x, x) or "#"
	if below == "-" and empty_below(rows, x, y, 3) then
		return "koopaflying"
	end
	if pipe_within(rows, x, y, 2) then
		return "plant"
	end
	if level_ctx and level_ctx.water then
		return "cheepcheepred"
	end
	if index % 3 == 0 then
		return "koopa"
	end
	return "goomba"
end

------------------------------------------------------------------------
-- D: spawn + flag
------------------------------------------------------------------------

local function char_solid(rows, x, y, legend)
	return is_solid_char(rows[y]:sub(x, x), legend)
end

local function clear_above(rows, x, y, n, legend)
	for dy = 1, n do
		local yy = y - dy
		if yy < 1 then
			return false
		end
		local ch = rows[yy]:sub(x, x)
		-- empty, floating enemies, and coins are fine above spawn/flag
		if ch == "-" or ch == "E" or ch == "e" or ch == "o" or ch == "c" then
			-- ok
		elseif legend.map[ch] and legend.map[ch].tile == T.EMPTY then
			-- ok
		else
			return false
		end
	end
	return true
end

function M.place_spawn(rows, w, h, legend)
	for x = 2, math.min(w, 40) do
		for y = h, 2, -1 do
			if char_solid(rows, x, y, legend) and clear_above(rows, x, y, 3, legend) then
				return x, y - 1
			end
		end
	end
	-- broader search
	for x = 2, w do
		for y = h, 2, -1 do
			if char_solid(rows, x, y, legend) and clear_above(rows, x, y, 2, legend) then
				return x, y - 1
			end
		end
	end
	return 3, h - 1
end

function M.place_flag(rows, w, h, legend)
	-- Flag entity sits ON the solid block (official smb: 78×11).
	for x = w - 2, 2, -1 do
		for y = h, 2, -1 do
			if char_solid(rows, x, y, legend) and clear_above(rows, x, y, 4, legend) then
				return x, y
			end
		end
	end
	return math.max(2, w - 3), h - 1
end

------------------------------------------------------------------------
-- Convert grid → cells
------------------------------------------------------------------------

local function make_cell(tile, opts)
	local cell = { tile }
	if opts then
		if opts.entity then
			cell[2] = opts.entity
			if opts.spawn_args then
				for i = 1, #opts.spawn_args do
					cell[#cell + 1] = opts.spawn_args[i]
				end
			end
		elseif opts.enemy then
			cell[2] = opts.enemy
		end
	end
	return cell
end

function M.convert_rows(rows, w, h, legend, level_ctx)
	local coinmap = {}
	local cells = {}
	for x = 1, w do
		cells[x] = {}
		coinmap[x] = {}
		for y = 1, h do
			cells[x][y] = { T.EMPTY }
			coinmap[x][y] = false
		end
	end

	local pipe_mask = {} -- [x][y] = true if handled by pipe detector
	for x = 1, w do
		pipe_mask[x] = {}
	end

	local pipes = {}
	if legend.pipes == "pP" then
		pipes = M.detect_pipes(rows, w, h)
		for i = 1, #pipes do
			local p = pipes[i]
			for y = p.top, p.bottom do
				pipe_mask[p.x][y] = true
				pipe_mask[p.x + 1][y] = true
				if y == p.top then
					cells[p.x][y] = { T.PIPE_TL }
					cells[p.x + 1][y] = { T.PIPE_TR }
				else
					cells[p.x][y] = { T.PIPE_L }
					cells[p.x + 1][y] = { T.PIPE_R }
				end
			end
		end
	end

	local enemy_index = 0
	for y = 1, h do
		for x = 1, w do
			if pipe_mask[x][y] then
				-- already set
			else
				local ch = rows[y]:sub(x, x)
				if ch == "p" or ch == "P" then
					-- orphan half-pipe: solid ground fallback
					cells[x][y] = { T.GROUND }
				else
					local entry = legend.map[ch]
					if not entry then
						error(string.format("unknown legend char %q at %d,%d", ch, x, y))
					end
					local opts = nil
					if entry.entity then
						opts = { entity = entry.entity }
					elseif entry.enemy == "auto" then
						enemy_index = enemy_index + 1
						opts = { enemy = M.classify_enemy(rows, x, y, h, level_ctx, enemy_index) }
					elseif entry.enemy then
						opts = { enemy = entry.enemy }
					end
					cells[x][y] = make_cell(entry.tile, opts)
					if entry.coin then
						coinmap[x][y] = true
					end
				end
			end
		end
	end

	local sx, sy = M.place_spawn(rows, w, h, legend)
	local fx, fy = M.place_flag(rows, w, h, legend)
	-- don't overwrite solid under spawn
	cells[sx][sy] = make_cell(T.EMPTY, {
		entity = T.ENT_SPAWN,
		spawn_args = { "true", "false", "false", "false", "false" },
	})
	-- flag on solid (keep tile, add entity)
	local flag_tile = cells[fx][fy][1]
	if flag_tile == T.EMPTY then
		flag_tile = T.HARD
	end
	cells[fx][fy] = { flag_tile, T.ENT_FLAG }

	return cells, coinmap, pipes, sx, sy, fx, fy
end

------------------------------------------------------------------------
-- E: serialize
------------------------------------------------------------------------

local function cell_token(cell, coin)
	local t = tostring(cell[1]) .. (coin and "c" or "")
	if #cell == 1 then
		return t, false
	end
	local parts = { t }
	for i = 2, #cell do
		parts[#parts + 1] = tostring(cell[i])
	end
	return table.concat(parts, LAYER), true
end

function M.count_serialized_cells(body)
	local n = 0
	for token in (body .. BLOCK):gmatch("(.-)" .. BLOCK) do
		local base, mul = token:match("^(.-)" .. MULTIPLY .. "(%d+)$")
		if mul then
			n = n + tonumber(mul)
		elseif token ~= "" then
			n = n + 1
		end
	end
	return n
end

function M.serialize(cells, coinmap, mw, mh)
	local out = {}
	local prev = nil
	local mul = 0
	local layered_prev = false

	local function flush()
		if prev == nil then
			return
		end
		if mul > 1 and not layered_prev then
			out[#out + 1] = prev .. MULTIPLY .. tostring(mul)
		else
			out[#out + 1] = prev
		end
	end

	local total = 0
	for y = 1, mh do
		for x = 1, mw do
			total = total + 1
			local tok, layered = cell_token(cells[x][y], coinmap[x][y])
			if (not layered) and tok == prev and not layered_prev then
				mul = mul + 1
			else
				flush()
				prev = tok
				mul = 1
				layered_prev = layered
			end
		end
	end
	flush()

	local body = table.concat(out, BLOCK)
	local counted = M.count_serialized_cells(body)
	assert(counted == mw * mh,
		string.format("serialize cell count %d != mw*mh %d", counted, mw * mh))
	assert(total == mw * mh)
	return tostring(mh) .. CATEGORY .. body
end

function M.emit_level(cells, coinmap, mw, mh, opts)
	opts = opts or {}
	local body = M.serialize(cells, coinmap, mw, mh)
	local bg = opts.background or { 92, 148, 252 }
	local parts = {
		body,
		"backgroundr" .. EQUAL .. tostring(bg[1]),
		"backgroundg" .. EQUAL .. tostring(bg[2]),
		"backgroundb" .. EQUAL .. tostring(bg[3]),
		"spriteset" .. EQUAL .. tostring(opts.spriteset or 1),
		"music" .. EQUAL .. (opts.music or "overworld.ogg"),
		"timelimit" .. EQUAL .. tostring(opts.timelimit or 400),
		"scrollfactor" .. EQUAL .. "0",
		"fscrollfactor" .. EQUAL .. "0",
	}
	return table.concat(parts, CATEGORY)
end

------------------------------------------------------------------------
-- File emitters
------------------------------------------------------------------------

local function ensure_dir(path)
	os.execute(string.format('mkdir -p "%s"', path))
end

local function write_file(path, contents)
	local f, err = io.open(path, "w")
	if not f then
		error("write: " .. tostring(err))
	end
	f:write(contents)
	f:close()
end

function M.convert_file(src_path, legend, level_ctx)
	local rows, w, h0 = M.read_level(src_path)
	local rows2, h, kept_tall = M.normalize_height(rows, w, legend.height or 15)
	if kept_tall then
		io.stderr:write(string.format(
			"WARN %s: top has content; keeping height %d (not cutting)\n", src_path, h))
	end
	local cells, coinmap, pipes, sx, sy, fx, fy =
		M.convert_rows(rows2, w, h, legend, level_ctx or {})
	local text = M.emit_level(cells, coinmap, w, h, level_ctx)
	return {
		text = text,
		mw = w,
		mh = h,
		pipes = pipes,
		spawn = { sx, sy },
		flag = { fx, fy },
		cells = cells,
		coinmap = coinmap,
		kept_tall = kept_tall,
	}
end

-- Lost Levels: mario_1..16 → 1-1 .. 4-4
function M.smb2_level_name(index)
	local world = math.floor((index - 1) / 4) + 1
	local level = ((index - 1) % 4) + 1
	return string.format("%d-%d", world, level)
end

-- SML: super_mario_land_XY.png.txt → X-Y
function M.smbl_level_name(filename)
	local a, b = filename:match("super_mario_land_(%d)(%d)")
	if not a then
		error("bad smbl name: " .. filename)
	end
	return a .. "-" .. b
end

function M.make_stub_level(mw, mh)
	mw = mw or 40
	mh = mh or 15
	local cells, coinmap = {}, {}
	for x = 1, mw do
		cells[x], coinmap[x] = {}, {}
		for y = 1, mh do
			coinmap[x][y] = false
			if y >= mh - 1 then
				cells[x][y] = { T.GROUND }
			else
				cells[x][y] = { T.EMPTY }
			end
		end
	end
	cells[3][mh - 2] = make_cell(T.EMPTY, {
		entity = T.ENT_SPAWN,
		spawn_args = { "true", "false", "false", "false", "false" },
	})
	cells[mw - 5][mh - 1] = { T.HARD, T.ENT_FLAG }
	return M.emit_level(cells, coinmap, mw, mh, {})
end

function M.import_smbl(src_dir, out_dir)
	ensure_dir(out_dir)
	local processed = src_dir .. "/Processed"
	local list = {}
	local p = io.popen('ls "' .. processed .. '"/*.txt 2>/dev/null | sort')
	for line in p:lines() do
		list[#list + 1] = line
	end
	p:close()

	local results = {}
	for i = 1, #list do
		local path = list[i]
		local base = path:match("([^/]+)$")
		local name = M.smbl_level_name(base)
		local r = M.convert_file(path, M.legend_smb, {
			background = { 92, 148, 252 },
			music = "overworld.ogg",
		})
		write_file(out_dir .. "/" .. name .. ".txt", r.text)
		results[#results + 1] = { name = name, path = path, result = r }
		print(string.format("smbl %s → %s (%dx%d)", base, name, r.mw, r.mh))
	end

	-- Stub 4-1 so nextlevel() can reach 4-2 after world 3.
	local stub = out_dir .. "/4-1.txt"
	if not io.open(stub, "r") then
		write_file(stub, M.make_stub_level(48, 15))
		print("smbl stub 4-1.txt (bridge to 4-2)")
	end

	write_file(out_dir .. "/settings.txt", table.concat({
		"name=super mario land (vglc)",
		"author=nintendo / vglc import",
		"description=SML levels from TheVGLC (incomplete: no 2-3/4-3 shooters). DEFAULT tileset.",
	}, "\n") .. "\n")

	return results
end

function M.import_smb2(src_dir, out_dir)
	ensure_dir(out_dir)
	local processed = src_dir .. "/Processed/WithEnemies"
	local results = {}
	local pipe_sum = 0
	local p_count = 0

	for i = 1, 16 do
		local path = string.format("%s/mario_%d.txt", processed, i)
		local f = assert(io.open(path, "r"))
		local raw = f:read("*a")
		f:close()
		for _ in raw:gmatch("p") do
			p_count = p_count + 1
		end

		local name = M.smb2_level_name(i)
		local r = M.convert_file(path, M.legend_smb2, {
			background = { 92, 148, 252 },
			music = (i % 4 == 0) and "castle.ogg" or "overworld.ogg",
		})
		pipe_sum = pipe_sum + M.pipe_height_sum(r.pipes)
		write_file(out_dir .. "/" .. name .. ".txt", r.text)
		results[#results + 1] = { name = name, path = path, result = r }
		print(string.format("smb2 mario_%d → %s (%dx%d, pipes=%d)",
			i, name, r.mw, r.mh, #r.pipes))
	end

	assert(p_count == 324, "smb2 p count expected 324, got " .. tostring(p_count))
	assert(pipe_sum == 324,
		string.format("smb2 pipe height sum expected 324, got %d (p_count=%d)", pipe_sum, p_count))

	write_file(out_dir .. "/settings.txt", table.concat({
		"name=super mario bros. 2 japan / lost levels (vglc)",
		"author=nintendo / vglc import",
		"description=SMB2J (Lost Levels) from TheVGLC WithEnemies. DEFAULT tileset. Pipes are solid decor.",
	}, "\n") .. "\n")

	return results, pipe_sum, p_count
end

return M
