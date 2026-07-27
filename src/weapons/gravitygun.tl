--[[ Gravity gun — ray pick, critically damped spring, hold/punt/drop. ]]

local MAX_RANGE = 8
local STEP = 0.25
local PROBE = 0.35
local HOLD_DIST = 0.3
local OMEGA = 14
local GRAB_DIST = 0.45
local REACH_LIMIT = 10
local PUNT_IMPULSE = 28
local SHOVE_IMPULSE = 10
local PUNT_TIME = 0.45
local COOLDOWN = 0.15

-- Pure: critically damped spring step (zeta=1). Exported for tests.
local function spring_step(pos: number, vel: number, target: number, omega: number, dt: number): number, number
	local x = pos - target
	local a = -2 * omega * vel - omega * omega * x
	vel = vel + a * dt
	pos = pos + vel * dt
	return pos, vel
end

local function hold_point(pl: {string:any}): number, number
	local ang = pl.pointingangle as number
	return (pl.x as number) + math.sin(-ang) * HOLD_DIST,
		(pl.y as number) - math.cos(-ang) * HOLD_DIST
end

local function aim_dir(pl: {string:any}): number, number
	local ang = pl.pointingangle as number
	return -math.sin(ang), -math.cos(ang)
end

local function dist2(ax: number, ay: number, bx: number, by: number): number
	local dx, dy = ax - bx, ay - by
	return dx * dx + dy * dy
end

-- Range clipped by traceline (walls / grills / doors). Pure helper for tests.
local function clip_range(sx: number, sy: number, hx: number, hy: number, maxrange: number, hit: boolean): number
	if not hit then
		return maxrange
	end
	local d = math.sqrt(dist2(sx, sy, hx, hy))
	if d < maxrange then
		return d
	end
	return maxrange
end

local function clear_beam(obj: {string:any})
	if not obj then
		return
	end
	obj.beamed = nil
	obj.gravity = nil
	if obj.active == false and not obj.parent then
		obj.active = true
	end
end

local function release_obj(pl: {string:any}, reason: string)
	local _: string = reason
	local pulling = pl.gg_pulling as {string:any}|nil
	local pickup = pl.pickup as {string:any}|nil

	if reason == "drop" and pickup then
		clear_beam(pickup as {string:any})
		pl.gg_pulling = nil
		pl.gg_state = "idle"
		pl.gg_vx = 0
		pl.gg_vy = 0
		if pl.dropbox then
			(pl.dropbox as function({string:any}))(pl)
		else
			pl.pickup = false
		end
		return
	end

	if pulling then
		clear_beam(pulling)
	end
	-- pickup may be false (legacy) — treat as empty
	if pickup then
		local held = pickup as {string:any}
		clear_beam(held)
		if held.parent == pl and held.dropped then
			(held.dropped as function({string:any}): any)(held)
		end
		pl.pickup = false
	end

	pl.gg_pulling = nil
	pl.gg_state = "idle"
	pl.gg_vx = 0
	pl.gg_vy = 0
end

-- A. pick_target: step along ray with checkrect; clip via traceline
local function pick_target(pl: {string:any}): {string:any}|nil
	local sx = (pl.x as number) + 6 / 16
	local sy = (pl.y as number) + 6 / 16
	local ang = pl.pointingangle as number
	local cox, _, _, _, hx, hy = traceline(sx, sy, ang, nil)
	local hit = cox ~= false and cox ~= nil
	local maxd = clip_range(sx, sy, hx as number, hy as number, MAX_RANGE, hit as boolean)

	local dx, dy = aim_dir(pl)
	local d = 0.0
	while d < maxd do
		d = d + STEP
		local x = sx + dx * d
		local y = sy + dy * d
		local col = checkrect(x - PROBE / 2, y - PROBE / 2, PROBE, PROBE, {"box"}, true)
		if #col >= 2 then
			local raw = (objects["box"] as {any})[col[2] as integer]
			if raw then
				local obj = raw as {string:any}
				if obj.grabbable and not obj.destroying then
					if not obj.beamed or obj.beamed == pl then
						return obj
					end
				end
			end
		end
	end
	return nil
end

local function begin_pull(pl: {string:any}, obj: {string:any})
	pl.gg_state = "pulling"
	pl.gg_pulling = obj
	pl.gg_vx = (obj.speedx as number) or 0
	pl.gg_vy = (obj.speedy as number) or 0
	obj.beamed = pl
	obj.gravity = 0
	obj.speedx = 0
	obj.speedy = 0
end

local function enter_hold(pl: {string:any}, obj: {string:any})
	pl.gg_state = "held"
	pl.gg_pulling = nil
	pl.pickup = obj
	obj.beamed = pl
	obj.gravity = 0
	obj.active = false
