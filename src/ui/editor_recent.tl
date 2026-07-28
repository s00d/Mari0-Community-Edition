--[[ Recent tiles + category filter for registry palettes. ]]

global EDITOR_RECENT_TILES: {integer} = {}
global EDITOR_RECENT_MAX: integer = 12
global EDITOR_PALETTE_CATEGORY: string = "all"

global function editor_recent_push(tile_id: integer)
	if not tile_id or tile_id < 1 then return end
	local tid = math.floor(tile_id) as integer
	local out: {integer} = { tid }
	for i = 1, #EDITOR_RECENT_TILES do
		local v = EDITOR_RECENT_TILES[i]
		if v ~= tid and #out < EDITOR_RECENT_MAX then
			out[#out + 1] = v
		end
	end
	EDITOR_RECENT_TILES = out
end

global function editor_recent_list(): {integer}
	return EDITOR_RECENT_TILES
end

global function palette_entity_categories(p: any): {string}
	local seen: {string:boolean} = {}
	local out: {string} = { "all" }
	local ents = (p as EditorPalettes).entities
	if not ents then return out end
	for i = 1, #ents do
		local e = ents[i] as {string:any}
		local c = tostring(e.category or "misc")
		if not seen[c] then
			seen[c] = true
			out[#out + 1] = c
		end
	end
	table.sort(out, function(a: string, b: string): boolean
		if a == "all" then return true end
		if b == "all" then return false end
		return a < b
	end)
	return out
end

global function palette_entities_filtered(p: any, category: string|nil): {any}
	local cat = category or EDITOR_PALETTE_CATEGORY
	local ents = (p as EditorPalettes).entities
	local out: {any} = {}
	if not ents then return out end
	for i = 1, #ents do
		local e = ents[i] as {string:any}
		if cat == "all" or tostring(e.category or "") == cat then
			out[#out + 1] = e
		end
	end
	return out
end

global function editor_cycle_palette_category(p: any): string
	local cats = palette_entity_categories(p)
	local cur = EDITOR_PALETTE_CATEGORY
	local idx = 1
	for i = 1, #cats do
		if cats[i] == cur then idx = i; break end
	end
	idx = idx % #cats + 1
	EDITOR_PALETTE_CATEGORY = cats[idx]
	return EDITOR_PALETTE_CATEGORY
end
