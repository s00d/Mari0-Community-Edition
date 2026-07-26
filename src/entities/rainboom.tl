--[[ Teal port of root rainboom.lua ]]

--omygoshomygoshomygosh
rawset(_G, "rainboom", rawget(_G, "rainboom") or {})

function rainboom.new(_: rainboom, x: number, y: number, dir: any): rainboom
	local self = setmetatable({}, { __index = rainboom }) as rainboom
	self:init(x, y, dir)
	return self
end

function rainboom:init(x: number, y: number, dir)
	self.x = x
	self.y = y
	self.dir = dir
	self.timer = 0
	self.frame = 1
	
	self.r = 0
	if dir == "up" then
		self.r = -math.pi/2
	elseif dir == "down" then
		self.r = math.pi/2
	elseif dir == "left" then
		self.r = math.pi
	end
end

function rainboom:update(dt: number)
	self.timer = self.timer + dt
	while self.timer > rainboomdelay do
		self.frame = self.frame + 1
		self.timer = self.timer - rainboomdelay
	end
	
	if self.frame > rainboomframes then
		return true
	end
	
	return false
end

function rainboom:draw()
	love.graphics.draw(rainboomimg, rainboomquad[self.frame], (self.x-xscroll)*16*scale, (self.y-yscroll-0.5)*16*scale, self.r, scale, scale, 29, 92)
end