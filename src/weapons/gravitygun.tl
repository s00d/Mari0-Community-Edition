--[[ Gravity gun — grab boxes OR solid map tiles, spring-drag on LMB, RMB punt as ball. ]]

local MAX_RANGE = 8
local STEP = 0.2
local PROBE = 0.55
local HOLD_DIST = 0.3
local OMEGA = 14
local GRAB_DIST = 0.45
local REACH_LIMIT = 10
local PUNT_IMPULSE = 28
local SHOVE_IMPULSE = 10
local PUNT_TIME = 0.55
local COOLDOWN = 0.12
local CONE_DOT = 0.72

local ball_quad: any = nil

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

-- Range clipped by traceline. Floor fudge keeps near-wall boxes reachable.
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
	if obj.parent and obj.parent ~= pl then
		return false
	end
	return true
end

-- Portal-anchored tiles must not be yanked out from under a portal.
local function tile_blocked_by_portal(x: number, y: number): boolean
	if not playerobjs then
		return false
	end
	local n = players or 0
	for i = 1, n do
		local v = playerobjs[i] and playerobjs[i].portal
		if v then
			local zv = v as {string:any}
			local x1 = zv.x1 as number
			local y1 = zv.y1 as number
			local x2 = zv.x2 as number
			local y2 = zv.y2 as number
			if (x == x1 and y == y1) or (x == x2 and y == y2) then
				return true
			end
		end
	end
	return false
end

local function tile_can_grab(cox: number, coy: number): boolean
	if not inmap or not inmap(cox, coy) then
		return false
	end
	if not map or not map[cox] or not map[cox][coy] then
		return false
	end
	local tid = map[cox][coy][1] as number
	if not tid or tid == 1 then
		return false
	end
	if not tilequads or not tilequads[tid] then
		return false
	end
	local tq = tilequads[tid]
	local coll = tq.getproperty and (tq:getproperty("collision", cox, coy) as boolean)
	if not coll then
		return false
	end
	if tq.getproperty and tq:getproperty("invisible", cox, coy) then
		return false
	end
	if tile_blocked_by_portal(cox, coy) then
		return false
	end
	return true
end

-- Pull a solid map tile out into a physics box (prop), clear the cell.
-- Exported for tests.
local function extract_tile(cox: number, coy: number): {string:any}|nil
	if not tile_can_grab(cox, coy) then
		return nil
	end
	if not box or not box.new then
		return nil
	end
	local tid = map[cox][coy][1] as number
	local tq = tilequads[tid]

	map[cox][coy][1] = 1
	if objects and objects["tile"] then
		objects["tile"][tilekey(cox, coy)] = nil
	end
	if init_map_cell_gels then
		init_map_cell_gels(map[cox][coy])
	end
	if checkportalremove then
		checkportalremove(cox, coy)
	end
	if generatespritebatch then
		generatespritebatch(0, 0)
	end

	local prop = (box.new as function(any, number, number): {string:any})(box, cox, coy)
	prop.gg_from_tile = true
	prop.gg_tileid = tid
	if tq then
		local tqa = tq as {string:any}
		prop.graphic = tqa.image or prop.graphic
		if tqa.quad then
			prop.quad = (tqa.quad as function({string:any}): any)(tqa)
		end
		prop.offsetX = 8
		prop.offsetY = 0
		prop.quadcenterX = 8
		prop.quadcenterY = 8
	end
	if objects and objects["box"] then
		table.insert(objects["box"] as {any}, prop)
	end
	return prop
end

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

-- Entity-only pick (no tile extract). Used for shove.
local function pick_entity(pl: {string:any}): {string:any}|nil
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
	return pick_cone(pl, sx, sy, dx, dy, MAX_RANGE)
end

-- Grab pick: entities first, else extract aimed solid tile into a prop.
local function pick_target(pl: {string:any}): {string:any}|nil
	local ent = pick_entity(pl)
	if ent then
		return ent
	end

	local sx = (pl.x as number) + 6 / 16
	local sy = (pl.y as number) + 6 / 16
	local ang = pl.pointingangle as number
	local cox, coy, _, _, hx, hy = traceline(sx, sy, ang, nil)
	if cox == false or cox == nil or coy == false or coy == nil then
		return nil
	end
	local cx = cox as number
	local cy = coy as number
	if dist2(sx, sy, hx as number, hy as number) > MAX_RANGE * MAX_RANGE then
		return nil
	end
	if not tile_can_grab(cx, cy) then
		return nil
	end
	return extract_tile(cx, cy)
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

