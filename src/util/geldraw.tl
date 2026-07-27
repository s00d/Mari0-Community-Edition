-- Tile gel overlay drawing (hot path: direct side lookup, no nested loops).

local GEL_ROT: {number} = {0, math.pi / 2, math.pi, math.pi * 1.5}

global function draw_tile_gel_overlays(gels: {string:any}, drawx: number, drawy: number, ox?: number, oy?: number)
	local pivotx = ox or 8
	local pivoty = oy or 8
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
}
