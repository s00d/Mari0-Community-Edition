--[[ Teal port of root fireball.lua ]]

rawset(_G, "fireball", rawget(_G, "fireball") or {})

local Anim8Effects = require("assets.anim8_effects")

function fireball.new(_: fireball, x: number, y: number, dir: any, v: any): fireball
	local self = setmetatable({}, { __index = fireball }) as fireball
	self:init(x, y, dir, v)
	return self
end

function fireball:init(x: number, y: number, dir, v)
	--PHYSICS STUFF
	self.y = y+4/16
	self.speedy = 0
	if dir == "right" then
		self.speedx = fireballspeed
		self.x = x+6/16
	else
		self.speedx = -fireballspeed
		self.x = x
	end
	self.width = 8/16
	self.height = 8/16
	self.active = true
	self.static = false
	self.category = 13
	
	self.mask = {	true,
					false, true, false, false, true,
					false, true, false, true, false,
					false, true, false, true, false,
					true, true, false, false, false,
					false, true, false, false, true,
					false, false, false, false, true}
					
	self.destroy = false
	self.destroysoon = false
	--self.gravity = 40
	
	--IMAGE STUFF
	self.drawable = true
	self.graphic = fireballimg
	self.quad = fireballquad[1]
	self.offsetX = 4
	self.offsetY = 4
	self.quadcenterX = 4
	self.quadcenterY = 4
	
	self.fireballthrower = v as Entity
	
	self.rotation = 0 --for portals
	self.gravitydirection = math.pi/2
	self.timer = 0
	self.quadi = 1
	(self as {string:any})["loop_anim"] = Anim8Effects.new_fireball_loop()
	(self as {string:any})["die_anim"] = nil
	
	self.emancipatecheck = true
end

local function fireball_notify_thrower(self: fireball)
	local thrower = self.fireballthrower
	if not thrower then
		return
	end
	local bag = thrower as {string:any}
	local cb = bag.fireballcallback
	if cb then
		(cb as function({string:any}))(bag)
	end
end

function fireball:update(dt: number): boolean
	--rotate back to 0 (portals)
	self.rotation = 0
	
	local bag = self as {string:any}
	if self.destroysoon == false then
		self.quad = Anim8Effects.step_fireball_loop(bag["loop_anim"] as Anim8Animation|nil, dt)
	else
		local quad: any
		local done: boolean
		quad, done = Anim8Effects.step_fireball_die(bag["die_anim"] as Anim8Animation|nil, dt)
		self.quad = quad
		if done then
			self.destroy = true
		end
	end
	
	if self.x < session.xscroll-1 or self.x > session.xscroll+width+1 or self.y > session.mapheight and self.active then
		fireball_notify_thrower(self)
		self.destroy = true
	end
	
	if self.destroy then
		return true
	else
		return false
	end
end

function fireball:leftcollide(a: any, b: Entity): any
	self.x = self.x-.5
	self:hitstuff(a, b)
	
	self.speedx = fireballspeed
	return false
end

function fireball:rightcollide(a: any, b: Entity): any
	self:hitstuff(a, b)
	
	self.speedx = -fireballspeed
	return false
end

function fireball:floorcollide(a: any, b: Entity): any
	if a ~= "tile" and a ~= "portalwall" then
		self:hitstuff(a, b)
	end
	
	self.speedy = -fireballjumpforce
	return false
end

function fireball:ceilcollide(a: any, b: Entity): any
	self:hitstuff(a, b)
	return false
end

function fireball:passivecollide(a: any, b: Entity): any
	self:ceilcollide(a, b)
	return false
end

function fireball:hitstuff(a, b)
	local ent = b as Entity
	if a == "tile" or a == "bulletbill" or a == "portalwall" or a == "spring" then
		self:explode()
		playsound("blockhit")
		
	elseif a == "player" then
		-- Enemy bullets (kills=true): Mario dies via his collide; just remove the shot.
		if self.kills then
			self:explode()
		end
	elseif a == "enemy" or a == "bowser" then
		-- Don't let turret/enemy bullets destroy their owner on spawn overlap.
		if ent == self.fireballthrower then
			return
		end
		if ent:shotted("right", false, false, true) ~= false then
			if a ~= "bowser" then
				addpoints((ent.firepoints as number) or 200, self.x, self.y)
			end
		end
		self:explode()
	end
end

function fireball:explode()
	if self.active then
		fireball_notify_thrower(self)
		
		self.destroysoon = true
		local bag = self as {string:any}
		bag["die_anim"] = Anim8Effects.new_fireball_die()
		self.quadi = 5
		self.quad = fireballquad[5]
		self.active = false
	end
end

function fireball:emancipate(): any
	if not self.kill then
		table.insert(emancipateanimations, emancipateanimation:new(self.x, self.y, self.width, self.height, self.graphic, self.quad, self.speedx, self.speedy, self.rotation, self.offsetX, self.offsetY, self.quadcenterX, self.quadcenterY))
		self.kill = true
		self.drawable = false
	end
	return nil
end