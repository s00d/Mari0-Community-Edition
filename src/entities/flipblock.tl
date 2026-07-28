--[[ AE flipblock — hit to spin and become passable briefly. Port of mari0_ae/flipblock.lua. ]]

rawset(_G, "flipblock", rawget(_G, "flipblock") or {})

local FLIP_TIME = 4.0

function flipblock.new(_: flipblock, x: number, y: number): flipblock
	local self = setmetatable({}, { __index = flipblock }) as flipblock
	self:init(x, y)
	return self
end

function flipblock:init(x: number, y: number)
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
	self.category = 2
	self.gravity = 0
	self.mask = {
		true,
		false, false, false, false, false,
		false, false, false, true, false,
		false, false, true, false, false,
		true, true, false, false, false,
		false, true, true, false, false,
		true, false, true, true, true,
		false, true,
	}
	self.drawable = true
	self.graphic = flipblockimg
	local iw = (flipblockimg as Image):getWidth()
	local ih = (flipblockimg as Image):getHeight()
	self.quad = love.graphics.newQuad(0, 0, math.min(16, iw), math.min(16, ih), iw, ih)
	self.offsetX = 8
	self.offsetY = 0
	self.quadcenterX = 8
	self.quadcenterY = 8
	self.rotation = 0
	self.flip = false
	self.timer = 0
end

function flipblock:hit()
	if self.flip then
		return
	end
	playsound("blockhit")
	self.flip = true
	self.timer = 0
	self.active = false
end

function flipblock:update(dt: number): boolean
	if self.flip then
		self.timer = self.timer + dt
		self.rotation = self.timer * 12
		if self.timer >= FLIP_TIME then
			self.flip = false
			self.timer = 0
			self.rotation = 0
			self.active = true
		end
	end
	return false
end

function flipblock:ceilcollide(a: any, _: Entity): any
	if a == "player" then
		self:hit()
	end
	return true
end

function flipblock:floorcollide(a: any, _: Entity): any
	if a == "player" then
		self:hit()
	end
	return true
end
