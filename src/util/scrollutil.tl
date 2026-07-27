-- Ported from root scrollutil.lua (Teal).

-- Camera / scroll coordinate helpers (from game.lua).

-- Pixel offset for tile spritebatches given fractional scroll.
local function scroll_batch_offset(scroll: number, sc: number|nil): number
	sc = sc or scale
	return math.floor(-math.fmod(scroll, 1) * 16 * sc)
end
_G.scroll_batch_offset = scroll_batch_offset


-- Mouse position → map tile (uses globals xscroll/yscroll/scale/yoffset).
local function getMouseTile(x: any, y: any): number, number
	local xout = math.floor(((x as number) + xscroll * 16 * scale) / (16 * scale)) + 1
	local yout = math.floor(((y as number) + yscroll * 16 * scale - yoffset * scale) / (16 * scale)) + 1
	return xout, yout
end
_G.getMouseTile = getMouseTile


local function cameraxpan(target: any, t: any)
	xpan = true
	xpanstart = xscroll
	xpandiff = (target as number) - (xpanstart as number)
	xpantime = t as number
	xpantimer = 0
end
_G.cameraxpan = cameraxpan


local function cameraypan(target: any, t: any)
	ypan = true
	ypanstart = yscroll
	ypandiff = (target as number) - (ypanstart as number)
	ypantime = t as number
	ypantimer = 0
end
_G.cameraypan = cameraypan

return {
	scroll_batch_offset = scroll_batch_offset,
	getMouseTile = getMouseTile,
	cameraxpan = cameraxpan,
	cameraypan = cameraypan,
}
