--[[ Teal port of root castlefire.lua ]]

rawset(_G, "castlefire", rawget(_G, "castlefire") or {})
rawset(_G, "castlefirefire", rawget(_G, "castlefirefire") or {})

local Anim8Effects = require("assets.anim8_effects")

function castlefire.new(_: castlefire, x: number, y: number, r: {any}): castlefire
	local self = setmetatable({}, { __index = castlefire }) as castlefire
	self:init(x, y, r)
	return self
end

function castlefire:init(x: number, y: number, r)
	self.x = x
	self.y = y+1/16
	self.length = 6
	self.dir = "cw"
	self.quadi = 1
	self.child = {}
	self.delay = castlefiredelay
	
	--Input list
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	--RANGE
	if #self.r > 0 and self.r[1] ~= "link" then
		self.length = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	--DELAY
	if #self.r > 0 and self.r[1] ~= "link" then
		self.delay = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	--DIR
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			self.dir = "ccw"
			table.remove(self.r, 1)
		end
	end
	
	for _ = 1, self.length do
		local temp = castlefirefire:new()
		table.insert(session.objects["castlefirefire"], temp)
		table.insert(self.child, temp)
	end
	self.angle = 0
	self.timer = 0
	self.timer2 = 0
	(self as {string:any})["sprite_anim"] = Anim8Effects.new_fireball_loop()
	
	self:updatepos()
	self:updatequad()
end

function castlefire:update(dt: number)
	self.timer = self.timer + dt
	
	while self.timer > self.delay do
		self.timer = self.timer - self.delay
		if self.dir == "cw" then
			self.angle = self.angle + castlefireangleadd
			self.angle = math.fmod(self.angle, 360)
		else
			self.angle = self.angle - castlefireangleadd
			while self.angle < 0 do
				self.angle = self.angle + 360
			end
		end
		
		self:updatepos()
	end
	
	self.timer2 = self.timer2 + dt
	local anim = (self as {string:any})["sprite_anim"] as Anim8Animation|nil
	Anim8Effects.step_fireball_loop(anim, dt)
	self.quadi = anim and (anim as Anim8Animation).position or self.quadi
	self:updatequad()
end

function castlefire:updatepos()
	local x = self.x-.5
	local y = self.y-.5
	
	for i = 1, self.length do
		local xadd = math.cos(math.rad(self.angle))*(i-1)*0.5
		local yadd = math.sin(math.rad(self.angle))*(i-1)*0.5
		
		self.child[i as integer].x = x+xadd-0.25
		self.child[i as integer].y = y+yadd-0.25
	end
end

function castlefire:updatequad()	
	for i = 1, self.length do
		self.child[i as integer].quad = fireballquad[self.quadi]
	end
end

--------------

function castlefirefire.new(_: castlefirefire): castlefirefire
	local self = setmetatable({}, { __index = castlefirefire }) as castlefirefire
	self:init()
	return self
end

function castlefirefire:init()
	--PHYSICS STUFF
	self.y = 0
	self.x = 0
	self.width = 8/16
	self.height = 8/16
	self.active = true
	self.static = true
	self.category = 23
	
	self.kills = true
	
	self.mask = {	true,
					true, false, true, true, true,
					true, true, true, true, true,
					true, true, true, true, true,
					true, true, true, true, true,
					true, true, true, true, true,
					true, true, true, true, true}
	
	--IMAGE STUFF
	self.drawable = true
	self.graphic = fireballimg
	self.quad = fireballquad[1]
	self.offsetX = 4
	self.offsetY = 4
	self.quadcenterX = 4
	self.quadcenterY = 4
end