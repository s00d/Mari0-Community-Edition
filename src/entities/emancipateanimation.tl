--[[ Teal port of root emancipateanimation.lua ]]

rawset(_G, "emancipateanimation", rawget(_G, "emancipateanimation") or {})

local Core = require("assets.anim8_core")

function emancipateanimation.new(_: emancipateanimation, x: number, y: number, width: any, height: any, img: any, quad: any, speedx: any, speedy: any, rotation: any, offsetX: any, offsetY: any, quadcenterX: any, quadcenterY: any): emancipateanimation
	local self = setmetatable({}, { __index = emancipateanimation }) as emancipateanimation
	self:init(x, y, width, height, img, quad, speedx, speedy, rotation, offsetX, offsetY, quadcenterX, quadcenterY)
	return self
end

emancemaxspeed = 3
emanceaccel = 20

function emancipateanimation:init(x: number, y: number, width, height, img, quad, speedx, speedy, rotation, offsetX, offsetY, quadcenterX, quadcenterY)
	self.x = x
	self.y = y
	self.width = width as number
	self.height = height as number
	self.img = img as Image
	self.quad = quad
	self.speedx = speedx as number
	self.speedy = speedy as number
	self.rotation = rotation as number
	self.offsetX = offsetX as number
	self.offsetY = offsetY as number
	self.quadcenterX = quadcenterX as number
	self.quadcenterY = quadcenterY as number
	
	self.speedx = math.max(-emancemaxspeed, math.min(emancemaxspeed, self.speedx))
	
	self.speedy = math.max(-emancemaxspeed, math.min(emancemaxspeed, self.speedy))
	
	self.rotationspeed = (math.random()-.5)*8
	self.timer = 0
	self.timer2 = 0
end

function emancipateanimation:update(dt: number): boolean
	self.speedx = self.speedx + (math.random()-.5)*dt*emanceaccel
	self.speedy = self.speedy + (math.random()-.5)*dt*emanceaccel

	self.x = self.x + self.speedx*dt
	self.y = self.y + self.speedy*dt
	
	self.rotation = self.rotation + self.rotationspeed*dt
	
	if self.timer < emancipateanimationtime-emancipatefadeouttime then
		local ticked: boolean
		self.timer2, ticked = Core.tick_interval(self.timer2, dt, emancipationfizzledelay)
		if ticked then
			table.insert(emancipationfizzles, emancipationfizzle:new(self.x+math.random()*self.width, self.y+math.random()*self.height, self.speedx, self.speedy))
		end
	end
	
	self.timer = self.timer + dt
	if self.timer > emancipateanimationtime then
		return true
	else
		return false
	end
end

function emancipateanimation:draw()
	local black = 1-self.timer/emancipateanimationtime
	local a = math.min(1, 1-(self.timer-(emancipateanimationtime-emancipatefadeouttime))/emancipatefadeouttime)

	love.graphics.setColor(black, black, black, a)
	if self.quad then
		love.graphics.draw(self.img, self.quad, entity_draw_x(self.x, self.offsetX), tile_draw_y(self.y, 0), self.rotation, scale, scale, self.quadcenterX, self.quadcenterY)
	else
		love.graphics.draw(self.img, entity_draw_x(self.x, self.offsetX), tile_draw_y(self.y, 0), self.rotation, scale, scale, self.quadcenterX, self.quadcenterY)
	end
end