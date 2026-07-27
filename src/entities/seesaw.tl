--[[ Teal port of root seesaw.lua ]]

rawset(_G, "seesaw", rawget(_G, "seesaw") or {})

function seesaw.new(_: seesaw, x: number, y: number, r: {any}): seesaw
	local self = setmetatable({}, { __index = seesaw }) as seesaw
	self:init(x, y, r)
	return self
end

--settings for the types
seesawtype = {}
seesawtype[1] = {7,4,6,3}
seesawtype[2] = {4,2,6,3}
seesawtype[3] = {7,3,6,3}
seesawtype[4] = {8,3,7,3}
seesawtype[5] = {5,3,7,3}
seesawtype[6] = {6,3,7,3}
seesawtype[7] = {4,3,7,1.5}
seesawtype[8] = {3,3,7,1.5}
seesawtype[9] = {3,4,7,1.5}

function seesaw:init(x: number, y: number, r: any)
	self.x = x
	self.y = y
	
	local t: any = 1
	
	self.range = (seesawtype[t] as {any})[1] as number
	self.dist1 = (seesawtype[t] as {any})[2] as number
	self.dist2 = (seesawtype[t] as {any})[3] as number
	self.width = (seesawtype[t] as {any})[4] as number
	
	--Input list
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	--RANGE
	if #self.r > 0 and self.r[1] ~= "link" then
		self.range = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	--DIST1
	if #self.r > 0 and self.r[1] ~= "link" then
		self.dist1 = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	--DIST2
	if #self.r > 0 and self.r[1] ~= "link" then
		self.dist2 = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	--WIDTH
	if #self.r > 0 and self.r[1] ~= "link" then
		self.width = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	
	self.lcount = 0
	self.rcount = 0
	self.falloff = false
	
	self.leftplatform = seesawplatform:new(self.x, self.y+self.dist1, self.width, self, "left") as seesawplatform
	self.rightplatform = seesawplatform:new(self.x+self.range, self.y+self.dist2, self.width, self, "right") as seesawplatform
	
	table.insert(objects["seesawplatform"] as {any}, self.leftplatform)
	table.insert(objects["seesawplatform"] as {any}, self.rightplatform)
end

function seesaw:update(dt: number)
	local leftp = self.leftplatform as seesawplatform
	local rightp = self.rightplatform as seesawplatform
	if self.falloff then
		leftp.speedy = leftp.speedy + seesawgravity*dt
		rightp.speedy = rightp.speedy + seesawgravity*dt
	else
		local speed = (self.lcount as number) - (self.rcount as number)
		
		leftp.speedy = leftp.speedy + speed*seesawspeed*dt
		rightp.speedy = rightp.speedy - speed*seesawspeed*dt
		
		if leftp.speedy > 0 and speed <= 0 then
			leftp.speedy = leftp.speedy - seesawfriction*dt
			if speed == 0 and leftp.speedy < 0 then
				leftp.speedy = 0
			end
		elseif leftp.speedy < 0 and speed >= 0 then
			leftp.speedy = leftp.speedy + seesawfriction*dt
		end
	
		if rightp.speedy > 0 and speed >= 0 then
			rightp.speedy = rightp.speedy - seesawfriction*dt
			if speed == 0 and rightp.speedy < 0 then
				leftp.speedy = 0
			end
		elseif rightp.speedy < 0 and speed <= 0 then
			rightp.speedy = rightp.speedy + seesawfriction*dt
		end
		
		--check if falloff
		if leftp.y-self.y <= 0 then
			if self.rcount ~= 0 then
				self:fallingoff("right")
			else
				leftp.y = self.y
				rightp.y = self.y+self.dist1+self.dist2-2-2/16
			end
		end
		
		if rightp.y-self.y <= 0 then
			if self.lcount ~= 0 then
				self:fallingoff("left")
			else
				rightp.y = self.y
				leftp.y = self.y+self.dist1+self.dist2-2-2/16
			end
		end
	end
end

function seesaw:fallingoff(side: any)
	local leftp = self.leftplatform as seesawplatform
	local rightp = self.rightplatform as seesawplatform
	leftp.speedy = 0
	rightp.speedy = 0
	
	self.falloffside = side
	self.falloff = true
end

function seesaw:draw()
	local leftp = self.leftplatform as seesawplatform
	local rightp = self.rightplatform as seesawplatform
	--left
	love.graphics.draw(seesawimg, seesawquad[1], math.floor((self.x-1-xscroll)*16*scale), (self.y-yscroll-1.5)*16*scale, 0, scale, scale)
	
	if self.falloff == false and leftp.y-self.y >= 0 then
		love.graphics.setScissor((self.x-1-xscroll)*16*scale, (self.y-yscroll-0.5)*16*scale, 16*scale, math.floor((leftp.y-self.y)*16*scale))
		for i = 1, math.ceil(leftp.y-self.y) do
			love.graphics.draw(seesawimg, seesawquad[3], math.floor((self.x-1-xscroll)*16*scale), (self.y-yscroll+i-1.5)*16*scale, 0, scale, scale)
		end
		love.graphics.setScissor()
	else
		if self.falloffside == "left" then
			for i = 1, self.dist1+self.dist2-2 do
				love.graphics.draw(seesawimg, seesawquad[3], math.floor((self.x-1-xscroll)*16*scale), (self.y-yscroll+i-1.5)*16*scale, 0, scale, scale)
			end
		end
	end
		
	
	--middle
	for i = 1, self.range-1 do
		love.graphics.draw(seesawimg, seesawquad[4], math.floor((self.x-1+i-xscroll)*16*scale), (self.y-yscroll-1.5)*16*scale, 0, scale, scale)
	end
		
	--right
	love.graphics.draw(seesawimg, seesawquad[2], math.floor((self.x-1+self.range-xscroll)*16*scale), (self.y-yscroll-1.5)*16*scale, 0, scale, scale)
	
	if self.falloff == false and rightp.y-self.y >= 0 then
		love.graphics.setScissor((self.x-1+self.range-xscroll)*16*scale, (self.y-yscroll-0.5)*16*scale, 16*scale, math.floor((rightp.y-self.y)*16*scale))
		for i = 1, math.ceil(rightp.y-self.y) do
			love.graphics.draw(seesawimg, seesawquad[3], math.floor((self.x+self.range-1-xscroll)*16*scale), (self.y-yscroll+i-1.5)*16*scale, 0, scale, scale)
		end
		love.graphics.setScissor()
	else
		if self.falloffside == "right" then
			for i = 1, self.dist1+self.dist2-2 do
				love.graphics.draw(seesawimg, seesawquad[3], math.floor((self.x+self.range-1-xscroll)*16*scale), (self.y-yscroll+i-1.5)*16*scale, 0, scale, scale)
			end
		end
	end
end

function seesaw:callbackleft(i)
	self.lcount = i
end

function seesaw:callbackright(i)
	self.rcount = i
end