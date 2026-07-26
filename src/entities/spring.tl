--[[ Teal port of root spring.lua ]]

rawset(_G, "spring", rawget(_G, "spring") or {})

function spring.new(_: spring, x: number, y: number): spring
	local self = setmetatable({}, { __index = spring }) as spring
	self:init(x, y)
	return self
end

function spring:init(x: number, y: number)
	self.cox = x
	self.coy = y
	
	--PHYSICS STUFF
	self.x = x-1
	self.y = y-31/16
	self.width = 16/16
	self.height = 31/16
	self.static = true
	self.active = true
	
	self.drawable = false
	
	self.timer = springtime
	
	self.category = 19
	
	self.mask = {true}
	
	self.frame = 1
end

function spring:update(dt: number): any...
	if self.timer < springtime then
		self.timer = self.timer + dt
		if self.timer > springtime then
			self.timer = springtime
		end
		self.frame = math.ceil(self.timer/(springtime/3)+0.001)+1
		if self.frame > 3 then
			self.frame = 6-self.frame
		end
	end
end

function spring:draw()
	love.graphics.draw(springimg, springquads[spriteset][self.frame], math.floor((self.x-xscroll)*16*scale), ((self.y-yscroll)*16-8)*scale, 0, scale, scale)
end

function spring:hit()
	self.timer = 0
end