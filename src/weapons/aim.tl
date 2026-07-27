--[[ Shared beam aim + entity pick for gravitygun / freezeray / lightgun. ]]

local MAX_RANGE = 8
local STEP = 0.2
local PROBE = 0.55
local CONE_DOT = 0.72

local PICK_LISTS = {"box", "iceblock", "enemy"}

local atan2 = math.atan2 or math.atan

local function mouse_world(mx: number, my: number, xs: number, ys: number, sc: number): number, number
	if sc == 0 then
		sc = 1
	end
	return xs + mx / (16 * sc), ys + 0.5 + my / (16 * sc)
end

local function cursor_world(): number, number
	local mx, my = 0.0, 0.0
	if love and love.mouse and love.mouse.getPosition then
		mx, my = love.mouse.getPosition()
	end
	local xs = (xscroll as number) or 0
	local ys = (yscroll as number) or 0
	local sc = (scale as number) or 1
	if sc == 0 then
		sc = 1
	end
	return mouse_world(mx, my, xs, ys, sc)
end

local function aim_dir(pl: {string:any}, ox: number|nil, oy: number|nil): number, number
	local wx, wy = cursor_world()
	local sx = ox or ((pl.x as number) + 6 / 16)
	local sy = oy or ((pl.y as number) + 6 / 16)
	local dx, dy = wx - sx, wy - sy
	local len = math.sqrt(dx * dx + dy * dy)
	if len < 0.05 then
		local ang = pl.pointingangle as number
		return -math.sin(ang), -math.cos(ang)
	end
	return dx / len, dy / len
end

-- Single aim source: cursor. Angle derived from the same vector.
local function aim(pl: {string:any}): number, number, number, number, number
	local sx = (pl.x as number) + 6 / 16
	local sy = (pl.y as number) + 6 / 16
	local dx, dy = aim_dir(pl, sx, sy)
	local ang = atan2(-dx, -dy) -- inverse of (-sin, -cos)
	return sx, sy, dx, dy, ang
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

-- Enemies are grabbable while alive (no grabbable flag required).
local function enemy_usable(obj: {string:any}, pl: {string:any}): boolean
	if not obj or obj.destroying or obj.dead or obj.shot or obj.kill then
		return false
	end
	if obj.beamed and obj.beamed ~= pl then
		return false
	end
	return true
end

local function entity_usable(group: string, obj: {string:any}, pl: {string:any}): boolean
	if group == "enemy" then
		return enemy_usable(obj, pl)
	end
	return box_usable(obj, pl)
end

local function pick_cone(pl: {string:any}, sx: number, sy: number, dx: number, dy: number, maxd: number): {string:any}|nil
	if not objects then
		return nil
	end
	local best: {string:any}|nil = nil
	local bestd = maxd
	for gi = 1, #PICK_LISTS do
		local group = PICK_LISTS[gi]
		local listn = objects[group] as {any:{string:any}}|nil
		if listn ~= nil then
			local list = listn as {any:{string:any}}
			for _, raw in pairs(list) do
				local obj = raw
				if entity_usable(group, obj, pl) then
					local cx = (obj.x as number) + ((obj.width as number) or 0.75) / 2
					local cy = (obj.y as number) + ((obj.height as number) or 0.75) / 2
					local tox, toy = cx - sx, cy - sy
					local d = math.sqrt(tox * tox + toy * toy)
					if d > 0.05 and d <= bestd then
						local ndx, ndy = tox / d, toy / d
						local dot = ndx * dx + ndy * dy
						if dot >= CONE_DOT then
							obj.gg_group = group
							best = obj
							bestd = d
						end
					end
				end
			end
		end
	end
	return best
end

-- Entity pick (boxes + iceblocks + enemies). Used for grab / freeze.
local function pick_entity(pl: {string:any}, maxrange?: number): {string:any}|nil
	local range = maxrange or MAX_RANGE
	local sx, sy, dx, dy, ang = aim(pl)
	local cox, _, _, _, hx, hy = traceline(sx, sy, ang, nil)
	local hit = cox ~= false and cox ~= nil
	local maxd = clip_range(sx, sy, hx as number, hy as number, range, hit as boolean)

	local d = 0.0
	while d < maxd do
		d = d + STEP
		local x = sx + dx * d
		local y = sy + dy * d
		local col = checkrect(x - PROBE / 2, y - PROBE / 2, PROBE, PROBE, PICK_LISTS, true)
		if #col >= 2 then
			local group = col[1] as string
			local raw = (objects[group] as {any})[col[2] as integer]
			if raw then
				local obj = raw as {string:any}
				if entity_usable(group, obj, pl) then
					obj.gg_group = group
					return obj
				end
			end
		end
	end
	return pick_cone(pl, sx, sy, dx, dy, range)
end

-- Surface hit for hard-light / portal-style placement. side = face normal.
local FACE_TO_DIR: {string:string} = { up = "up", down = "down", left = "left", right = "right" }

local function aim_surface(pl: {string:any}): number, number, string
	local sx, sy, _, _, ang = aim(pl)
	local cox, coy, side = traceline(sx, sy, ang, nil)
	if cox == false or cox == nil then
		return 0, 0, ""
	end
	return cox as number, coy as number, FACE_TO_DIR[side as string] or ""
end

return {
	MAX_RANGE = MAX_RANGE,
	STEP = STEP,
	PROBE = PROBE,
	CONE_DOT = CONE_DOT,
	PICK_LISTS = PICK_LISTS,
	mouse_world = mouse_world,
	cursor_world = cursor_world,
	aim_dir = aim_dir,
	aim = aim,
	dist2 = dist2,
	clip_range = clip_range,
	box_usable = box_usable,
	enemy_usable = enemy_usable,
	entity_usable = entity_usable,
	pick_entity = pick_entity,
	aim_surface = aim_surface,
}
