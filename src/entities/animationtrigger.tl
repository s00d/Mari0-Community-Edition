--[[ Teal port of root animationtrigger.lua ]]

rawset(_G, "animationtrigger", rawget(_G, "animationtrigger") or {})

function animationtrigger.new(_: animationtrigger, x: number, y: number, r: {any}): animationtrigger
	local self = setmetatable({}, { __index = animationtrigger }) as animationtrigger
	self:init(x, y, r)
	return self
end

function animationtrigger:init(x: number, y: number, r)
	self.x = x
	self.y = y
	self.cox = x
	self.coy = y
	
	--Input list
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	--IDENTIFIER
	if #self.r > 0 and self.r[1] ~= "link" then
		self.id = tostring(self.r[1])
		table.remove(self.r, 1)
	end
end

function animationtrigger:link(): any|nil
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

function animationtrigger:input(t, input): any
	if input == "in" then
		if t == "on" or t == "toggle" then
			if not animationtriggerfuncs[self.id as string] then
				return
			end
			
			for i = 1, #animationtriggerfuncs[self.id as string] do
				animationtriggerfuncs[self.id as string][i]:trigger()
			end
		end
	end
	return nil
end