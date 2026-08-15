--[[ Full-map static tile spritebatches.
     Fill once on load/dirty; scroll only changes draw offset.
     Animated (>10000), coinblock, invisible, bouncing: not batched (drawlevel_tiles). ]]

local record TileSlot
	batch_id: integer
	slot_id: integer
end

local slots: {any: TileSlot} = {}

local BATCH_SMB = 1
local BATCH_PORTAL = 2
local BATCH_CUSTOM = 3
local BATCH_SMB_FRONT = 4
local BATCH_PORTAL_FRONT = 5
local BATCH_CUSTOM_FRONT = 6

local function modcustom_batch_id(tilenumber: number, foreground: boolean): integer|nil
	for i = 1, (modcustomtiles as integer) or 0 do
		if tilenumber <= smbtilecount+portaltilecount+customtilecount+modcustomtilecount[i] then
			if foreground then
				return 50 + i
			end
			return 10 + i
		end
	end
	return nil
end

local function get_batch(batch_id: integer): SpriteBatch
	if batch_id == BATCH_SMB then
		return smbspritebatch
	elseif batch_id == BATCH_PORTAL then
		return portalspritebatch
	elseif batch_id == BATCH_CUSTOM then
		return customspritebatch
	elseif batch_id == BATCH_SMB_FRONT then
		return smbspritebatchfront
	elseif batch_id == BATCH_PORTAL_FRONT then
		return portalspritebatchfront
	elseif batch_id == BATCH_CUSTOM_FRONT then
		return customspritebatchfront
	elseif batch_id >= 10 and batch_id < 50 then
		return modcustomspritebatch[batch_id - 9] as SpriteBatch
	end
	return modcustomspritebatchfront[batch_id - 49] as SpriteBatch
end

local function resolve_tile_batch(tilenumber: number, foreground: boolean): integer, any
	if not foreground then
		if tilenumber <= smbtilecount then
			return BATCH_SMB, tilequads[tilenumber]:quad()
		elseif tilenumber <= smbtilecount+portaltilecount then
			return BATCH_PORTAL, tilequads[tilenumber]:quad()
		elseif tilenumber <= smbtilecount+portaltilecount+customtilecount then
			return BATCH_CUSTOM, tilequads[tilenumber]:quad()
		end
		local mod_id = modcustom_batch_id(tilenumber, false)
		if mod_id then
			return mod_id, tilequads[tilenumber]:quad()
		end
	else
		if tilenumber <= smbtilecount then
			return BATCH_SMB_FRONT, tilequads[tilenumber]:quad()
		elseif tilenumber <= smbtilecount+portaltilecount then
			return BATCH_PORTAL_FRONT, tilequads[tilenumber]:quad()
		elseif tilenumber <= smbtilecount+portaltilecount+customtilecount then
			return BATCH_CUSTOM_FRONT, tilequads[tilenumber]:quad()
		end
		local mod_id = modcustom_batch_id(tilenumber, true)
		if mod_id then
			return mod_id, tilequads[tilenumber]:quad()
		end
	end
	return BATCH_SMB, tilequads[1]:quad()
end

local function map_screen_coords(cox: number, coy: number): number, number
	if level_mapmode then
		return (cox - 1) * 16 * scale, (coy - 1) * 16 * scale
	end
	return (cox - 1) * 16 * scale, ((coy - 1) * 16 - 8) * scale
end

local function clear_slot(key: any)
	local old = slots[key]
	if not old then
		return
	end
	get_batch(old.batch_id):set(old.slot_id, 0, 0, 0, 0, 0)
	slots[key] = nil
end

local function clear_all_batches()
	for key in pairs(slots) do
		slots[key] = nil
	end
	if smbspritebatch then smbspritebatch:clear() end
	if smbspritebatchfront then smbspritebatchfront:clear() end
	if portalspritebatch then portalspritebatch:clear() end
	if portalspritebatchfront then portalspritebatchfront:clear() end
	if customtiles and customspritebatch then
		customspritebatch:clear()
		customspritebatchfront:clear()
	end
	if modcustomtiles and modcustomspritebatch then
		for i = 1, modcustomtiles as number do
			(modcustomspritebatch[i as number] as SpriteBatch):clear()
			(modcustomspritebatchfront[i as number] as SpriteBatch):clear()
		end
	end
end

