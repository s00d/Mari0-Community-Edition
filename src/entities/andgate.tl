--[[ Teal port of root andgate.lua ]]

rawset(_G, "andgate", rawget(_G, "andgate") or {})

function andgate.new(_: andgate, x: number, y: number, r: {any}): andgate
	local self = setmetatable({}, { __index = andgate }) as andgate
	self:init(x, y, r)
	return self
end

function andgate:init(x: number, y: number, r)
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
	self.inputstate = {}
	self.outputstate = "off"
end

function andgate:link(): any|nil
	while #self.r > 3 do
		for _, w in pairs(outputs) do
			for _, v in pairs(objects[w]) do
				if tonumber(self.r[3]) == v.cox and tonumber(self.r[4]) == v.coy then
					v:addoutput(self, self.r[2])
					self.inputstate[tonumber(self.r[2])] = "off"
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

function andgate:addoutput(a, t)
	table.insert(self.outtable, {a, t} as {any})
end

function andgate:update(_: number)
	if self.initial then
		self.initial = false
	end
end

function andgate:draw()
	if self.visible then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(andgateimg, math.floor((self.x-1-xscroll)*16*scale), ((self.y-yscroll-1)*16-8)*scale, 0, scale, scale)
	end
end

function andgate:out(t)
	for i = 1, #self.outtable do
		if (self.outtable[i] as {Entity, any})[1].input then
			(self.outtable[i] as {Entity, any})[1]:input(t, (self.outtable[i] as {Entity, any})[2])
		end
	end
end

function andgate:input(t, input): any
	if tonumber(input) then
		if t == "toggle" then
			if self.inputstate[tonumber(input)] == "on" then
				self.inputstate[tonumber(input)] = "off"
			else
				self.inputstate[tonumber(input)] = "on"
			end
		else
			self.inputstate[tonumber(input)] = t
		end
		
		local pass = "on"
		for _, v in pairs(self.inputstate) do
			if v ~= "on" then
				pass = "off"
			end
		end
		
		if self.outputstate ~= pass then
			self:out(pass)
			self.outputstate = pass
		end
	end
	return nil
end