-- Portal teleportation helpers (extracted from physics.lua).
-- Depends at runtime on: portals, inrange, checkrect, yacceleration, gdt.
-- Globals newx/newy are intentionally assigned (legacy portalcoords contract).

global function inportal(self: Entity): boolean
	if self.mask[2] then
		return
	end
	for i, v in pairs(portals) do
		if v.x1 ~= false and v.x2 ~= false then
			local portal1Y = v.y1 as number
			local portal2Y = v.y2 as number
			local portal1X = v.x1 as number
			local portal2X = v.x2 as number
			local portal1xplus, portal1yplus = portal_facing_offset(v.facing1)
			local portal2xplus, portal2yplus = portal_facing_offset(v.facing2)
			
			local x = math.floor(self.x+self.width/2)+1
			local y = math.floor(self.y+self.height/2)+1
			
			if (x == portal1X or x == portal1X + portal1xplus) and (y == portal1Y or y == portal1Y + portal1yplus) then
				local entryportalX = v.x1 as number
				local entryportalY = v.y1 as number
				local entryportalfacing = v.facing1
				
				local exitportalX = v.x2 as number
				local exitportalY = v.y2 as number
				local exitportalfacing = v.facing2
				
				self.x, self.y, self.speedx, self.speedy, self.rotation = portalcoords(self.x, self.y, self.speedx, self.speedy, self.width, self.height, self.rotation, self.animationdirection, entryportalX, entryportalY, entryportalfacing, exitportalX, exitportalY, exitportalfacing, self, true)

			elseif (x == portal2X or x == portal2X + portal2xplus) and (y == portal2Y or y == portal2Y + portal2yplus) then
				local entryportalX = v.x2 as number
				local entryportalY = v.y2 as number
				local entryportalfacing = v.facing2
				
				local exitportalX = v.x1 as number
				local exitportalY = v.y1 as number
				local exitportalfacing = v.facing1
				
				self.x, self.y, self.speedx, self.speedy, self.rotation = portalcoords(self.x, self.y, self.speedx, self.speedy, self.width, self.height, self.rotation, self.animationdirection, entryportalX, entryportalY, entryportalfacing, exitportalX, exitportalY, exitportalfacing, self)

			end
		end
	end
	
	return false
end

global function checkportalHOR(self: Entity, nextY: number): boolean --handles horizontal (up- and down facing) portal teleportation
	for i, v in pairs(portals) do
		if v.x1 ~= false and v.x2 ~= false then
		
			local portal1xplus = 0
			local portal2xplus = 0
			local portal1Y = v.y1 as number
			local portal2Y = v.y2 as number
			
			--Get the extra block of each portal
			if v.facing1 == "up" then
				portal1xplus = 1
				portal1Y = portal1Y - 1
			elseif v.facing1 == "down" then
				portal1xplus = -1
			end
			
			if v.facing2 == "up" then
				portal2xplus = 1
				portal2Y = portal2Y - 1
			elseif v.facing2 == "down" then
				portal2xplus = -1
			end
			
			--first part checks whether object is in the portal's x range,                                  second part whether object just moved through the portal's Y value
			if ((v.x1 == math.floor(self.x+1) or (v.x1 as number)+portal1xplus == math.floor(self.x+1)) and inrange(portal1Y, self.y+self.height/2, nextY+self.height/2))
			or ((v.x2 == math.floor(self.x+1) or (v.x2 as number)+portal2xplus == math.floor(self.x+1)) and inrange(portal2Y, self.y+self.height/2, nextY+self.height/2)) then
			
				--check which portal is entry
				local entryportalX: number
				local entryportalY: number
				local entryportalfacing: any
				local exitportalX: number
				local exitportalY: number
				local exitportalfacing: any
				local entryportalxplus: number = 0
				local entryportalyplus: number = 0
				local exitportalxplus: number = 0
				local exitportalyplus: number = 0
				if (v.x1 == math.floor(self.x+1) or (v.x1 as number)+portal1xplus == math.floor(self.x+1)) and inrange(portal1Y, self.y+self.height/2, nextY+self.height/2) then
					entryportalX = v.x1 as number
					entryportalY = v.y1 as number
					entryportalfacing = v.facing1
					entryportalxplus = portal1xplus
					
					exitportalX = v.x2 as number
					exitportalY = v.y2 as number
					exitportalfacing = v.facing2
					exitportalxplus = portal2xplus
				else
					entryportalX = v.x2 as number
					entryportalY = v.y2 as number
					entryportalfacing = v.facing2	
					entryportalxplus = portal2xplus
					
					exitportalX = v.x1 as number
					exitportalY = v.y1 as number
					exitportalfacing = v.facing1
					exitportalxplus = portal1xplus
				end
				
				--check if movement makes that portal even a possibility
				if entryportalfacing == "up" then
					if self.speedy < 0 then
						return false
					end
				elseif entryportalfacing == "down" then
					if self.speedy > 0 then
						return false
					end
				end
				
				if entryportalfacing == "left" or entryportalfacing == "right" then
					return false
				end
				
				local testx, testy, testspeedx, testspeedy, testrotation = portalcoords(self.x, self.y, self.speedx, self.speedy, self.width, self.height, self.rotation, self.animationdirection, entryportalX, entryportalY, entryportalfacing, exitportalX, exitportalY, exitportalfacing, self, true)
			
				if #checkrect(testx, testy, self.width, self.height, {"exclude", self}, false) == 0 then --Check if exit position is free
					self.x, self.y, self.speedx, self.speedy, self.rotation = testx, testy, testspeedx, testspeedy, testrotation
				else
					self.speedy = -self.speedy*0.95
					if math.abs(self.speedy) < 2 then
						if self.speedy > 0 then
							self.speedy = 2
						else
							self.speedy = -2
						end
					end
				end
				
				
				if (entryportalfacing == "down" and exitportalfacing == "up") or (entryportalfacing == "up" and exitportalfacing == "down") then
					
				else
					self.jumping = false
					self.falling = true
				end
				
				if self.portaled then
					self:portaled(exitportalfacing)
				end
				
				return true
			end
		end
	end
	return false
