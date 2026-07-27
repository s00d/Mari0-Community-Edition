--[[ Ball from the gravity gun: flies straight, explodes on impact, kills enemies. ]]

rawset(_G, "gravityball", rawget(_G, "gravityball") or {})

require("weapons.punt")

local SPEED = 22
local LIFETIME = 3
local TRAIL_N = 8
local EXPLODE_FRAMES = {5, 6, 7}
local FRAME_TIME = 0.05

function gravityball.new(_: gravityball, x: number, y: number, dx: number, dy: number, owner: any): gravityball
	local self = setmetatable({}, { __index = gravityball }) as gravityball
	self:init(x, y, dx, dy, owner)
	return self
end

function gravityball:init(x: number, y: number, dx: number, dy: number, owner: any)
	self.width = 8 / 16
	self.height = 8 / 16
	self.x = x - self.width / 2
	self.y = y - self.height / 2
	self.speedx = dx * SPEED
	self.speedy = dy * SPEED

	self.static = false
	self.active = true
	self.category = 13 -- same as fireball: reuse existing masks
	-- Literal copy of fireball.tl mask
	self.mask = {	true,
					false, true, false, false, true,
					false, true, false, true, false,
					false, true, false, true, false,
					true, true, false, false, false,
					false, true, false, false, true,
					false, false, false, false, true}
	self.gravity = 0 -- straight flight
	self.gravitydirection = math.pi / 2
	self.portalable = true
	self.autodelete = true
	self.emancipatecheck = true

	self.owner = owner
	self.timer = 0
	self.frametimer = 0
	self.state = "flying"
	self.frame = 1
	self.bounces_left = 2
	self.gelreactive = true

	self.drawable = true
	self.graphic = fireballimg
	self.quad = fireballquad[1]
	self.offsetX = 4
	self.offsetY = 4
	self.quadcenterX = 4
	self.quadcenterY = 4
	self.rotation = 0

	-- Preallocated trail ring: zero allocs per frame
	self.trail = {}
	for i = 1, TRAIL_N do
		self.trail[i] = { x = self.x, y = self.y }
	end
	self.traili = 1
end

function gravityball:update(dt: number): boolean
	self.rotation = 0
	self.timer = self.timer + dt

	if self.state == "exploding" then
		self.frametimer = self.frametimer + dt
		while self.frametimer > FRAME_TIME do
			self.frametimer = self.frametimer - FRAME_TIME
			self.frame = self.frame + 1
			if self.frame > #EXPLODE_FRAMES then
				return true
			end
			self.quad = fireballquad[EXPLODE_FRAMES[self.frame as integer]]
		end
		return false
	end

	self.traili = self.traili % TRAIL_N + 1
	local slot = self.trail[self.traili as integer]
	slot.x = self.x
	slot.y = self.y

	self.quad = fireballquad[math.floor(self.timer / 0.04) % 4 + 1]

	if self.timer > LIFETIME then
		self:explode()
	end
	return false
end

function gravityball:hitstuff(a: any, b: Entity, dir: string|nil)
	if self.state ~= "flying" then
		return
	end
	if a == "player" then
		return
	end
	-- Bounce gel: reflect instead of explode while bounces remain.
	if a == "tile" and (self.bounces_left as number) > 0 and b.cox and b.coy then
		local x, y = b.cox as number, b.coy as number
		local gid: number|nil = nil
		local d = dir or "floor"
		if d == "floor" then
			gid = map_cell_gel_id(map[x][y], GEL_SIDE_TOP)
		elseif d == "ceil" then
			gid = map_cell_gel_id(map[x][y], GEL_SIDE_BOTTOM)
		elseif d == "left" then
			gid = map_cell_gel_id(map[x][y], GEL_SIDE_RIGHT)
		elseif d == "right" then
			gid = map_cell_gel_id(map[x][y], GEL_SIDE_LEFT)
		end
		if gel_has(gid, "bounce") then
			self.bounces_left = (self.bounces_left as number) - 1
			-- Floor/side already handled by gel_react when gelreactive; ceil needs reflect.
			if d == "ceil" then
				self.speedy = -(self.speedy as number)
			elseif d == "floor" and not self.gelreactive then
				self.speedy = -(self.speedy as number)
			elseif d == "left" or d == "right" then
				if not self.gelreactive then
					self.speedx = -(self.speedx as number)
				end
			end
			return
		end
	end
	if a == "enemy" or a == "bowser" then
		if punt_kill_entity(b as {string:any}) then
			if addpoints then
				addpoints((b.firepoints as number) or 200, self.x, self.y)
			end
		end
	end
	self:explode()
end

function gravityball:explode()
	if self.state ~= "flying" then
		return
	end
	self.state = "exploding"
	self.active = false
	self.speedx = 0
	self.speedy = 0
	self.width = 1
	self.height = 1
	self.offsetX = 8
	self.offsetY = 8
	self.quadcenterX = 8
	self.quadcenterY = 8
	self.frame = 1
	self.frametimer = 0
	self.quad = fireballquad[EXPLODE_FRAMES[1]]
	if playsound then
		playsound("blockhit")
	end
	earthquake = math.max((earthquake as number) or 0, 0.12)
end

function gravityball:leftcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b, "left")
	return false
end

function gravityball:rightcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b, "right")
	return false
end

function gravityball:floorcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b, "floor")
	return false
end

function gravityball:ceilcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b, "ceil")
	return false
end

function gravityball:passivecollide(a: any, b: Entity): boolean
	self:hitstuff(a, b, "floor")
	return false
end

function gravityball:emancipate(): any
	self:explode()
	return nil
end
