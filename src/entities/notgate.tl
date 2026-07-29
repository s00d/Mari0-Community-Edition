--[[ Teal port of root notgate.lua ]]

rawset(_G, "notgate", rawget(_G, "notgate") or {})

function notgate.new(_: notgate, x: number, y: number, r: {any}): notgate
	local self = setmetatable({}, { __index = notgate }) as notgate
	self:init(x, y, r)
	return self
end

function notgate:init(x: number, y: number, r)
	logicgate_init_xy(self as any, x, y, r as {any})
	self.outtable = {}
	self.input1state = "on"
	self.initial = true
	self.power = false
end

function notgate:link(): any|nil
	while #self.r > 3 do
		for _, w in pairs(outputs) do
			for _, v in pairs(objects[w]) do
				if tonumber(self.r[3]) == v.cox and tonumber(self.r[4]) == v.coy then
					v:addoutput(self, self.r[2])
				end
			end
		end
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
	end
	return nil
end

function notgate:addoutput(a, t)
	logicgate_addoutput(self, a, t)
end

function notgate:out(t)
	logicgate_out(self, t)
end

function notgate:update(_: number)
	if self.initial then
		self.initial = false
		self:input("off", "in")
	end
end

function notgate:draw()
	logicgate_draw_img(self, notgateimg)
end

function notgate:input(t, input): any
	if input == "in" then
		if t == "on" and self.input1state == "off" then
			self.power = not self.power
		elseif t == "off" and self.input1state == "on" then
			self.power = not self.power
		elseif t == "toggle" then
			self.power = not self.power
		end
		
		self.input1state = t
	
		local out = "on"
		if not self.power then
			out = "off"
		end
		
		self:out(out)
	end
	return nil
end
