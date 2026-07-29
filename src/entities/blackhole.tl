--[[ Black-hole projectile: fly → suck nearby boxes/enemies/tiles → radial fling. ]]

rawset(_G, "blackhole", rawget(_G, "blackhole") or {})

require("weapons.punt")

local SPEED = 16
local FLY_TIME = 0.45
local SUCK_TIME = 0.9
local BLAST_TIME = 0.18
local SUCK_RADIUS = 4
local MAX_VICTIMS = 8
local MAX_TILES = 3
local OMEGA = 18
local MAXV = 50
local FLING_MIN = 18
local FLING_MAX = 28
local TRAIL_N = 10
local ORBIT_N = 6

local atan2 = math.atan2 or math.atan

local function cx(self: blackhole): number
	return (self.x as number) + (self.width as number) / 2
end

local function cy(self: blackhole): number
	return (self.y as number) + (self.height as number) / 2
end

local function dist2(ax: number, ay: number, bx: number, by: number): number
	local dx = ax - bx
	local dy = ay - by
	return dx * dx + dy * dy
end

local function spring_step(pos: number, vel: number, target: number, omega: number, dt: number): number, number
	if Weapons and Weapons.gravitygun and Weapons.gravitygun.spring_step then
		return (Weapons.gravitygun.spring_step as function(number, number, number, number, number): number, number)(
			pos, vel, target, omega, dt)
	end
	local x = pos - target
	local a = -2 * omega * vel - omega * omega * x
	vel = vel + a * dt
	pos = pos + vel * dt
	return pos, vel
end

local function mark_victim(self: blackhole, obj: {string:any})
	if obj.bh_grabbed then
		return
	end
	if not obj.bh_saved then
		obj.bh_saved = {
			gravity = obj.gravity,
			movement = obj.movement,
		}
	end
	obj.bh_grabbed = true
	obj.beamed = self
	obj.gravity = 0
	obj.parent = nil
	if obj.movement ~= nil then
		obj.movement = nil
	end
	obj.active = true
	table.insert(self.victims as {any}, obj)
end

local function release_victim(obj: {string:any})
	if not obj then
		return
	end
	local saved_raw = obj.bh_saved
	if type(saved_raw) == "table" then
		local saved = saved_raw as {string:any}
		obj.gravity = saved["gravity"]
		obj.movement = saved["movement"]
		obj.bh_saved = nil
	else
		obj.gravity = nil
	end
	obj.beamed = nil
	obj.bh_grabbed = nil
end

local function already_victim(self: blackhole, obj: {string:any}): boolean
	local list = self.victims as {any}
	for i = 1, #list do
		if list[i] == obj then
			return true
		end
	end
	return false
end

function blackhole.new(_: blackhole, x: number, y: number, dx: number, dy: number, owner: any): blackhole
	local self = setmetatable({}, { __index = blackhole }) as blackhole
	self:init(x, y, dx, dy, owner)
	return self
end

function blackhole:init(x: number, y: number, dx: number, dy: number, owner: any)
	self.width = 10 / 16
	self.height = 10 / 16
	self.x = x - self.width / 2
	self.y = y - self.height / 2
	self.speedx = dx * SPEED
	self.speedy = dy * SPEED

	self.static = false
	self.active = true
	self.category = 13
	self.mask = {	true,
					false, true, false, false, true,
					false, true, false, true, false,
					false, true, false, true, false,
					true, true, false, false, false,
					false, true, false, false, true,
					false, false, false, false, true}
	self.gravity = 0
	self.gravitydirection = math.pi / 2
	self.portalable = true
	self.autodelete = true
	self.emancipatecheck = true

	self.owner = owner
	self.timer = 0
	self.phasetimer = 0
	self.state = "flying"
	self.tiles_pulled = 0
	self.victims = {} as {any}
	self.orbit_a = 0
	self.blast_flash = 0

	-- Procedural only — drawn via :draw(), not spritebatch path.
	self.drawable = false
	self.rotation = 0

	self.trail = {}
	for i = 1, TRAIL_N do
		self.trail[i] = { x = self.x, y = self.y }
	end
	self.traili = 1
end

