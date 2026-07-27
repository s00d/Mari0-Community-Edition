--[[ Teal port of root emancipationgrill.lua ]]

rawset(_G, "emancipationgrill", rawget(_G, "emancipationgrill") or {})

function emancipationgrill.new(_: emancipationgrill, x: number, y: number, r: {any}): emancipationgrill
	local self = setmetatable({}, { __index = emancipationgrill }) as emancipationgrill
	self:init(x, y, r)
	return self
end

function emancipationgrill:init(x: number, y: number, r: any)
	self.x = x
	self.y = y
	self.r = {unpack(r as {any})}
	self.dir = "hor"
	self.active = true
	self.inputstate = "off" as any
	
	self.thickness = 4 -- For aabb checks
	
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	--Input list
	--DIR
	if #self.r > 0 and self.r[1] ~= "link" then
		self.dir = self.r[1]
		table.remove(self.r, 1)
	end
	
	--OFF
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			self.active = false
		end
		table.remove(self.r, 1)
	end
	
	self.destroy = false
	if getTile(self.x, self.y) == true then
		self.destroy = true
	end
	
	for i, v in pairs(emancipationgrills as {any:Entity}) do
		local a, b = v:getTileInvolved(self.x, self.y)
		if a and b == self.dir then
			self.destroy = true
		end
	end
	
	local particles: Dyn = {}
	particles.i = {}
	particles.dir = {}
	particles.speed = {}
	particles.mod = {}
	self.particles = particles
	
	local involved: {any:any} = {}
	self.involvedtiles = involved
	
	--find start and end
	if self.dir == "hor" then
		local curx = self.x
		while curx >= 1 and getTile(curx, self.y) == false do
			involved[curx] = self.y
			curx = curx - 1
		end
		self.startx = curx + 1
		
		local curx2 = self.x
		while curx2 <= mapwidth and getTile(curx2, self.y) == false do
			involved[curx2] = self.y
			curx2 = curx2 + 1
		end
		self.endx = curx2 - 1
		
		self.range = math.floor(((self.endx - self.startx + 1 + emanceimgwidth/16)*16)*scale)
	else
		local cury = self.y
		while cury >= 1 and getTile(self.x, cury) == false do
			involved[cury] = self.x
			cury = cury - 1
		end
		self.starty = cury + 1
		
		local cury2 = self.y
		while cury2 <= mapheight and getTile(self.x, cury2) == false do
			involved[cury2] = self.x
			cury2 = cury2 + 1
		end
		self.endy = cury2 - 1
		
		self.range = math.floor(((self.endy - self.starty + 1 + emanceimgwidth/16)*16)*scale)
	end
	
	for _ = 1, self.range/16/scale do
		table.insert(particles.i as {number}, math.random())
		table.insert(particles.speed as {number}, (1-emanceparticlespeedmod)+math.random()*emanceparticlespeedmod*2)
		if math.random(2) == 1 then
			table.insert(particles.dir as {number}, 1)
		else
			table.insert(particles.dir as {number}, -1)
		end
		table.insert(particles.mod as {number}, math.random(4)-2)
	end
end

function emancipationgrill:link()
	while #self.r > 3 do
		for j, w in pairs(outputs) do
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

function emancipationgrill:update(dt: number): any...
	if self.destroy then
		return true
	end

	local particles = self.particles
	for i, v in pairs(particles.i as {any:number}) do
		(particles.i as {any:number})[i] = (particles.i as {any:number})[i] + emanceparticlespeed/(self.range/16/scale)*dt*(particles.speed as {any:number})[i]
		while (particles.i as {any:number})[i] > 1 do
			(particles.i as {any:number})[i] = (particles.i as {any:number})[i]-1
			(particles.speed as {any:number})[i] = (1-emanceparticlespeedmod)+math.random()*emanceparticlespeedmod*2
			if math.random(2) == 1 then
				(particles.dir as {any:number})[i] = 1
			else
				(particles.dir as {any:number})[i] = -1
			end
			(particles.mod as {any:number})[i] = math.random(4)-2
		end
	end
end

