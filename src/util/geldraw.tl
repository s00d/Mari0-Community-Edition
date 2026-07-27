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

global function init_map_cell_gels(cell: MapCell)
	cell.gels = {}
	cell.gelSides = {}
end

global function map_cell_set_gel(cell: MapCell, side: integer, gelId: number)
	local gels = cell.gels
	if gels == nil then
		gels = {}
		cell.gels = gels
	end
	local sides = cell.gelSides
	if sides == nil then
		sides = {}
		cell.gelSides = sides
	end
	gels[GEL_SIDE_KEY[side] as string] = gelId
	sides[side] = gelId
end

global function map_cell_gel_id(cell: MapCell, side: integer): number|nil
	local sides = cell.gelSides
	if sides ~= nil then
		return sides[side] as number|nil
	end
	local gels = cell.gels
	if gels == nil then
		return nil
	end
	return gels[GEL_SIDE_KEY[side] as string] as number|nil
end

global function draw_tile_gel_overlays(gelSides: {number}, drawx: number, drawy: number, ox: number, oy: number)
	local pivotx = ox
	local pivoty = oy
	local imgs = gelgroundimgs
	for side = 1, 4 do
		local gid = gelSides[side]
		if gid then
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
	if gid then
		love.graphics.draw(imgs[gid as integer], drawx, drawy, GEL_ROT[1], scale, scale, pivotx, pivoty)
	end
	gid = gels.right
	if gid then
		love.graphics.draw(imgs[gid as integer], drawx, drawy, GEL_ROT[2], scale, scale, pivotx, pivoty)
	end
	gid = gels.bottom
	if gid then
		love.graphics.draw(imgs[gid as integer], drawx, drawy, GEL_ROT[3], scale, scale, pivotx, pivoty)
	end
	gid = gels.left
	if gid then
		love.graphics.draw(imgs[gid as integer], drawx, drawy, GEL_ROT[4], scale, scale, pivotx, pivoty)
	end
end

return {
	draw_tile_gel_overlays = draw_tile_gel_overlays,
	draw_entity_gel_overlays = draw_entity_gel_overlays,
	map_cell_set_gel = map_cell_set_gel,
	map_cell_gel_id = map_cell_gel_id,
	init_map_cell_gels = init_map_cell_gels,
}