end

global function checkportalVER(self: Entity, nextX: number): boolean --handles vertical (left- and right facing) portal teleportation
	for i, v in pairs(portals) do
		if v.x1 ~= false and v.x2 ~= false then
			local portal1yplus = 0
			local portal2yplus = 0
			local portal1X = v.x1 as number
			local portal2X = v.x2 as number
			
			--Get the extra block of each portal
			if v.facing1 == "right" then
				portal1yplus = 1
			elseif v.facing1 == "left" then
				portal1yplus = -1
				portal1X = portal1X - 1
			end
			
			if v.facing2 == "right" then
				portal2yplus = 1
			elseif v.facing2 == "left" then
				portal2yplus = -1
				portal2X = portal2X - 1
			end
			
			if ((v.y1 == math.floor(self.y+1) or (v.y1 as number)+portal1yplus == math.floor(self.y+1)) and inrange(portal1X, self.x+self.width/2, nextX+self.width/2))
			or ((v.y2 == math.floor(self.y+1) or (v.y2 as number)+portal2yplus == math.floor(self.y+1)) and inrange(portal2X, self.x+self.width/2, nextX+self.width/2)) then
				--check which portal is entry
				local entryportalX: number
				local entryportalY: number
				local entryportalfacing: any
				local exitportalX: number
				local exitportalY: number
				local exitportalfacing: any
				local entryportalxplus: number = 0
				local entryportalyplus: number = 0
				local exitportalxplus: number = 0
				local exitportalyplus: number = 0
				if (v.y1 == math.floor(self.y+1) or (v.y1 as number)+portal1yplus == math.floor(self.y+1)) and inrange(portal1X, self.x+self.width/2, nextX+self.width/2) then
					entryportalX = v.x1 as number
					entryportalY = v.y1 as number
					entryportalfacing = v.facing1
					entryportalyplus = portal1yplus
					
					exitportalX = v.x2 as number
					exitportalY = v.y2 as number
					exitportalfacing = v.facing2
					exitportalyplus = portal2yplus
				else
					entryportalX = v.x2 as number
					entryportalY = v.y2 as number
					entryportalfacing = v.facing2
					entryportalyplus = portal2yplus
					
					exitportalX = v.x1 as number
					exitportalY = v.y1 as number
					exitportalfacing = v.facing1
					exitportalyplus = portal1yplus
				end
				
				--check if movement makes that portal even a possibility
				if entryportalfacing == "right" then
					if self.speedx > 0 then
						return false
					end
				elseif entryportalfacing == "left" then
					if self.speedx < 0 then
						return false
					end
				end
				
				if entryportalfacing == "up" or entryportalfacing == "down" then
					return false
				end
				
				local testx, testy, testspeedx, testspeedy, testrotation = portalcoords(self.x, self.y, self.speedx, self.speedy, self.width, self.height, self.rotation, self.animationdirection, entryportalX, entryportalY, entryportalfacing, exitportalX, exitportalY, exitportalfacing, self, true)
			
				if #checkrect(testx, testy, self.width, self.height, {"exclude", self}, false) == 0 then
					self.x, self.y, self.speedx, self.speedy, self.rotation = testx, testy, testspeedx, testspeedy, testrotation
				else
					self.speedx = -self.speedx
				end
				
				self.jumping = false
				self.falling = true
				
				if self.portaled then
					self:portaled(exitportalfacing)
				end
				
				return true
			end
		end
	end
	return false
