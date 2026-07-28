--[[ AE long fire jet. Port of mari0_ae/longfire.lua (simplified). ]]

rawset(_G, "longfire", rawget(_G, "longfire") or {})

function longfire.new(_: longfire, x: number, y: number, r: {any}): longfire
	local self = setmetatable({}, { __index = longfire }) as longfire
	self:init(x, y, r)
	return self
end

function longfire:init(x: number, y: number, r: {any})
	self.cox = x
	self.coy = y
	self.dir = "left"
	self.on = true
	local rr = r
	if rr and #rr > 2 then
		local v1 = rr[3]
		if type(v1) == "string" and (v1 == "left" or v1 == "right" or v1 == "up" or v1 == "down") then
			self.dir = v1 as string
		end
	end
	self.width = 47 / 16
	self.height = 14 / 16
	self.x = x - 47 / 16
	self.y = y - 14 / 16
	if self.dir == "right" then
		self.x = x - 15 / 16
	elseif self.dir == "up" then
		self.x = x - 15 / 16
		self.y = y - 47 / 16
		self.width = 14 / 16
		self.height = 47 / 16
	elseif self.dir == "down" then
		self.x = x - 15 / 16
		self.y = y - 1
		self.width = 14 / 16
		self.height = 47 / 16
	end
	self.speedx = 0
	self.speedy = 0
	self.static = true
	self.active = true
	self.category = 17
	self.gravity = 0
	self.mask = {true}
	self.drawable = true
	self.graphic = longfireimg
	local iw = (longfireimg as Image):getWidth()
	local ih = (longfireimg as Image):getHeight()
	self.quad = love.graphics.newQuad(0, 0, math.min(48, iw), math.min(16, ih), iw, ih)
	self.offsetX = 24
	self.offsetY = 2
	self.quadcenterX = 24
	self.quadcenterY = 8
	self.rotation = 0
	if self.dir == "up" then
		self.rotation = math.pi * 0.5
	elseif self.dir == "down" then
		self.rotation = math.pi * 1.5
	end
	self.timer = 0
end

function longfire:update(dt: number): boolean
	self.timer = self.timer + dt
	-- Toggle on/off like AE
	if self.timer > 2 then
		self.timer = 0
		self.on = not self.on
		self.active = self.on
	end
	return false
end

function longfire:leftcollide(a: any, b: Entity): any
	return self:hurt(a, b)
end

function longfire:rightcollide(a: any, b: Entity): any
	return self:hurt(a, b)
end

function longfire:ceilcollide(a: any, b: Entity): any
	return self:hurt(a, b)
end

function longfire:floorcollide(a: any, b: Entity): any
	return self:hurt(a, b)
end

function longfire:hurt(a: any, b: Entity): any
	if self.on and a == "player" then
		local pl = b as mario
		pl:die("enemy")
	end
	return false
end
