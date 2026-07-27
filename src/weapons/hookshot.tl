--[[ Hookshot — Zelda reel + Bionic Commando swing via PBD distance constraint. ]]

local MIN_LEN = 0.8
local MAX_LEN = 9
local RETRACT_RATE = 7 -- blocks/sec
local DETACH_BOOST = 9
local HOOK_SPEED = 22
local COOLDOWN = 0.25
local PULL_SPEED = 16

local atan2 = math.atan2 or math.atan

-- Pure: PBD distance constraint. Exported for tests.
local function rope_step(pl: {string:any}, dt: number)
	local ax = pl.grapple_x as number
	local ay = pl.grapple_y as number
	local px = (pl.x as number) + (pl.width as number) / 2
	local py = (pl.y as number) + (pl.height as number) / 2

	local dx, dy = ax - px, ay - py
	local d = math.sqrt(dx * dx + dy * dy)
	if d < 0.001 then
		return
	end
	local nx, ny = dx / d, dy / d

	-- hold LMB = reel in; otherwise fixed length
	if pl.grapple_reel then
		pl.grapple_len = math.max(MIN_LEN, (pl.grapple_len as number) - RETRACT_RATE * dt)
	end
	local rest = pl.grapple_len as number

	if d > rest then
		-- 1. positional correction onto circle
		pl.x = (pl.x as number) + nx * (d - rest)
		pl.y = (pl.y as number) + ny * (d - rest)

		-- 2. kill only radial velocity away from anchor
		local vx = pl.speedx as number
		local vy = pl.speedy as number
		local radial = vx * nx + vy * ny
		if radial < 0 then
			pl.speedx = vx - radial * nx
			pl.speedy = vy - radial * ny
		end
	end
end

local function clear_fields(pl: {string:any})
	pl.grapple = false
	pl.grapple_x = nil
	pl.grapple_y = nil
	pl.grapple_cox = nil
	pl.grapple_coy = nil
	pl.grapple_len = nil
	pl.grapple_reel = nil
end

local function detach(pl: {string:any}, reason: string, boost: boolean)
	local _: string = reason
	if not pl.grapple then
		return
	end
	clear_fields(pl)
	if boost then
		pl.speedy = math.min((pl.speedy as number) or 0, -DETACH_BOOST)
	end
end

local function attach(pl: {string:any}, ax: number, ay: number, cox: number, coy: number)
	pl.grapple = true
	pl.grapple_x = ax
	pl.grapple_y = ay
	pl.grapple_cox = cox
	pl.grapple_coy = coy
	local px = (pl.x as number) + (pl.width as number) / 2
	local py = (pl.y as number) + (pl.height as number) / 2
	pl.grapple_len = math.min(MAX_LEN, math.sqrt((ax - px) ^ 2 + (ay - py) ^ 2))
	pl.grapple_reel = true
	if playsound then
		playsound("hookshot") -- no-op until assets/sounds/hookshot.ogg exists
	end
end

local function reel_target_to(pl: {string:any}, target: {string:any})
	local px = (pl.x as number) + ((pl.width as number) or 0.75) / 2
	local py = (pl.y as number) + ((pl.height as number) or 0.75) / 2
	local tw = (target.width as number) or 0.75
	local th = (target.height as number) or 0.75
	local tx = (target.x as number) + tw / 2
	local ty = (target.y as number) + th / 2
	local dx, dy = px - tx, py - ty
	local d = math.sqrt(dx * dx + dy * dy)
	if d < 0.001 then
		return
	end
	target.speedx = dx / d * PULL_SPEED
	target.speedy = dy / d * PULL_SPEED
	if target.gravity == nil then
		target.falling = true
	end
end

local function aim(pl: {string:any}): number, number, number, number
	local sx = (pl.x as number) + 6 / 16
	local sy = (pl.y as number) + 6 / 16
	local ang = (pl.pointingangle as number) or 0
	local dx = -math.sin(ang)
	local dy = -math.cos(ang)
	return sx, sy, dx, dy
