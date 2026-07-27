--[[ Enemy movement dispatch table. Existing CE moves + endless AI. ]]

global ENEMY_MOVES: {string:function(enemy, number)} = {}

local function closest_player(self: enemy): mario|nil
	if not playerobjs or players < 1 then
		return nil
	end
	local best: mario|nil = nil
	local bestd = math.huge
	for i = 1, players do
		local pl = playerobjs[i] as mario
		if pl and not pl.dead then
			local dx = (pl.x + pl.width / 2) - (self.x + self.width / 2)
			local dy = (pl.y + pl.height / 2) - (self.y + self.height / 2)
			local d = dx * dx + dy * dy
			if d < bestd then
				bestd = d
				best = pl
			end
		end
	end
	return best
end

local function traceline_blocked(x1: number, y1: number, x2: number, y2: number): boolean
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	if len < 0.05 then
		return false
	end
	local steps = math.max(1, math.floor(len * 4))
	local ux, uy = dx / steps, dy / steps
	for i = 1, steps do
		local x = x1 + ux * i
		local y = y1 + uy * i
		local cox = math.floor(x) + 1
		local coy = math.floor(y) + 1
		if inmap and inmap(cox, coy) and map and map[cox] and map[cox][coy] and tilequads then
			local tid = map[cox][coy][1] as number
			local tq = tilequads[tid]
			if tq and tq.getproperty and tq:getproperty("collision", cox, coy) then
				return true
			end
		end
	end
	-- light bridges block beams/arrows
	if objects and objects["lightbridgebody"] then
		local col = checkrect and checkrect(math.min(x1, x2), math.min(y1, y2), math.abs(x2 - x1) + 0.1, math.abs(y2 - y1) + 0.1, {"lightbridgebody"}, true)
		if col and #col >= 2 then
			return true
		end
	end
	return false
end

local function spawn_bullet(x: number, y: number, vx: number, vy: number, owner: enemy)
	if not fireball or not fireball.new or not objects or not objects["fireball"] then
		return
	end
	local dir = vx >= 0 and "right" or "left"
	local f = (fireball.new as function(any, number, number, any, any): {string:any})(fireball, x, y, dir, owner)
	f.x = x
	f.y = y
	f.speedx = vx
	f.speedy = vy
	f.gravity = 0
	table.insert(objects["fireball"] as {any}, f)
end

local function playsfx(name: string)
	if playsound then
		-- stub missing names onto existing cues
		local map: {string:string} = {
			turretfall = "blockhit",
			turretalert = "oneup",
			bonescollapse = "stomp",
			thwomp = "blockhit",
			chargesnort = "shot",
			arrowfire = "fireball",
			latchgrab = "stomp",
		}
		playsound(map[name] or name)
	end
end


ENEMY_MOVES["truffleshuffle"] = function(self: enemy, dt: number)
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
end

ENEMY_MOVES["shell"] = function(self: enemy, dt: number)
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
end

ENEMY_MOVES["follow"] = function(self: enemy, _dt: number)
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
		
			nearestplayerx = nearestplayerx + playerobjs[nearestplayer].speedx*(self.distancetime or 0)
		
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
end

ENEMY_MOVES["piston"] = function(self: enemy, dt: number)
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
end

ENEMY_MOVES["wiggle"] = function(self: enemy, _dt: number)
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
end

ENEMY_MOVES["verticalwiggle"] = function(self: enemy, _dt: number)
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
end

ENEMY_MOVES["rocket"] = function(self: enemy, _dt: number)
		if self.y > self.starty+(self.rocketdistance or 15) and self.speedy > 0 then
			self.y = self.starty+(self.rocketdistance or 15)
		
			self.speedy = -math.sqrt(2*(self.gravity or yacceleration)*(self.rocketdistance or 15))
		end
	
		if self.speedy < 0 then
			self.upsidedown = false
		else
			self.upsidedown = true
		end
end

ENEMY_MOVES["squid"] = function(self: enemy, dt: number)
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
end

ENEMY_MOVES["targety"] = function(self: enemy, dt: number)
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
end

ENEMY_MOVES["flyvertical"] = function(self: enemy, dt: number)
		self.flyingtimer = self.flyingtimer + dt
	
		while self.flyingtimer > (self.flyingtime or 7) do
			self.flyingtimer = self.flyingtimer - (self.flyingtime or 7)
		end
	
		local newy = ((self.func as function({string:any}, number): number)(self, self.flyingtimer/(self.flyingtime or 7)) as number)*(self.flyingdistance or 7.5) + (self.starty as number)
		self.y = newy
end