local function apply_ball_look(obj: {string:any})
	obj.gg_ball = true
	if portalprojectileimg and love and love.graphics and love.graphics.newQuad then
		obj.graphic = portalprojectileimg
		if not ball_quad then
			local w = (portalprojectileimg.getWidth and portalprojectileimg:getWidth()) or 12
			local h = (portalprojectileimg.getHeight and portalprojectileimg:getHeight()) or 12
			ball_quad = love.graphics.newQuad(0, 0, w, h, w, h)
		end
		obj.quad = ball_quad
		obj.offsetX = 6
		obj.offsetY = 6
		obj.quadcenterX = 6
		obj.quadcenterY = 6
	end
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
	apply_ball_look(obj)
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

local function held_object(pl: {string:any}): {string:any}|nil
	if pl.gg_state == "held" and pl.pickup then
		return pl.pickup as {string:any}
	end
	if pl.gg_state == "pulling" and pl.gg_pulling then
		return pl.gg_pulling as {string:any}
	end
	return nil
end

local function fire(pl: {string:any}, button: any)
	if on_cooldown(pl) then
		return
	end
	local lmb = button == "l" or button == 1
	local rmb = button == "r" or button == 2

	if lmb then
		-- LMB only acquires; drag continues while held. Never punt on LMB.
		if pl.gg_state == "idle" or pl.gg_state == nil then
			local obj = pick_target(pl)
			if obj then
				begin_pull(pl, obj)
				set_cooldown(pl)
			end
		end
	elseif rmb then
		-- RMB = punt/launch as circular projectile while holding; else short shove.
		local obj = held_object(pl)
		if obj then
			pl.pickup = false
			pl.gg_pulling = nil
			pl.gg_state = "idle"
			pl.gg_vx = 0
			pl.gg_vy = 0
			apply_impulse(obj, pl, PUNT_IMPULSE)
			set_cooldown(pl)
			return
		end
		local shove = pick_entity(pl)
		if shove then
			apply_impulse(shove, pl, SHOVE_IMPULSE)
			set_cooldown(pl)
		end
	end
end

-- Hold-LMB keeps trying to acquire while idle.
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
		-- LMB release drops (HL2-style hold-to-carry).
		if not mouse_held_pull(pl) then
			release_obj(pl, "drop")
			return
		end
		spring_object(pl, obj, dt)
		if dist2(obj.x as number, obj.y as number, pl.x as number, pl.y as number) > REACH_LIMIT * REACH_LIMIT then
			release_obj(pl, "outofreach")
		end
	end
end

local function world_to_screen(wx: number, wy: number): number, number
	local xs = (xscroll as number) or 0
	local ys = (yscroll as number) or 0
	local sc = (scale as number) or 1
	return math.floor((wx - xs) * 16 * sc), math.floor((wy - ys - 0.5) * 16 * sc)
end

local function draw(pl: {string:any})
	local state = (pl.gg_state as string) or "idle"
	if state ~= "pulling" and state ~= "held" then
		return
	end
	local objn = held_object(pl)
	if objn == nil or not love or not love.graphics then
		return
	end
	local obj = objn as {string:any}
	local sx = (pl.x as number) + 6 / 16
	local sy = (pl.y as number) + 6 / 16
	local ox = (obj.x as number) + ((obj.width as number) or 0.75) / 2
	local oy = (obj.y as number) + ((obj.height as number) or 0.75) / 2
	local x1, y1 = world_to_screen(sx, sy)
	local x2, y2 = world_to_screen(ox, oy)
	love.graphics.setColor(0.35, 0.85, 1.0, 0.85)
	love.graphics.setLineWidth(((scale as number) or 1) * 1.5)
	love.graphics.line(x1, y1, x2, y2)
	love.graphics.circle("fill", x2, y2, ((scale as number) or 1) * 2.5)
	love.graphics.setColor(1, 1, 1, 1)
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
	draw = draw,
	equip = equip,
	unequip = unequip,
	spring_step = spring_step,
	clip_range = clip_range,
	release_obj = release_obj,
	pick_target = pick_target,
	pick_entity = pick_entity,
	extract_tile = extract_tile,
	tile_can_grab = tile_can_grab,
	MAX_RANGE = MAX_RANGE,
}
