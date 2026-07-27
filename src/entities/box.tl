--[[ Teal port of root box.lua ]]

rawset(_G, "box", rawget(_G, "box") or {})

function box.new(_: box, x: number, y: number): box
	local self = setmetatable({}, { __index = box }) as box
	self:init(x, y)
	return self
end

function box:init(x: number, y: number)
	--PHYSICS STUFF
	self.cox = x
	self.coy = y
	self.x = x-14/16
	self.y = y-12/16
	self.speedy = 0
	self.speedx = 0
	self.width = 12/16
	self.height = 12/16
	self.static = false
	self.active = true
	self.category = 9
	self.parent = nil
	self.portaloverride = true

	self.mask = {	true,
					false, false, false, false, false,
					false, true, false, true, true,
					false, false, true, false, false,
					true, true, false, false, true,
					false, true, true, false, false,
					true, false, true, true, true}
					
	self.emancipatecheck = true

	self.userect = adduserect(self.x, self.y, 12/16, 12/16, self)
	
	--IMAGE STUFF
	self.drawable = true
	self.graphic = boximg
	self.quad = boxquad[1]
	self.offsetX = 6
	self.offsetY = 2
	self.quadcenterX = 6
	self.quadcenterY = 6
	
	self.rotation = 0 --for portals
	self.gravitydirection = math.pi/2
	
	self.falling = false
	self.destroying = false
	self.outtable = {}
	self.portaledframe = false
	self.grabbable = true
	self.beamed = nil
	self.punttimer = 0
end

function box:update(dt: number): boolean
	local friction = boxfrictionair
	if self.falling == false then
		friction = boxfriction
	end
	
	--Funnels and fuck
	if self.funnel and not self.infunnel then
		self:enteredfunnel(true)
	end
	
	if self.infunnel and not self.funnel then
		self:enteredfunnel(false)
	end
	
	self.funnel = false
	
	if not self.pushed then
		if self.speedx > 0 then
			self.speedx = self.speedx - friction*dt
			if self.speedx < 0 then
				self.speedx = 0
			end
		else
			self.speedx = self.speedx + friction*dt
			if self.speedx > 0 then
				self.speedx = 0
			end
		end
	else
		self.pushed = false
	end
	
	self.rotation = 0

	if self.punttimer and (self.punttimer as number) > 0 then
		self.punttimer = (self.punttimer as number) - dt
	end

	-- gravity-gun beam: stay in physics loop with gravity=0 (spring runs in weapon update)
	if self.beamed and not self.parent then
		self.gravity = 0
		self.speedx = 0
		self.speedy = 0
	end
	
	if self.parent then
		local parent = self.parent as Entity
		local oldx = self.x
		local oldy = self.y
		
		self.x = parent.x+math.sin(-parent.pointingangle)*0.3
		self.y = parent.y-math.cos(-parent.pointingangle)*0.3
		
		if self.portaledframe == false then
			for h, u in pairs(emancipationgrills) do
				if u.active then
					if u.dir == "hor" then
						if inrange(self.x+6/16, u.startx-1, u.endx, true) and inrange(u.y-14/16, oldy, self.y, true) then
							self:emancipate(h)
						end
					else
						if inrange(self.y+6/16, u.starty-1, u.endy, true) and inrange(u.x-14/16, oldx, self.x, true) then
							self:emancipate(h)
						end
					end
				end
			end
		end
		
		self.rotation = parent.rotation
	end
	
	(self.userect as {string:any})["x"] = self.x
	(self.userect as {string:any})["y"] = self.y

	--check if offscreen
	if self.y > mapheight+2 then
		self:destroy()
	end
	
	self.portaledframe = false
	
	if self.destroying then
		return true
	else
		return false
	end
end

function box:globalcollide(a: any, _: Entity, _: any, _: any, dir: any): boolean
	if a == "platform" or a == "seesawplatform" then
		if dir == "floor" then
			if self.jumping and self.speedy < -jumpforce + 0.1 then
				return true
			end
		else
			return true
		end
	end
	return false
end

function box:ceilcollide(a: any, b: Entity, c: any, d: any): boolean
	if self:globalcollide(a, b, c, d, "ceil") then
		return false
	end
	return true