end

local function on_cooldown(pl: {string:any}): boolean
	local d = pl.weapondelay as {string:number}|nil
	if d == nil then
		return false
	end
	return ((d as {string:number}).hookshot or 0) > 0
end

local function set_cooldown(pl: {string:any})
	if not pl.weapondelay then
		pl.weapondelay = {}
	end
	(pl.weapondelay as {string:number}).hookshot = COOLDOWN
end

local function shoot_hook(pl: {string:any})
	local sx, sy, dx, dy = aim(pl)
	if not objects or not hook or not hook.new then
		return
	end
	local list = objects["hook"] as {any}|nil
	if list == nil then
		list = {} as {any}
		objects["hook"] = list as {any:Entity}
	end
	table.insert(list as {any}, (hook.new as function(any, number, number, number, number, any): any)(
		hook, sx + dx * 0.6, sy + dy * 0.6, dx, dy, pl))
	set_cooldown(pl)
	if playsound then
		playsound("shot")
	end
end

local function mouse_held_lmb(pl: {string:any}): boolean
	if pl.playernumber ~= mouseowner then
		return true
	end
	if love and love.mouse and love.mouse.isDown then
		return love.mouse.isDown(1) == true
	end
	return true
end

local function anchor_solid(cox: number, coy: number): boolean
	if not inmap or not inmap(cox, coy) then
		return false
	end
	if not map or not map[cox] or not map[cox][coy] then
		return false
	end
	local tid = map[cox][coy][1] as number
	if not tid or tid == 1 or not tilequads or not tilequads[tid] then
		return false
	end
	local tq = tilequads[tid]
	if tq.getproperty then
		return (tq:getproperty("collision", cox, coy) as boolean) == true
	end
	return false
end

local function grill_between(pl: {string:any}): boolean
	if not traceline then
		return false
	end
	local ax = pl.grapple_x as number
	local ay = pl.grapple_y as number
	local px = (pl.x as number) + (pl.width as number) / 2
	local py = (pl.y as number) + (pl.height as number) / 2
	local dx, dy = ax - px, ay - py
	local d = math.sqrt(dx * dx + dy * dy)
	if d < 0.05 then
		return false
	end
	local ang = atan2(-dx, -dy)
	local cox, _, _, _, hx, hy = traceline(px, py, ang, nil)
	local hd = math.sqrt(((hx as number) - px) ^ 2 + ((hy as number) - py) ^ 2)
	-- grill/door: traceline returns false and stops short of anchor
	if (cox == false or cox == nil) and hd < d - 0.25 then
		return true
	end
	return false
end

local function fire(pl: {string:any}, button: any)
	local lmb = button == "l" or button == 1
	local rmb = button == "r" or button == 2

	if rmb then
		if pl.grapple then
			detach(pl, "jump", true)
		end
		return
	end

	if not lmb then
		return
	end
	if pl.grapple then
		pl.grapple_reel = true
		return
	end
	if on_cooldown(pl) then
		return
	end
	-- cancel in-flight hooks for this player
	local list = objects and objects["hook"] as {any:{string:any}}|nil
	if list ~= nil then
		for _, h in pairs(list as {any:{string:any}}) do
			if h.owner == pl and h.state == "flying" then
				h.destroy = true
			end
		end
	end
	shoot_hook(pl)
end

local function hold(pl: {string:any}, button: any, _: number)
	local lmb = button == "l" or button == 1
	if lmb and pl.grapple then
		pl.grapple_reel = true
	end
end