end

local function apply_impulse(obj: {string:any}, pl: {string:any}, strength: number)
	local dx, dy = aim_dir(pl)
	obj.speedx = ((obj.speedx as number) or 0) + dx * strength
	obj.speedy = ((obj.speedy as number) or 0) + dy * strength
	obj.falling = true
	obj.punttimer = PUNT_TIME
end

local function on_cooldown(pl: {string:any}): boolean
	local d = pl.weapondelay as {string:number}|nil
	if d == nil then
		return false
	end
	local dd = d as {string:number}
	return (dd.gravitygun or 0) > 0
end

local function set_cooldown(pl: {string:any})
	if not pl.weapondelay then
		pl.weapondelay = {}
	end
	(pl.weapondelay as {string:number}).gravitygun = COOLDOWN
end

local function fire(pl: {string:any}, button: any)
	if on_cooldown(pl) then
		return
	end
	local lmb = button == "l" or button == 1
	local rmb = button == "r" or button == 2

	if lmb then
		if pl.gg_state == "held" and pl.pickup then
			local obj = pl.pickup as {string:any}
			clear_beam(obj)
			obj.active = true
			apply_impulse(obj, pl, PUNT_IMPULSE)
			pl.pickup = false
			pl.gg_state = "idle"
			pl.gg_pulling = nil
			set_cooldown(pl)
			return
		end
		local obj = pick_target(pl)
		if obj then
			begin_pull(pl, obj)
			set_cooldown(pl)
		end
	elseif rmb then
		if pl.gg_state == "held" and pl.pickup then
			release_obj(pl, "drop")
			set_cooldown(pl)
			return
		end
		local obj = pick_target(pl)
		if obj then
			apply_impulse(obj, pl, SHOVE_IMPULSE)
			set_cooldown(pl)
		end
	end
end

local function spring_object(pl: {string:any}, obj: {string:any}, dt: number): number, number, number, number
	local tx, ty = hold_point(pl)
	local ox = obj.x as number
	local oy = obj.y as number
	local vx = (pl.gg_vx as number) or 0
	local vy = (pl.gg_vy as number) or 0
	ox, vx = spring_step(ox, vx, tx, OMEGA, dt)
	oy, vy = spring_step(oy, vy, ty, OMEGA, dt)
	obj.x = ox
	obj.y = oy
	obj.speedx = 0
	obj.speedy = 0
	pl.gg_vx = vx
	pl.gg_vy = vy
	return tx, ty, ox, oy
end

local function update(pl: {string:any}, dt: number)
	local state = (pl.gg_state as string) or "idle"

	if state == "pulling" then
		local objn = pl.gg_pulling as {string:any}|nil
		if objn == nil then
			release_obj(pl, "destroying")
			return
		end
		local obj = objn as {string:any}
		if obj.destroying then
			release_obj(pl, "destroying")
			return
		end
		if pl.playernumber == mouseowner and not love.mouse.isDown(1) then
			release_obj(pl, "cancel")
			return
		end
		local tx, ty, ox, oy = spring_object(pl, obj, dt)
		if dist2(ox, oy, tx, ty) < GRAB_DIST * GRAB_DIST then
			enter_hold(pl, obj)
		elseif dist2(ox, oy, pl.x as number, pl.y as number) > REACH_LIMIT * REACH_LIMIT then
			release_obj(pl, "outofreach")
		end
	elseif state == "held" then
		local objn = pl.pickup as {string:any}|nil
		if objn == nil then
			release_obj(pl, "destroying")
			return
		end
		local obj = objn as {string:any}
		if obj.destroying then
			release_obj(pl, "destroying")
			return
		end
		if obj.beamed ~= pl then
			release_obj(pl, "stolen")
			return
		end
		spring_object(pl, obj, dt)
		if dist2(obj.x as number, obj.y as number, pl.x as number, pl.y as number) > REACH_LIMIT * REACH_LIMIT then
			release_obj(pl, "outofreach")
		end
	end
end

local function equip(_: {string:any})
end

local function unequip(pl: {string:any})
	release_obj(pl, "switch")
end

return {
	id = "gravitygun",
	name = "gravity gun",
	icon = "assets/graphics/weapons/gravitygun.png",
	anim = "portal",
	cooldown = COOLDOWN,
	fire = fire,
	update = update,
	equip = equip,
	unequip = unequip,
	spring_step = spring_step,
	clip_range = clip_range,
	release_obj = release_obj,
	pick_target = pick_target,
	MAX_RANGE = MAX_RANGE,
}
