--[[ Teal port of root portalent.lua ]]

rawset(_G, "portalent", rawget(_G, "portalent") or {})

function portalent.new(_: portalent, x: number, y: number, i: any, r: any): portalent
	local self = setmetatable({}, { __index = portalent }) as portalent
	self:init(x, y, i, r)
	return self
end

function portalent:init(x: number, y: number, i, r)
	self.cox = x
	self.coy = y
	self.x = x
	self.y = y
	
	self.dir = "up"
	self.portal = i as number
	self.id = 1
	self.power = false

	--Input list
	self.input1state = "off"
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	--DIRECTION
	if #self.r > 0 and self.r[1] ~= "link" then
		self.dir = self.r[1] as string
		table.remove(self.r, 1)
	end
	
	--ID
	if #self.r > 0 then
		self.id = tonumber(self.r[1] as string) as number
		table.remove(self.r, 1)
	end
	
	--POWER
	if #self.r > 0 and self.r[1] ~= "link" then
		self.power = self.r[1] == "true"
		table.remove(self.r, 1)
	end
	
	if not portals[self.id] then
		portals[self.id] = portal:new(self.id)
	end
	
	if self.power then
		self:trigger()
	end
end

function portalent:link()
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
end

function portalent:update(dt: number): any...
	
end

function portalent:draw()
	
end

function portalent:input(t, input)
	if input == "power" then
		local oldpower = self.power
		if t == "on" and self.input1state == "off" then
			self.power = not self.power
		elseif t == "off" and self.input1state == "on" then
			self.power = not self.power
		elseif t == "toggle" then
			self.power = not self.power
		end
		
		if self.power and not oldpower then
			self:trigger()
		elseif not self.power and oldpower then
			self:rem()
		end
		
		self.input1state = t
	end
end

function portalent:trigger()
	portals[self.id]:createportal(self.portal as number, self.x, self.y, self.dir, -1)
end

function portalent:rem()
	local p = self.portal as number
	local port = portals[self.id] as {string:any}
	if port["x" .. p] == self.x and port["y" .. p] == self.y and port["facing" .. p] == self.dir then
		portals[self.id]:removeportal(p)
	else
		print("Portal wasn't removed because it isn't at this position")
	end
end