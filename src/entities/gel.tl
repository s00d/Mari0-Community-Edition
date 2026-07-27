--[[ Teal port of root gel.lua ]]

rawset(_G, "gel", rawget(_G, "gel") or {})

function gel.new(_: gel, x: number, y: number, id: any): gel
	local self = setmetatable({}, { __index = gel }) as gel
	self:init(x, y, id)
	return self
end

function gel:init(x: number, y: number, id)
	self.id = gel_clamp_id(id)
	
	--PHYSICS STUFF
	self.x = x-14/16
	self.y = y-12/16
	self.speedy = 0
	self.speedx = 0
	self.width = 12/16
	self.height = 12/16
	self.static = false
	self.active = true
	self.category = 8
	self.mask = {false, false, true, true, true, true, true, true, false, false, true}
	self.gravity = 50
	self.autodelete = true
	self.timer = 0
	
	--IMAGE STUFF
	self.drawable = true
	self.quad = gelquad[math.random(3)]
	self.offsetX = 8
	self.offsetY = 0
	self.quadcenterX = 8
	self.quadcenterY = 8
	self.rotation = 0 --for portals
	local gelimgs: {Image} = {gel1img, gel2img, gel3img, gel4img}
	self.graphic = gelimgs[self.id as integer]
	
	self.destroy = false
end

function gel:update(dt: number): boolean
	--Funnels and fuck
	if self.funnel and not self.infunnel then
		self:enteredfunnel(true)
	end
	
	if self.infunnel and not self.funnel then
		self:enteredfunnel(false)
	end
	
	self.funnel = false

	if self.speedy > gelmaxspeed then
		self.speedy = gelmaxspeed
	end
	
	self.rotation = 0
	
	self.timer = self.timer + dt
	if self.timer >= gellifetime then
		return true
	end
	
	return self.destroy
end

function gel:leftcollide(a: any, b: Entity): boolean|nil
	if self:globalcollide(a, b) then
		return false
	end
	self.destroy = true
	if a == "tile" then
		local x, y = b.cox, b.coy
		
		if (inmap(x+1, y) and tilequads[map[x+1][y][1]]:getproperty("collision", x+1, y)) or (inmap(x, y) and tilequads[map[x][y][1]]:getproperty("collision", x, y) == false) then
			return nil
		end
		
		--see if adjsajcjet tile is a better fit
		if math.floor(self.y+self.height/2)+1 ~= y then
			if inmap(x, math.floor(self.y+self.height/2)+1) and tilequads[map[x][math.floor(self.y+self.height/2)+1][1]]:getproperty("collision", x, math.floor(self.y+self.height/2)+1) then
				y = math.floor(self.y+self.height/2)+1
			end
		end
		
		map_cell_set_gel(map[x][y], GEL_SIDE_RIGHT, self.id)
	elseif a == "lightbridgebody" and b.dir == "ver" then
		entity_set_gel(b, GEL_SIDE_RIGHT, self.id)
	end
	return nil
end

function gel:rightcollide(a: any, b: Entity): boolean|nil
	if self:globalcollide(a, b) then
		return false
	end
	self.destroy = true
	if a == "tile" then
		local x, y = b.cox, b.coy
		
		if (inmap(x-1, y) and tilequads[map[x-1][y][1]]:getproperty("collision", x-1, y)) or (inmap(x, y) and tilequads[map[x][y][1]]:getproperty("collision", x, y) == false) then
			return nil
		end
		
		--see if adjsajcjet tile is a better fit
		if math.floor(self.y+self.height/2)+1 ~= y then
			if inmap(x, math.floor(self.y+self.height/2)+1) and tilequads[map[x][math.floor(self.y+self.height/2)+1][1]]:getproperty("collision", x, math.floor(self.y+self.height/2)+1) then
				y = math.floor(self.y+self.height/2)+1
			end
		end
		
		map_cell_set_gel(map[x][y], GEL_SIDE_LEFT, self.id)
	elseif a == "lightbridgebody" and b.dir == "ver" then
		entity_set_gel(b, GEL_SIDE_LEFT, self.id)
	end
	return nil
end

function gel:floorcollide(a: any, b: Entity): boolean|nil
	if self:globalcollide(a, b) then
		return false
	end
	self.destroy = true
	if a == "tile" then
		local x, y = b.cox, b.coy
		
		if (inmap(x, y-1) and tilequads[map[x][y-1][1]]:getproperty("collision", x, y-1)) or (inmap(x, y) and tilequads[map[x][y][1]]:getproperty("collision", x, y) == false) then
			return nil
		end
		
		--see if adjsajcjet tile is a better fit
		if math.floor(self.x+self.width/2)+1 ~= x then
			if inmap(x, y) and tilequads[map[x][y][1]]:getproperty("collision", x, y) then
				x = math.floor(self.x+self.width/2)+1
			end
		end
		
		if inmap(x, y) and tilequads[map[x][y][1]]:getproperty("collision", x, y) then
			if map_cell_gel_id(map[x][y], GEL_SIDE_TOP) == self.id then
				if self.speedx > 0 then
					for cox = x+1, x+self.speedx*0.2 do
						if inmap(cox, y-1) and tilequads[map[cox][y][1]]:getproperty("collision", cox, y) == true and tilequads[map[cox][y-1][1]]:getproperty("collision", cox, y-1) == false then
							if map_cell_gel_id(map[cox][y], GEL_SIDE_TOP) ~= self.id then
								map_cell_set_gel(map[cox][y], GEL_SIDE_TOP, self.id)
								break
							end
						else
							break
						end
					end
				elseif self.speedx < 0 then
					for cox = x-1, x+self.speedx*0.2, -1 do
						if inmap(cox, y-1) and tilequads[map[cox][y][1]]:getproperty("collision", cox, y) and tilequads[map[cox][y-1][1]]:getproperty("collision", cox, y-1) == false then
							if map_cell_gel_id(map[cox][y], GEL_SIDE_TOP) ~= self.id then
								map_cell_set_gel(map[cox][y], GEL_SIDE_TOP, self.id)
								break
							end
						else
							break
						end
					end
				end
			else
				map_cell_set_gel(map[x][y], GEL_SIDE_TOP, self.id)
			end
		end
	elseif a == "lightbridgebody" and b.dir == "hor" then
		entity_set_gel(b, GEL_SIDE_TOP, self.id)
	end
	return nil
end

function gel:ceilcollide(a: any, b: Entity): boolean|nil
	if self:globalcollide(a, b) then
		return false
	end
	self.destroy = true
	if a == "tile" then
		local x, y = b.cox, b.coy
		if not inmap(x, y+1) or tilequads[map[x][y+1][1]]:getproperty("collision", x, y+1) == false then
			local x, y = b.cox, b.coy
			
			map_cell_set_gel(map[x][y], GEL_SIDE_BOTTOM, self.id)
		end
	elseif a == "lightbridgebody" and b.dir == "hor" then
		entity_set_gel(b, GEL_SIDE_BOTTOM, self.id)
	end
	return nil
end

function gel:globalcollide(a: any, b: Entity): boolean|nil
	if a == "tile" then
		local x, y = b.cox, b.coy
		if tilequads[map[x][y][1]]:getproperty("invisible", x, y) or tilequads[map[x][y][1]]:getproperty("grate", x, y) then
			return true
		end
	end
	return nil
end

function gel:enteredfunnel(inside)
	if inside then
		self.infunnel = true
	else
		self.infunnel = false
		self.gravity = 50
	end
end