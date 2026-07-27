-- Tile gel overlay drawing and numeric gelSides helpers (hot path: no string keys).

local GEL_ROT: {number} = {0, math.pi / 2, math.pi, math.pi * 1.5}
local GEL_SIDE_KEY: {string} = {"top", "right", "bottom", "left"}

global GEL_SIDE_TOP: integer = 1
global GEL_SIDE_RIGHT: integer = 2
global GEL_SIDE_BOTTOM: integer = 3
global GEL_SIDE_LEFT: integer = 4

global GEL_SIDE_BY_NAME = {
	top = 1,
	right = 2,
	bottom = 3,
	left = 4,
} as {string:integer}

-- Leave nil until a gel is painted (empty {} is truthy → draw loop every tile).
global function init_map_cell_gels(cell: MapCell)
	cell.gels = nil
	cell.gelSides = nil
end

local function sides_empty(sides: {number:number}): boolean
	for i = 1, 4 do
		if sides[i] then
			return false
		end
	end
	return true
end

global function map_cell_set_gel(cell: MapCell, side: integer, gelId: number)
	if gel_has(gelId, "cleanse") then
		local sidesn = cell.gelSides
		if sidesn ~= nil then
			local sides = sidesn as {number:number}
			sides[side] = nil
			if sides_empty(sides) then
				cell.gelSides = nil
			end
		end
		-- Clear legacy string key if present (read fallback / old cells).
		local gelsn = cell.gels
		if gelsn ~= nil then
			local gels = gelsn as {string:any}
			gels[GEL_SIDE_KEY[side] as string] = nil
		end
		return
	end

	local sidesn = cell.gelSides
	local sides: {number:number}
	if sidesn == nil then
		sides = {}
		cell.gelSides = sides
	else
		sides = sidesn as {number:number}
	end
	sides[side] = gelId
	-- Numeric gelSides only; string gels kept for legacy read fallback / level tooling.
end

global function map_cell_gel_id(cell: MapCell, side: integer): number|nil
	local sidesn = cell.gelSides
	if sidesn ~= nil then
		local sides = sidesn as {number:number}
		return sides[side] as number|nil
	end
	local gelsn = cell.gels
	if gelsn == nil then
		return nil
	end
	local gels = gelsn as {string:any}
	return gels[GEL_SIDE_KEY[side] as string] as number|nil
end

global function entity_set_gel(entity: any, side: integer, gelId: number)
	local ent = entity as {any:any}
	if gel_has(gelId, "cleanse") then
		local sidesn = ent.gelSides as {number:number}|nil
		if sidesn ~= nil then
			local sides = sidesn as {number:number}
			sides[side] = nil
			if sides_empty(sides) then
				ent.gelSides = nil
			end
		end
		local gelsn = ent.gels as {string:any}|nil
		if gelsn ~= nil then
			local gels = gelsn as {string:any}
			gels[GEL_SIDE_KEY[side] as string] = nil
		end
		return
	end

	local sidesn = ent.gelSides as {number:number}|nil
	local sides: {number:number}
	if sidesn == nil then
		sides = {}
		ent.gelSides = sides
	else
		sides = sidesn as {number:number}
	end
	sides[side] = gelId
end

global function entity_gel_id(entity: any, side: integer): number|nil
	local ent = entity as {any:any}
	local sidesn = ent.gelSides as {number:number}|nil
	if sidesn ~= nil then
		local sides = sidesn as {number:number}
		return sides[side] as number|nil
	end
	local gelsn = ent.gels as {string:any}|nil
	if gelsn == nil then
		return nil
	end
	local gels = gelsn as {string:any}
	return gels[GEL_SIDE_KEY[side] as string] as number|nil
end

global function draw_tile_gel_overlays(gelSides: {number}, drawx: number, drawy: number, ox: number, oy: number)
	local pivotx = ox
	local pivoty = oy
	local imgs = gelgroundimgs
	for side = 1, 4 do
		local gid = gelSides[side]
		if gid and imgs[gid as integer] then
			love.graphics.draw(imgs[gid as integer], drawx, drawy, GEL_ROT[side], scale, scale, pivotx, pivoty)
		end
	end
end

-- Legacy entity tables (lightbridgebody) still use string-keyed gels.
global function draw_entity_gel_overlays(gels: {string:any}, drawx: number, drawy: number, ox: number, oy: number)
	local pivotx = ox
	local pivoty = oy
	local imgs = gelgroundimgs
	local gid = gels.top
	if gid and imgs[gid as integer] then
		love.graphics.draw(imgs[gid as integer], drawx, drawy, GEL_ROT[1], scale, scale, pivotx, pivoty)
	end
	gid = gels.right
	if gid and imgs[gid as integer] then
		love.graphics.draw(imgs[gid as integer], drawx, drawy, GEL_ROT[2], scale, scale, pivotx, pivoty)
	end
	gid = gels.bottom
	if gid and imgs[gid as integer] then
		love.graphics.draw(imgs[gid as integer], drawx, drawy, GEL_ROT[3], scale, scale, pivotx, pivoty)
	end
	gid = gels.left
	if gid and imgs[gid as integer] then
		love.graphics.draw(imgs[gid as integer], drawx, drawy, GEL_ROT[4], scale, scale, pivotx, pivoty)
	end
end

return {
	draw_tile_gel_overlays = draw_tile_gel_overlays,
	draw_entity_gel_overlays = draw_entity_gel_overlays,
	map_cell_set_gel = map_cell_set_gel,
	map_cell_gel_id = map_cell_gel_id,
	entity_set_gel = entity_set_gel,
	entity_gel_id = entity_gel_id,
	init_map_cell_gels = init_map_cell_gels,
}
