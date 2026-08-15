--[[ Teal port of root lightbridge.lua ]]

rawset(_G, "lightbridge", rawget(_G, "lightbridge") or {})
rawset(_G, "lightbridgebody", rawget(_G, "lightbridgebody") or {})

function lightbridge.new(_: lightbridge, x: number, y: number, r: {any}): lightbridge
	local self = setmetatable({}, { __index = lightbridge }) as lightbridge
	self:init(x, y, r)
	return self
end

function lightbridge:init(x: number, y: number, r: any)
	self.cox = x
	self.coy = y
	self.dir = "right"
	self.r = {unpack(r as {any})}
	
	self.childtable = {}
	
	self.power = true
	self.glowa = 1
	self.glowtimer = 0
	self.input1state = "off"
	self.children = 0
	
	self.dir = "right"
	
	--Input list
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	--DIRECTION
	if #self.r > 0 and self.r[1] ~= "link" then
		self.dir = self.r[1] as string
		table.remove(self.r, 1)
	end
	
	--POWER
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			self.power = false
		end
		table.remove(self.r, 1)
	end
	
	self:updaterange()
end

function lightbridge:link()
	while #self.r > 3 do
		for _, w in pairs(outputs) do
			for _, v in pairs(session.objects[w] as {any:Entity}) do
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

function lightbridge:input(t, input)
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

function lightbridge:update(dt: number): boolean
	if self.destroy then
		return true
	end
	self.glowtimer = self.glowtimer + dt*2
	return false
end

function lightbridge:getglowa(offset: any): number
	return math.sin(self.glowtimer - (offset as number)*0.5)*.25+.75
end

function lightbridge:draw()
	local rot: any = 0
	if self.dir == "up" then
		rot = math.pi*1.5
	elseif self.dir == "down" then
		rot = math.pi*0.5
	elseif self.dir == "left" then
		rot = math.pi
	end

	love.graphics.draw(lightbridgesideimg, tile_draw_x(self.cox-.5), tile_draw_y_raw(self.coy-1), rot, world_draw_scale(), world_draw_scale(), 8, 8)
end

function lightbridge:updaterange()
	--save old gel values (numeric gelSides)
	local gels: {number:Dyn} = {}
	
	for _, v in pairs(self.childtable) do
		local v = v as Entity
		local top = entity_gel_id(v, GEL_SIDE_TOP)
		local left = entity_gel_id(v, GEL_SIDE_LEFT)
		local right = entity_gel_id(v, GEL_SIDE_RIGHT)
		local bottom = entity_gel_id(v, GEL_SIDE_BOTTOM)
		if top then
			table.insert(gels, {x=v.cox, y=v.coy, dir="top", i=top} as Dyn)
		elseif left then
			table.insert(gels, {x=v.cox, y=v.coy, dir="left", i=left} as Dyn)
		elseif right then
			table.insert(gels, {x=v.cox, y=v.coy, dir="right", i=right} as Dyn)
		elseif bottom then
			table.insert(gels, {x=v.cox, y=v.coy, dir="bottom", i=bottom} as Dyn)
		end
	end	
	
	for _, v in pairs(self.childtable) do
		local v = v as Entity
		v.destroy = true
	end
	self.childtable = {}
	
	if self.power == false then
		return
	end
	
	local dir = self.dir
	local startx, starty = self.cox, self.coy
	local x, y = self.cox, self.coy
	self.children = 0
	
	local firstcheck = true
	local quit = false
	while x >= 1 and x <= session.mapwidth and y >= 1 and y <= session.mapheight and (tilequads[session.map[x][y][1]]:getproperty("collision", x, y) == false or tilequads[session.map[x][y][1]]:getproperty("grate", x, y)) and (x ~= startx or y ~= starty or dir ~= self.dir or firstcheck == true) and quit == false do
		firstcheck = false
		
		self.children = self.children + 1
		if dir == "right" then
			x = x + 1
			table.insert(session.objects["lightbridgebody"], lightbridgebody:new(self, x-1, y, "hor", self.children))
		elseif dir == "left" then
			x = x - 1
			table.insert(session.objects["lightbridgebody"], lightbridgebody:new(self, x+1, y, "hor", self.children))
		elseif dir == "up" then
			y = y - 1
			table.insert(session.objects["lightbridgebody"], lightbridgebody:new(self, x, y+1, "ver", self.children))
		elseif dir == "down" then
			y = y + 1
			table.insert(session.objects["lightbridgebody"], lightbridgebody:new(self, x, y-1, "ver", self.children))
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
			x, y = portalx as number, portaly as number
			dir = portalfacing as string
			
			if dir == "right" then
				x = x + 1
			elseif dir == "left" then
				x = x - 1
			elseif dir == "up" then
				y = y - 1
			elseif dir == "down" then
				y = y + 1
			end
		end
		
		--doors
		for _, v in pairs(session.objects["door"] as {any:Entity}) do
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
	
	--Restore gels! yay!
	--crosscheck childtable with gels to see any matching shit
	for _, w in pairs(self.childtable) do
		for _, v in pairs(gels) do
			if (v["x"] as number) == w.cox and (v["y"] as number) == w.coy then
				local d = v["dir"] as string
				local gelSide = GEL_SIDE_BY_NAME[d]
				if gelSide then
					if d == "left" or d == "right" then
						if w.dir == "ver" then
							entity_set_gel(w, gelSide, v["i"] as number)
						end
					else
						if w.dir == "hor" then
							entity_set_gel(w, gelSide, v["i"] as number)
						end
					end
				end
			end
		end
	end
