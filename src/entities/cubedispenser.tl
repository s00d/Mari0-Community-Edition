--[[ Teal port of root cubedispenser.lua ]]

rawset(_G, "cubedispenser", rawget(_G, "cubedispenser") or {})

function cubedispenser.new(_: cubedispenser, x: number, y: number, r: {any}): cubedispenser
	local self = setmetatable({}, { __index = cubedispenser }) as cubedispenser
	self:init(x, y, r)
	return self
end

function cubedispenser:init(x: number, y: number, r)
	--PHYSICS STUFF
	self.cox = x
	self.coy = y
	self.x = x-1
	self.y = y-1
	self.speedy = 0
	self.speedx = 0
	self.width = 2
	self.height = 2
	self.static = true
	self.active = true
	self.category = 7
	self.mask = {true, false, false, false, false, false, false, false, true}
	
	self.timer = cubedispensertime
	self.t = "box"
	
	--Input list
	self.input1state = "off"
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	--DROP ON LOAD
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			self.timer = 0
		end
		table.remove(self.r, 1)
	end
	
	--DROP ON LOAD
	if #self.r > 0 and self.r[1] ~= "link" then
		self.spawnondestroy = self.r[1] == "true"
		table.remove(self.r, 1)
	end
	
	--TYPE
	if #self.r > 0 and self.r[1] ~= "link" then
		self.t = self.r[1]
		
		table.remove(self.r, 1)
	end
	
	self.inputactive = false
	self.boxexists = false
	self.box = nil
end

function cubedispenser:input(t, input): any
	if input == "drop" or input == "drop_enemy_triggered" then
		if (t == "on" and self.input1state == "off") or (t == "toggle" ) then
			if self.boxexists then
				self.boxexists = false
				if input == "drop" then
					self:removebox()
				end
			end
			
			self.timer = 0
		end
	end
	return nil
end

function cubedispenser:link(): any|nil
	while #self.r > 3 do
		for _, w in pairs(outputs) do
			for _, v in pairs(objects[w]) do
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

function cubedispenser:update(dt: number): boolean
	if self.timer < cubedispensertime then
		self.timer = self.timer + dt
		
		if self.timer > 0.6 and self.boxexists == false then
			local temp: Entity|nil = nil
			if self.t == "box" then
				temp = box:new(self.cox+.5, self.coy)
				temp:addoutput(self, "drop")
				table.insert(objects["box"], temp)
			elseif tablecontains(enemies, self.t) then
				temp = enemy:new(self.cox, self.coy+2-enemiesdata[self.t].height, self.t as string)
				
				if self.spawnondestroy then
					temp:addoutput(self, "drop_enemy_triggered")
				end
				
				temp.mask[7] = true
				table.insert(objects["enemy"], temp)
			end
			
			self.box = temp
			self.boxexists = true
		elseif self.timer > 1 then
			self.timer = 1
		end	
	end
	return false
end

function cubedispenser:draw()
	love.graphics.draw(cubedispenserimg, tile_draw_x(self.cox - 1), tile_draw_y_raw(self.coy - 1.5), 0, world_draw_scale(), world_draw_scale(), 0, 0)
end

function cubedispenser:removebox()
	if self.box then
		-- emancipate expects one extra argument on Entity.
		self.box:emancipate(nil)
	end
end