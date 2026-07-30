--[[ Teal port of root squarewave.lua ]]

rawset(_G, "squarewave", rawget(_G, "squarewave") or {})

function squarewave.new(_: squarewave, x: number, y: number, r: {any}): squarewave
	local self = setmetatable({}, { __index = squarewave }) as squarewave
	self:init(x, y, r)
	return self
end

function squarewave:init(x: number, y: number, r)
	self.x = x
	self.y = y
	self.cox = x
	self.coy = y
	
	self.outtable = {}
	self.time1 = 1
	self.time2 = 1
	self.visible = false
	self.initial = true
	self.cycle_id = 0
	
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	if #self.r > 0 and self.r[1] ~= "link" then
		self.time1 = self.r[1] as number
		table.remove(self.r, 1)
	end
	if #self.r > 0 and self.r[1] ~= "link" then
		self.time2 = self.r[1] as number
		table.remove(self.r, 1)
	end
	self.phase_offset = 0
	if #self.r > 0 and self.r[1] ~= "link" then
		self.phase_offset = (self.r[1] as number) * (self.time1 + self.time2)
		table.remove(self.r, 1)
	end
	if #self.r > 0 and self.r[1] ~= "link" then
		self.visible = (self.r[1] == "true")
		table.remove(self.r, 1)
	end
end

function squarewave:addoutput(a, t)
	table.insert(self.outtable, {a, t} as {any})
end

local function squarewave_schedule_cycle(self: squarewave, delay: number)
	self.cycle_id = (self.cycle_id or 0) + 1
	local token = self.cycle_id
	HumpTimer.after(delay, function()
		if self.cycle_id ~= token then
			return
		end
		self:out("on")
		HumpTimer.after(self.time2, function()
			if self.cycle_id ~= token then
				return
			end
			self:out("off")
			squarewave_schedule_cycle(self, self.time1)
		end)
	end)
end

function squarewave:update(_: number)
	if self.initial then
		self.initial = false
		local cycle = self.time1 + self.time2
		local phase = cycle > 0 and (self.phase_offset % cycle) or 0
		if phase > self.time1 then
			self:out("on")
			local token = self.cycle_id + 1
			self.cycle_id = token
			HumpTimer.after(cycle - phase, function()
				if self.cycle_id ~= token then
					return
				end
				self:out("off")
				squarewave_schedule_cycle(self, self.time1)
			end)
		elseif phase > 0 then
			squarewave_schedule_cycle(self, self.time1 - phase)
		else
			squarewave_schedule_cycle(self, self.time1)
		end
	end
end

function squarewave:draw()
	if self.visible then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(squarewaveimg, tile_draw_x(self.x-1), tile_draw_y(self.y-1, -8), 0, world_draw_scale(), world_draw_scale())
	end
end

function squarewave:out(t)
	for i = 1, #self.outtable do
		if (self.outtable[i] as {Entity, any})[1].input then
			(self.outtable[i] as {Entity, any})[1]:input(t, (self.outtable[i] as {Entity, any})[2])
		end
	end
end
