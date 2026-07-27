--[[ Gravity gun — ray/cone pick, critically damped spring, hold/punt/drop. ]]

local MAX_RANGE = 8
local STEP = 0.2
local PROBE = 0.55
local HOLD_DIST = 0.3
local OMEGA = 14
local GRAB_DIST = 0.45
local REACH_LIMIT = 10
local PUNT_IMPULSE = 28
local SHOVE_IMPULSE = 10
local PUNT_TIME = 0.45
local COOLDOWN = 0.15
local CONE_DOT = 0.72 -- ~44° half-angle; floor-aimed boxes often miss pure tile-clipped rays

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
-- Adds a small fudge so boxes sitting on the floor (ray hits tile first) remain reachable.
local function clip_range(sx: number, sy: number, hx: number, hy: number, maxrange: number, hit: boolean): number
	if not hit then
		return maxrange
	end
	local d = math.sqrt(dist2(sx, sy, hx, hy)) + 0.75
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
		elseif held.parent == pl then
			held.parent = nil
			held.active = true
		end
		pl.pickup = false
	end

	pl.gg_pulling = nil
	pl.gg_state = "idle"
	pl.gg_vx = 0
	pl.gg_vy = 0
end

local function box_usable(obj: {string:any}, pl: {string:any}): boolean
	if not obj or not obj.grabbable or obj.destroying then
		return false
	end
	if obj.beamed and obj.beamed ~= pl then
		return false
	end
	-- held by someone else via E-pickup
	if obj.parent and obj.parent ~= pl then
		return false
	end
	return true
end

-- Cone fallback: nearest grabbable box along aim (survives floor-tile ray clips).
local function pick_cone(pl: {string:any}, sx: number, sy: number, dx: number, dy: number, maxd: number): {string:any}|nil
	if not objects or not objects["box"] then
		return nil
	end
	local boxes = objects["box"] as {any:{string:any}}
	local best: {string:any}|nil = nil
	local bestd = maxd
	for _, raw in pairs(boxes) do
		local obj = raw
		if box_usable(obj, pl) then
			local cx = (obj.x as number) + ((obj.width as number) or 0.75) / 2
			local cy = (obj.y as number) + ((obj.height as number) or 0.75) / 2
			local tox, toy = cx - sx, cy - sy
			local d = math.sqrt(tox * tox + toy * toy)
			if d > 0.05 and d <= bestd then
				local ndx, ndy = tox / d, toy / d
				local dot = ndx * dx + ndy * dy
				if dot >= CONE_DOT then
					best = obj
					bestd = d
				end
			end
		end
	end
	return best
end

-- A. pick_target: step along ray with checkrect; cone fallback when tile clip misses boxes
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
				if box_usable(obj, pl) then
					return obj
				end
			end
		end
	end

	-- Floor-aimed cubes: traceline often hits the tile under the box first.
	return pick_cone(pl, sx, sy, dx, dy, MAX_RANGE)
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
	obj.parent = pl
	obj.gravity = 0
	obj.active = false
	obj.speedx = 0
	obj.speedy = 0
end

local function apply_impulse(obj: {string:any}, pl: {string:any}, strength: number)
	local dx, dy = aim_dir(pl)
	obj.parent = nil
	obj.beamed = nil
	obj.active = true
	obj.gravity = nil
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
			pl.pickup = false
			pl.gg_state = "idle"
			pl.gg_pulling = nil
			pl.gg_vx = 0
			pl.gg_vy = 0
			apply_impulse(obj, pl, PUNT_IMPULSE)
			set_cooldown(pl)
			return
		end
		if pl.gg_state == "idle" or pl.gg_state == nil then
			local obj = pick_target(pl)
			if obj then
				begin_pull(pl, obj)
				set_cooldown(pl)
			end
		end
	elseif rmb then
		if pl.gg_state == "held" and pl.pickup then
			release_obj(pl, "drop")
			set_cooldown(pl)
			return
		end
		if pl.gg_state == "pulling" then
			release_obj(pl, "cancel")
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

-- Hold-LMB keeps trying to acquire a target (press alone often misses floor cubes).
local function hold(pl: {string:any}, button: any, _: number)
	local lmb = button == "l" or button == 1
	if lmb and (pl.gg_state == "idle" or pl.gg_state == nil) then
		fire(pl, "l")
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

local function mouse_held_pull(pl: {string:any}): boolean
	-- Non-mouse players (joy) keep pull until release via RMB / unequip.
	if pl.playernumber ~= mouseowner then
		return true
	end
	if love and love.mouse and love.mouse.isDown then
		return love.mouse.isDown(1) == true
	end
	return true
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
		if not mouse_held_pull(pl) then
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
	hold = hold,
	update = update,
	equip = equip,
	unequip = unequip,
	spring_step = spring_step,
	clip_range = clip_range,
	release_obj = release_obj,
	pick_target = pick_target,
	MAX_RANGE = MAX_RANGE,
}
