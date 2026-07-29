--[[ Teal port of root firework.lua ]]

rawset(_G, "fireworkboom", rawget(_G, "fireworkboom") or {})

function fireworkboom.new(_: fireworkboom, x: any, yoffset: any): fireworkboom
	local self = setmetatable({}, { __index = fireworkboom }) as fireworkboom
	self:init(x, yoffset)
	return self
end

function fireworkboom:init(x: any, yoffset: any)
	self.x = (x as number)+(math.random(9)-5)
	self.y = math.random(5)+2+(yoffset as number)
	self.timer = 0
	self.finished = false
	marioscore = marioscore + 200

	HumpTimer.after(fireworksoundtime, function()
		if not self.finished then
			playsound("boom")
		end
	end)
	HumpTimer.after(fireworkdelay, function()
		self.finished = true
	end)
end

function fireworkboom:update(dt: number): boolean
	self.timer = self.timer + dt
	return self.finished
end

function fireworkboom:draw()
	local framelength = fireworkdelay/3
	local frame = 5
	if self.timer > framelength then
		frame = 6
	end
	if self.timer > framelength*2 then
		frame = 7
	end
	
	love.graphics.draw(fireballimg, fireballquad[frame], tile_draw_x(self.x), tile_draw_y_raw(self.y-0.5), 0, scale, scale, 8, 8)
end
