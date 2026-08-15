--[[ Black-hole gameplay post-FX on shader pass 3 (does not touch menu shaders 1–2). ]]

local MUZZLE_DECAY = 4.5
local PASS = 3

local muzzle = 0.0
local muzzle_cx = 0.5
local muzzle_cy = 0.5
local enabled = false

local function screen_uv(wx: number, wy: number): number, number
	local vw = world_viewport_w()
	local vh = world_viewport_h()
	if vw <= 0 then vw = 1 end
	if vh <= 0 then vh = 1 end
	-- Shader runs on screen buffer; map tile center through camera.
	local sx = world_screen_px_x(wx * 16)
	local sy = world_screen_px_y(wy * 16)
	return sx / vw, sy / vh
end

local function apply(strength: number, mode: number, cx: number, cy: number)
	if not shaders or not shaders.set or not shaders.setParameter then
		return
	end
	if strength < 0.02 then
		if enabled then
			shaders:set(PASS, nil)
			enabled = false
		end
		return
	end
	if not enabled then
		shaders:set(PASS, "blackholefx")
		enabled = true
	end
	shaders:setParameter("blackholefx", "center", { cx, cy })
	shaders:setParameter("blackholefx", "strength", strength)
	shaders:setParameter("blackholefx", "mode", mode)
	shaders:setParameter("blackholefx", "time", (love and love.timer and love.timer.getTime and love.timer.getTime()) or 0)
end

local function pulse_muzzle(wx: number, wy: number)
	muzzle = 1.0
	muzzle_cx, muzzle_cy = screen_uv(wx, wy)
	screenshake(0.12)
end

local function sync(dt: number)
	muzzle = math.max(0, muzzle - dt * MUZZLE_DECAY)

	local best_s = muzzle
	local best_mode = 2.0
	local best_cx, best_cy = muzzle_cx, muzzle_cy

	if session.objects and session.objects["blackhole"] then
		for _, h_any in pairs(session.objects["blackhole"] as {any:any}) do
			local h = h_any as {string:any}
			if h then
				local hx = (h.x as number) + ((h.width as number) or 0.6) / 2
				local hy = (h.y as number) + ((h.height as number) or 0.6) / 2
				local u, v = screen_uv(hx, hy)
				local st = h.state as string
				local s = 0.0
				local mode = 0.0
				if st == "flying" then
					s = 0.35 + 0.15 * math.sin(((h.timer as number) or 0) * 12)
					mode = 0.0
				elseif st == "sucking" then
					local t = (h.phasetimer as number) or 0
					s = 0.55 + math.min(0.55, t * 0.5)
					mode = 0.0
					screenshake(0.06 + s * 0.08)
				elseif st == "blast" then
					s = (h.blast_flash as number) or 0
					mode = 1.0
				end
				if s > best_s then
					best_s = s
					best_mode = mode
					best_cx, best_cy = u, v
				end
			end
		end
	end

	-- Prefer muzzle when freshly fired and no stronger hole FX
	if muzzle > 0.15 and muzzle >= best_s * 0.85 then
		best_s = muzzle
		best_mode = 2.0
		best_cx, best_cy = muzzle_cx, muzzle_cy
	end

	apply(best_s, best_mode, best_cx, best_cy)
end

local function clear()
	muzzle = 0
	if enabled and shaders and shaders.set then
		shaders:set(PASS, nil)
	end
	enabled = false
end

return {
	pulse_muzzle = pulse_muzzle,
	sync = sync,
	clear = clear,
	PASS = PASS,
}
