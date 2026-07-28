--[[ Unified context drag: move / paint / select / resize (no tool modes). ]]

global record EditorDragState
	kind: string
	ox: number
	oy: number
	from_x: number
	from_y: number
	to_x: number
	to_y: number
	started: boolean
	handle: string|nil
	ent_t: string|nil
end

global EDITOR_DRAG: EditorDragState|nil = nil
global EDITOR_DRAG_THRESHOLD: number = 4

local RESIZABLE: {string:string} = {
	pipe = "vh",
	emance = "vh",
	emancipationgrill = "vh",
	platform = "h",
	lightbridge = "vh",
	scaffold = "h",
}

local function cell_entity_type(cox: number, coy: number): string|nil
	if not inmap(cox, coy) then return nil end
	local c = map[cox][coy]
	if not c or not c[2] then return nil end
	if type(c[2]) == "string" then return c[2] as string end
	if entitylist and type(c[2]) == "number" then
		local e = entitylist[c[2] as integer]
		if e then return e.t end
	end
	return nil
end

local function has_entity(cox: number, coy: number): boolean
	return cell_entity_type(cox, coy) ~= nil
end

local function resize_handle_at(cox: number, coy: number): string|nil
	local t = cell_entity_type(cox, coy)
	if not t then return nil end
	local ax = RESIZABLE[t]
	if not ax then return nil end
	-- For map cells, size often lives in args; treat single-cell + neighbor empties as edges
	-- Prefer: if brush inactive and click on entity, move; resize when holding shift
	if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
		if ax:find("h", 1, true) then return "e" end
		if ax:find("v", 1, true) then return "s" end
	end
	return nil
end

local function move_entity_cell(fx: number, fy: number, tx: number, ty: number)
	if not inmap(fx, fy) or not inmap(tx, ty) then return end
	if fx == tx and fy == ty then return end
	editor_undo_record(fx, fy)
	editor_undo_record(tx, ty)
	local src = map[fx][fy]
	local dst = map[tx][ty]
	-- swap entity slots (keep destination tile art)
	local tile_dst = dst[1]
	local copy: {any} = {}
	for i = 1, #src do copy[i] = src[i] end
	for i = 2, #src do src[i] = nil end
	dst[1] = tile_dst
	for i = 2, #copy do dst[i] = copy[i] end
end

local function bump_size_arg(cox: number, coy: number, handle: string, nx: number, ny: number)
	local c = map[cox][coy]
	if not c then return end
	editor_undo_record(cox, coy)
	local sz = tonumber(c[3] as any) or 2
	if handle == "e" or handle == "w" then
		local dx = math.abs(nx - cox) + 1
		c[3] = math.max(1, dx)
	elseif handle == "s" or handle == "n" then
		local dy = math.abs(ny - coy) + 1
		c[3] = math.max(1, dy)
	else
		c[3] = sz
	end
end

global function editor_drag_begin(mx: number, my: number, palette_active: boolean)
	local cox, coy = getMouseTile(mx, my + 8 * scale)
	if not inmap(cox, coy) then
		EDITOR_DRAG = nil
		return
	end
	local h = resize_handle_at(cox, coy)
	if h and has_entity(cox, coy) then
		editor_undo_begin()
		EDITOR_DRAG = {
			kind = "resize", ox = mx, oy = my, from_x = cox, from_y = coy,
			to_x = cox, to_y = coy, started = false, handle = h, ent_t = cell_entity_type(cox, coy),
		}
		return
	end
	if has_entity(cox, coy) and not palette_active and not editentities then
		-- clicking entity while in tile mode → move
		editor_undo_begin()
		EDITOR_DRAG = {
			kind = "move", ox = mx, oy = my, from_x = cox, from_y = coy,
			to_x = cox, to_y = coy, started = false, handle = nil, ent_t = cell_entity_type(cox, coy),
		}
		return
	end
	if has_entity(cox, coy) and editentities and not love.keyboard.isDown("lalt") then
		editor_undo_begin()
		EDITOR_DRAG = {
			kind = "move", ox = mx, oy = my, from_x = cox, from_y = coy,
			to_x = cox, to_y = coy, started = false, handle = nil, ent_t = cell_entity_type(cox, coy),
		}
		return
	end
	if palette_active or (not editentities) or editentities then
		editor_undo_begin()
		EDITOR_DRAG = {
			kind = "paint", ox = mx, oy = my, from_x = cox, from_y = coy,
			to_x = cox, to_y = coy, started = false, handle = nil, ent_t = nil,
		}
		return
	end
	EDITOR_DRAG = {
		kind = "select", ox = mx, oy = my, from_x = cox, from_y = coy,
		to_x = cox, to_y = coy, started = true, handle = nil, ent_t = nil,
	}
end

global function editor_drag_move(mx: number, my: number): boolean
	if EDITOR_DRAG == nil then return false end
	local d = EDITOR_DRAG as EditorDragState
	local cox, coy = getMouseTile(mx, my + 8 * scale)
	if d.kind == "paint" then
		if not d.started then
			if (math.abs(mx - d.ox) as number) + (math.abs(my - d.oy) as number) < EDITOR_DRAG_THRESHOLD then
				return true
			end
			d.started = true
		end
		if inmap(cox, coy) and (cox ~= d.to_x or coy ~= d.to_y) then
			d.to_x, d.to_y = cox, coy
			placetile(mx, my)
		end
		return true
	elseif d.kind == "move" then
		if inmap(cox, coy) and (cox ~= d.to_x or coy ~= d.to_y) then
			move_entity_cell(d.to_x, d.to_y, cox, coy)
			d.to_x, d.to_y = cox, coy
		end
		return true
	elseif d.kind == "resize" and d.handle then
		if inmap(cox, coy) then
			bump_size_arg(d.from_x, d.from_y, d.handle as string, cox, coy)
			d.to_x, d.to_y = cox, coy
		end
		return true
	elseif d.kind == "select" then
		d.to_x, d.to_y = cox, coy
		return true
	end
	return false
end

global function editor_drag_end(_mx: number, _my: number)
	if EDITOR_DRAG == nil then return end
	local d = EDITOR_DRAG as EditorDragState
	if d.kind == "paint" or d.kind == "move" or d.kind == "resize" then
		editor_undo_commit()
	elseif d.kind == "select" then
		-- existing selection tool can pick up from coords if needed
	end
	EDITOR_DRAG = nil
end

global function editor_drag_active(): boolean
	return EDITOR_DRAG ~= nil
end
