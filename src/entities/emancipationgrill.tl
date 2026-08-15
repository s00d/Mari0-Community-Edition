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
	self.inputstate = "off"
	
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
	
	for _, v in pairs(emancipationgrills as {any:Entity}) do
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
		while curx2 <= session.mapwidth and getTile(curx2, self.y) == false do
			involved[curx2] = self.y
			curx2 = curx2 + 1
		end
		self.endx = curx2 - 1
		
		self.range = math.floor((self.endx - self.startx + 1 + emanceimgwidth/16) * 16)
	else
		local cury = self.y
		while cury >= 1 and getTile(self.x, cury) == false do
			involved[cury] = self.x
			cury = cury - 1
		end
		self.starty = cury + 1
		
		local cury2 = self.y
		while cury2 <= session.mapheight and getTile(self.x, cury2) == false do
			involved[cury2] = self.x
			cury2 = cury2 + 1
		end
		self.endy = cury2 - 1
		
		self.range = math.floor((self.endy - self.starty + 1 + emanceimgwidth/16) * 16)
	end
	
	for _ = 1, self.range/16 do
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

function emancipationgrill:update(dt: number): boolean
	if self.destroy then
		return true
	end

	local particles = self.particles
	for i, _ in pairs(particles.i as {any:number}) do
		(particles.i as {any:number})[i] = (particles.i as {any:number})[i] + emanceparticlespeed/(self.range/16)*dt*(particles.speed as {any:number})[i]
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
	if self.destroy then
		return
	end

	local sc = world_draw_scale()
	local thick = self.thickness

	if self.dir == "hor" then
		local parstartleft = tile_draw_x(self.startx - 1)
		local parstartright = tile_draw_x(self.endx - 1)
		local line_y = tile_draw_y(self.y - 1, thick / 2)

		if self.active then
			love.graphics.setScissor(
				screen_draw_x(self.startx - 1),
				screen_draw_y(self.y - 1) - math.floor(thick / 2 * sc),
				math.floor((self.range - emanceimgwidth) * sc),
				math.floor(thick * sc)
			)

			love.graphics.setColor(unpack(emancelinecolor))
			love.graphics.rectangle("fill", parstartleft, line_y, self.range, thick)
			love.graphics.setColor(1, 1, 1)

			for i, v in pairs(self.particles.i as {any:number}) do
				local mod_i = (self.particles.mod as {any:number})[i]
				local py = tile_draw_y(self.y - 1, mod_i)
				if ((self.particles.dir as {any:number})[i]) == 1 then
					local px = parstartleft + self.range * v
					love.graphics.draw(emanceparticleimg, math.floor(px), py, math.pi/2, sc, sc)
				else
					local px = parstartright - self.range * v
					love.graphics.draw(emanceparticleimg, math.floor(px), py, -math.pi/2, sc, sc, 1)
				end
			end

			love.graphics.setScissor()
		end

		love.graphics.draw(emancesideimg, parstartleft, tile_draw_y(self.y - 1, 4), 0, sc, sc)
		love.graphics.draw(emancesideimg, parstartright + 16, tile_draw_y(self.y - 1, -4), math.pi, sc, sc)
	else
		local parstartup = tile_draw_y_raw(self.starty - 1)
		local parstartdown = tile_draw_y_raw(self.endy - 1)
		local line_x = tile_draw_x(self.x - 1) + thick * 1.5
		local line_x_screen = world_camera_screen_x(math.floor((self.x - 1) * 16 + thick * 1.5))

		if self.active then
			love.graphics.setScissor(
				line_x_screen,
				screen_draw_y(self.starty - 1) - math.floor(8 * sc),
				math.floor(thick * sc),
				math.floor((self.range - emanceimgwidth) * sc)
			)

			love.graphics.setColor(unpack(emancelinecolor))
			love.graphics.rectangle(
				"fill",
				line_x,
				parstartup - 8,
				thick,
				self.range - emanceimgwidth
			)
			love.graphics.setColor(1, 1, 1)

			for i, v in pairs(self.particles.i as {any:number}) do
				local mod_i = (self.particles.mod as {any:number})[i]
				local px = line_x - (mod_i + 9)
				if ((self.particles.dir as {any:number})[i]) == 1 then
					local py = parstartup + self.range * v
					love.graphics.draw(emanceparticleimg, math.floor(px), py, math.pi, sc, sc)
				else
					local py = parstartdown - self.range * v
					love.graphics.draw(emanceparticleimg, math.floor(px), py, 0, sc, sc, 1)
				end
			end

			love.graphics.setScissor()
		end

		love.graphics.draw(emancesideimg, tile_draw_x(self.x) - 4, parstartup - 8, math.pi/2, sc, sc)
		love.graphics.draw(emancesideimg, tile_draw_x(self.x) - 12, parstartdown + 8, -math.pi/2, sc, sc)
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
