--[[ Teal port of root laserdetector.lua ]]

rawset(_G, "laserdetector", rawget(_G, "laserdetector") or {})

function laserdetector.new(_: laserdetector, x: number, y: number, r: {any}): laserdetector
	local self = setmetatable({}, { __index = laserdetector }) as laserdetector
	self:init(x, y, r)
	return self
end

function laserdetector:init(x: number, y: number, r)
	self.cox = x
	self.coy = y
	self.dir = "right"
	
	self.drawable = false
	
	--Input list
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	--DIRECTION
	if #self.r > 0 and self.r[1] ~= "link" then
		self.dir = self.r[1] as string
		table.remove(self.r, 1)
	end
	
	self.outtable = {}
	self.allowclear = true
	self.out = "off"
end

function laserdetector:update(_: number)
	self.allowclear = true
	
	if self.out ~= self.prevout then
		self.prevout = self.out
		for i = 1, #self.outtable do
			local entry = self.outtable[i] as {Entity, any}
			if entry[1].input then
				entry[1]:input(self.out, entry[2])
			end
		end
	end
end

function laserdetector:input(t): any
	self.allowclear = false
	if t == "on" then
		self.out = "on"
	end
	return nil
end

function laserdetector:draw()
	local rot: number = 0
	if self.dir == "down" then
		rot = math.pi/2
	elseif self.dir == "left" then
		rot = math.pi
	elseif self.dir == "up" then
		rot = math.pi*1.5
	end
	love.graphics.draw(laserdetectorimg, tile_draw_x(self.cox-0.5), tile_draw_y_raw(self.coy-1), rot, world_draw_scale(), world_draw_scale(), 8, 8)
end

function laserdetector:addoutput(a, t)
	table.insert(self.outtable, {a, t} as {any})
end

function laserdetector:clear(): any
	if self.allowclear then
		self.allowclear = false
		self.out = "off"
	end
	return nil
end