local function begin_suck(self: blackhole)
	if self.state ~= "flying" then
		return
	end
	self.state = "sucking"
	self.phasetimer = 0
	self.speedx = 0
	self.speedy = 0
	self.active = false -- stay put; attract via spring velocities on victims
	if playsound then
		playsound("portalgun")
	end
end

local function try_pull_tiles(self: blackhole)
	if (self.tiles_pulled as number) >= MAX_TILES then
		return
	end
	local gg = Weapons and Weapons.gravitygun
	if not gg then
		return
	end
	local can_grab = gg.tile_can_grab as function(number, number): boolean
	local extract = gg.extract_tile as function(number, number): {string:any}|nil
	if not can_grab or not extract then
		return
	end
	local hx, hy = cx(self), cy(self)
	local best_d: number = SUCK_RADIUS * SUCK_RADIUS
	local bx: number|nil = nil
	local by: number|nil = nil
	local ix = math.floor(hx)
	local iy = math.floor(hy)
	for y = iy - 3, iy + 3 do
		for x = ix - 3, ix + 3 do
			if can_grab(x, y) then
				local d = dist2(hx, hy, x - 0.5, y - 0.5)
				if d < best_d then
					best_d = d
					bx = x
					by = y
				end
			end
		end
	end
	if bx and by then
		local prop = extract(bx, by)
		if prop then
			self.tiles_pulled = (self.tiles_pulled as number) + 1
			if not already_victim(self, prop) and #(self.victims as {any}) < MAX_VICTIMS then
				mark_victim(self, prop)
			end
		end
	end
end

local function gather_targets(self: blackhole)
	local hx, hy = cx(self), cy(self)
	local r2 = SUCK_RADIUS * SUCK_RADIUS
	local list = self.victims as {any}
	if #list >= MAX_VICTIMS then
		return
	end

	local function consider(obj_any: any)
		if type(obj_any) ~= "table" then
			return
		end
		local obj = obj_any as {string:any}
		if obj.destroying or obj.dead or obj.kill then
			return
		end
		if already_victim(self, obj) then
			return
		end
		if #list >= MAX_VICTIMS then
			return
		end
		local ox = (obj.x as number) + ((obj.width as number) or 0.75) / 2
		local oy = (obj.y as number) + ((obj.height as number) or 0.75) / 2
		if dist2(hx, hy, ox, oy) <= r2 then
			mark_victim(self, obj)
		end
	end

	if objects and objects["box"] then
		for _, v in pairs(objects["box"] as {any:{string:any}}) do
			consider(v)
		end
	end
	if objects and objects["enemy"] then
		for _, v in pairs(objects["enemy"] as {any:{string:any}}) do
			consider(v)
		end
	end
end

local function attract_victims(self: blackhole, dt: number)
	local hx, hy = cx(self), cy(self)
	local list = self.victims as {any}
	for i = 1, #list do
		local obj = list[i] as {string:any}
		if obj and not obj.destroying then
			local ow = (obj.width as number) or 0.75
			local oh = (obj.height as number) or 0.75
			local tx = hx - ow / 2
			local ty = hy - oh / 2
			local px = obj.x as number
			local py = obj.y as number
			local vx = (obj.speedx as number) or 0
			local vy = (obj.speedy as number) or 0
			px, vx = spring_step(px, vx, tx, OMEGA, dt)
			py, vy = spring_step(py, vy, ty, OMEGA, dt)
			local sp = math.sqrt(vx * vx + vy * vy)
			if sp > MAXV then
				vx = vx * (MAXV / sp)
				vy = vy * (MAXV / sp)
			end
			obj.x = px
			obj.y = py
			obj.speedx = vx
			obj.speedy = vy
			obj.gravity = 0
			obj.parent = nil
		end
	end
end