ENEMY_MOVES["flyhorizontal"] = function(self: enemy, dt: number)
		self.flyingtimer = self.flyingtimer + dt
	
		while self.flyingtimer > (self.flyingtime or 7) do
			self.flyingtimer = self.flyingtimer - (self.flyingtime or 7)
		end
	
		local newx = ((self.func as function({string:any}, number): number)(self, self.flyingtimer/(self.flyingtime or 7)) as number)*(self.flyingdistance or 7.5) + (self.startx as number)
		self.x = newx
end


-- ===== endless / unique AI =====

local function n(v: number|nil, d: number): number
	if v == nil then return d end
	return v
end

ENEMY_MOVES["turret"] = function(self: enemy, dt: number)
	local st = self.turretstate or "idle"
	if st == "toppled" then
		self.turrettimer = n(self.turrettimer, 0) + dt
		if self.turrettimer > 3 then
			self:shotted("right", false, false, false, false)
		end
		return
	end
	if math.abs(self.speedx) > 3 or (self.gg_was_grabbed and not self.beamed) then
		self.turretstate = "toppled"
		self.turrettimer = 0
		self.rotation = math.pi / 2
		self.gg_was_grabbed = false
		playsfx("turretfall")
		return
	end
	self.speedx = 0
	local pl = closest_player(self)
	if pl == nil then return end
	local p = pl as mario
	local sx = self.x + self.width / 2
	local sy = self.y + self.height / 2
	local px = p.x + p.width / 2
	local py = p.y + p.height / 2
	local dx, dy = px - sx, py - sy
	local len = math.sqrt(dx * dx + dy * dy)
	local facing = (self.animationdirection == "right") and 1 or -1
	local seen = len > 0.05 and len < n(self.turretrange, 9)
		and (dx / len) * facing >= n(self.turretcone, 0.82)
		and not traceline_blocked(sx, sy, px, py)
	if st == "idle" then
		if seen then
			self.turretstate = "windup"
			self.turrettimer = 0
			playsfx("turretalert")
		end
	elseif st == "windup" then
		self.turrettimer = n(self.turrettimer, 0) + dt
		if not seen then
			self.turretstate = "idle"
		elseif self.turrettimer >= n(self.turretwindup, 0.6) then
			self.turretstate = "firing"
			self.turrettimer = 0
			self.turretshots = 0
		end
	elseif st == "firing" then
		self.turrettimer = n(self.turrettimer, 0) + dt
		if self.turrettimer >= n(self.turretburstdelay, 0.12) then
			self.turrettimer = 0
			self.turretshots = n(self.turretshots, 0) + 1
			spawn_bullet(sx + facing * 0.4, sy, facing * 14, 0, self)
			if self.turretshots >= n(self.turretburst, 5) then
				self.turretstate = "cooldown"
				self.turrettimer = 0
			end
		end
	elseif st == "cooldown" then
		self.turrettimer = n(self.turrettimer, 0) + dt
		if self.turrettimer >= n(self.turretcooldown, 1.4) then
			self.turretstate = "idle"
		end
	end
end

ENEMY_MOVES["sine"] = function(self: enemy, dt: number)
	self.sinetimer = n(self.sinetimer, math.random() * math.pi * 2) + dt
	local dir = (self.animationdirection == "right") and 1 or -1
	local amp = n(self.sineamp, 1.5)
	local freq = n(self.sinefreq, 2.2)
	self.speedx = dir * n(self.sinespeed, 3.5)
	self.speedy = amp * freq * math.cos(self.sinetimer * freq)
end

ENEMY_MOVES["shy"] = function(self: enemy, dt: number)
	local pl = closest_player(self)
	if pl == nil then return end
	local p = pl as mario
	local dx = (self.x + self.width / 2) - (p.x + p.width / 2)
	local dy = (self.y + self.height / 2) - (p.y + p.height / 2)
	local len = math.max(0.001, math.sqrt(dx * dx + dy * dy))
	local ang = p.pointingangle or 0
	local ax, ay = -math.sin(ang), -math.cos(ang)
	local watched = (dx / len) * ax + (dy / len) * ay >= n(self.shycone, 0.6)
	local accel = n(self.shyaccel, 6)
	local maxs = n(self.shyspeed, 3)
	if watched then
		self.shycover = true
		self.speedx = self.speedx - self.speedx * math.min(1, dt * 12)
		self.speedy = self.speedy - self.speedy * math.min(1, dt * 12)
		self.drawalpha = 0.35
	else
		self.shycover = false
		self.speedx = self.speedx - (dx / len) * accel * dt
		self.speedy = self.speedy - (dy / len) * accel * dt
		local s = math.sqrt(self.speedx ^ 2 + self.speedy ^ 2)
		if s > maxs then
			self.speedx = self.speedx / s * maxs
			self.speedy = self.speedy / s * maxs
		end
		self.drawalpha = 1.0
	end
