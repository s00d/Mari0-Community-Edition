--[[ Teal port of root scaffold.lua ]]

rawset(_G, "scaffold", rawget(_G, "scaffold") or {})

function scaffold.new(_: scaffold, x: number, y: number, r: {any}): scaffold
	local self = setmetatable({}, { __index = scaffold }) as scaffold
	self:init(x, y, r)
	return self
end

function scaffold:init(x: number, y: number, r)
	--Input list
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	--DIRECTION
	if #self.r > 0 then
		self.dir = self.r[1] as string
		table.remove(self.r, 1)
	end
	
	--POWER
	if #self.r > 0 then
		self.power = self.r[1] == "false"
		table.remove(self.r, 1)
	end
	
	--SIZE
	if #self.r > 0 then
		self.size = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	
	--Distance
	if #self.r > 0 then
		self.distance = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	
	--SPEED
	if #self.r > 0 then
		self.speed = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	
	--Time1
	if #self.r > 0 then
		self.time1 = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	
	--Time2
	if #self.r > 0 then
		self.time2 = tonumber(self.r[1])
		table.remove(self.r, 1)
	end

	--PHYSICS STUFF
	if (self.size ~= math.floor(self.size)) then
		self.x = x-0.25
	else
		self.x = x-1
	end	
	self.y = y-15/16
	self.startx = self.x
	self.starty = self.y+15/16
	self.speedx = 0 --!
	self.speedy = 0
	self.width = self.size
	self.height = 8/16
	self.static = true
	self.active = true
	self.category = 15
	self.mask = {true}
	self.gravity = 0
	if self.dir == "down" or self.dir == "up" then
		self.starty = self.starty-1
	end
	
	--IMAGE STUFF
	self.drawable = false
	
	self.rotation = 0
	
	self.timer = 0
	self.state = "start"
	self.input1state = "off"
end

function scaffold:link(): any|nil
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

function scaffold:input(t, input): any
	if input == "power" then
		if t == "on" and self.input1state == "off" then
			self.power = not self.power
		elseif t == "off" and self.input1state == "on" then
			self.power = not self.power
		elseif t == "toggle" then
			self.power = not self.power
		end
		self.input1state = t
	end
	return nil
end

function scaffold:update(dt: number): boolean
	if not self.power then
		return false
	end
	
	if self.state == "start" then
		self.timer = self.timer + dt
		if self.timer > self.time1 then
			if self.dir == "right" then
				self.speedx = self.speed
			elseif self.dir == "left" then
				self.speedx = -self.speed
			elseif self.dir == "down" then
				self.speedy = self.speed
			elseif self.dir == "up" then
				self.speedy = -self.speed
			end
			self.state = "movingforth"
			self.timer = 0
		end
	elseif self.state == "end" then
		self.timer = self.timer + dt
		if self.timer > self.time2 then
			if self.dir == "right" then
				self.speedx = -self.speed
			elseif self.dir == "left" then
				self.speedx = self.speed
			elseif self.dir == "down" then
				self.speedy = -self.speed
			elseif self.dir == "up" then
				self.speedy = self.speed
			end
			self.state = "movingback"
			self.timer = 0
		end
	elseif self.state == "movingforth" or self.state == "movingback" then
		--moving part!
		local checktable: {string} = {"player", "enemy", "box"}
		local nextx, nexty = self.x + self.speedx*dt, self.y + self.speedy*dt

		for _, v in ipairs(checktable) do
			for _, w in pairs(objects[v] as {any:Body}) do
				if inrange(w.x, self.x-w.width, self.x+self.width) and inrange(w.y + w.height, self.y - 0.1, self.y + 0.1) then
					local newx = w.x + self.speedx*dt
					local newy = nexty - w.height
					if #checkrect(newx, newy, w.width, w.height, {"exclude", w, self}, true) == 0 then
						w.x = newx
						w.y = newy
						
						blay = newy+w.height
					end
				end
			end
		end
		
		self.x = nextx
		self.y = nexty
		
		if self.dir == "right" or self.dir == "left" then
			--check if end or start
			if self.state == "movingforth" then
				if self.dir == "right" then
					if self.x > self.startx + self.distance then
						self.state = "end"
						self.x = self.startx + self.distance
					end
				else
					if self.x < self.startx - self.distance then
						self.state = "end"
						self.x = self.startx - self.distance
					end
				end
			else
				if self.dir == "left" then
					if self.x > self.startx then
						self.state = "start"
						self.x = self.startx
					end
				else
					if self.x < self.startx then
						self.state = "start"
						self.x = self.startx
					end
				end
			end			
		else
			--check if end or start
			if self.state == "movingforth" then
				if self.dir == "down" then
					if self.y > self.starty + self.distance then
						self.state = "end"
						self.y = self.starty + self.distance
					end
				else
					if self.y < self.starty - self.distance then
						self.state = "end"
						self.y = self.starty - self.distance
					end
				end
			else
				if self.dir == "up" then
					if self.y > self.starty then
						self.state = "start"
						self.y = self.starty
					end
				else
					if self.y < self.starty then
						self.state = "start"
						self.y = self.starty
					end
				end
			end		
		end
	end
	
	return false
end

function scaffold:draw()
	for i = 1, self.size do
		if self.dir ~= "justright" then
			love.graphics.draw(scaffoldimg, math.floor((self.x+i-1-xscroll)*16*scale), math.floor((self.y-yscroll-8/16)*16*scale), 0, scale, scale)
		else
			love.graphics.draw(platformbonusimg, math.floor((self.x+i-1-xscroll)*16*scale), math.floor((self.y-yscroll-8/16)*16*scale), 0, scale, scale)
		end
	end
	
	if math.ceil(self.size) ~= self.size then --draw 1 more on the rightest
		love.graphics.draw(scaffoldimg, math.floor((self.x+self.size-1-xscroll)*16*scale), math.floor((self.y-yscroll-8/16)*16*scale), 0, scale, scale)
	end
end

function scaffold:rightcollide(_: any, _: Entity): boolean
	return false
end

function scaffold:leftcollide(_: any, _: Entity): boolean
	return false
end

function scaffold:ceilcollide(_: any, _: Entity): boolean
	if self.dir == "justright" then
		self.speedx = platformbonusspeed
	end
	return false
end

function scaffold:floorcollide(_: any, _: Entity): boolean
	return false
end

function scaffold:passivecollide(_: any, _: Entity): boolean
	return false
end