local function do_blast(self: blackhole)
	if self.state ~= "sucking" then
		return
	end
	self.state = "blast"
	self.phasetimer = 0
	self.blast_flash = 1
	local hx, hy = cx(self), cy(self)
	local list = self.victims as {any}
	for i = 1, #list do
		local obj = list[i] as {string:any}
		if obj and not obj.destroying then
			local ox = (obj.x as number) + ((obj.width as number) or 0.75) / 2
			local oy = (obj.y as number) + ((obj.height as number) or 0.75) / 2
			local ang = atan2(oy - hy, ox - hx)
			if ang ~= ang then -- nan
				ang = math.random() * math.pi * 2
			end
			ang = ang + (math.random() - 0.5) * (math.pi * 2 / 3)
			local spd = FLING_MIN + math.random() * (FLING_MAX - FLING_MIN)
			obj.speedx = math.cos(ang) * spd
			obj.speedy = math.sin(ang) * spd
			obj.punttimer = 0.45
			release_victim(obj)
		end
	end
	self.victims = {} as {any}
	if playsound then
		playsound("boom")
	end
	earthquake = math.max((earthquake as number) or 0, 0.35)
end

function blackhole:update(dt: number): boolean
	self.rotation = 0
	self.timer = (self.timer as number) + dt
	self.phasetimer = (self.phasetimer as number) + dt
	self.orbit_a = (self.orbit_a as number) + dt * 6

	self.traili = (self.traili as integer) % TRAIL_N + 1
	local slot = self.trail[self.traili as integer]
	slot.x = self.x
	slot.y = self.y

	if self.state == "flying" then
		if (self.phasetimer as number) >= FLY_TIME then
			begin_suck(self)
		end
		return false
	end

	if self.state == "sucking" then
		gather_targets(self)
		-- Pull a tile every ~0.28s while sucking
		if math.floor((self.phasetimer as number) / 0.28) > (self.tiles_pulled as number) then
			try_pull_tiles(self)
		end
		attract_victims(self, dt)
		if (self.phasetimer as number) >= SUCK_TIME then
			do_blast(self)
		end
		return false
	end

	if self.state == "blast" then
		self.blast_flash = math.max(0, (self.blast_flash as number) - dt / BLAST_TIME)
		if (self.phasetimer as number) >= BLAST_TIME then
			return true
		end
		return false
	end

	return false
end

function blackhole:hitstuff(a: any, _: Entity)
	if self.state ~= "flying" then
		return
	end
	if a == "player" then
		return
	end
	begin_suck(self)
end

function blackhole:leftcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b)
	return false
end

function blackhole:rightcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b)
	return false
end

function blackhole:floorcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b)
	return false
end

function blackhole:ceilcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b)
	return false
end

function blackhole:passivecollide(a: any, b: Entity): boolean
	self:hitstuff(a, b)
	return false
end

function blackhole:emancipate(): any
	if self.state == "flying" then
		begin_suck(self)
	elseif self.state == "sucking" then
		do_blast(self)
	end
	return nil
end

