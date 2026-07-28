--[[ Autotile: 4/8-neighbor bitmask + paint helpers.
     mode=4 → 16 tiles (N=1 E=2 S=4 W=8).
     mode=8 → blob (47 unique) with diagonal cull; table may be 16 or 256. ]]

global AUTOTILE_GROUPS: {string:AutotileGroup} = {}
global AUTOTILE_BY_TILE: {integer:string} = {}
global autotile_enabled: boolean = true

local function copy_set(tiles: {integer}): {integer:boolean}
	local s: {integer:boolean} = {}
	for i = 1, #tiles do
		s[tiles[i]] = true
	end
	return s
end

-- Parse "name=mode:t0,t1,..." or "name=mode:0=t¤1=t¤..."
global function autotile_parse(data: string): {string:AutotileGroup}
	local out: {string:AutotileGroup} = {}
	if not data or #data == 0 then
		return out
	end
	for line in string.gmatch(data, "[^\r\n]+") do
		if string.sub(line, 1, 1) ~= "#" and string.find(line, "=", 1, true) then
			local name, rest = string.match(line, "^%s*([%w_%-]+)%s*=%s*(.+)%s*$")
			if name and rest then
				local mode_s, tiles_s = string.match(rest, "^(%d+)%s*:%s*(.+)$")
				if not mode_s then
					mode_s, tiles_s = "4", rest
				end
				local mode_n = tonumber(mode_s) or 4
				local mode: integer = 4
				if mode_n == 8 then
					mode = 8
				end
				local tiles: {integer} = {}
				local keyed = false
				-- keyed form: 0=1,1=34,... or 0=1¤1=34
				if string.find(tiles_s, "%d+%s*=%s*%d+") then
					keyed = true
					local max_i = (mode == 8) and 255 or 15
					local tmp: {integer:integer} = {}
					for part in string.gmatch(tiles_s, "[^,¤×]+") do
						local k, v = string.match(part, "(%d+)%s*=%s*(%d+)")
						if k and v then
							tmp[tonumber(k) as integer] = tonumber(v) as integer
						end
					end
					for i = 0, max_i do
						tiles[#tiles + 1] = tmp[i as integer] or tmp[0] or 1
					end
				else
					for part in string.gmatch(tiles_s, "[^,]+") do
						local n = tonumber((part as string):match("%d+"))
						if n then
							tiles[#tiles + 1] = math.floor(n) as integer
						end
					end
				end
				local need = (mode == 8 and (#tiles > 16 or keyed)) and 256 or 16
				while #tiles < need do
					tiles[#tiles + 1] = tiles[#tiles] or 1
				end
				out[name] = { name = name, mode = mode, tiles = tiles, set = copy_set(tiles) }
			end
		end
	end
	return out
end

global function autotile_load_text(data: string)
	AUTOTILE_GROUPS = autotile_parse(data)
	AUTOTILE_BY_TILE = {}
	local names: {string} = {}
	for name in pairs(AUTOTILE_GROUPS) do
		names[#names + 1] = name
	end
	table.sort(names)
	for i = 1, #names do
		local g = AUTOTILE_GROUPS[names[i]]
		for j = 1, #g.tiles do
			local tid = g.tiles[j]
			if not AUTOTILE_BY_TILE[tid] then
				AUTOTILE_BY_TILE[tid] = g.name
			end
		end
	end
end

global function autotile_load_mappack(pack: string|nil)
	AUTOTILE_GROUPS = {}
	AUTOTILE_BY_TILE = {}
	local mp = pack or mappack
	if not mp then
		return
	end
	local base = mappack_path(mp)
	local path = base .. "/autotile.txt"
	if love.filesystem.getInfo(path) then
		local data = love.filesystem.read(path)
		if data then
			autotile_load_text(data as string)
		end
	end
end

local function in_group(g: AutotileGroup, x: number, y: number): boolean
	if not inmap(x, y) then
		return false
	end
	local tid = map[x][y][1] as integer
	return g.set[tid] == true
end

global function autotile_mask(x: number, y: number, g: AutotileGroup): integer
	if g.mode == 8 then
		-- N E NE S SE W SW NW bits: 1,4,2,16,8,64,32,128 (Wang blob order)
		local n = in_group(g, x, y - 1)
		local e = in_group(g, x + 1, y)
		local s = in_group(g, x, y + 1)
		local w = in_group(g, x - 1, y)
		local ne = in_group(g, x + 1, y - 1)
		local se = in_group(g, x + 1, y + 1)
		local sw = in_group(g, x - 1, y + 1)
		local nw = in_group(g, x - 1, y - 1)
		-- Edges first; diagonals only if both adjacent edges set (blob cull)
		local m = 0
		if n then m = m + 1 end
		if e then m = m + 4 end
		if s then m = m + 16 end
		if w then m = m + 64 end
		if ne and n and e then m = m + 2 end
		if se and e and s then m = m + 8 end
		if sw and s and w then m = m + 32 end
		if nw and w and n then m = m + 128 end
		return math.floor(m) as integer
	end
	local n = in_group(g, x, y - 1) and 1 or 0
	local e = in_group(g, x + 1, y) and 1 or 0
	local s = in_group(g, x, y + 1) and 1 or 0
	local w = in_group(g, x - 1, y) and 1 or 0
	return math.floor(n + e * 2 + s * 4 + w * 8) as integer
end

global function autotile_pick(g: AutotileGroup, mask: integer): integer
	if g.mode == 8 and #g.tiles >= 256 then
		local i = (mask % 256) + 1
		return g.tiles[i] or g.tiles[1] or 1
	end
	-- mode 4, or compact mode-8 tables: use orthogonal nibble
	local ortho = mask
	if g.mode == 8 then
		local n = (mask % 2)
		local e = math.floor(mask / 4) % 2
		local s = math.floor(mask / 16) % 2
		local w = math.floor(mask / 64) % 2
		ortho = n + e * 2 + s * 4 + w * 8
	end
	local i = (ortho % 16) + 1
	return g.tiles[i] or g.tiles[1] or 1
end

local function set_tile_raw(x: number, y: number, tid: integer)
	if not inmap(x, y) then
		return
	end
	editor_undo_record(x, y)
	map[x][y][1] = tid
	init_map_cell_gels(map[x][y])
end

global function autotile_refresh_cell(x: number, y: number)
	if not inmap(x, y) then
		return
	end
	local tid = map[x][y][1] as integer
	local gname = AUTOTILE_BY_TILE[tid]
	if not gname then
		return
	end
	local g = AUTOTILE_GROUPS[gname]
	if not g then
		return
	end
	local nt = autotile_pick(g, autotile_mask(x, y, g))
	if nt ~= tid then
		set_tile_raw(x, y, nt)
	end
end

global function autotile_around(x: number, y: number)
	if not autotile_enabled then
		return
	end
	autotile_refresh_cell(x, y)
	autotile_refresh_cell(x, y - 1)
	autotile_refresh_cell(x + 1, y)
	autotile_refresh_cell(x, y + 1)
	autotile_refresh_cell(x - 1, y)
	autotile_refresh_cell(x + 1, y - 1)
	autotile_refresh_cell(x + 1, y + 1)
	autotile_refresh_cell(x - 1, y + 1)
	autotile_refresh_cell(x - 1, y - 1)
end

-- Refresh a rectangle (paste seams).
global function autotile_region(x0: number, y0: number, x1: number, y1: number)
	if not autotile_enabled then
		return
	end
	local xa = math.min(x0, x1) - 1
	local xb = math.max(x0, x1) + 1
	local ya = math.min(y0, y1) - 1
	local yb = math.max(y0, y1) + 1
	for x = xa, xb do
		for y = ya, yb do
			autotile_refresh_cell(x, y)
		end
	end
end

global function autotile_paint(x: number, y: number, tile_id: integer, raw_mode: boolean): boolean
	if raw_mode or not autotile_enabled then
		return false
	end
	local gname = AUTOTILE_BY_TILE[tile_id]
	if not gname then
		return false
	end
	local g = AUTOTILE_GROUPS[gname]
	if not g then
		return false
	end
	set_tile_raw(x, y, g.tiles[1])
	autotile_around(x, y)
	return true
end

global function autotile_group_for_tile(tile_id: integer): AutotileGroup|nil
	local gname = AUTOTILE_BY_TILE[tile_id]
	if not gname then
		return nil
	end
	return AUTOTILE_GROUPS[gname]
end