end

ENEMY_MOVES["bones"] = function(self: enemy, dt: number)
	if self.bonesdown then
		if self.frozen then
			return
		end
		self.bonestimer = n(self.bonestimer, 0) + dt
		self.speedx = 0
		if self.quadgroup then
			local qi = 4 + math.floor(self.bonestimer * 8) % 2
			self.quadno = qi
			if self.quadgroup[qi] then
				self.quad = self.quadgroup[qi]
			end
		end
		if self.bonestimer >= n(self.bonesrevive, 4) then
			self.bonesdown = false
			self.active = true
			self.stompable = true
			self.killsonsides = true
			self.quadno = 1
			if self.quadgroup and self.quadgroup[1] then
				self.quad = self.quadgroup[1]
			end
		end
		return
	end
	local tf = ENEMY_MOVES["truffleshuffle"]
	if tf then tf(self, dt) end
end

ENEMY_MOVES["slam"] = function(self: enemy, dt: number)
	local st = self.slamstate or "wait"
	if st == "wait" then
		self.speedy = 0
		local pl = closest_player(self)
		if pl ~= nil then
			local p = pl as mario
			if math.abs((p.x + p.width / 2) - (self.x + self.width / 2)) < n(self.slamtrigger, 3.5)
				and p.y > self.y then
				self.slamstate = "drop"
				self.slamtimer = 0
			end
		end
	elseif st == "drop" then
		self.speedy = math.min(n(self.slammax, 22), self.speedy + n(self.slamaccel, 90) * dt)
	elseif st == "rest" then
		self.speedy = 0
		self.slamtimer = n(self.slamtimer, 0) + dt
		if self.slamtimer >= n(self.slamrest, 0.7) then
			self.slamstate = "rise"
		end
	elseif st == "rise" then
		self.speedy = -n(self.slamrise, 2)
		if self.y <= self.starty then
			self.y = self.starty
			self.slamstate = "wait"
		end
	end
end

ENEMY_MOVES["charge"] = function(self: enemy, dt: number)
	local st = self.chargestate or "patrol"
	local pl = closest_player(self)
	local dx = 0.0
	if pl ~= nil then
		local p = pl as mario
		dx = (p.x + p.width / 2) - (self.x + self.width / 2)
	end
	if st == "patrol" then
		local tf = ENEMY_MOVES["truffleshuffle"]
		if tf then tf(self, dt) end
		if pl ~= nil then
			local p = pl as mario
			if math.abs(dx) < n(self.chargeaggro, 8) and math.abs(p.y - self.y) < 2 then
				self.chargestate = "windup"
				self.chargetimer = 0
				self.chargedir = dx > 0 and 1 or -1
				self.speedx = 0
				playsfx("chargesnort")
			end
		end
	elseif st == "windup" then
		self.chargetimer = n(self.chargetimer, 0) + dt
		self.speedx = -n(self.chargedir, 1) * 0.8
		if self.chargetimer >= n(self.chargewindup, 0.55) then
			self.chargestate = "run"
		end
	elseif st == "run" then
		self.speedx = n(self.chargedir, 1) * n(self.chargespeed, 13)
		self.animationdirection = n(self.chargedir, 1) > 0 and "right" or "left"
	elseif st == "stun" then
		self.chargetimer = n(self.chargetimer, 0) + dt
		self.speedx = 0
		self.quadno = 5
		if self.chargetimer >= n(self.chargestun, 1.6) then
			self.chargestate = "patrol"
		end
	end
end

ENEMY_MOVES["hop"] = function(self: enemy, dt: number)
	if self.falling or self.jumping then
		return
	end
	self.hoptimer = n(self.hoptimer, 0) + dt
	if self.hoptimer >= n(self.hopdelay, 1.1) then
		self.hoptimer = 0
		local pl = closest_player(self)
		local dir = 1
		if pl ~= nil and (pl as mario).x < self.x then
			dir = -1
		end
		self.speedy = -n(self.hopforce, 9)
		self.speedx = dir * n(self.hopdrift, 2.5)
		self.falling = true
	end
end

