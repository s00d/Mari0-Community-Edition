--[[ Teal port of root laser.lua ]]

rawset(_G, "laser", rawget(_G, "laser") or {})

function laser.new(_: laser, x: number, y: number, r: {any}): laser
	local self = setmetatable({}, { __index = laser }) as laser
	self:init(x, y, r)
	return self
end

function laser:init(x: number, y: number, r: any)
	self.cox = x
	self.coy = y
	
	self.blocked = false
	self.lasertable = {}
	self.outtable = {}
	
	self.framestart = 0
	
	self.power = true
	self.input1state = "off"
	
	self.dir = "right"
	
	--Input list
	self.input1state = "off"
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	--DIRECTION
	if #self.r > 0 and self.r[1] ~= "link" then
		self.dir = self.r[1]
		table.remove(self.r, 1)
	end
	
	--POWER
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			self.power = false
		end
		table.remove(self.r, 1)
	end
end

function laser:link()
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
end

function laser:input(t, input)
	if input == "power" then
		if t == "on" and self.input1state == "off" then
			self.power = not self.power
		elseif t == "off" and self.input1state == "on" then
			self.power = not self.power
		elseif t == "toggle" then
			self.power = not self.power
		end
		self:updaterange()
		
		self.input1state = t
	end
end

function laser:update(dt: number): any...
	if self.framestart < 2 then
		self.framestart = self.framestart + 1
		return
	end
	local x: number = 0
	local y: number = 0
	local width: number = 0
	local height: number = 0
	local col = false
	
	for i = 1, #self.lasertable, 5 do
		if (self.lasertable[i] as string) == "left" then
			
			x = (self.lasertable[i+1] as number)-1+(self.lasertable[i+3] as number)
			y = (self.lasertable[i+2] as number)-0.5625
			width = -(self.lasertable[i+3] as number)+1
			height = 2/16
		elseif (self.lasertable[i] as string) == "right" then
			
			x = (self.lasertable[i+1] as number)-1
			y = (self.lasertable[i+2] as number)-0.5625
			width = (self.lasertable[i+3] as number)+1
			height = 2/16
		elseif (self.lasertable[i] as string) == "up" then
			
			x = (self.lasertable[i+1] as number)-0.5625
			y = (self.lasertable[i+2] as number)+(self.lasertable[i+4] as number)-1
			width = 2/16
			height = -(self.lasertable[i+4] as number)+1
			
		elseif (self.lasertable[i] as string) == "down" then
			
			x = (self.lasertable[i+1] as number)-0.5625
			y = (self.lasertable[i+2] as number)-1
			width = 2/16
			height = (self.lasertable[i+4] as number)+1
		end
		
		local rectcol = checkrect(x, y, width, height, {"player", "box", "enemy"})
		
		if #rectcol > 0 then
			col = true
			self.blocked = true
		
			local obj: Entity|nil = nil
			if (self.lasertable[i] as string) == "right" or (self.lasertable[i] as string) == "down" then
				local smallestx = mapwidth+1
				local smallesti: number = 0
			
				for j = 1, #rectcol, 2 do
					if (objects[rectcol[j as integer] as any] as {any:Entity})[rectcol[(j+1) as integer] as any].x < smallestx then
						smallestx = (objects[rectcol[j as integer] as any] as {any:Entity})[rectcol[(j+1) as integer] as any].x
						smallesti = j
					end
				end
				obj = (objects[rectcol[smallesti as integer] as any] as {any:Entity})[rectcol[(smallesti+1) as integer] as any]
			else
				local biggestx: number = -1
				local biggesti: number = 0
			
				for j = 1, #rectcol, 2 do
					if (objects[rectcol[j as integer] as any] as {any:Entity})[rectcol[(j+1) as integer] as any].x > biggestx then
						biggestx = (objects[rectcol[j as integer] as any] as {any:Entity})[rectcol[(j+1) as integer] as any].x
						biggesti = j
					end
				end
				
				obj = (objects[rectcol[biggesti as integer] as any] as {any:Entity})[rectcol[(biggesti+1) as integer] as any]
			end
			local o = obj as Entity
			
			local newtable = {} as {any}
			for k = 1, i*5 do
				table.insert(newtable as {any}, self.lasertable[k])
			end
			
			if (self.lasertable[i] as string) == "left" then
				if o.laser then
					(o.laser as function(Entity, any))(o, "right")
				end
				
				newtable[i+3] = o.x - (newtable[i+1] as number) + o.width+1
			elseif (self.lasertable[i] as string) == "right" then
				if o.laser then
					(o.laser as function(Entity, any))(o, "left")
				end
				
				newtable[i+3] = o.x - (newtable[i+1] as number)
			elseif (self.lasertable[i] as string) == "up" then
				if o.laser then
					(o.laser as function(Entity, any))(o, "down")
				end
				
				newtable[i+4] = o.y - (newtable[i+2] as number)+1
			elseif (self.lasertable[i] as string) == "down" then
				if o.laser then
					(o.laser as function(Entity, any))(o, "up")
				end
				
				
				newtable[i+4] = o.y - (newtable[i+2] as number) + 1 - o.height+1-1
			end
			
			self.lasertable = newtable
			
			self:updateoutputs()
			break
		end
	end
	
	self:updateoutputs()
	
	if col == false and self.blocked == true then
		self.blocked = false
		self:updaterange()
	end
