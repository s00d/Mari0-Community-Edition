--[[ Teal port of root rsflipflop.lua ]]

rawset(_G, "rsflipflop", rawget(_G, "rsflipflop") or {})

function rsflipflop.new(_: rsflipflop, x: number, y: number, r: {any}): rsflipflop
	local self = setmetatable({}, { __index = rsflipflop }) as rsflipflop
	self:init(x, y, r)
	return self
end

function rsflipflop:init(x: number, y: number, r)
	logicgate_init_xy(self as any, x, y, r as {any})
	self.outtable = {}
	self.output = false
end

function rsflipflop:link(): any|nil
	while #self.r > 3 do
		for _, w in pairs(outputs) do
			for _, v in pairs(session.objects[w]) do
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

function rsflipflop:addoutput(a, t)
	logicgate_addoutput(self, a, t)
end

function rsflipflop:out(t)
	logicgate_out(self, t)
end

function rsflipflop:draw()
	logicgate_draw_img(self, rsflipflopimg)
end

function rsflipflop:input(t, input): any
	if input == "set" then
		if (t == "on" or t == "toggle") and not self.output then
			self.output = true
			self:out("on")
		end
	elseif input == "reset" then
		if (t == "on" or t == "toggle") and self.output then
			self.output = false
			self:out("off")
		end
	end
	return nil
end