end

global function portalcoords(x: number, y: number, speedx: number, speedy: number, width: number, height: number, rotation: number, animationdirection: any, entryportalX: number|boolean, entryportalY: number|boolean, entryportalfacing: any, exitportalX: number|boolean, exitportalY: number|boolean, exitportalfacing: any, self: Entity, live: boolean|nil): number, number, number, number, number, any
	local eX = entryportalX as number
	local eY = entryportalY as number
	local xX = exitportalX as number
	local xY = exitportalY as number
	entryportalX, entryportalY, exitportalX, exitportalY = eX, eY, xX, xY
	x = x + width/2
	y = y + height/2
	
	local directrange: number = 0 --vector orthogonal to portal vector T
	local relativerange: number = 0 --vector symmetrical to portal vector =
	
	if entryportalfacing == "up" then
		directrange = entryportalY - y - 1
		if width == 2 then
			relativerange = 0
		else
			relativerange = ((x-width/2) - entryportalX + 1) / (2-width)
		end
	elseif entryportalfacing == "right" then
		directrange = x - entryportalX
		if height == 2 then
			relativerange = 0
		else
			relativerange = ((y-height/2) - entryportalY + 1) / (2-height)
		end
	elseif entryportalfacing == "down" then
		directrange = y - entryportalY	
		if width == 2 then
			relativerange = 0
		else
			relativerange = ((x-width/2) - entryportalX + 2) / (2-width)
		end
	elseif entryportalfacing == "left" then
		directrange = entryportalX - x - 1
		if height == 2 then
			relativerange = 0
		else
			relativerange = ((y-height/2) - entryportalY + 2) / (2-height)
		end
	end
	
	relativerange = math.min(1, math.max(0, relativerange))
	
	if entryportalfacing == "up" and exitportalfacing == "up" then --up -> up
		newx = x + (exitportalX - entryportalX)
		newy = exitportalY + directrange - 1
		speedy = -speedy
		
		rotation = rotation - math.pi
		
		if live then
			local grav = yacceleration
			if self and self.gravity then
				grav = self.gravity
			end

			--keep it from bugging out by having a minimum exit speed
			
			local minspeed = math.sqrt(2*grav*(height))
			
			if speedy > -minspeed then
				speedy = -minspeed
			end
		end
	elseif (entryportalfacing == "down" and exitportalfacing == "down") then --down -> down
		newx = x + (exitportalX - entryportalX)
		newy = exitportalY - directrange
		speedy = -speedy
		
		rotation = rotation - math.pi
		
	elseif entryportalfacing == "up" and exitportalfacing == "right" then --up -> right
		newy = exitportalY - relativerange*(2-height) - height/2 + 1
		newx = exitportalX - directrange
		
		speedx, speedy = speedy, -speedx
		
		rotation = rotation - math.pi/2
		
	elseif entryportalfacing == "up" and exitportalfacing == "left" then --up -> left
		newy = exitportalY + relativerange*(2-height) + height/2 - 2
		newx = exitportalX + directrange - 1
		
		speedx, speedy = -speedy, speedx
		
		rotation = rotation + math.pi/2
		
	elseif (entryportalfacing == "up" and exitportalfacing == "down") then --up -> down
		newx = x + (exitportalX - entryportalX) - 1
		newy = exitportalY - directrange
		
	
		--prevent low-fps bugs in a cheap way:
		if entryportalY > exitportalY then
			while newy+.5 + speedy*gdt > entryportalY do
				newy = newy - 0.01
			end
			
			while newy+.5 < exitportalY do
				newy = newy + 0.01
			end
		end
		
		--prevent porting into block by limiting X, yo
		if newx <= exitportalX - 2 + width/2 then
			newx = exitportalX - 2 + width/2
		elseif newx > exitportalX - width/2 then
			newx = exitportalX - width/2
		end
		
	elseif (entryportalfacing == "down" and exitportalfacing == "up") then --down -> up
		newx = x + (exitportalX - entryportalX) + 1
		newy = exitportalY + directrange - 1
		
	elseif (entryportalfacing == "down" and exitportalfacing == "left") then --down -> left
		newy = exitportalY - relativerange*(2-height) - height/2
		newx = exitportalX + directrange - 1
		
		speedx, speedy = speedy, -speedx
		
		rotation = rotation - math.pi/2
		
	elseif (entryportalfacing == "down" and exitportalfacing == "right") then --down -> right
		newy = exitportalY + relativerange*(2-height) + height/2 - 1
		newx = exitportalX - directrange
		
		speedx, speedy = -speedy, speedx
		
		rotation = rotation + math.pi/2
		
	--LEFT/RIGHT CODE!
	elseif (entryportalfacing == "left" and exitportalfacing == "right") then --left -> right
		newx = exitportalX - directrange
		newy = y + (exitportalY - entryportalY)+1
	elseif (entryportalfacing == "right" and exitportalfacing == "left") then --right -> left
		newx = exitportalX + directrange - 1
		newy = y + (exitportalY - entryportalY)-1
	elseif (entryportalfacing == "right" and exitportalfacing == "right") then --right -> right
		newx = exitportalX - directrange
		newy = y + (exitportalY - entryportalY)
		
		speedx = -speedx
		if animationdirection == "left" then
			animationdirection = "right"
		elseif animationdirection == "right" then
			animationdirection = "left"
		end
		
	elseif (entryportalfacing == "left" and exitportalfacing == "left") then --left -> left
		newx = exitportalX + directrange - 1
		newy = y + (exitportalY - entryportalY)
		
		speedx = -speedx
		if animationdirection == "left" then
			animationdirection = "right"
		elseif animationdirection == "right" then
			animationdirection = "left"
		end
		
	elseif (entryportalfacing == "left" and exitportalfacing == "up") then --left -> up
		newx = exitportalX + relativerange*(2-width) + width/2 - 1
		newy = exitportalY + directrange - 1
		
		speedx, speedy = speedy, -speedx
		
		rotation = rotation - math.pi/2
		
		if live then		
			--keep it from bugging out by having a minimum exit speed
			local grav = yacceleration
			if self and self.gravity then
				grav = self.gravity
			end
			
			local minspeed = math.sqrt(2*grav*(height))
			
			if speedy > -minspeed then
				speedy = -minspeed
			end
		end
		
	elseif (entryportalfacing == "right" and exitportalfacing == "up") then --right -> up
		newx = exitportalX - relativerange*(2-width) - width/2 + 1
		newy = exitportalY + directrange - 1
		
		speedx, speedy = -speedy, speedx
		
		rotation = rotation + math.pi/2
		
		if live then
			--keep it from bugging out by having a minimum exit speed
			local grav = yacceleration
			if self and self.gravity then
				grav = self.gravity
			end
			
			local minspeed = math.sqrt(2*grav*(height))
			
			if speedy > -minspeed then
				speedy = -minspeed
			end
		end
		
	elseif (entryportalfacing == "left" and exitportalfacing == "down") then --left -> down
		newx = exitportalX - relativerange*(2-width) - width/2
		newy = exitportalY - directrange
		
		speedx, speedy = -speedy, speedx
		
		rotation = rotation + math.pi/2
		
	elseif (entryportalfacing == "right" and exitportalfacing == "down") then --right -> down
		newx = exitportalX + relativerange*(2-width) + width/2 - 2
		newy = exitportalY - directrange
		
		speedx, speedy = speedy, -speedx
		
		rotation = rotation - math.pi/2
	end
	
	newx = newx - width/2
	newy = newy - height/2
	
	return newx, newy, speedx, speedy, rotation, animationdirection
end

