--[[ Teal port of root faithplate.lua ]]

rawset(_G, "faithplate", rawget(_G, "faithplate") or {})

function faithplate.new(_: faithplate, x: number, y: number, r: {any}): faithplate
	local self = setmetatable({}, { __index = faithplate }) as faithplate
	self:init(x, y, r)
	return self
end

function faithplate:init(x: number, y: number, r)
	self.cox = x
	self.coy = y
	
	self.x = x-1
	self.y = y-1
	self.width = 2
	self.height = 0.125
	self.active = true
	self.static = true
	self.category = 26
	
	self.power = true
	
	self.mask = {true}
	
	self.animationtimer = 1
	
	self.includetable = {"player", "box", "enemy"}
	
	self.xspeed = 0
	self.yspeed = 20
	
	self.input1state = "off"
	
	--Input list
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	--Xspeed
	if #self.r > 0 then
		local xs = self.r[1] as string
		if string.sub(xs, 1, 1) == "m" then
			self.xspeed = -(tonumber(string.sub(xs, 2)) as number)
		else
			self.xspeed = tonumber(xs) as number
		end
		table.remove(self.r, 1)
	end
	--Yspeed
	if #self.r > 0 then
		self.yspeed = (tonumber(self.r[1] as any) as number) or 20
		table.remove(self.r, 1)
	end
	--POWER
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			self.power = false
		end
		table.remove(self.r, 1)
	end
	
	--determine rough direction
	if self.yspeed > math.abs(self.xspeed)*2 then
		self.dir = "up"
	elseif self.xspeed > 0 then
		self.dir = "right"
	else
		self.dir = "left"
	end
end

function faithplate:input(t, input): any
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

function faithplate:link(): any|nil
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
	return nil
end

function faithplate:update(dt: number)
	if self.animationtimer < 1 then
		self.animationtimer = self.animationtimer + dt / faithplatetime
	end
	
	if self.power then
		local intable = checkrect(self.x+.5, self.y-0.125, 1, 0.125, self.includetable)
		
		for i = 1, #intable, 2 do
			local obj = (objects[intable[i] as any] as {any:Entity})[intable[i+1] as any]
			if not obj.ignorefaithplates then
				if obj.speedy >= 0 then
					obj.speedy = -self.yspeed
					obj.speedx = self.xspeed
					
					obj.x = self.x+1-obj.width/2
					
					
					if obj.faithplate then
						(obj.faithplate as function(Entity, any))(obj, self.dir)
					end
					
					self.animationtimer = 0
				end
			end
		end
	end
end

function faithplate:draw()
	local quad = 2
	if self.power then
		quad = 1
	end
	
	love.graphics.setScissor(math.floor((self.cox-1-xscroll)*16*scale), (self.coy-yscroll-4)*16*scale, 32*scale, (2.5+2/16)*16*scale)
	
	love.graphics.setColor(unpack(background))
	love.graphics.rectangle("fill", math.floor((self.cox-1-xscroll)*16*scale), (self.coy-yscroll-1.5)*16*scale, 32*scale, 2*scale)
	love.graphics.setColor(1, 1, 1)
	

	if self.animationtimer < 1 then
		if self.dir == "right" then
			local rot: number = 0
			if self.animationtimer < 0.1 then
				rot = math.pi/4*(self.animationtimer/0.1)
			elseif self.animationtimer < 0.3 then
				rot = math.pi/4
			else
				rot = math.pi/4*(1 - (self.animationtimer-0.3)/0.7)
			end
				
			love.graphics.draw(faithplateplateimg, faithplatequad[quad], math.floor((self.cox+1-xscroll)*16*scale), (self.coy-yscroll-1.5)*16*scale, rot, scale, scale, 32)
		elseif self.dir == "left" then
			local rot: number = 0
			if self.animationtimer < 0.1 then
				rot = math.pi/4*(self.animationtimer/0.1)
			elseif self.animationtimer < 0.3 then
				rot = math.pi/4
			else
				rot = math.pi/4*(1 - (self.animationtimer-0.3)/0.7)
			end
			
			love.graphics.draw(faithplateplateimg, faithplatequad[quad], math.floor((self.cox-1-xscroll)*16*scale), (self.coy-yscroll-1.5)*16*scale, -rot, -scale, scale, 32)
		elseif self.dir == "up" then
			local ymod: number = 0
			if self.animationtimer < 0.1 then
				ymod = .5*(self.animationtimer/0.1)
			elseif self.animationtimer < 0.3 then
				ymod = .5
			else
				ymod = .5*(1 - (self.animationtimer-0.3)/0.7)
			end
			
			love.graphics.draw(faithplateplateimg, faithplatequad[quad], math.floor((self.cox-1-xscroll)*16*scale), (self.coy-yscroll-1.5-ymod)*16*scale, 0, scale, scale)
		end
	else
		if self.dir ~= "left" then
			love.graphics.draw(faithplateplateimg, faithplatequad[quad], math.floor((self.cox-1-xscroll)*16*scale), (self.coy-yscroll-1.5)*16*scale, 0, scale, scale)
		else
			love.graphics.draw(faithplateplateimg, faithplatequad[quad], math.floor((self.cox+1-xscroll)*16*scale), (self.coy-yscroll-1.5)*16*scale, 0, -scale, scale)
		end
	end
	
	love.graphics.setScissor()
end