ENEMY_MOVES["trap"] = function(self: enemy, dt: number)
	self.trapcd = math.max(0, n(self.trapcd, 0) - dt)
	if self.trapcd > 0 then
		return
	end
	local facing = (self.animationdirection == "right") and 1 or -1
	local sy = self.y + 0.5
	if not playerobjs then return end
	for i = 1, players do
		local p = playerobjs[i] as mario
		if p and not p.dead
			and math.abs((p.y + p.height / 2) - sy) < 0.6
			and (p.x - self.x) * facing > 0
			and math.abs(p.x - self.x) < n(self.trapreach, 12)
			and not traceline_blocked(self.x, sy, p.x, sy) then
			spawn_bullet(self.x + facing * 0.6, sy, facing * n(self.trapspeed, 18), 0, self)
			self.trapcd = n(self.trapcooldown, 1.8)
			playsfx("arrowfire")
			return
		end
	end
end

ENEMY_MOVES["hover"] = function(self: enemy, dt: number)
	local pl = closest_player(self)
	if pl == nil then return end
	local p = pl as mario
	local sx = self.x + self.width / 2
	local sy = self.y + self.height / 2
	local px = p.x + p.width / 2
	local py = p.y + p.height / 2
	local dx, dy = px - sx, py - sy
	local len = math.max(0.001, math.sqrt(dx * dx + dy * dy))
	local want = len - n(self.hoverkeep, 3)
	local ux, uy = dx / len, dy / len
	local accel = n(self.hoveraccel, 3.5)
	local sign = want > 0 and 1 or -1
	self.speedx = self.speedx + ux * accel * dt * sign
	self.speedy = self.speedy + uy * accel * dt * sign
	local s = math.sqrt(self.speedx ^ 2 + self.speedy ^ 2)
	local maxs = n(self.hoverspeed, 2.2)
	if s > maxs then
		self.speedx = self.speedx / s * maxs
		self.speedy = self.speedy / s * maxs
	end
	self.hovercd = n(self.hovercd, 0) + dt
	local shotspeed = n(self.shotspeed, 9)
	if self.hovercd >= n(self.hoverfire, 2.4) and len < 11 and not traceline_blocked(sx, sy, px, py) then
		self.hovercd = 0
		local tlead = len / shotspeed * n(self.hoverlead, 0.35)
		local tx = px + p.speedx * tlead
		local ty = py + p.speedy * tlead
		local l2 = math.max(0.001, math.sqrt((tx - sx) ^ 2 + (ty - sy) ^ 2))
		spawn_bullet(sx, sy, (tx - sx) / l2 * shotspeed, (ty - sy) / l2 * shotspeed, self)
	end
end

ENEMY_MOVES["latch"] = function(self: enemy, dt: number)
	if self.latchedto then
		local pl = self.latchedto as mario
		if pl.dead then
			self.latchedto = nil
			return
		end
		self.x = pl.x + (pl.width - self.width) / 2
		self.y = pl.y - self.height * 0.5
		self.speedx, self.speedy = 0, 0
		self.latchtimer = n(self.latchtimer, 0) + dt
		if self.latchtimer >= n(self.latchdrain, 0.9) then
			self.latchtimer = 0
			pl:die("latch")
		end
		local d = 0
		if pl.speedx > 1 then d = 1 elseif pl.speedx < -1 then d = -1 end
		if d ~= 0 and d ~= n(self.lastdir, 0) then
			self.lastdir = d
			self.shakes = n(self.shakes, 0) + 1
			self.shakewin = 0
		end
		self.shakewin = n(self.shakewin, 0) + dt
		if self.shakewin > n(self.latchwindow, 1) then
			self.shakes = 0
			self.shakewin = 0
		end
		if n(self.shakes, 0) >= n(self.latchshake, 6) then
			self.latchedto = nil
			self.speedx = -d * 8
			self.speedy = -6
			self.shakes = 0
			self.latchcd = 2.0
		end
		return
	end
	self.latchcd = math.max(0, n(self.latchcd, 0) - dt)
	local pl = closest_player(self)
	if pl == nil then return end
	local p = pl as mario
	local dx = p.x - self.x
	local dy = p.y - self.y
	local len = math.max(0.001, math.sqrt(dx * dx + dy * dy))
	local sp = n(self.latchspeed, 4.5)
	self.speedx = dx / len * sp
	self.speedy = dy / len * sp
	if len < 0.5 and self.latchcd <= 0 then
		self.latchedto = p
		self.latchtimer = 0
		playsfx("latchgrab")
	end
end

global function enemymove_drybones_stomp(self: enemy): boolean
	self.bonesdown = true
	self.bonestimer = 0
	self.killsonsides = false
	self.stompable = false
	self.speedx = 0
	playsfx("bonescollapse")
	return false
end

-- ===== ENGINE FAULT identity AI =====

