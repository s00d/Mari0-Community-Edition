--[[ Teal port of root orgate.lua ]]

rawset(_G, "orgate", rawget(_G, "orgate") or {})

function orgate.new(_: orgate, x: number, y: number, r: {any}): orgate
	local self = setmetatable({}, { __index = orgate }) as orgate
	self:init(x, y, r)
	return self
end

function orgate:init(x: number, y: number, r)
	logicgate_init_xy(self as any, x, y, r as {any})
	self.outtable = {}
	self.inputstate = {}
	self.outputstate = "off"
end

function orgate:link(): any|nil
	return logicgate_link(self)
end

function orgate:addoutput(a, t)
	logicgate_addoutput(self, a, t)
end

function orgate:out(t)
	logicgate_out(self, t)
end

function orgate:update(_: number)
	if self.initial then
		self.initial = false
	end
end

function orgate:draw()
	logicgate_draw_img(self, orgateimg)
end

function orgate:input(t, input): any
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
		
		local pass = "off"
		for _, v in pairs(self.inputstate) do
			if v == "on" then
				pass = "on"
			end
		end
		
		if self.outputstate ~= pass then
			self:out(pass)
			self.outputstate = pass
		end
	end
	return nil
end
