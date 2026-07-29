--[[ Teal port of root andgate.lua ]]

rawset(_G, "andgate", rawget(_G, "andgate") or {})

function andgate.new(_: andgate, x: number, y: number, r: {any}): andgate
	local self = setmetatable({}, { __index = andgate }) as andgate
	self:init(x, y, r)
	return self
end

function andgate:init(x: number, y: number, r)
	logicgate_init_xy(self as any, x, y, r as {any})
	self.outtable = {}
	self.inputstate = {}
	self.outputstate = "off"
end

function andgate:link(): any|nil
	return logicgate_link(self)
end

function andgate:addoutput(a, t)
	logicgate_addoutput(self, a, t)
end

function andgate:out(t)
	logicgate_out(self, t)
end

function andgate:update(_: number)
	if self.initial then
		self.initial = false
	end
end

function andgate:draw()
	logicgate_draw_img(self, andgateimg)
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