function emancipationgrill:draw()
	if self.destroy == false then
		if self.dir == "hor" then
			parstartleft = math.floor((self.startx-1-xscroll)*16*scale)
			parstartright = math.floor((self.endx-1-xscroll)*16*scale)
			if self.active then
				love.graphics.setScissor(parstartleft, ((self.y-yscroll-1)*16-self.thickness/2)*scale,
					self.range - emanceimgwidth*scale, self.thickness*scale)
				
				love.graphics.setColor(unpack(emancelinecolor))
				love.graphics.rectangle("fill", math.floor((self.startx-1-xscroll)*16*scale), ((self.y-yscroll-1)*16-self.thickness/2)*scale,
					self.range, self.thickness*scale)
				love.graphics.setColor(1, 1, 1)
				
				for i, v in pairs(self.particles.i as {any:number}) do
					local y = ((self.y-1-yscroll)*16-((self.particles.mod as {any:number})[i]))*scale
					if ((self.particles.dir as {any:number})[i]) == 1 then
						local x = parstartleft+self.range*v
						love.graphics.draw(emanceparticleimg, math.floor(x), y, math.pi/2, scale, scale)
					else
						local x = parstartright-self.range*v
						love.graphics.draw(emanceparticleimg, math.floor(x), y, -math.pi/2, scale, scale, 1)
					end
				end
				
				love.graphics.setScissor()
			end
			
			--Sidethings
			love.graphics.draw(emancesideimg, parstartleft, ((self.y-1-yscroll)*16-4)*scale, 0, scale, scale)
			love.graphics.draw(emancesideimg, parstartright+16*scale, ((self.y-1-yscroll)*16+4)*scale, math.pi, scale, scale)
		else --ver
			parstartup = math.floor((self.starty-yscroll-1)*16*scale)
			parstartdown = math.floor((self.endy-yscroll-1)*16*scale)
			if self.active then
				love.graphics.setScissor(math.floor(((self.x-1-xscroll)*16+self.thickness*1.5)*scale), parstartup-8*scale,
					self.thickness*scale, self.range - emanceimgwidth*scale)
				
				love.graphics.setColor(unpack(emancelinecolor))
				love.graphics.rectangle("fill", math.floor(((self.x-1-xscroll)*16+self.thickness*1.5)*scale), parstartup-8*scale,
					self.thickness*scale, self.range - emanceimgwidth*scale)
				love.graphics.setColor(1, 1, 1)
				
				for i, v in pairs(self.particles.i as {any:number}) do
					local x = ((self.x-1-xscroll)*16-((self.particles.mod as {any:number})[i])+9)*scale
					if ((self.particles.dir as {any:number})[i]) == 1 then
						local y = parstartup-yscroll+self.range*v
						love.graphics.draw(emanceparticleimg, math.floor(x), y, math.pi, scale, scale)
					else
						local y = parstartdown-yscroll-self.range*v
						love.graphics.draw(emanceparticleimg, math.floor(x), y, 0, scale, scale, 1)
					end
				end
				
				love.graphics.setScissor()
			end
			
			--Sidethings
			love.graphics.draw(emancesideimg, math.floor(((self.x-xscroll)*16-4)*scale), parstartup-8*scale, math.pi/2, scale, scale)
			love.graphics.draw(emancesideimg, math.floor(((self.x-xscroll)*16-12)*scale), parstartdown+8*scale, -math.pi/2, scale, scale)
		end
	end
end

function emancipationgrill:getTileInvolved(x: any, y: any): any, any
	if self.active then
		if self.dir == "hor" then
			if (self.involvedtiles as {any:any})[x] == y then
				return true, "hor"
			else
				return false, "hor"
			end
		else
			if (self.involvedtiles as {any:any})[y] == x then
				return true, "ver"
			else
				return false, "ver"
			end
		end
	else
		return false, nil
	end
end

function emancipationgrill:input(t: any, input: any)
	if input == "power" then
		if t == "on" and self.inputstate == "off" then
			self.active = not self.active
		elseif t == "off" and self.inputstate == "on" then
			self.active = not self.active
		elseif t == "toggle" then
			self.active = not self.active
		end
		
		self.inputstate = t
	end
end