local function update(pl: {string:any}, dt: number)
	if not pl.grapple then
		return
	end

	-- 1) LMB released → detach, keep tangential velocity
	if not mouse_held_lmb(pl) then
		detach(pl, "release", false)
		return
	end
	pl.grapple_reel = true

	-- 4) anchor tile no longer collision
	local cox = pl.grapple_cox as number|nil
	local coy = pl.grapple_coy as number|nil
	if cox ~= nil and coy ~= nil and not anchor_solid(cox as number, coy as number) then
		detach(pl, "broken_anchor", false)
		return
	end

	-- 5) emancipation grill between player and anchor
	if grill_between(pl) then
		detach(pl, "grill", false)
		return
	end

	-- 6) desync guard
	local ax = pl.grapple_x as number
	local ay = pl.grapple_y as number
	local px = (pl.x as number) + (pl.width as number) / 2
	local py = (pl.y as number) + (pl.height as number) / 2
	local d = math.sqrt((ax - px) ^ 2 + (ay - py) ^ 2)
	if d > MAX_LEN * 1.5 then
		detach(pl, "outofreach", false)
		return
	end

	rope_step(pl, dt)
end

local function world_to_screen(wx: number, wy: number): number, number
	local xs = (xscroll as number) or 0
	local ys = (yscroll as number) or 0
	local sc = (scale as number) or 1
	return math.floor((wx - xs) * 16 * sc), math.floor((wy - ys - 0.5) * 16 * sc)
end

local function draw(pl: {string:any})
	if not love or not love.graphics then
		return
	end
	if not pl.grapple then
		-- in-flight rope from player to hook
		local list = objects and objects["hook"] as {any:{string:any}}|nil
		if list == nil then
			return
		end
		for _, h in pairs(list as {any:{string:any}}) do
			if h.owner == pl and h.state == "flying" then
				local sx = (pl.x as number) + 6 / 16
				local sy = (pl.y as number) + 6 / 16
				local hx = (h.x as number) + ((h.width as number) or 0.5) / 2
				local hy = (h.y as number) + ((h.height as number) or 0.5) / 2
				local x1, y1 = world_to_screen(sx, sy)
				local x2, y2 = world_to_screen(hx, hy)
				love.graphics.setColor(0.85, 0.7, 0.35, 0.9)
				love.graphics.setLineWidth(((scale as number) or 1) * 1.5)
				love.graphics.line(x1, y1, x2, y2)
			end
		end
		love.graphics.setColor(1, 1, 1, 1)
		return
	end
	local sx = (pl.x as number) + ((pl.width as number) or 0.75) / 2
	local sy = (pl.y as number) + ((pl.height as number) or 0.75) / 2
	local x1, y1 = world_to_screen(sx, sy)
	local x2, y2 = world_to_screen(pl.grapple_x as number, pl.grapple_y as number)
	love.graphics.setColor(0.85, 0.7, 0.35, 0.95)
	love.graphics.setLineWidth(((scale as number) or 1) * 1.75)
	love.graphics.line(x1, y1, x2, y2)
	love.graphics.circle("fill", x2, y2, ((scale as number) or 1) * 2.5)
	love.graphics.setColor(1, 1, 1, 1)
end

local function equip(_: {string:any})
end

local function unequip(pl: {string:any})
	detach(pl, "switch", false)
	local list = objects and objects["hook"] as {any:{string:any}}|nil
	if list ~= nil then
		for _, h in pairs(list as {any:{string:any}}) do
			if h.owner == pl then
				h.destroy = true
			end
		end
	end
end

return {
	id = "hookshot",
	name = "hookshot",
	icon = "assets/graphics/weapons/hookshot.png",
	anim = "portal",
	cooldown = COOLDOWN,
	fire = fire,
	hold = hold,
	update = update,
	draw = draw,
	equip = equip,
	unequip = unequip,
	rope_step = rope_step,
	detach = detach,
	attach = attach,
	reel_target_to = reel_target_to,
	anchor_solid = anchor_solid,
	grill_between = grill_between,
	clear_fields = clear_fields,
	MIN_LEN = MIN_LEN,
	MAX_LEN = MAX_LEN,
	RETRACT_RATE = RETRACT_RATE,
	DETACH_BOOST = DETACH_BOOST,
	HOOK_SPEED = HOOK_SPEED,
}