end

function lightbridge:addChild(t: lightbridgebody)
	table.insert(self.childtable, t)
end

------------------------------------

function lightbridgebody.new(_: lightbridgebody, parent: lightbridge, x: number, y: number, dir: string, i: any): lightbridgebody
	local self = setmetatable({}, { __index = lightbridgebody }) as lightbridgebody
	self:init(parent, x, y, dir, i)
	return self
end

function lightbridgebody:init(parent: lightbridge, x: number, y: number, dir: string, i: any)
	parent:addChild(self)
	self.i = i
	self.cox = x
	self.coy = y
	self.dir = dir
	self.parent = parent

	--PHYSICS STUFF
	if dir == "hor" then
		self.x = x-1
		self.y = y-9/16
		self.width = 1
		self.height = 1/8
	else
		self.x = x-9/16
		self.y = y-1
		self.width= 1/8
		self.height = 1
	end
	self.static = true
	self.active = true
	self.category = 28
	
	self.mask = {true}
	
	self.gels = nil
	self.gelSides = nil
	
	self:pushstuff()
end

function lightbridgebody:pushstuff()
	local col = checkrect(self.x, self.y, self.width, self.height, {"box", "player"})
	for i = 1, #col, 2 do
		local v = session.objects[col[i]][col[i+1]]
		if self.dir == "ver" then
			if v.speedx >= 0 then
				if #checkrect(self.x + self.width, v.y, v.width, v.height, {"exclude", v}, true) > 0 then
					v.x = self.x - v.width
				else
					v.x = self.x + self.width
				end
			else
				if #checkrect(self.x - v.width, v.y, v.width, v.height, {"exclude", v}, true) > 0 then
					v.x = self.x + self.width
				else
					v.x = self.x - v.width
				end
			end
		elseif self.dir == "hor" then
			if v.speedy <= 0 then
				if #checkrect(v.x, self.y - v.height, v.width, v.height, {"exclude", v}, true) > 0 then
					v.y = self.y + self.height
				else
					v.y = self.y - v.height
				end
			else
				if #checkrect(v.x, self.y + self.height, v.width, v.height, {"exclude", v}, true) > 0 then
					v.y = self.y - v.height
				else
					v.y = self.y + self.height
				end
			end
		end
	end
end

function lightbridgebody:update(_: number): boolean
	if self.destroy then
		return true
	else
		return false
	end
end

function lightbridgebody:draw()
	love.graphics.setColor(1, 1, 1)
	
	local glowa = self.parent:getglowa(self.i)
	
	if self.dir == "hor" then
		love.graphics.draw(lightbridgeimg, tile_draw_x(self.cox-1), tile_draw_y_raw(self.coy-1.5), 0, world_draw_scale(), world_draw_scale())
		love.graphics.setColor(1, 1, 1, glowa)
		love.graphics.draw(lightbridgeglowimg, tile_draw_x(self.cox-1), tile_draw_y_raw(self.coy-1.5), 0, world_draw_scale(), world_draw_scale())
	else
		love.graphics.draw(lightbridgeimg, tile_draw_x(self.cox-1/16), tile_draw_y_raw(self.coy-1), math.pi/2, world_draw_scale(), world_draw_scale(), 8, 1)
		love.graphics.setColor(1, 1, 1, glowa)
		love.graphics.draw(lightbridgeglowimg, tile_draw_x(self.cox-1/16), tile_draw_y_raw(self.coy-1), math.pi/2, world_draw_scale(), world_draw_scale(), 8, 1)
	end
	
	love.graphics.setColor(1, 1, 1)
	
	--gel
	if self.gelSides then
		local px = tile_draw_x(self.cox - .5)
		local py = tile_draw_y(self.coy - 1, 0)
		draw_tile_gel_overlays(self.gelSides, px, py, 8, 2)
	end
end