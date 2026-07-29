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
	self.dir = dir as string
	self.frame = 1
	self.finished = false
	self.tick_id = 0
	
	self.r = 0
	if dir == "up" then
		self.r = -math.pi/2
	elseif dir == "down" then
		self.r = math.pi/2
	elseif dir == "left" then
		self.r = math.pi
	end

	self.tick_id = self.tick_id + 1
	local token = self.tick_id
	HumpTimer.every(rainboomdelay, function()
		if self.tick_id ~= token or self.finished then
			return
		end
		self.frame = self.frame + 1
		if self.frame > rainboomframes then
			self.finished = true
		end
	end, rainboomframes as integer)
end

function rainboom:update(_: number): boolean
	return self.finished
end

function rainboom:draw()
	love.graphics.draw(rainboomimg, rainboomquad[self.frame as integer], tile_draw_x(self.x), tile_draw_y_raw(self.y-0.5), self.r, scale, scale, 29, 92)
end