local function should_batch(cox: number, coy: number, bounce_skip: {any:any}|nil): boolean, integer, boolean
	if not inmap(cox, coy) then
		return false, 0, false
	end
	local skip = bounce_skip
	if skip == nil then
		skip = build_blockbounce_lookup(blockbouncex, blockbouncey) as {any:any}
	end
	local skipmap = skip as {any:any}
	if skipmap[tilekey(cox, coy)] then
		return false, 0, false
	end
	local t = session.map[cox][coy]
	local tilenumber = t[1] as integer
	if tilenumber == nil or tilenumber == 0 then
		return false, 0, false
	end
	if tilequads[tilenumber]:getproperty("invisible", cox, coy) then
		return false, 0, false
	end
	if tilequads[tilenumber]:getproperty("coinblock", cox, coy) then
		return false, 0, false
	end
	if tilenumber > 10000 then
		return false, 0, false
	end
	local fg = tilequads[tilenumber]:getproperty("foreground", cox, coy) and true or false
	return true, tilenumber, fg
end

-- Hide/show one map cell in the static batches.
global function tile_spritebatch_update_tile(cox: number, coy: number)
	if not smbspritebatch then
		return
	end
	local key = tilekey(cox, coy)
	clear_slot(key)
	local ok, tilenumber, foreground = should_batch(cox, coy, nil)
	if not ok then
		return
	end
	local batch_id, quad = resolve_tile_batch(tilenumber, foreground)
	local sx, sy = map_screen_coords(cox, coy)
	local slot_id = get_batch(batch_id):add(quad, sx, sy, 0, scale, scale) as integer
	slots[key] = { batch_id = batch_id, slot_id = slot_id }
end

-- Full-map rebuild (load, scale change, editor mass edits).
global function tile_spritebatch_rebuild()
	if not smbspritebatch or not session or not session.map then
		return
	end
	if rawget(_G, "prof_push") ~= nil then
		(rawget(_G, "prof_push") as function(string))("generatespritebatch")
	end
	clear_all_batches()
	local bounce_skip = build_blockbounce_lookup(blockbouncex, blockbouncey) as {any:any}
	local mw = session.mapwidth as integer
	local mh = session.mapheight as integer
	for x = 1, mw do
		for y = 1, mh do
			local key = tilekey(x, y)
			local ok, tilenumber, foreground = should_batch(x, y, bounce_skip)
			if ok then
				local batch_id, quad = resolve_tile_batch(tilenumber, foreground)
				local sx, sy = map_screen_coords(x, y)
				local slot_id = get_batch(batch_id):add(quad, sx, sy, 0, scale, scale) as integer
				slots[key] = { batch_id = batch_id, slot_id = slot_id }
			end
		end
	end
	if not spritebatchX then
		spritebatchX = {}
	end
	if not spritebatchY then
		spritebatchY = {}
	end
	spritebatchX[1] = math.floor(session.xscroll) as integer
	spritebatchY[1] = math.floor(session.yscroll) as integer
	if rawget(_G, "prof_pop") ~= nil then
		(rawget(_G, "prof_pop") as function(string|nil))("generatespritebatch")
	end
end

-- Draw offset: entire map in batch, camera = -scroll (pixel-snapped).
global function tile_spritebatch_draw_offset(): number, number
	local sc = scale or 1
	return math.floor(-session.xscroll * 16 * sc), math.floor(-session.yscroll * 16 * sc)
end

global function tile_spritebatch_draw_bg()
	local batchx, batchy = tile_spritebatch_draw_offset()
	love.graphics.draw(smbspritebatch, batchx, batchy)
	love.graphics.draw(portalspritebatch, batchx, batchy)
	if customtiles then
		love.graphics.draw(customspritebatch, batchx, batchy)
	end
	if modcustomtiles then
		for i = 1, modcustomtiles do
			love.graphics.draw(modcustomspritebatch[i as integer], batchx, batchy)
		end
	end
end

global function tile_spritebatch_draw_fg()
	local batchx, batchy = tile_spritebatch_draw_offset()
	love.graphics.draw(smbspritebatchfront, batchx, batchy)
	love.graphics.draw(portalspritebatchfront, batchx, batchy)
	if customtiles then
		love.graphics.draw(customspritebatchfront, batchx, batchy)
	end
	if modcustomtiles then
		for i = 1, modcustomtiles do
			love.graphics.draw(modcustomspritebatchfront[i as integer], batchx, batchy)
		end
	end
end
