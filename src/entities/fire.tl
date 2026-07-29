--[[ Teal port of root fire.lua ]]

rawset(_G, "fire", rawget(_G, "fire") or {})

local Anim8Effects = require("assets.anim8_effects")

function fire.new(_: fire, x: number, y: number): fire
	local self = setmetatable({}, { __index = fire }) as fire
	self:init(x, y)
	return self
end

function fire:init(x: number, y: number)
	--PHYSICS STUFF
	if objects["bowser"][1] then --make bowser fire this
		self.y = objects["bowser"][1].y+0.25
		self.x = objects["bowser"][1].x-0.750
		
		--get goal Y
		self.targety = objects["bowser"][1].starty-math.random(3)+2/16
	else
		self.y = y-1+1/16
		self.targety = self.y
		self.x = x+6/16
	end
	
	self.speedy = 0
	self.speedx = -firespeed
	
	self.width = 24/16
	self.height = 8/16
	self.active = true
	self.static = true
	self.autodelete = true
	self.gravity = 0
	self.category = 17
	
	self.mask = {	true,
					true, false, true, true, true,
					true, true, true, true, true,
					true, true, true, true, true,
					true, true, true, true, true,
					true, true, true, true, true,
					true, true, true, true, true}
	
	--IMAGE STUFF
	self.drawable = true
	self.graphic = fireimg
	self.quad = firequad[1]
	self.offsetX = 0
	self.offsetY = 8
	self.quadcenterX = 0
	self.quadcenterY = 0
	
	self.rotation = 0 --for portals
	self.timer = 0
	self.quadi = 1
	(self as {string:any})["fire_anim"] = Anim8Effects.new_fire()
	
	playsound("fire")
end

function fire:update(dt: number)
	local anim = (self as {string:any})["fire_anim"] as Anim8Animation|nil
	self.quad = Anim8Effects.step_fire(anim, dt)
	
	self.x = self.x + self.speedx*dt
	
	if self.y > self.targety then
		self.y = self.y - fireverspeed*dt
		if self.y < self.targety then
			self.y = self.targety
		end
	elseif self.y < self.targety then
		self.y = self.y + fireverspeed*dt
		if self.y > self.targety then
			self.y = self.targety
		end
	end
end

function fire:leftcollide(_: any, _: Entity): boolean
	return false
end

function fire:rightcollide(_: any, _: Entity): boolean
	return false
end

function fire:floorcollide(_: any, _: Entity): boolean
	return false
end

function fire:ceilcollide(_: any, _: Entity): boolean
	return false
end