function blackhole:draw()
	if not love or not love.graphics then
		return
	end
	local sc = world_draw_scale()
	if sc == 0 then
		sc = 1
	end
	local hx, hy = cx(self), cy(self)
	local sx, sy = weapon_draw_xy(hx, hy)
	local t = self.timer as number
	local pt = self.phasetimer as number
	local st = self.state as string

	-- Trail
	local trail = self.trail as {{string:number}}
	local n = #trail
	local head = self.traili as integer
	for k = 1, n - 1 do
		local i0 = (head - k - 1) % n + 1
		local i1 = (head - k) % n + 1
		local a = 1 - k / n
		local x0, y0 = weapon_draw_xy(trail[i0].x + self.width / 2, trail[i0].y + self.height / 2)
		local x1, y1 = weapon_draw_xy(trail[i1].x + self.width / 2, trail[i1].y + self.height / 2)
		love.graphics.setColor(0.35, 0.05, 0.55, a * 0.65)
		love.graphics.setLineWidth(sc * a * 2.2)
		love.graphics.line(x0, y0, x1, y1)
	end

	local core_r = sc * (st == "blast" and 14 or (st == "sucking" and 9 or 6))

	-- Accretion disk (sucking / flying)
	if st ~= "blast" then
		love.graphics.setLineWidth(sc * 1.2)
		for ring = 1, 3 do
			local rr = core_r * (1.6 + ring * 0.55 + 0.08 * math.sin(t * 9 + ring))
			local a = (st == "sucking" and 0.55 or 0.28) * (1 - (ring - 1) * 0.25)
			love.graphics.setColor(0.55 + ring * 0.1, 0.1, 0.95, a)
			love.graphics.circle("line", sx, sy, rr)
		end
		-- Spiral arms
		local oa0 = self.orbit_a as number
		for arm = 1, 4 do
			local base = oa0 + (arm - 1) * (math.pi / 2)
			love.graphics.setColor(0.65, 0.2, 1.0, st == "sucking" and 0.45 or 0.22)
			love.graphics.setLineWidth(sc * 1.1)
			local px, py = sx, sy
			for step = 1, 10 do
				local ang = base + step * 0.35
				local rad = core_r * (0.9 + step * 0.28)
				local nx = sx + math.cos(ang) * rad
				local ny = sy + math.sin(ang) * rad
				love.graphics.line(px, py, nx, ny)
				px, py = nx, ny
			end
		end
	end

	-- Outer glow
	love.graphics.setColor(0.45, 0.1, 0.75, 0.35)
	love.graphics.circle("fill", sx, sy, core_r * 1.8)
	-- Purple ring
	love.graphics.setColor(0.7, 0.25, 1.0, 0.9)
	love.graphics.setLineWidth(sc * 1.5)
	love.graphics.circle("line", sx, sy, core_r * 1.15)
	-- Black core
	love.graphics.setColor(0.02, 0.0, 0.05, 1)
	love.graphics.circle("fill", sx, sy, core_r)

	-- Orbiting sparks (more while sucking)
	local oa = self.orbit_a as number
	local sparks = st == "sucking" and (ORBIT_N * 2) or ORBIT_N
	for i = 1, sparks do
		local ang = oa * (1 + (st == "sucking" and 0.4 or 0)) + (i - 1) * (math.pi * 2 / sparks)
		local rr = core_r * (1.4 + 0.15 * math.sin(oa * 2 + i) + (st == "sucking" and 0.35 * math.sin(t * 7 + i) or 0))
		local px = sx + math.cos(ang) * rr
		local py = sy + math.sin(ang) * rr
		love.graphics.setColor(0.85, 0.55, 1.0, 0.85)
		love.graphics.circle("fill", px, py, sc * (st == "sucking" and 1.8 or 1.4))
	end

	-- Inward dust while sucking
	if st == "sucking" then
		for i = 1, 18 do
			local seed = i * 17.13 + pt * 4
			local ang = seed + math.sin(seed) * 3
			local life = math.fmod(pt * 2.2 + i * 0.17, 1)
			local rad = core_r * (3.2 - life * 2.6)
			local px = sx + math.cos(ang) * rad
			local py = sy + math.sin(ang) * rad
			love.graphics.setColor(0.7, 0.35, 1.0, (1 - life) * 0.7)
			love.graphics.circle("fill", px, py, sc * (1.2 + (1 - life)))
		end
		local list = self.victims as {any}
		for i = 1, #list do
			local obj = list[i] as {string:any}
			if obj then
				local ox = (obj.x as number) + ((obj.width as number) or 0.75) / 2
				local oy = (obj.y as number) + ((obj.height as number) or 0.75) / 2
				local x2, y2 = weapon_draw_xy(ox, oy)
				love.graphics.setColor(0.55, 0.15, 0.9, 0.55)
				love.graphics.setLineWidth(sc)
				love.graphics.line(sx, sy, x2, y2)
			end
		end
	end

	-- Blast flash + expanding shock rings
	if st == "blast" then
		local f = self.blast_flash as number
		love.graphics.setColor(0.9, 0.6, 1.0, f * 0.7)
		love.graphics.circle("fill", sx, sy, sc * (10 + (1 - f) * 30))
		love.graphics.setLineWidth(sc * 2)
		for ring = 1, 3 do
			local expand = (1 - f) * (18 + ring * 14)
			love.graphics.setColor(0.75, 0.35, 1.0, f * (0.9 - ring * 0.2))
			love.graphics.circle("line", sx, sy, sc * expand)
		end
		-- Debris sparks outward
		for i = 1, 12 do
			local ang = i * (math.pi * 2 / 12) + t
			local rad = sc * (8 + (1 - f) * 40)
			love.graphics.setColor(1, 0.8, 1, f * 0.85)
			love.graphics.circle("fill", sx + math.cos(ang) * rad, sy + math.sin(ang) * rad, sc * 2)
		end
	end

	love.graphics.setColor(1, 1, 1, 1)
end