ENEMY_MOVES["nullptr"] = function(self: enemy, _dt: number)
	local pl = closest_player(self)
	if pl == nil then
		self.drawable = false
		return
	end
	local p = pl as mario
	local sx = self.x + self.width / 2
	local sy = self.y + self.height / 2
	local px = p.x + p.width / 2
	local py = p.y + p.height / 2
	local dx, dy = px - sx, py - sy
	local len = math.max(0.001, math.sqrt(dx * dx + dy * dy))
	local ang = p.pointingangle or 0
	local ax, ay = -math.sin(ang), -math.cos(ang)
	-- visible only when player aims at us (same cone math as shy)
	local from_pl_x = sx - px
	local from_pl_y = sy - py
	local plen = math.max(0.001, math.sqrt(from_pl_x * from_pl_x + from_pl_y * from_pl_y))
	local aimed = (from_pl_x / plen) * ax + (from_pl_y / plen) * ay >= n(self.npcone, 0.55)
	self.drawable = aimed
	local spd = n(self.npspeed, 3.2)
	self.speedx = (dx / len) * spd
	self.speedy = (dy / len) * spd
end

ENEMY_MOVES["offbyone"] = function(self: enemy, dt: number)
	local tf = ENEMY_MOVES["truffleshuffle"]
	if tf then
		tf(self, dt)
	end
	if self.obo_base_ox == nil then
		self.obo_base_ox = self.offsetX or 6
	end
	local shift = (self.animationdirection == "right") and 16 or -16
	self.offsetX = (self.obo_base_ox as number) + shift
end

ENEMY_MOVES["memleak"] = function(self: enemy, dt: number)
	local grow = n(self.mlgrow, 0.08)
	local mlmax = n(self.mlmax, 3.0)
	self.width = math.min(mlmax, self.width + grow * dt)
	self.height = math.min(mlmax, self.height + grow * dt)
	self.customscale = self.width / 0.75
	self.mltimer = n(self.mltimer, 0) + dt
	if self.mltimer >= n(self.mlsplit, 6.0) then
		self.mltimer = 0
		local list = (objects and objects["enemy"]) as {any}|nil
		if list and #list < 60 and enemy and enemy.new then
			local e = enemy:new(self.x + 1, self.y + 1, self.t, nil)
			e.x = self.x
			e.y = self.y - 1
			e.width = 0.75
			e.height = 0.75
			e.customscale = 1
			e.mltimer = 0
			table.insert(list, e)
		end
	end
	local tf = ENEMY_MOVES["truffleshuffle"]
	if tf then
		tf(self, dt)
	end
end

global function enemymove_splitter_die(self: enemy): boolean
	local lvl = n(self.splitlevel, 0)
	if lvl <= 0 then
		return true
	end
	if not objects or not objects["enemy"] then
		return true
	end
	local count = n(self.splitcount, 2)
	local scale = n(self.splitscale, 0.6)
	for i = 1, count do
		local e = enemy:new(self.x + 1, self.y + 1, self.t, nil)
		e.x = self.x
		e.y = self.y
		e.splitlevel = lvl - 1
		e.width = self.width * scale
		e.height = self.height * scale
		e.customscale = n(self.customscale, 1) * scale
		e.hopforce = n(self.hopforce, 9) * 1.15
		e.speedx = (i == 1 and -1 or 1) * 3
		e.speedy = -5
		table.insert(objects["enemy"] as {any}, e)
	end
	return true
end

global function enemymove_thwomp_floor(self: enemy)
	if self.slamstate == "drop" then
		self.slamstate = "rest"
		self.slamtimer = 0
		earthquake = math.max(earthquake or 0, 0.4)
		playsfx("thwomp")
	end
end

global function enemymove_charger_wall(self: enemy, a: any, b: Entity|nil)
	if self.chargestate == "run" then
		self.chargestate = "stun"
		self.chargetimer = 0
		earthquake = math.max(earthquake or 0, 0.25)
		if a == "tile" and b ~= nil and destroyblock and tilequads and map then
			local tile = b as Entity
			local cox = tile.cox
			local coy = tile.coy
			if cox and coy and map[cox] and map[cox][coy] then
				local tid = map[cox][coy][1] as number
				local tq = tilequads[tid]
				if tq and tq.getproperty and tq:getproperty("breakable", cox, coy) then
					destroyblock(cox, coy)
				end
			end
		end
	end
end

global function enemymove_dispatch(self: enemy, dt: number)
	local mvname = self.movement as string|nil
	if not mvname then
		return
	end
	local mv = ENEMY_MOVES[mvname]
	if mv then
		mv(self, dt)
	end
end
