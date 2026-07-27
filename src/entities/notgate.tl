--[[ Teal port of root notgate.lua ]]

rawset(_G, "notgate", rawget(_G, "notgate") or {})

function notgate.new(_: notgate, x: number, y: number, r: {any}): notgate
	local self = setmetatable({}, { __index = notgate }) as notgate
	self:init(x, y, r)
	return self
end

function notgate:init(x: number, y: number, r)
	self.x = x
	self.y = y
	self.cox = x
	self.coy = y
	self.visible = false
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	--VISIBLE
	if #self.r > 0 and self.r[1] ~= "link" then
		self.visible = (self.r[1] == "true")
		table.remove(self.r, 1)
	end
	
	self.outtable = {}
	self.input1state = "on"
	self.initial = true
end

function notgate:link(): any|nil
	while #self.r > 3 do
		for j, w in pairs(outputs) do
			for i, v in pairs(objects[w]) do
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
	table.insert(self.outtable, {a, t} as {any})
end

function notgate:update(dt: number): any...
	if self.initial then
		self.initial = false
		self:input("off", "in")
	end
end

function notgate:draw()
	if self.visible then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(notgateimg, math.floor((self.x-1-xscroll)*16*scale), ((self.y-yscroll-1)*16-8)*scale, 0, scale, scale)
	end
end

function notgate:out(t)
	for i = 1, #self.outtable do
		if (self.outtable[i] as {Entity, any})[1].input then
			(self.outtable[i] as {Entity, any})[1]:input(t, (self.outtable[i] as {Entity, any})[2])
		end
	end
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