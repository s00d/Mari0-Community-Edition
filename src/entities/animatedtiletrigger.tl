--[[ Teal port of root animatedtiletrigger.lua ]]

rawset(_G, "animatedtiletrigger", rawget(_G, "animatedtiletrigger") or {})

function animatedtiletrigger.new(_: animatedtiletrigger, x: number, y: number, r: {any}): animatedtiletrigger
	local self = setmetatable({}, { __index = animatedtiletrigger }) as animatedtiletrigger
	self:init(x, y, r)
	return self
end

function animatedtiletrigger:init(x: number, y: number, r)
	self.x = x
	self.y = y
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	self.visible = true
	
	--VISIBLE
	if #self.r > 0 and self.r[1] ~= "link" then
		self.visible = (self.r[1] == "true")
		table.remove(	self.r, 1)
	end
	
	--REGION
	if #self.r > 0 then
		local s = strsplit(self.r[1], ":")
		self.regionX, self.regionY, self.regionwidth, self.regionheight = s[2] as any, s[3] as any, tonumber(s[4] as string), tonumber(s[5] as string)
		if string.sub(self.regionX as string, 1, 1) == "m" then
			self.regionX = -tonumber(string.sub(self.regionX as string, 2))
		end
		if string.sub(self.regionY as string, 1, 1) == "m" then
			self.regionY = -tonumber(string.sub(self.regionY as string, 2))
		end
		
		self.regionX = (tonumber(self.regionX as string) or 0) + self.x - 1
		self.regionY = (tonumber(self.regionY as string) or 0) + self.y - 1
		table.remove(self.r, 1)
	end
end

function animatedtiletrigger:link(): any|nil
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

function animatedtiletrigger:update()

end

function animatedtiletrigger:draw()	
	if self.visible then
		love.graphics.draw(animatedtiletriggerimg, math.floor((self.x-1-xscroll)*16*scale), ((self.y-yscroll-1)*16-8)*scale, 0, scale, scale)
	end
end

function animatedtiletrigger:input(t, input): any
	for x = (self.regionX as number)+1, (self.regionX as number) + (self.regionwidth as number) do
		for y = (self.regionY as number)+1, (self.regionY as number) + (self.regionheight as number) do
			if animatedtimers[x] and animatedtimers[x][y] then
				animatedtimers[x][y]:input(t)
			end
		end
	end
	return nil
end