-- Ported from root scrollutil.lua (Teal).

-- Camera / scroll coordinate helpers (from game.lua).

-- Pixel offset for tile spritebatches given fractional scroll.
local function scroll_batch_offset(scroll: number, sc?: number): number
	sc = sc or scale
	return math.floor(-math.fmod(scroll, 1) * 16 * sc)
end
_G.scroll_batch_offset = scroll_batch_offset


-- Mouse position → map tile (uses globals xscroll/yscroll/scale/yoffset).
local function getMouseTile(x: any, y: any): number, number
	local xout = math.floor(((x as number) + session.xscroll * 16 * scale) / (16 * scale)) + 1
	local yout = math.floor(((y as number) + session.yscroll * 16 * scale - yoffset * scale) / (16 * scale)) + 1
	return xout, yout
end
_G.getMouseTile = getMouseTile


-- Flux-driven camera pan (linear). Progress applied in camera_pan_apply after follow.
local pan_x = { k = 1 } as {string:number}
local pan_y = { k = 1 } as {string:number}
local pan_x_tween: FluxTween|nil = nil
local pan_y_tween: FluxTween|nil = nil

local function camera_pan_stop()
	if pan_x_tween ~= nil then
		(pan_x_tween as FluxTween):stop()
		pan_x_tween = nil
	end
	if pan_y_tween ~= nil then
		(pan_y_tween as FluxTween):stop()
		pan_y_tween = nil
	end
	xpan = false
	ypan = false
	pan_x.k = 1
	pan_y.k = 1
end
_G.camera_pan_stop = camera_pan_stop

local function cameraxpan(target: any, t: any)
	if pan_x_tween ~= nil then
		(pan_x_tween as FluxTween):stop()
		pan_x_tween = nil
	end
	xpan = true
	xpanstart = session.xscroll
	xpandiff = (target as number) - (xpanstart as number)
	local duration = (t as number) or 0
	if duration <= 0 then
		pan_x.k = 1
		session.xscroll = (xpanstart as number) + (xpandiff as number)
		xpan = false
		return
	end
	pan_x.k = 0
	pan_x_tween = Flux.to(pan_x, duration, { k = 1 }):ease("linear"):oncomplete(function()
		-- Snap before clearing flag: Flux.update runs before camera_pan_apply.
		session.xscroll = (xpanstart as number) + (xpandiff as number)
		pan_x.k = 1
		xpan = false
		pan_x_tween = nil
	end)
end
_G.cameraxpan = cameraxpan

local function cameraypan(target: any, t: any)
	if pan_y_tween ~= nil then
		(pan_y_tween as FluxTween):stop()
		pan_y_tween = nil
	end
	ypan = true
	ypanstart = session.yscroll
	ypandiff = (target as number) - (ypanstart as number)
	local duration = (t as number) or 0
	if duration <= 0 then
		pan_y.k = 1
		session.yscroll = (ypanstart as number) + (ypandiff as number)
		ypan = false
		return
	end
	pan_y.k = 0
	pan_y_tween = Flux.to(pan_y, duration, { k = 1 }):ease("linear"):oncomplete(function()
		session.yscroll = (ypanstart as number) + (ypandiff as number)
		pan_y.k = 1
		ypan = false
		pan_y_tween = nil
	end)
end
_G.cameraypan = cameraypan

-- Called at end of scroll_update: pan overrides autoscroll (same order as legacy timers).
local function camera_pan_apply()
	if xpan then
		session.xscroll = (xpanstart as number) + (xpandiff as number) * pan_x.k
	end
	if ypan then
		session.yscroll = (ypanstart as number) + (ypandiff as number) * pan_y.k
	end
end
_G.camera_pan_apply = camera_pan_apply

return {
	scroll_batch_offset = scroll_batch_offset,
	getMouseTile = getMouseTile,
	cameraxpan = cameraxpan,
	cameraypan = cameraypan,
	camera_pan_stop = camera_pan_stop,
	camera_pan_apply = camera_pan_apply,
}
