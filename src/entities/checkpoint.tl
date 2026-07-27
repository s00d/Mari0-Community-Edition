--[[ Teal port of root checkpoint.lua ]]

rawset(_G, "checkpoint", rawget(_G, "checkpoint") or {})

function checkpoint.new(_: checkpoint, x: number, y: number, r: {any}): checkpoint
	local self = setmetatable({}, { __index = checkpoint }) as checkpoint
	self:init(x, y, r)
	return self
end

function checkpoint:init(x: number, y: number, r)
	self.x = x
	self.y = y
	self.cox = x
	self.coy = y
	
	self.r = {unpack(r as {any})}
	
	self.all = true
	self.p = {false, false, false, false}
	self.rest = false
	self.visible = false
	
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	--Check all
	if #self.r > 0 and self.r[1] ~= "link" then
		self.all = self.r[1] == "true"
		table.remove(self.r, 1)
	end
	
	--p1-4
	for i = 1, 4 do
		if #self.r > 0 and self.r[1] ~= "link" then
			self.p[i] = self.r[1] == "true"
			table.remove(self.r, 1)
		end
	end
	
	--rest
	if #self.r > 0 and self.r[1] ~= "link" then
		self.rest = self.r[1] == "true"
		table.remove(self.r, 1)
	end
	
	--visible
	if #self.r > 0 and self.r[1] ~= "link" then
		self.visible = self.r[1] == "true"
		table.remove(self.r, 1)
	end
	
	--REGION
	if #self.r > 0 then
		local s = strsplit(self.r[1], ":")
		local rx = s[2]
		local ry = s[3]
		self.regionwidth = tonumber(s[4]) as number
		self.regionheight = tonumber(s[5]) as number
		local regionx: number
		local regiony: number
		if string.sub(rx, 1, 1) == "m" then
			regionx = -(tonumber(string.sub(rx, 2)) or 0)
		else
			regionx = tonumber(rx) or 0
		end
		if string.sub(ry, 1, 1) == "m" then
			regiony = -(tonumber(string.sub(ry, 2)) or 0)
		else
			regiony = tonumber(ry) or 0
		end
		self.regionX = regionx + self.x - 1
		self.regionY = regiony + self.y - 1
		table.remove(self.r, 1)
	end
	
	self.input1state = "off"
end

function checkpoint:update(): any...
	local col = checkrect(self.regionX, self.regionY, self.regionwidth, self.regionheight, {"player"})
	
	if #col > 0 then
		self:trigger()
	end
end

function checkpoint:link(): any|nil
	while #self.r > 3 do
		for j, w in pairs(outputs as {any:any}) do
			for i, v in pairs(objects[w] as {any:Entity}) do
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

function checkpoint:input(t, input): any
	if input == "trigger" then
		if t == "on" and self.input1state == "off" then
			self:trigger()
		elseif t == "toggle" then
			self:trigger()
		end
		
		self.input1state = t
	end
	return nil
end

function checkpoint:trigger(): any
	local modtable = {}
	if self.all then
		table.insert(modtable, 1)
		table.insert(modtable, 2)
		table.insert(modtable, 3)
		table.insert(modtable, 4)
		table.insert(modtable, 5)
	else
		for i = 1, 4 do
			if self.p[i] then
				table.insert(modtable, i)
			end
		end
		
		if self.rest then
			table.insert(modtable, 5)
		end
	end
	
	for i, v in ipairs(modtable) do
		checkpointx[v] = self.x
		checkpointy[v] = self.y
	end
	
	checkpointsub = mariosublevel
	return nil
end