end

function laser:updateoutputs()
	for i = 1, #self.lasertable, 5 do
		if (self.lasertable[i] as string) == "left" then
			for x = (self.lasertable[i+1] as number), math.ceil((self.lasertable[i+1] as number)+(self.lasertable[i+3] as number))-1, -1 do
				local y = (self.lasertable[i+2] as number)
				self:checktile(x, y, "left")
			end
		elseif (self.lasertable[i] as string) == "right" then
			for x = (self.lasertable[i+1] as number), math.floor((self.lasertable[i+1] as number)+(self.lasertable[i+3] as number))+1 do
				local y = (self.lasertable[i+2] as number)
				self:checktile(x, y, "right")
			end
		elseif (self.lasertable[i] as string) == "up" then
			for y = (self.lasertable[i+2] as number), (self.lasertable[i+2] as number)+(self.lasertable[i+4] as number)-1, -1 do
				local x = (self.lasertable[i+1] as number)
				self:checktile(x, y, "up")
			end
		elseif (self.lasertable[i] as string) == "down" then
			for y = (self.lasertable[i+2] as number), (self.lasertable[i+2] as number)+(self.lasertable[i+4] as number)+1 do
				local x = (self.lasertable[i+1] as number)
				self:checktile(x, y, "down")
			end
		end
	end
	
	for i, v in pairs(self.outtable as {any:Entity}) do
		v:clear()
	end
end

function laser:checktile(x, y, dir)
	--check if block is a detector
	for i, v in pairs(objects["laserdetector"] as {any:Entity}) do
		--if (dir == "left" and v.dir == "right") or (dir == "right" and v.dir == "left") or (dir == "up" and v.dir == "down") or (dir == "down" and v.dir == "up") then
			if x == v.cox and y == v.coy and (v.cox ~= self.r[4] or v.coy ~= self.r[5]) then
				table.insert(self.outtable, v)
				v:input("on")
			end
		--end
	end
end

function laser:draw()	
	for i = 1, #self.lasertable, 5 do
		if (self.lasertable[i] as string) == "left" then
			if (self.lasertable[i+3] as number) < 1 then
				love.graphics.setScissor(math.floor(((self.lasertable[i+1] as number)+(self.lasertable[i+3] as number)-xscroll-1)*16*scale), ((self.lasertable[i+2] as number)-yscroll-1.5)*16*scale, (-(self.lasertable[i+3] as number)+1)*16*scale, 16*scale)
				local b = 0
				for x = (self.lasertable[i+1] as number), math.floor((self.lasertable[i+1] as number)+(self.lasertable[i+3] as number))-1, -1 do
					b = b + 1
					love.graphics.draw(laserimg, math.floor((x-xscroll-1)*16*scale), ((self.lasertable[i+2] as number)-yscroll-20/16)*16*scale, 0, scale, scale)
				end
			end
		elseif (self.lasertable[i] as string) == "right" then
			if (self.lasertable[i+3] as number) > -1 then
				love.graphics.setScissor(math.floor(((self.lasertable[i+1] as number)-xscroll-1)*16*scale), ((self.lasertable[i+2] as number)-yscroll-1.5)*16*scale, ((self.lasertable[i+3] as number)+1)*16*scale, 16*scale)
					local b = 0
				for x = (self.lasertable[i+1] as number), math.ceil((self.lasertable[i+1] as number)+(self.lasertable[i+3] as number))+1 do
					b = b + 1
					love.graphics.draw(laserimg, math.floor((x-xscroll-1)*16*scale), ((self.lasertable[i+2] as number)-yscroll-20/16)*16*scale, 0, scale, scale)
				end
			end
		elseif (self.lasertable[i] as string) == "up" then
			for y = (self.lasertable[i+2] as number), (self.lasertable[i+2] as number)+(self.lasertable[i+4] as number), -1 do
				love.graphics.draw(laserimg, math.floor(((self.lasertable[i+1] as number)-xscroll-5/16)*16*scale), (y-yscroll-1)*16*scale, math.pi/2, scale, scale, 8, 1)
			end
		elseif (self.lasertable[i] as string) == "down" then
			for y = (self.lasertable[i+2] as number), (self.lasertable[i+2] as number)+(self.lasertable[i+4] as number) do
				love.graphics.draw(laserimg, math.floor(((self.lasertable[i+1] as number)-xscroll-5/16)*16*scale), (y-yscroll-1)*16*scale, math.pi/2, scale, scale, 8, 1)
			end
		end
		
		love.graphics.setScissor()
	end
	
	local rot: any = 0
	if self.dir == "up" then
		rot = math.pi*1.5
	elseif self.dir == "down" then
		rot = math.pi*0.5
	elseif self.dir == "left" then
		rot = math.pi
	end

	love.graphics.draw(lasersideimg, math.floor((self.cox-xscroll-.5)*16*scale), (self.coy-yscroll-1)*16*scale, rot, scale, scale, 8, 8)