end

function box:leftcollide(a: any, b: Entity, c: any, d: any): boolean
	if self:globalcollide(a, b, c, d, "left") then
		return false
	end

	if a == "button" then
		self.y = b.y - self.height
		self.x = b.x + b.width - 0.01
		if self.speedy > 0 then
			self.speedy = 0
		end
		return false
	elseif a == "player" then
		self.pushed = true
		return false
	end
	return true
end

function box:rightcollide(a: any, b: Entity, c: any, d: any): boolean
	if self:globalcollide(a, b, c, d, "right") then
		return false
	end
	
	if a == "button" then
		self.y = b.y - self.height
		self.x = b.x - self.width+0.01
		if self.speedy > 0 then
			self.speedy = 0
		end
		return false
	elseif a == "player" then
		self.pushed = true
		return false
	end
	return true
end

function box:floorcollide(a: any, b: Entity, c: any, d: any): boolean
	if self:globalcollide(a, b, c, d, "floor") then
		return false
	end
	
	if self.falling then
		self.falling = false
	end
	
	if a == "enemy" and (b as Dyn).killedbyboxes then
		if b.stompable then
			b:stomp()
		else
			b:shotted("right", false, false, false)
		end
		addpoints(200, self.x, self.y)
		playsound("stomp")
		self.falling = true
		self.speedy = -10
		return false
	end
	-- punt kill window: any enemy hit while punttimer active
	if a == "enemy" and self.punttimer and (self.punttimer as number) > 0 then
		if b.stompable then
			b:stomp()
		elseif b.shotted then
			b:shotted("right", false, false, false)
		end
		addpoints(200, self.x, self.y)
		playsound("stomp")
		return false
	end
	return true
end

function box:passivecollide(a: any, b: Entity, c: any, d: any): boolean
	if self:globalcollide(a, b, c, d, "passive") then
		return false
	end
	
	if a == "player" then
		if self.x+self.width > b.x+b.width then
			self.x = b.x+b.width
		else
			self.x = b.x-self.width
		end
	end
	return true
end

function box:startfall()
	self.falling = true
end

function box:emancipate(_a: any): any
	if not self.destroying then
		local speedx, speedy = self.speedx, self.speedy
		if self.parent then
			local parent = self.parent as Entity
			parent:cubeemancipate()
			speedx = speedx + parent.speedx
			speedy = speedy + parent.speedy
		elseif self.beamed and Weapons then
			Weapons.release(self.beamed as {string:any}, "emancipate")
		end
		table.insert(emancipateanimations, emancipateanimation:new(self.x, self.y, self.width, self.height, self.graphic, self.quad, speedx, speedy, self.rotation, self.offsetX, self.offsetY, self.quadcenterX, self.quadcenterY))
		self:destroy()
	end
	return nil
end

function box:destroy()
	if self.beamed and Weapons then
		Weapons.release(self.beamed as {string:any}, "destroying")
	end
	(self.userect as {string:any}).delete = true
	self.destroying = true
	
	for i = 1, #self.outtable do
		local out = (self.outtable[i] as {Entity, any})[1] as Entity
		if out.input then
			(out.input as function(Entity, any, any))(out, "toggle", (self.outtable[i] as {Entity, any})[2])
		end
	end
end

function box:addoutput(a: any, t: any)
	table.insert(self.outtable, {a, t} as {any})
end

function box:used(id: any): any
	self.parent = playerobjs[id as integer] as Entity
	self.active = false
	playerobjs[id as integer]:pickupbox(self)
	return nil
end

function box:dropped()
	self.parent = nil
	self.active = true
end

function box:portaled()
	self.portaledframe = true
	-- release if object portals while gravity-gun held (player may keep cube through own portal)
	if self.beamed and Weapons then
		Weapons.release(self.beamed as {string:any}, "objportal")
	end
end

function box:enteredfunnel(inside: any)
	if inside then
		self.infunnel = true
	else
		self.infunnel = false
		self.gravity = 0
	end
end

function box:faithplate(_dir: any)
	self.falling = true
end

function box:onbutton(s: any): any
	if s then
		self.quad = boxquad[2]
	else
		self.quad = boxquad[1]
	end
	return nil
end
