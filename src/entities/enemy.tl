--[[ Enemy class (Teal port of root enemy.lua).  ]]

rawset(_G, "enemy", rawget(_G, "enemy") or {})

function enemy.new(_: enemy, x: number, y: number, t: string, a: any): enemy
	local self = setmetatable({}, { __index = enemy }) as enemy
	self:init(x, y, t, a)
	return self
end

function enemy:init(x: number, y: number, t: string, a: any)
	if not enemiesdata[t] then
		return
	end
	
	self.t = t as string
	if a then
		self.a = {unpack(a as {any})}
	else
		self.a = {}
	end
	
	--Some standard values..
	self.rotation = 0
	self.active = true
	self.static = false
	self.mask = {}
	self.gravitydirection = math.pi/2
	
	self.combo = 1
	
	self.falling = false
	
	self.shot = false
	self.outtable = {}
	
	self.speedx = 0
	self.speedy = 0
	
	--Get our enemy's properties from the property table
	do
		local bag = self as {string:any}
		for i, v in pairs(enemiesdata[self.t] as {string:any}) do
			bag[i as string] = v
		end
	end
	
	if self.customtimer then
		self.customtimertimer = 0
		self.currentcustomtimerstage = 1
	end
	
	--Decide on a random movement if it's random..
	if self.movementrandoms then
		self.movement = self.movementrandoms[math.random(#self.movementrandoms)] as string
	end
	
	self.x = x-.5-self.width/2+(self.spawnoffsetx or 0)
	self.y = y-self.height+(self.spawnoffsety or 0)
	
	if self.animationtype == "mirror" then
		self.animationtimer = 0
		self.animationdirection = "left"
	elseif self.animationtype == "frames" then
		self.quadi = self.animationstart
		self.quad = self.quadgroup[self.quadi as integer]
		self.animationtimer = 0
	end
	
	if self.stompanimation then
		self.deathtimer = 0
	end
	
	if self.shellanimal then
		self.upsidedown = false
		self.resettimer = 0
		self.wiggletimer = 0
		self.wiggleleft = true
	end
	
	if self.customscissor then
		local scissor = {unpack(self.customscissor as {any})}
		scissor[1] = (scissor[1] as number) + x - 1
		scissor[2] = (scissor[2] as number) + y - 1
		self.customscissor = scissor
	end
	
	if self.starttowardsplayerhorizontal then --Prize for best property name
		local closestplayer = 1
		self.animationdirection = "right"
		local closestdist = math.huge
		for i = 1, #(playerobjs as {any}) do
			local v = playerobjs[i]
			local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
			if dist < closestdist then
				closestdist = dist
				closestplayer = i
			end
		end
			
		if playerobjs[closestplayer] then
			if playerobjs[closestplayer].x < self.x then
				self.speedx = -math.abs(self.speedx)
				self.animationdirection = "right"
			else
				self.speedx = math.abs(self.speedx)
				self.animationdirection = "left"
			end
		end
	end
	
	self.spawnallow = true
	self.spawnedenemies = {}
	if self.movement == "piston" then
		self.pistontimer = self.pistonretracttime
		self.pistonstate = "retracting"
		
		if self.spawnonlyonextended then
			self.spawnallow = false
		end
	elseif self.movement == "flyvertical" or self.movement == "flyhorizontal" then
		self.flyingtimer = 0
		self.startx = self.x
		self.starty = self.y
	elseif self.movement == "squid" then
		self.squidstate = "idle"
	end
	
	if self.speedxtowardsplayer then
		local closestplayer = 1
		local closestdist = math.sqrt((playerobjs[1].x-self.x)^2+(playerobjs[1].y-self.y)^2)
		for i = 2, players do
			local v = playerobjs[i]
			local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
			if dist < closestdist then
				closestdist = dist
				closestplayer = i
			end
		end
		
		if playerobjs[closestplayer].x + playerobjs[closestplayer].width/2 > self.x + self.width/2 then
			self:leftcollide("", {}, "", {})
			self.speedx = math.abs(self.speedx)
		else
			self:rightcollide("", {}, "", {})
			self.speedx = -math.abs(self.speedx)
		end
	end
	
	if self.lifetime and self.lifetime > 0 then
		self.lifetimer = self.lifetime
	end
	
	if self.jumps then
		self.jumptimer = 0
	end
	
	self.firstmovement = self.movement as any
	self.firstanimationtype = self.animationtype

	-- Apparently we now have to deal with case sensitivity.
	-- This could definitely happen in more places, especially with custom enemies, so keep an eye out.
	self.offsetX = self.offsetX or self.offsetx
	self.offsetY = self.offsetY or self.offsety
	self.quadcenterX = self.quadcenterX or self.quadcenterx
	self.quadcenterY = self.quadcenterY or self.quadcentery
	
	self.startoffsetY = self.offsetY
	self.startquadcenterY = self.quadcenterY
	self.startoffsetY = self.offsetY
	self.startx = self.x
	self.starty = self.y
	self.startgravity = self.gravity
	
	if self.spawnsenemy then
		self.spawnenemytimer = 0
		self.spawnenemydelay = self.spawnenemydelays[math.random(#self.spawnenemydelays)]
	end
	
	self.throwanimationstate = 0
	
	if self.chasetime then
		self.chasetimer = 0
	end
	
	if self.spawnsound then
		playsound(self.spawnsound)
	end
	
	self.outtable = {}
end

function enemy:update(dt: number): any...
	--Funnels and fuck
	if self.funnel and not self.infunnel then
		self:enteredfunnel(true)
	end
	
	if self.infunnel and not self.funnel then
		self:enteredfunnel(false)
	end
	
	self.funnel = false
	if self.lifetimer then
		self.lifetimer = self.lifetimer - dt
		if self.lifetimer <= 0 then
			if self.transforms and self.transformtrigger == "lifetime" then
				self:transform(self.transformsinto)
			end
			self:output()
			self.dead = true
			
			return true
		end
	end
	
	if self.kill then
		self:output()
		self.dead = true
		
		return true
	end
	
	if self.stompanimation and self.dead then
		self.deathtimer = self.deathtimer + dt
		if self.deathtimer > 0.5 then
			self:output()
			
			return true
		else
			return false
		end
	end
	
	if not self.doesntunrotate then
		self.rotation = unrotate(self.rotation, self.gravitydirection, dt)
	end
	
	if self.shot then
		self.speedy = self.speedy + shotgravity*dt
		
		self.x = self.x+self.speedx*dt
		self.y = self.y+self.speedy*dt
		
		return false
	end
	
	if self.animationtype == "mirror" then
		self.animationtimer = self.animationtimer + dt
		while self.animationtimer > self.animationspeed do
			self.animationtimer = self.animationtimer - self.animationspeed
			if self.animationdirection == "left" then
				self.animationdirection = "right"
			else
				self.animationdirection = "left"
			end
		end
	elseif self.animationtype == "frames" then
		self.animationtimer = self.animationtimer + dt
		while self.animationtimer > self.animationspeed do
			self.animationtimer = self.animationtimer - self.animationspeed
			self.quadi = self.quadi + 1
			if self.quadi > self.animationstart + self.animationframes - 1 then
				self.quadi = self.quadi - self.animationframes
			end
			self.quad = self.quadgroup[self.quadi as integer]
		end
		
		if self.speedx > 0 then
			self.animationdirection = "left"
		else
			self.animationdirection = "right"
		end
	end
	
	if self.spawnsenemy then
		if lakitoend and self.movement == "follow" then
			self.speedx = -3
			return false
		end
		self.spawnenemytimer = self.spawnenemytimer + dt
		while self.spawnenemytimer >= self.spawnenemydelay and self.spawnallow and (not self.spawnmax or (self:getspawnedenemies() as number) < (self.spawnmax as number)) do
			if self.spawnsenemyrandoms then
				self.spawnsenemy = self.spawnsenemyrandoms[math.random(#self.spawnsenemyrandoms)]
			end
			self:spawnenemy(self.spawnsenemy)
			self.spawnenemytimer = 0
			self.spawnenemydelay = self.spawnenemydelays[math.random(#self.spawnenemydelays)]
			self.throwanimationstate = 0
			if self.animationtype == "frames" then
				self.quad = self.quadgroup[self.quadi + self.throwanimationstate]
			end
		end
		
		if self.throwpreparetime and self.spawnenemytimer >= (self.spawnenemydelay - self.throwpreparetime) then
			self.throwanimationstate = self.throwquadoffset
			if self.animationtype == "frames" then
				self.quad = self.quadgroup[self.quadi + self.throwanimationstate]
			end
		end
	end	
	
	if self.movement == "truffleshuffle" then
		if self.speedx > 0 then
			if self.speedx > self.truffleshufflespeed then
				self.speedx = self.speedx - self.truffleshuffleacceleration*dt*2
				if self.speedx < self.truffleshufflespeed then
					self.speedx = self.truffleshufflespeed
				end
			elseif self.speedx < self.truffleshufflespeed then
				self.speedx = self.speedx + self.truffleshuffleacceleration*dt*2
				if self.speedx > self.truffleshufflespeed then
					self.speedx = self.truffleshufflespeed
				end
			end
		else
			if self.speedx < -self.truffleshufflespeed then
				self.speedx = self.speedx + self.truffleshuffleacceleration*dt*2
				if self.speedx > -self.truffleshufflespeed then
					self.speedx = -self.truffleshufflespeed
				end
			elseif self.speedx > -self.truffleshufflespeed then
				self.speedx = self.speedx - self.truffleshuffleacceleration*dt*2
				if self.speedx < -self.truffleshufflespeed then
					self.speedx = -self.truffleshufflespeed
				end
			end
		end
		
		if self.turnaroundoncliff and self.falling == false then
			--check if nothing below
			local x = math.floor(self.x + self.width/2+1)
			local y = math.floor(self.y + self.height+1.5)
			if inmap(x, y) and tilequads[map[x][y][1]]:getproperty("collision", x, y) == false and ((inmap(x+.5, y) and tilequads[map[math.ceil(x+.5)][y][1]]:getproperty("collision", math.ceil(x+.5), y)) or (inmap(x-.5, y) and tilequads[map[math.floor(x-.5)][y][1]]:getproperty("collision", math.floor(x-.5), y))) then
				if self.speedx < 0 then
					self.x = x-self.width/2
				else
					self.x = x-1-self.width/2
				end
				self.speedx = -self.speedx
			end
		end
		
	elseif self.movement == "shell" then
		if self.small then
			if self.wakesup then
				if math.abs(self.speedx) < 0.0001 then
					self.resettimer = self.resettimer + dt
					if self.resettimer > self.resettime then
						self.offsetY = self.startoffsetY
						self.quadcenterY = self.startquadcenterY
						self.quad = self.quadgroup[self.animationstart]
						self.small = false
						self.speedx = -self.truffleshufflespeed
						self.resettimer = 0
						self.upsidedown = false
						self.kickedupsidedown = false
						self.movement = self.firstmovement
						self.animationtype = self.firstanimationtype
						
						if self.chasemarioonwakeup then
							local px = playerobjs[getclosestplayer(self.x)].x as number
							if px > self.x then
								self.speedx = -self.speedx
							end
						end
					elseif self.resettimer > self.resettime-self.wiggletime then
						self.wiggletimer = self.wiggletimer + dt
						while self.wiggletimer > self.wiggledelay do
							self.wiggletimer = self.wiggletimer - self.wiggledelay
							if self.wiggleleft then
								self.x = self.x + 1/16
							else
								self.x = self.x - 1/16
							end
							self.wiggleleft = not self.wiggleleft
						end
					end
				else
					self.resettimer = 0
				end
			end
		end
		
	elseif self.movement == "follow" then
		local nearestplayer = 1
		while playerobjs[nearestplayer] and playerobjs[nearestplayer].dead do
			nearestplayer = nearestplayer + 1
		end
		
		if playerobjs[nearestplayer] then
			local nearestplayerx = playerobjs[nearestplayer].x
			for i = 2, players do
				local v = playerobjs[i]
				if v.x > nearestplayerx and not v.dead then
					nearestplayer = i
				end
			end
			
			nearestplayerx = nearestplayerx + playerobjs[nearestplayer].speedx*self.distancetime
			
			local distance = math.abs(self.x - nearestplayerx)
			
			--check if too far in wrong direction
			if (not self.direction or self.direction == "left") and self.x < nearestplayerx-self.followspace then
				self.direction = "right"
				self.animationdirection = "right"
			elseif self.direction == "right" and self.x > nearestplayerx+self.followspace then
				self.direction = "left"
				self.animationdirection = "left"
			end
			
			if self.direction == "right" then
				if self.nofollowspeedup then
					self.speedx = self.followspeed or 2
				else
					self.speedx = math.max((self.followspeed or 2), round((distance-3)*2))
				end
			else
				self.speedx = -(self.followspeed or 2)
			end
		end
	elseif self.movement == "piston" then
		self.pistontimer = self.pistontimer + dt
		
		if self.pistonstate == "extending" then		
			--move X
			if self.x > self.startx + self.pistondistx then
				self.x = self.x - self.pistonspeedx*dt
				if self.x < self.startx + self.pistondistx then
					self.x = self.startx + self.pistondistx
				end
			elseif self.x < self.startx + self.pistondistx then
				self.x = self.x + self.pistonspeedx*dt
				if self.x > self.startx + self.pistondistx then
					self.x = self.startx + self.pistondistx
				end
			end
			
			--move Y
			if self.y > self.starty + self.pistondisty then
				self.y = self.y - self.pistonspeedy*dt
				if self.y < self.starty + self.pistondisty then
					self.y = self.starty + self.pistondisty
				end
			elseif self.y < self.starty + self.pistondisty then
				self.y = self.y + self.pistonspeedy*dt
				if self.y > self.starty + self.pistondisty then
					self.y = self.starty + self.pistondisty
				end
			end
			
			if self.x == self.startx + self.pistondistx and self.y == self.starty + self.pistondisty and not self.spawnallow then
				self.spawnallow = true
				self.spawnenemytimer = self.spawnenemydelay
			end
			
			if self.pistontimer > self.pistonextendtime then
				self.pistontimer = 0
				self.spawnallow = false
				self.pistonstate = "retracting"
			end
			
			
		else --retracting			
			--move X
			if self.x > self.startx then
				self.x = self.x - self.pistonspeedx*dt
				if self.x < self.startx then
					self.x = self.startx
				end
			elseif self.x < self.startx then
				self.x = self.x + self.pistonspeedx*dt
				if self.x > self.startx then
					self.x = self.startx
				end
			end
			
			--move Y
			if self.y > self.starty then
				self.y = self.y - self.pistonspeedy*dt
				if self.y < self.starty then
					self.y = self.starty
				end
			elseif self.y < self.starty then
				self.y = self.y + self.pistonspeedy*dt
				if self.y > self.starty then
					self.y = self.starty
				end
			end
			
			if self.inactiveonretracted and self.x == self.startx and self.y == self.starty then
				self.active = false
			end
			
			if self.pistontimer > self.pistonretracttime then
				local playernear = false
				for i = 1, players do
					local v = playerobjs[i]
					if inrange(v.x+v.width/2, self.x+self.width/2-(self.dontpistondist or 3), self.x+self.width/2+(self.dontpistondist or 3)) then
						playernear = true
					end
				end
				
				if not self.dontpistonnearplayer or not playernear then
					self.pistontimer = 0
					self.pistonstate = "extending"
					self.active = true
				end
			end
		end
	elseif self.movement == "wiggle" then
		if self.speedx < 0 then
			if self.x < self.startx-self.wiggledistance then
				self.speedx = self.wigglespeed or 1
			end
		elseif self.speedx > 0 then
			if self.x > self.startx then
				self.speedx = -self.wigglespeed or 1
			end
		else
			self.speedx = self.wigglespeed or 1
		end
		
	elseif self.movement == "verticalwiggle" then
		if self.speedy < 0 then
			if self.y < self.starty-self.verticalwiggledistance then
				self.speedy = self.verticalwigglespeed or 1
			end
		elseif self.speedy > 0 then
			if self.y > self.starty then
				self.speedy = -self.verticalwigglespeed or 1
			end
		else
			self.speedy = self.verticalwigglespeed or 1
		end
		
	elseif self.movement == "rocket" then
		if self.y > self.starty+(self.rocketdistance or 15) and self.speedy > 0 then
			self.y = self.starty+(self.rocketdistance or 15)
			
			self.speedy = -math.sqrt(2*(self.gravity or yacceleration)*(self.rocketdistance or 15))
		end
		
		if self.speedy < 0 then
			self.upsidedown = false
		else
			self.upsidedown = true
		end
		
	elseif self.movement == "squid" then
		local closestplayer = 1
		local closestdist = math.sqrt((playerobjs[1].x-self.x)^2+(playerobjs[1].y-self.y)^2)
		for i = 2, players do
			local v = playerobjs[i]
			local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
			if dist < closestdist then
				closestdist = dist
				closestplayer = i
			end
		end
		
		if self.squidstate == "idle" then
			self.speedy = self.squidfallspeed
			
			--get if change state to upward
			if (self.y+self.speedy*dt) + self.height + 0.0625 >= (playerobjs[closestplayer].y - (24/16 - playerobjs[closestplayer].height)) then
				self.squidstate = "upward"
				self.upx = self.x
				self.speedx = 0
				self.speedy = 0
				
				if self.animationtype == "squid" then
					self.quad = self.quadgroup[2]
				end
				
				--get if to change direction
				if true then--math.random(2) == 1 then
					if self.direction == "right" then
						if self.x > playerobjs[closestplayer].x then
							self.direction = "left"
						end
					else
						if self.x < playerobjs[closestplayer].x then
							self.direction = "right"
						end
					end
				end
			end
			
		elseif self.squidstate == "upward" then
			if self.direction == "right" then
				self.speedx = self.speedx + self.squidacceleration*dt
				if self.speedx > self.squidxspeed then
					self.speedx = self.squidxspeed
				end
			else
				self.speedx = self.speedx - self.squidacceleration*dt
				if self.speedx < -self.squidxspeed then
					self.speedx = -self.squidxspeed
				end
			end
			
			self.speedy = self.speedy - self.squidacceleration*dt
			
			if self.speedy < -self.squidupspeed then
				self.speedy = -self.squidupspeed
			end
			
			if math.abs(self.x - self.upx) >= (self.squidhordistance or 2) then
				self.squidstate = "downward"
				self.downy = self.y
				self.speedx = 0
			end
			
		elseif self.squidstate == "downward" then
			self.speedy = self.squidfallspeed
			if self.y > self.downy + self.squiddowndistance then
				self.squidstate = "idle"
			end
			
			if self.animationtype == "squid" then
				self.quad = self.quadgroup[1]
			end
		end
		
	elseif self.movement == "targety" then
		if self.y > self.targety then
			self.y = self.y - self.targetyspeed*dt
			if self.y < self.targety then
				self.y = self.targety
			end
		elseif self.y < self.targety then
			self.y = self.y + self.targetyspeed*dt
			if self.y > self.targety then
				self.y = self.targety
			end
		end
	elseif self.movement == "flyvertical" then
		self.flyingtimer = self.flyingtimer + dt
		
		while self.flyingtimer > (self.flyingtime or 7) do
			self.flyingtimer = self.flyingtimer - (self.flyingtime or 7)
		end
		
		local newy = (self:func(self.flyingtimer/(self.flyingtime or 7)) as number)*(self.flyingdistance or 7.5) + (self.starty as number)
		self.y = newy
	elseif self.movement == "flyhorizontal" then
		self.flyingtimer = self.flyingtimer + dt
		
		while self.flyingtimer > (self.flyingtime or 7) do
			self.flyingtimer = self.flyingtimer - (self.flyingtime or 7)
		end
		
		local newx = (self:func(self.flyingtimer/(self.flyingtime or 7)) as number)*(self.flyingdistance or 7.5) + (self.startx as number)
		self.x = newx
	end
	
	if self.jumps then
		self.jumptimer = self.jumptimer + dt
		if self.jumptimer > self.jumptime then
			self.jumptimer = self.jumptimer - self.jumptime
			--decide whether up or down
			local dir: string
			if self.y > 12 then
				dir = "up"
			elseif self.y < 6 then
				dir = "down"
			else
				if math.random(2) == 1 then
					dir = "up"
				else
					dir = "down"
				end
			end
			
			if dir == "up" then
				self.speedy = -self.jumpforce
				self.mask[2] = true
				self.jumping = "up"
			else
				self.speedy = -self.jumpforcedown
				self.mask[2] = true
				self.jumping = "down"
				self.jumpingy = self.y
			end
		end
		
		if self.jumping then
			if self.jumping == "up" then
				if self.speedy > 0 then
					self.jumping = false
					self.mask[2] = false
				end
			elseif self.jumping == "down" then
				if self.y > self.jumpingy + self.height+1.1 then
					self.jumping = false
					self.mask[2] = false
				end
			end
		end
	end
	
	if self.facesplayer then
		local closestplayer = 1
		local closestdist = math.sqrt((playerobjs[1].x-self.x)^2+(playerobjs[1].y-self.y)^2)
		for i = 2, players do
			local v = playerobjs[i]
			local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
			if dist < closestdist then
				closestdist = dist
				closestplayer = i
			end
		end
		
		if playerobjs[closestplayer].x + playerobjs[closestplayer].width/2 > self.x + self.width/2 then
			self.animationdirection = "left"
		else
			self.animationdirection = "right"
		end
	end
	
	if self.chasetime then
		if self.chasetimer > self.chasetime then
			local closestplayer = 1
			local closestdist = math.sqrt((playerobjs[1].x-self.x)^2+(playerobjs[1].y-self.y)^2)
			for i = 2, players do
				local v = playerobjs[i]
				local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
				if dist < closestdist then
					closestdist = dist
					closestplayer = i
				end
			end
			
			if playerobjs[closestplayer].x + playerobjs[closestplayer].width/2 < self.x + self.width/2 then
				self.speedx = -(self.chasespeed or 1.5)
			else
				self.chasetimer = 0
				self.startx = self.x
			end
		else
			self.chasetimer = self.chasetimer + dt
		end
	end
	
	--Check if player is near
	if self.transforms and (self.transformtrigger == "playernear" or self.transformtrigger == "playernotnear") then
		if type(self.playerneardist) == "number" then
			for i = 1, players do
				local v = playerobjs[i]
				if inrange(v.x+v.width/2, self.x+self.width/2-((self.playerneardist or 3) as number), self.x+self.width/2+((self.playerneardist or 3) as number)) then
					if self.transformtrigger == "playernear" then
						self:transform(self.transformsinto)
						return
					end
				elseif self.transformtrigger == "playernotnear" then
					self:transform(self.transformsinto)
					
				end
			end
		elseif type(self.playerneardist) == "table" and #(self.playerneardist as {number}) == 4 then
			local pnd = self.playerneardist as {number}
			local col = checkrect(self.x+pnd[1], self.y+pnd[2], self.x+pnd[1]+pnd[3], self.y+pnd[2]+pnd[4], {"player"})
			if #col > 0 then
				if self.transformtrigger == "playernear" then
					self:transform(self.transformsinto)
					return
				end
			elseif self.transformtrigger == "playernotnear" then
				self:transform(self.transformsinto)
				return
			end
		end
	end
	
	--Check if player if facing the enemy
	if self.staticifseen or self.staticifnotseen or (self.transforms and (self.transformtrigger == "seen" or self.transformtrigger == "notseen"))then
		local lookedat = false
		for i = 1, players do
			local v = playerobjs[i]
			if v.x+(self.width/2) > self.x+(self.width/2) then
				if v.portalsavailable[1] or v.portalsavailable[2] then
					if v.pointingangle > 0 then
						lookedat = true
					end
				else
					if v.animationdirection == "left" then
						lookedat = true
					end
				end
			else
				if v.portalsavailable[1] or v.portalsavailable[2] then
					if v.pointingangle < 0 then
						lookedat = true
					end
				else
					if v.animationdirection == "right" then
						lookedat = true
					end
				end
			end
		end
		if (self.transforms and self.transformtrigger == "notseen") or self.staticifnotseen then
			lookedat = not lookedat
		end
		if lookedat then
			if self.staticifseen or self.staticifnotseen then
				self.static = true
			else
				self:transform(self.transformsinto)
				return
			end
		else
			if self.staticifseen or self.staticifnotseen then
				self.static = false
			end
		end
	end
	
	if self.rotatetowardsplayer then
		for i = 1, players do
			local v = playerobjs[i]
			if not v.dead then
				self.rotation = (-math.atan2((v.x+v.width/2)-(self.x+self.width/2), (v.y+v.height/2)-(self.y+self.height/2-3/16)))-math.pi/2
			end
		end
	end
	
	if self.customtimer then
		self.customtimertimer = self.customtimertimer + dt
		while self.customtimertimer > (((self.customtimer as {any})[self.currentcustomtimerstage as integer] as {any})[1] as number) do
			local ct = self.customtimer as {{any}}
			local stage = ct[self.currentcustomtimerstage as integer]
			self.customtimertimer = self.customtimertimer - stage[1] as number
			if stage[2] and stage[3] then
				self:customtimeraction(stage[2], stage[3])
			elseif stage[2] then
				self:customtimeraction(stage[2])
			end
			self.currentcustomtimerstage = self.currentcustomtimerstage + 1
			if self.currentcustomtimerstage > #ct then
				self.currentcustomtimerstage = 1
			end
		end
	end
end

function enemy:addoutput(a: any, t: any): any
	table.insert(self.outtable, {a, t} as {any})
end

function enemy:shotted(dir: any, below: any, high: any, fireball: any, star: any): any
	if fireball and self.resistsfire then
		return false
	end
	
	if star and self.resistsstar then
		return false
	end
	
	if self.shothealth then
		if self.shothealth > 1 then
			self.shothealth = self.shothealth - 1
			return
		end
	elseif self.health and not self.shothealth then
		if self.health > 1 then
			self.health = self.health - 1
			return
		end
	end
	
	if self.givecoinwhenshot then
		collectcoin(nil, nil, 1)
	end
	
	playsound("shot")
	
	if self.transforms and (self.transformtrigger == "shot" or self.transformtrigger == "death") then
		self:transform(self.transformsinto)
		return
	end
	
	self.speedy = -(self.shotjumpforce or shotjumpforce)
	if high then
		self.speedy = self.speedy*2
	end
	self.direction = (dir or "right") as string
	self.gravity = shotgravity
	
	if self.direction == "left" then
		self.speedx = -(self.shotspeedx or shotspeedx)
	else
		self.speedx = self.shotspeedx or shotspeedx
	end
	
	if self.shellanimal then
		self.small = true
		self.quad = self.quadgroup[self.smallquad]
		if below then
			self.upsidedown = true
			self.kickedupsidedown = true
			self.offsetY = 4
			self.movement = self.smallmovement as string
			self.animationtype = "none"
		else
			self.shot = true
			self.active = false
		end
	else
		self.shot = true
		self.active = false
	end
	
	if self.doesntflyawayonfireball then
		self.kill = true
		self.drawable = false
	end
	
	return true
end

function enemy:decodearg(arg: any): any
	if type(arg) == "table" then
		local a = arg as {any}
		if not (a[1] and a[2]) then return end
		
		if a[1] == "global" then
			return (_G as {string:any})[a[2] as string] or false
		elseif a[1] == "self" then
			return (self as {string:any})[a[2] as string]
		elseif a[1] == "concat" then
			if not a[3] then return end
			return (tostring(self:decodearg(a[2])) .. tostring(self:decodearg(a[3])))
		end
	else
		return arg
	end
end

function enemy:customtimeraction(action: any, arg: any): any
	local bag = self as {string:any}
	if type(action) == "table" then --compound action
		local act = action as {any}
		local args = (arg as {any}) or {}
	
		realaction = act[1] or false -- any
		act[2] = self:decodearg(act[2]) --decode argument
		act[3] = self:decodearg(act[3])
		
		if string.sub(realaction as string, -4, -1) == "than" then
			if not (act[2] and act[3]) then return end
			if globintCH(act[2],  string.sub(realaction as string, 1, -5), act[3]) then --coding practice, using string.sub the same way Maurice did
				local a1 = args[1] as {any}
				local a2 = args[2] as {any}
				self:customtimeraction(a1[1], a1[2])
			else
				local a1 = args[1] as {any}
				local a2 = args[2] as {any}
				self:customtimeraction(a2[1], a2[2])
			end
		elseif realaction == "istrue" then
			print(globools[act[2] as string])
			if globools[act[2] as string] then
				local a1 = args[1] as {any}
				local a2 = args[2] as {any}
				self:customtimeraction(a1[1], a1[2])
			else
				local a1 = args[1] as {any}
				local a2 = args[2] as {any}
				self:customtimeraction(a2[1], a2[2])
			end
		elseif realaction == "simultaneous" then
			table.remove(act, 1)
			for i, v in ipairs(act as {any}) do
				local vv = v as {any}
				self:customtimeraction(vv[1], vv[2])
			end
		end
	else
		arg = self:decodearg(arg) --decode argument
		
		if action == "bounce" then
			if self.speedy == 0 then
				self.speedy = -((arg or 10) as number)
			end
		elseif action == "playsound" then
			playsound(arg)
		elseif string.sub(action as string, 0, 7) == "reverse" then
			local parameter = string.sub(action as string, 8, string.len(action as string))
			if not bag[parameter as string] then return end
			if type(bag[parameter as string]) ~= "number" then return end
			bag[parameter as string] = -(bag[parameter as string] as number)
		elseif string.sub(action as string, 0, 3) == "add" then
			local parameter = string.sub(action as string, 4, string.len(action as string))
			if not bag[parameter as string] or not arg or tonumber(arg) == nil then return end
			if type(bag[parameter as string]) ~= "number" then return end
			bag[parameter as string] = (bag[parameter as string] as number) + (arg as number)
		elseif string.sub(action as string, 0, 8) == "multiply" then
			local parameter = string.sub(action as string, 9, string.len(action as string))
			if not bag[parameter as string] or not arg or tonumber(arg) == nil then return end
			if type(bag[parameter as string]) ~= "number" then return end
			bag[parameter as string] = (bag[parameter as string] as number) * (arg as number)
		elseif action == "setframe" then
			self.quad = self.quadgroup[arg]
		elseif string.sub(action as string, 0, 3) == "set" then
			if not arg then --if arg is nil set it to false
				bag[string.sub(action as string, 4, string.len(action as string))] = false
			else
				bag[string.sub(action as string, 4, string.len(action as string))] = arg
			end
		elseif action == "print" then
			print(arg)
		end
	end
end

function enemy:func(i: any): number -- 0-1 in please
	return (-math.cos((i as number)*math.pi*2)+1)/2
end

function enemy:globalcollide(a: any, b: Entity, c: any, d: any, dir: any): any
	if a == "tile" then
		if not self.resistsspikes then
			dir = twistdirection(self.gravitydirection, dir)
			if dir == "ceil" and tilequads[map[b.cox][b.coy][1]]:getproperty("spikesbottom", b.cox, b.coy) then
				self:shotted()
				return false
			elseif dir == "right" and tilequads[map[b.cox][b.coy][1]]:getproperty("spikesleft", b.cox, b.coy) then
				self:shotted()
				return false
			elseif dir == "left" and tilequads[map[b.cox][b.coy][1]]:getproperty("spikesright", b.cox, b.coy) then
				self:shotted()
				return false
			elseif dir == "floor" and tilequads[map[b.cox][b.coy][1]]:getproperty("spikestop", b.cox, b.coy) then
				self:shotted()
				return false
			end
		end
	end

	if a == "platform" or a == "seesawplatform" then
		if dir == "floor" then
			if self.jumping and self.speedy < -jumpforce + 0.1 then
				return true
			end
		else
			return true
		end
	end
	
	if a == "player" and self.removeonmariocontact then
		self.kill = true
		self.drawable = false
		return true
	end

	if a == "player" then
		return true
	end
	
	if self.killsenemies and a == "enemy" then
		-- Kicked shells must actively kill other enemies (previously returned without doing so,
		-- which let shells phase through when the other side's collide was skipped).
		if b and b.active and not b.shot and not b.dead and b.shotted then
			local dir = "right"
			if self.speedx < 0 then
				dir = "left"
			end
			b:shotted(dir)
			addpoints((firepoints[b.t] or 200), b.x, b.y)
		end
		return true
	end
	
	if a == "fireball" and self.resistsfire then
		return true
	end
	
	if b.killsenemies then
		if self.shot or self.dead then
			return true
		end
		local dir = "right"
		if b.speedx < 0 then
			dir = "left"
		end
		self:shotted(dir)
		
		addpoints((firepoints[self.t] or 200), self.x, self.y)
		return true
	end
	
	if self.transforms and (self.transformtrigger == "globalcollide" or self.transformtrigger == "collide") then
		if self.transformtriggerenemycollide then
			if a == "enemy" and b.t == self.transformtriggerenemycollide then
				self:transform(self.transformsinto)
			end
		elseif self.transformtriggerobjectcollide then
			if a == self.transformtriggerenemycollide then
				self:transform(self.transformsinto)
			end
		else
			self:transform(self.transformsinto)
		end
		return true
	end
	
	if self.breaksblocks then
		if self.breakblockside == "global" and a == "tile" then
			hitblock(b.cox, b.coy, self, true)
		end
	end
	
	if self.nocollidestops or b.nocollidestops then
		return true
	end
end

function enemy:leftcollide(a: any, b: Entity, c: any, d: any): any
	if self:globalcollide(a, b, c, d, "left") then
		return false
	end
	
	if a == "tile" then
		if tilequads[map[b.cox][b.coy][1]]:getproperty("platform", b.cox, b.coy) then
			return false
		end
	end
	
	if self.transforms and self.transformtrigger == "leftcollide" then
		if self.transformtriggerenemycollide then
			if a == "enemy" and b.t == self.transformtriggerenemycollide then
				self:transform(self.transformsinto)
			end
		elseif self.transformtriggerobjectcollide then
			if a == self.transformtriggerenemycollide then
				self:transform(self.transformsinto)
			end
		else
			self:transform(self.transformsinto)
		end
		return
	end
	
	if self.reflects then
		self.speedx = -self.speedx
	end
	
	if self.breaksblocks then
		if (self.breakblockside == "sides" or self.breakblockside == "left") and a == "tile" then
			hitblock(b.cox, b.coy, self, true)
		end
	end
	
	if self.movement == "truffleshuffle" then
		self.speedx = self.truffleshufflespeed
		if not self.dontmirror then
			self.animationdirection = "left"
		end
		return false
	elseif self.small then
		if a ~= "enemy" then
			self.speedx = self.smallspeed
			
			if a == "tile" then
				hitblock(b.cox, b.coy, self, true)
			elseif self:onscreen() then
				playsound("blockhit")
			end
			return false
		end
	end
end

function enemy:rightcollide(a: any, b: Entity, c: any, d: any): any
	if self:globalcollide(a, b, c, d, "right") then
		return false
	end
	
	if a == "tile" then
		if tilequads[map[b.cox][b.coy][1]]:getproperty("platform", b.cox, b.coy) then
			return false
		end
	end
	
	if self.transforms and self.transformtrigger == "rightcollide" then
		if self.transformtriggerenemycollide then
			if a == "enemy" and b.t == self.transformtriggerenemycollide then
				self:transform(self.transformsinto)
			end
		elseif self.transformtriggerobjectcollide then
			if a == self.transformtriggerenemycollide then
				self:transform(self.transformsinto)
			end
		else
			self:transform(self.transformsinto)
		end
		return
	end
	
	if self.reflects then
		self.speedx = -self.speedx
	end
	
	if self.breaksblocks then
		if (self.breakblockside == "sides" or self.breakblockside == "right") and a == "tile" then
			hitblock(b.cox, b.coy, self, true)
		end
	end
	
	if self.movement == "truffleshuffle" then
		self.speedx = -self.truffleshufflespeed
		if not self.dontmirror then
			self.animationdirection = "right"
		end
		return false
	elseif self.small then
		if a ~= "enemy" then
			self.speedx = -self.smallspeed
			
			if a == "tile" then
				hitblock(b.cox, b.coy, self, true)
			elseif self:onscreen() then
				playsound("blockhit")
			end
			return false
		end
	end
end

function enemy:ceilcollide(a: any, b: Entity, c: any, d: any): any
	if self:globalcollide(a, b, c, d, "ceil") then
		return false
	end
	
	if a == "tile" then
		if tilequads[map[b.cox][b.coy][1]]:getproperty("platform", b.cox, b.coy) then
			return false
		end
	end
	
	if self.transforms and self.transformtrigger == "ceilcollide" then
		if self.transformtriggerenemycollide then
			if a == "enemy" and b.t == self.transformtriggerenemycollide then
				self:transform(self.transformsinto)
			end
		elseif self.transformtriggerobjectcollide then
			if a == self.transformtriggerenemycollide then
				self:transform(self.transformsinto)
			end
		else
			self:transform(self.transformsinto)
		end
		return
	end
	
	if self.reflects then
		self.speedy = -self.speedy
	end
	
	if self.breaksblocks then
		if self.breakblockside == "ceil" and a == "tile" then
			hitblock(b.cox, b.coy, self, true)
		end
	end
end

function enemy:floorcollide(a: any, b: Entity, c: any, d: any): any
	if self:globalcollide(a, b, c, d, "floor") then
		return false
	end
	
	if self.transforms and self.transformtrigger == "floorcollide" then
		if self.transformtriggerenemycollide then
			if a == "enemy" and b.t == self.transformtriggerenemycollide then
				self:transform(self.transformsinto)
			end
		elseif self.transformtriggerobjectcollide then
			if a == self.transformtriggerenemycollide then
				self:transform(self.transformsinto)
			end
		else
			self:transform(self.transformsinto)
		end
		return
	end
	
	if self.reflects then
		self.speedy = -self.speedy
	end
	
	if self.bounces then
		self.speedy = -(self.bounceforce or 10)
	end
	
	if self.kickedupsidedown then
		self.speedx = 0
		self.kickedupsidedown = false
	end
	
	self.falling = false
end

function enemy:passivecollide(a: any, b: Entity, c: any, d: any): any
	if self:globalcollide(a, b, c, d, "passive") then
		return false
	end
	
	if a == "tile" then
		if tilequads[map[b.cox][b.coy][1]]:getproperty("platform", b.cox, b.coy) then
			return false
		end
	end
end

function enemy:startfall(): any
	self.falling = true
end

function enemy:stomp(x: any, b: Entity): any
	if self.stompable then
		if self.stomphealth then
			if self.stomphealth > 1 then
				self.stomphealth = self.stomphealth - 1
				return
			end
		elseif self.health and not self.stomphealth then
			if self.health > 1 then
				self.health = self.health - 1
				return
			end
		end
	
		if self.transforms and (self.transformtrigger == "stomp" or self.transformtrigger == "death") then
			self:transform(self.transformsinto)
			return
		end
		
		if self.givecoinwhenstomped then
			collectcoin(nil, nil, 1)
		end
		
		if self.shellanimal then
			if not self.small then
				self.quadcenterY = 19
				self.offsetY = 0
				self.quad = self.quadgroup[self.smallquad]
				self.small = true
				self.movement = self.smallmovement as string
				self.speedx = 0
				self.animationtype = "none"
			elseif self.speedx == 0 then
				if self.x > (x as number) then
					self.speedx = self.smallspeed
					self.x = (x as number)+12/16+self.smallspeed*gdt
					if b then
						self.size = b.size
					else
						self.size = 1
					end
					self.killsenemies = true
				else
					self.speedx = -self.smallspeed
					self.x = (x as number)-self.width-self.smallspeed*gdt
					if b then
						self.size = b.size
					else
						self.size = 1
					end
					self.killsenemies = true
				end
			else
				self.speedx = 0
				self.combo = 1
				self.killsenemies = false
			end
		else
			self.active = false
			if self.stompanimation then
				self.quad = self.quadgroup[self.stompedframe]
				if self.fallswhenstomped then
					self.shot = true
					self.gravity = shotgravity
				else
					self.dead = true
				end
			else
				self.shot = true
				self.gravity = shotgravity
			end
		end
	end
end

function enemy:autodeleted(): any
	self.dead = true
	self:output()
end

function enemy:output(): any
	for i = 1, #self.outtable do
		local ot = self.outtable[i as integer] as {any}
		if (ot[1] as Entity).input then
			(ot[1] as Entity):input("toggle", ot[2])
		end
	end
end

function enemy:addoutput(a: any, t: any): any
	table.insert(self.outtable, {a, t} as {any})
end

function enemy:portaled(): any
	if self.killsenemiesafterportal then
		self.killsenemies = true
	end
end

function enemy:spawnenemy(t: any): any
	local speedx: number = 0
	local speedy: number = 0
	if self.spawnenemyspeedx then
		speedx = self.spawnenemyspeedx
	end
	if self.spawnenemyspeedy then
		speedy = self.spawnenemyspeedy
	end
	
	if (self.spawnenemyspeedxrandomstart and self.spawnenemyspeedxrandomend) then
		speedx = math.random()*(self.spawnenemyspeedxrandomend-self.spawnenemyspeedxrandomstart) + self.spawnenemyspeedxrandomstart
	end
	
	if (self.spawnenemyspeedyrandomstart and self.spawnenemyspeedyrandomend) then
		speedy = math.random()*(self.spawnenemyspeedyrandomend-self.spawnenemyspeedyrandomstart) + self.spawnenemyspeedyrandomstart
	end
	
	local closestplayer = 1
	local closestdist = math.sqrt((playerobjs[1].x-self.x)^2+(playerobjs[1].y-self.y)^2)
	for i = 2, players do
		local v = playerobjs[i]
		local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
		if dist < closestdist then
			closestdist = dist
			closestplayer = i
		end
	end

	if self.spawnenemytowardsplayer then
		
		local a = -math.atan2(playerobjs[closestplayer].x-self.x, playerobjs[closestplayer].y-self.y)+math.pi/2
		
		speedx = math.cos(a)*self.spawnenemyspeed
		speedy = math.sin(a)*self.spawnenemyspeed
	end
	
	if self.spawnenemyspeedxtowardsplayer then
		if playerobjs[closestplayer].x + playerobjs[closestplayer].width/2 > self.x + self.width/2 then
			speedx = math.abs(speedx)
		else
			speedx = -math.abs(speedx)
		end
	end
	
	local xoffset = self.spawnenemyoffsetx or 0
	local yoffset = self.spawnenemyoffsety or 0
	
	local temp = enemy:new(self.x+self.width/2+.5+xoffset, self.y+self.height+yoffset, t as string, {})
	table.insert(objects["enemy"], temp)
	
	temp.speedx = speedx
	temp.speedy = speedy
	
	if temp.movement == "truffleshuffle" and temp.speedx > 0 then
		temp.animationdirection = "left"
	end
	
	table.insert(self.spawnedenemies, temp)
	temp.spawner = self
end

function enemy:transform(t: any): any

	if self.transfoutid and self.transfoutaction then
		if self.transfoutvalue then
			globintSH(self.transfoutid, self.transfoutaction, self.transfoutvalue)
		else
			globoolSH(self.transfoutid, self.transfoutaction)
		end
	end

	if not self.dontactuallytransform then
		local xoffset = self.transformsoffsetx or 0
		local yoffset = self.transformsoffsety or 0
		if self.transformsintorandoms then
			self.transformsinto = (self.transformsintorandoms as {any})[math.random(#(self.transformsintorandoms as {any}))] as string
			t = self.transformsinto
		end

		local temp = enemy:new(self.x+self.width/2+.5+xoffset, self.y+self.height+yoffset, t as string, {})

		if self.transformpassedparameters then
			local bag = self as {string:any}
			local tbag = temp as {string:any}
			for i = 1, #(self.transformpassedparameters as {any}) do
				if (self.transformpassedparameters as {any})[i] ~= nil then
					tbag[(self.transformpassedparameters as {any})[i] as string] = bag[(self.transformpassedparameters as {any})[i] as string]
				end
			end
		end

		table.insert(objects["enemy"], temp)

		if self.spawner then
			table.insert((self.spawner as enemy).spawnedenemies, temp)
		end

		self.kill = true
		self.active = false
		self.drawable = false
	end
end

function enemy:emancipate(): any
	if not self.kill then
		table.insert(emancipateanimations, emancipateanimation:new(self.x, self.y, self.width, self.height, self.graphic, self.quad, self.speedx, self.speedy, self.rotation, self.offsetX, self.offsetY, self.quadcenterX, self.quadcenterY))
		self.kill = true
		self.drawable = false
	end
end

function enemy:laser(guns: any, pewpew: any): any
	if not self.laserresistant then
		self:shotted()
	end
end

function enemy:enteredfunnel(inside: any): any
	if inside then
		self.infunnel = true
	else
		self.infunnel = false
		self.gravity = self.startgravity
	end
end

function enemy:getspawnedenemies(): any
	local count = 0
	for i, v in pairs(self.spawnedenemies as {any:enemy}) do
		if not v.dead then
			count = count + 1
		end
	end
	
	return count
end

function enemy:onscreen(): any
	return enemy_onscreen(self.x, self.y, self.width, self.height)
end

return enemy
