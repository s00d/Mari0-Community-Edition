--[[ AE donut block — falls after stood on. Port of mari0_ae/donut.lua (alesan99). ]]

rawset(_G, "donut", rawget(_G, "donut") or {})

function donut.new(_: donut, x: number, y: number, r: {any}): donut
	local self = setmetatable({}, { __index = donut }) as donut
	self:init(x, y, r)
	return self
end

function donut:init(x: number, y: number, _: {any})
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
	self.mask = {true}
	self.autodelete = true
	self.drawable = true
	self.graphic = donutimg
	self.quad = love.graphics.newQuad(0, 0, 16, 16, (donutimg as Image):getWidth(), (donutimg as Image):getHeight())
	self.offsetX = 8
	self.offsetY = 0
	self.quadcenterX = 8
	self.quadcenterY = 8
	self.rotation = 0
	self.falling = false
	self.fallingtimer = 0
	self.shaketimer = 0
	self.PLATFORM = true
end

function donut:update(dt: number): boolean
	if self.falling then
		self.fallingtimer = self.fallingtimer + dt
		self.shaketimer = (self.shaketimer + 8 * dt) % 1
		self.offsetX = 7 + math.floor(math.abs(self.shaketimer - 0.5) * 4 + 0.5)
		if self.fallingtimer > 0.4 then
			self.speedy = 8
			self.offsetX = 8
		end
		if self.y > session.mapheight + 2 then
			return true
		end
	end
	return false
end

function donut:ceilcollide(a: any, _: Entity): any
	if a == "player" then
		self.falling = true
		self.static = false
	end
	return true
end

function donut:leftcollide(_: any, _: Entity): any
	return false
end

function donut:rightcollide(_: any, _: Entity): any
	return false
end

function donut:floorcollide(_: any, _: Entity): any
	return false
end
