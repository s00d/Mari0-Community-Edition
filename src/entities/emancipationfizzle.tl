--[[ Teal port of root emancipationfizzle.lua ]]

rawset(_G, "emancipationfizzle", rawget(_G, "emancipationfizzle") or {})

function emancipationfizzle.new(_: emancipationfizzle, x: number, y: number, speedx: any, speedy: any): emancipationfizzle
	local self = setmetatable({}, { __index = emancipationfizzle }) as emancipationfizzle
	self:init(x, y, speedx, speedy)
	return self
end

function emancipationfizzle:init(x: number, y: number, speedx, speedy)
	self.x = x
	self.y = y
	self.r = math.random()*math.pi*2
	self.rotspeed = (math.random()-.5)*2
	self.speedx = (speedx as number)+(math.random()-.5)*1
	self.speedy = (speedy as number)+(math.random()-.5)*1
	
	self.timer = 0
end

function emancipationfizzle:update(dt: number): boolean
	self.x = self.x + self.speedx*dt
	self.y = self.y + self.speedy*dt
	
	self.r = (self.r as number) + self.rotspeed*dt
	
	self.timer = self.timer + dt
	if self.timer > emancipationfizzletime then
		return true
	end	
	return false
end

function emancipationfizzle:draw()
	love.graphics.setColor((1-self.timer/emancipationfizzletime), (1-self.timer/emancipationfizzletime), (1-self.timer/emancipationfizzletime), (1-self.timer/emancipationfizzletime))
	love.graphics.draw(fizzleimg, (self.x-xscroll)*16*scale, (self.y-yscroll-.5)*16*scale, self.r, scale, scale, 2, 1)
end