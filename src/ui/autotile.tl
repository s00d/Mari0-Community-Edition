--[[ Autotile: 4/8-neighbor bitmask + paint helpers. ]]

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
				for part in string.gmatch(tiles_s, "[^,]+") do
					local n = tonumber((part as string):match("%d+"))
					if n then
						tiles[#tiles + 1] = math.floor(n) as integer
					end
				end
				while #tiles < 16 do
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
	local n = in_group(g, x, y - 1) and 1 or 0
	local e = in_group(g, x + 1, y) and 1 or 0
	local s = in_group(g, x, y + 1) and 1 or 0
	local w = in_group(g, x - 1, y) and 1 or 0
	return math.floor(n + e * 2 + s * 4 + w * 8) as integer
end

global function autotile_pick(g: AutotileGroup, mask: integer): integer
	local i = (mask % 16) + 1
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
