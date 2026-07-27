--[[ Endless Spelunky-style room stitcher (fixed arena, no streaming).
     Pure logic + optional love.filesystem room load. Separate RNG per seed.
     # ponytail: no mapminx/mapminy streaming yet — add when arenas exceed fixed stitch size. ]]

require "core.stringutil"
require "app.variables"
require "world.levelio"
require "world.endless_enemies"

local ROOM_W: integer = 16
local ROOM_H: integer = 15
local DEFAULT_COLS: integer = 10
local DEFAULT_ROWS: integer = 16

local ENEMY_SWAP: {string:{string}} = {
	goomba = {"goomba", "koopa", "goomba"},
	koopa = {"koopa", "goomba", "koopa"},
}

local function new_exits(): {string:boolean}
	return {l = false, r = false, u = false, d = false}
end

local function exits_from_suffix(s: string): {string:boolean}|nil
	if not s:match("^[lrud]+$") then
		return nil
	end
	local e = new_exits()
	if s:find("l", 1, true) then e.l = true end
	if s:find("r", 1, true) then e.r = true end
	if s:find("u", 1, true) then e.u = true end
	if s:find("d", 1, true) then e.d = true end
	return e
end

local function has_required(have: {string:boolean}, need: {string:boolean}): boolean
	if need.l and not have.l then return false end
	if need.r and not have.r then return false end
	if need.u and not have.u then return false end
	if need.d and not have.d then return false end
	return true
end

local function exit_count(e: {string:boolean}): integer
	local n = 0
	if e.l then n = n + 1 end
	if e.r then n = n + 1 end
	if e.u then n = n + 1 end
	if e.d then n = n + 1 end
	return n
end

global function endless_parse_room_name(filename: string): string, {string:boolean}, string
	local base = filename:match("([^/\\]+)%.txt$") or filename
	base = base:match("([^/\\]+)$") or base
	local parts: {string} = {}
	for p in base:gmatch("[^_]+") do
		parts[#parts + 1] = p
	end
	local exits = new_exits()
	if #parts > 0 then
		local maybe = exits_from_suffix(parts[#parts])
		if maybe then
			exits = maybe
			parts[#parts] = nil
		end
	end
	local tag = table.concat(parts, "_")
	if tag == "" then
		tag = base
	end
	local kind = "normal"
	if tag == "start" or tag:match("^start") then
		kind = "start"
	elseif tag == "end" or tag:match("^end") then
		kind = "end"
	elseif tag == "filler" then
		kind = "filler"
	end
	return base, exits, kind
end

global function endless_copy_cell(cell: MapCell): MapCell
	local c: MapCell = {}
	for i = 1, #cell do
		c[i] = cell[i]
	end
	return c
end

local function rng_random(rng: {any:any}, a: number|nil, b: number|nil): number
	local fn = rng["random"] as function({any:any}, number|nil, number|nil): number
	return fn(rng, a, b)
end

local function make_fallback_rng(seed: number): {any:any}
	local state = math.floor(seed) % 2147483647
	if state <= 0 then
		state = 1
	end
	local rng: {any:any} = {}
	rng.random = function(_: {any:any}, a: number|nil, b: number|nil): number
		state = (1103515245 * state + 12345) % 2147483648
		local u = state / 2147483648
		if a == nil then
			return u
		end
		if b == nil then
			return 1 + math.floor(u * a)
		end
		return a + math.floor(u * (b - a + 1))
	end
	return rng
end

global function endless_new_rng(seed: number): {any:any}
	local love_mod = rawget(_G, "love") as {any:any}|nil
	if love_mod ~= nil then
		local lm = love_mod as {any:any}
		local math_mod = lm["math"] as {any:any}|nil
		if math_mod ~= nil then
			local mm = math_mod as {any:any}
			local nrg = mm["newRandomGenerator"]
			if nrg then
				return (nrg as function(number): {any:any})(seed)
			end
		end
	end
	return make_fallback_rng(seed)
end

global function endless_room_from_text(name: string, text: string): {any:any}|nil
	local parsed, err = level_parse_tiles_only(text)
	if not parsed then
		print("endless room parse fail " .. name .. ": " .. tostring(err))
		return nil
	end
	local p = parsed as LevelTilesParse
	local _, exits, kind = endless_parse_room_name(name)
	return {
		name = name,
		kind = kind,
		exits = exits,
		map = p.map,
		coinmap = p.coinmap,
		mapwidth = p.mapwidth,
		mapheight = p.mapheight,
	}
end

global function endless_load_templates_from_dir(dir: string, read_file: function(string): (string|nil), names: {string}|nil): {{any:any}}
	local list: {string} = names or {}
	if not names then
		local love_mod = rawget(_G, "love") as {any:any}|nil
		if love_mod ~= nil then
			local lm = love_mod as {any:any}
			local fs = lm["filesystem"] as {any:any}|nil
			if fs ~= nil then
				local fstab = fs as {any:any}
				local gdi = fstab["getDirectoryItems"]
				if gdi then
					list = (gdi as function(string): {string})(dir)
				end
			end
		end
	end
	local templates: {{any:any}} = {}
	for i = 1, #list do
		local fname = list[i]
		if fname:match("%.txt$") then
			local text = read_file(dir .. "/" .. fname)
			if text then
				local tmpl = endless_room_from_text(fname:gsub("%.txt$", ""), text)
				if tmpl then
					templates[#templates + 1] = tmpl
				end
			end
		end
	end
	return templates
end

global function endless_load_templates(dir: string, read_file: function(string): (string|nil), list_names: {string}): {{any:any}}
	return endless_load_templates_from_dir(dir, read_file, list_names)
end

local function kind_matches(t: {any:any}, kind: string): boolean
	if kind == "start" or kind == "end" then
		return t.kind == kind
	end
	if kind == "filler" then
		return t.kind == "filler"
	end
	return t.kind == "normal"
end

local function pick_template(templates: {{any:any}}, need: {string:boolean}, kind: string, rng: {any:any}): {any:any}|nil
	local exact: {{any:any}} = {}
	local ok: {{any:any}} = {}
	local fallback: {any:any}|nil = nil
	for i = 1, #templates do
		local t = templates[i]
		if t.name == "room_lrud" then
			fallback = t
		end
		if kind_matches(t, kind) and has_required(t.exits as {string:boolean}, need) then
			ok[#ok + 1] = t
			if exit_count(t.exits as {string:boolean}) == exit_count(need) then
				exact[#exact + 1] = t
			end
		end
	end
	local pool = (#exact > 0) and exact or ok
	if #pool == 0 then
		return fallback
	end
	return pool[math.floor(rng_random(rng, 1, #pool))]
end

local function random_walk(rng: {any:any}, cols: integer, rows: integer): {{{any:any}}}, {{number}}, {number}, {number}
	local grid: {{{any:any}}} = {}
	for cx = 1, cols do
		grid[cx] = {}
		for cy = 1, rows do
			grid[cx][cy] = {on_path = false, exits = new_exits(), template = nil}
		end
	end

	local cx = math.floor(rng_random(rng, 1, cols))
	local cy = 1
	local startc, startr = cx, cy
	grid[cx][cy].on_path = true
	local path: {{number}} = {{cx, cy}}

	if cy < rows then
		local first: {string} = {"down"}
		if cx < cols then first[#first + 1] = "right" end
		local pick = first[math.floor(rng_random(rng, 1, #first))]
		local cell = grid[cx][cy]
		local exits = cell.exits as {string:boolean}
		if pick == "right" then
			exits.r = true
			cx = cx + 1
			(grid[cx][cy].exits as {string:boolean}).l = true
		else
			exits.d = true
			cy = cy + 1
			(grid[cx][cy].exits as {string:boolean}).u = true
		end
		grid[cx][cy].on_path = true
		path[#path + 1] = {cx, cy}
	end

	while cy < rows do
		local choices: {string} = {"down"}
		if cx > 1 then choices[#choices + 1] = "left" end
		if cx < cols then choices[#choices + 1] = "right" end
		choices[#choices + 1] = "down"
		local pick = choices[math.floor(rng_random(rng, 1, #choices))]
		local cell = grid[cx][cy]
		local exits = cell.exits as {string:boolean}
		if pick == "left" then
			exits.l = true
			cx = cx - 1
			(grid[cx][cy].exits as {string:boolean}).r = true
		elseif pick == "right" then
			exits.r = true
			cx = cx + 1
			(grid[cx][cy].exits as {string:boolean}).l = true
		else
			exits.d = true
			cy = cy + 1
			(grid[cx][cy].exits as {string:boolean}).u = true
		end
		grid[cx][cy].on_path = true
		path[#path + 1] = {cx, cy}
	end

	return grid, path, {startc, startr}, {cx, cy}
end

local function maybe_swap_enemy(cell: MapCell, rng: {any:any})
	if #cell < 2 then
		return
	end
	local e = cell[2]
	if type(e) == "string" then
		local opts = ENEMY_SWAP[e as string]
		if opts then
			cell[2] = opts[math.floor(rng_random(rng, 1, #opts))]
		end
	end
end

global function endless_stitch(grid: {{{any:any}}}, room_w: integer, room_h: integer, rng: {any:any}|nil): {number:{number:MapCell}}, {number:{number:boolean}}, number, number
	local cols = #grid
	local rows = #grid[1]
	local mw = cols * room_w
	local mh = rows * room_h
	local map: {number:{number:MapCell}} = {}
	local coinmap: {number:{number:boolean}} = {}
	for x = 1, mw do
		map[x] = {}
		coinmap[x] = {}
	end

	for cy = 1, rows do
		for cx = 1, cols do
			local cell = grid[cx][cy]
			local tmpl = cell.template as {any:any}
			assert(tmpl, "missing room template at " .. cx .. "," .. cy)
			local ox = (cx - 1) * room_w
			local oy = (cy - 1) * room_h
			local tmap = tmpl.map as {number:{number:MapCell}}
			local tcoin = tmpl.coinmap as {number:{number:boolean}}
			for ly = 1, room_h do
				for lx = 1, room_w do
					local copied = endless_copy_cell(tmap[lx][ly])
					if rng then
						maybe_swap_enemy(copied, rng)
					end
					map[ox + lx][oy + ly] = copied
					coinmap[ox + lx][oy + ly] = tcoin[lx][ly] and true or false
				end
			end
		end
	end
	return map, coinmap, mw, mh
end

global function endless_assign_rooms(grid: {{{any:any}}}, templates: {{any:any}}, start_pos: {number}, end_pos: {number}, rng: {any:any})
	local cols = #grid
	local rows = #grid[1]
	for cy = 1, rows do
		for cx = 1, cols do
			local cell = grid[cx][cy]
			local kind = "normal"
			if cx == start_pos[1] and cy == start_pos[2] then
				kind = "start"
			elseif cx == end_pos[1] and cy == end_pos[2] then
				kind = "end"
			elseif not cell.on_path then
				kind = "filler"
				local exits = cell.exits as {string:boolean}
				if cx > 1 and (grid[cx - 1][cy].exits as {string:boolean}).r then exits.l = true end
				if cx < cols and (grid[cx + 1][cy].exits as {string:boolean}).l then exits.r = true end
				if cy > 1 and (grid[cx][cy - 1].exits as {string:boolean}).d then exits.u = true end
				if cy < rows and (grid[cx][cy + 1].exits as {string:boolean}).u then exits.d = true end
				if exit_count(exits) == 0 then
					kind = "filler"
				else
					kind = "normal"
				end
			end
			local tmpl = pick_template(templates, cell.exits as {string:boolean}, kind, rng)
			if not tmpl then
				tmpl = pick_template(templates, cell.exits as {string:boolean}, "normal", rng)
			end
			assert(tmpl, "no room template for " .. cx .. "," .. cy)
			cell.template = tmpl
		end
	end
end

global function endless_generate(seed: number, templates: {{any:any}}, opts: {any:any}|nil): {any:any}
	assert(#templates > 0, "endless: no room templates")
	local o: {any:any}
	if opts then
		o = opts
	else
		o = {}
	end
	local cols = (o["cols"] as integer) or DEFAULT_COLS
	local rows = (o["rows"] as integer) or DEFAULT_ROWS
	local room_w = (o["room_w"] as integer) or ROOM_W
	local room_h = (o["room_h"] as integer) or ROOM_H
	local rng = endless_new_rng(seed)

	local grid, path, start_pos, end_pos = random_walk(rng, cols, rows)
	endless_assign_rooms(grid, templates, start_pos, end_pos, rng)
	local map, coinmap, mw, mh = endless_stitch(grid, room_w, room_h, rng)

	-- budget-populate unique enemies per room (deterministic)
	local pc = (players as number) or 1
	for cy = 1, rows do
		for cx = 1, cols do
			local cell = grid[cx][cy]
			local tmpl = cell.template as {any:any}
			local kind = endless_room_kind_from_name((tmpl.name as string) or "room")
			local depth = cy
			local ox = (cx - 1) * room_w
			local oy = (cy - 1) * room_h
			endless_populate(map, ox, oy, room_w, room_h, kind, depth, rng, pc)
		end
	end

	local body = level_serialize_maptiles(map, coinmap, mw, mh, 1)
	local cd = CATEGORYDELIMITER[1]
	local eq = EQUALSIGN[1]
	local level_text = tostring(mh) .. cd .. body
		.. cd .. "backgroundr" .. eq .. "92"
		.. cd .. "backgroundg" .. eq .. "148"
		.. cd .. "backgroundb" .. eq .. "252"
		.. cd .. "spriteset" .. eq .. "1"
		.. cd .. "music" .. eq .. "overworld.ogg"
		.. cd .. "timelimit" .. eq .. "500"
		.. cd .. "scrollfactor" .. eq .. "0"
		.. cd .. "fscrollfactor" .. eq .. "0"

	return {
		seed = seed,
		map = map,
		coinmap = coinmap,
		mapwidth = mw,
		mapheight = mh,
		cols = cols,
		rows = rows,
		path = path,
		start_room = start_pos,
		end_room = end_pos,
		level_text = level_text,
	}
end

global function endless_path_connected(path: {{number}}): boolean
	if #path < 2 then
		return #path == 1
	end
	for i = 2, #path do
		local a, b = path[i - 1], path[i]
		local dx = math.abs(a[1] - b[1])
		local dy = math.abs(a[2] - b[2])
		if not ((dx == 1 and dy == 0) or (dx == 0 and dy == 1)) then
			return false
		end
	end
	return true
end

global function endless_no_deadlock(path: {{number}}, rows: integer): boolean
	if #path == 0 then
		return false
	end
	return path[#path][2] == rows
end

local template_cache: {string:{{any:any}}} = {}

global function endless_get_templates(mappack_name: string): {{any:any}}
	local dir = mappack_path(mappack_name) .. "/rooms"
	if template_cache[dir] then
		return template_cache[dir]
	end
	local function read_file(path: string): string|nil
		local love_mod = rawget(_G, "love") as {any:any}|nil
		if love_mod ~= nil then
			local lm = love_mod as {any:any}
			local fs = lm["filesystem"] as {any:any}|nil
			if fs ~= nil then
				local fstab = fs as {any:any}
				local get_info = fstab["getInfo"] as function(string): {any:any}|nil
				local read = fstab["read"] as function(string): string
				if get_info and get_info(path) then
					return read(path)
				end
			end
		end
		local f = io.open(path, "r")
		if not f then
			return nil
		end
		local s = f:read("*a")
		f:close()
		return s
	end
	local templates = endless_load_templates_from_dir(dir, read_file, nil)
	template_cache[dir] = templates
	return templates
end

global function endless_generate_for_mappack(mappack_name: string, seed: number|nil): {any:any}
	local s = seed
	if not s then
		s = math.floor((os.time() % 1000000) + (os.clock() * 1000))
	end
	local templates = endless_get_templates(mappack_name)
	return endless_generate(s as number, templates, nil)
end

return {
	ROOM_W = ROOM_W,
	ROOM_H = ROOM_H,
	DEFAULT_COLS = DEFAULT_COLS,
	DEFAULT_ROWS = DEFAULT_ROWS,
}
