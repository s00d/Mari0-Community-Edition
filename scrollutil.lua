-- Camera / scroll coordinate helpers (from game.lua).

-- Pixel offset for tile spritebatches given fractional scroll.
function scroll_batch_offset(scroll, sc)
	sc = sc or scale
	return math.floor(-math.fmod(scroll, 1) * 16 * sc)
end

-- Mouse position → map tile (uses globals xscroll/yscroll/scale/yoffset).
function getMouseTile(x, y)
	local xout = math.floor((x + xscroll * 16 * scale) / (16 * scale)) + 1
	local yout = math.floor((y + yscroll * 16 * scale - yoffset * scale) / (16 * scale)) + 1
	return xout, yout
end

function cameraxpan(target, t)
	xpan = true
	xpanstart = xscroll
	xpandiff = target - xpanstart
	xpantime = t
	xpantimer = 0
end

function cameraypan(target, t)
	ypan = true
	ypanstart = yscroll
	ypandiff = target - ypanstart
	ypantime = t
	ypantimer = 0
end