end

function laser:updaterange()
	self.lasertable = {}
	if self.power == false then
		self:updateoutputs()
		return
	end
	
	local dir = self.dir
	local startx, starty = self.cox, self.coy
	local rangex, rangey = 0, 0
	local x, y = self.cox, self.coy
	
	local firstcheck = true
	local quit = false
	while x >= 1 and x <= mapwidth and y >= 1 and y <= mapheight and (tilequads[map[x][y][1]]:getproperty("collision", x, y) == false or tilequads[map[x][y][1]]:getproperty("grate", x, y)) and (x ~= startx or y ~= starty or dir ~= self.dir or firstcheck == true) and quit == false do
		firstcheck = false
		
		if dir == "right" then
			x = x + 1
			rangex = rangex + 1
		elseif dir == "left" then
			x = x - 1
			rangex = rangex - 1
		elseif dir == "up" then
			y = y - 1
			rangey = rangey - 1
		elseif dir == "down" then
			y = y + 1
			rangey = rangey + 1
		end
		
		--check if current block is a portal
		local opp = "left"
		if dir == "left" then
			opp = "right"
		elseif dir == "up" then
			opp = "down"
		elseif dir == "down" then
			opp = "up"
		end
		
		local portalx, portaly, portalfacing, infacing = getPortal(x, y, opp)
		
		if portalx ~= false and ((dir == "left" and infacing == "right") or (dir == "right" and infacing == "left") or (dir == "up" and infacing == "down") or (dir == "down" and infacing == "up")) then
			
			if dir == "right" then
				x = x - 1
				rangex = rangex - 1
			elseif dir == "left" then
				x = x + 1
				rangex = rangex + 1
			elseif dir == "up" then
				y = y + 1
				rangey = rangey + 1
			elseif dir == "down" then
				y = y - 1
				rangey = rangey - 1
			end
			
			table.insert(self.lasertable, dir)
			table.insert(self.lasertable, x-rangex)
			table.insert(self.lasertable, y-rangey)
			table.insert(self.lasertable, rangex)
			table.insert(self.lasertable, rangey)
			
			x, y = portalx as number, portaly as number
			dir = portalfacing
			
			rangex, rangey = 0, 0
			
			if dir == "right" then
				x = (portalx as number) + 1
			elseif dir == "left" then
				x = (portalx as number) - 1
				rangex = 0
			elseif dir == "up" then
				y = (portaly as number) - 1
			elseif dir == "down" then
				y = (portaly as number) + 1
			end
		end
		
		--doors
		for i, v in pairs(objects["door"] as {any:Entity}) do
			if v.active then
				if v.dir == "ver" then
					if x == v.cox and (y == v.coy or y == v.coy-1) then
						quit = true
					end
				elseif v.dir == "hor" then
					if y == v.coy and (x == v.cox or x == v.cox+1) then
						quit = true
					end
				end
			end
		end
	end
		
	if dir == "right" then
		x = x - 1
		rangex = rangex - 1
	elseif dir == "left" then
		x = x + 1
		rangex = rangex + 1
	elseif dir == "up" then
		y = y + 1
		rangey = rangey + 1
	elseif dir == "down" then
		y = y - 1
		rangey = rangey - 1
	end
	
	table.insert(self.lasertable, dir)
	table.insert(self.lasertable, x-rangex)
	table.insert(self.lasertable, y-rangey)
	table.insert(self.lasertable, rangex)
	table.insert(self.lasertable, rangey)
	
	self:update()
end