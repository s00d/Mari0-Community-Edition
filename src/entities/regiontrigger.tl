--[[ Teal port of root regiontrigger.lua ]]

rawset(_G, "regiontrigger", rawget(_G, "regiontrigger") or {})

function regiontrigger.new(_: regiontrigger, x: number, y: number, r: {any}): regiontrigger
	local self = setmetatable({}, { __index = regiontrigger }) as regiontrigger
	self:init(x, y, r)
	return self
end

function regiontrigger:init(x: number, y: number, r)
	self.x = x
	self.y = y
	self.cox = x
	self.coy = y
	
	self.checktable = "all" as any
	self.outtable = {}
	
	--Input list
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	self.checktable = {}
	
	for a,b in pairs(self.r as {any:any}) do
		dbprint(a,b)
	end
	
	--TRIGGER ON PLAYER?
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			table.insert(self.checktable as {any}, "player")
		end			
		table.remove(self.r, 1)
	end
	
	--TRIGGER ON ENEMY?
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" or self.r[1] == "all" then
			table.insert(self.checktable as {any}, "enemy")
		elseif tonumber(self.r[1] as string) then
			table.insert(self.checktable as {any}, self.r[1])
		end	
	
		table.remove(self.r, 1)
	end
	
	--REGION
	if #self.r > 0 then
		local s = strsplit(self.r[1] as string, ":")
		self.regionX, self.regionY, self.regionwidth, self.regionheight = s[2], s[3], tonumber(s[4]) as number, tonumber(s[5]) as number
		if string.sub(self.regionX as string, 1, 1) == "m" then
			self.regionX = -tonumber(string.sub(self.regionX as string, 2))
		end
		if string.sub(self.regionY as string, 1, 1) == "m" then
			self.regionY = -tonumber(string.sub(self.regionY as string, 2))
		end
		
		self.regionX = (tonumber(self.regionX) as number) + self.x - 1
		self.regionY = (tonumber(self.regionY) as number) + self.y - 1
		table.remove(self.r, 1)
	end
	
	self.out = "off" as any
end

function regiontrigger:update(dt: number): any...
	local col = checkrect(self.regionX, self.regionY, self.regionwidth, self.regionheight, self.checktable)
	
	if self.out == "off" and #col > 0 then
		self.out = "on" as any
		for i = 1, #self.outtable do
			if (self.outtable[i] as {Entity, any})[1].input then
				(self.outtable[i] as {Entity, any})[1]:input(self.out, (self.outtable[i] as {Entity, any})[2])
			end
		end
	elseif self.out == "on" and #col == 0 then
		self.out = "off" as any
		for i = 1, #self.outtable do
			if (self.outtable[i] as {Entity, any})[1].input then
				(self.outtable[i] as {Entity, any})[1]:input(self.out, (self.outtable[i] as {Entity, any})[2])
			end
		end
	end
end

function regiontrigger:draw()
	
end

function regiontrigger:addoutput(a, t)
	table.insert(self.outtable, {a as Entity, t})
end