--[[ AE small spring. Port of mari0_ae/smallspring.lua (vertical only). ]]

rawset(_G, "smallspring", rawget(_G, "smallspring") or {})

function smallspring.new(_: smallspring, x: number, y: number): smallspring
	local self = setmetatable({}, { __index = smallspring }) as smallspring
	self:init(x, y)
	return self
end

function smallspring:init(x: number, y: number)
	self.cox = x
	self.coy = y
	self.x = x - 1
	self.y = y - 1
	self.width = 1
	self.height = 1
	self.speedx = 0
	self.speedy = 0
	self.static = true
	self.active = true
	self.category = 19
	self.mask = {true}
	self.drawable = true
	self.graphic = smallspringimg
	local iw = (smallspringimg as Image):getWidth()
	local ih = (smallspringimg as Image):getHeight()
	self.quad = love.graphics.newQuad(0, 0, math.min(16, iw), math.min(16, ih), iw, ih)
	self.offsetX = 8
	self.offsetY = 0
	self.quadcenterX = 8
	self.quadcenterY = 8
	self.rotation = 0
	self.timer = 0
	self.frame = 1
end

function smallspring:update(dt: number): boolean
	if self.timer > 0 then
		self.timer = self.timer - dt
		if self.timer < 0 then
			self.timer = 0
		end
	end
	return false
end

function smallspring:hit()
	self.timer = springtime or 0.2
end

function smallspring:ceilcollide(a: any, b: Entity): any
	if a == "player" then
		self:hit()
		local pl = b as mario
		pl.speedy = -(springhighforce or 20)
		pl:hitspring(self as Entity)
	end
	return true
end
