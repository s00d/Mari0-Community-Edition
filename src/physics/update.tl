-- Per-frame physics mover loop (extracted from physics.lua).
-- Depends at runtime on: objects, PHYSICS_LATE_*, convert*, checkportal*,
-- handlegroup, checkcollision, inmap, tilequads, map, tilekey, checkforemances, inportal.

global function physicsupdate(dt: number)
	local lobjects = objects
	
	for j, w in pairs(lobjects) do
		if j ~= "tile" then
			for i, v in pairs(w) do
				if v.static == false and v.active then
					local body = v as Body
					--GRAVITY
					v.speedy = v.speedy + (v.gravity or yacceleration)*dt*0.5
					
					if v.speedy > maxyspeed then
						v.speedy = maxyspeed
					end
					
					--Standard conversion!
					if v.gravitydirection and v.gravitydirection ~= math.pi/2 then
						v.speedx, v.speedy = convertfromstandard(v, v.speedx, v.speedy)
					end
					
					--PORTALS LOL
					local passed = false
					if v.portalable ~= false then
						if not checkportalVER(v, v.x+v.speedx*dt) then
							if checkportalHOR(v, v.y+v.speedy*dt) then
								passed = true
							end
						else
							passed = true
						end
						
						if passed and j == "player" then
							playsound("portalenter")
						end
					end
					
					--COLLISIONS ROFL
					local horcollision = false
					local vercollision = false
					
					--VS OTHER OBJECTS PRE TILE GROUP
					for h, u in pairs(lobjects) do
						if h ~= "tile" and not PHYSICS_LATE_SET[h as string] then
							local hor, ver = handlegroup(i, h, u as {any:Body}, body, j, dt, passed)
							if hor then
								horcollision = true
							end
							if ver then
								vercollision = true
							end
						end
					end
					
					--VS TILES (Because I only wanna check close ones)
					local xstart = math.floor(v.x+v.speedx*dt-2/16)+1
					local ystart = math.floor(v.y+v.speedy*dt-2/16)+1
					
					local xfrom = xstart
					local xto = xstart+math.ceil(v.width+0.0001)
					local dir = 1
					
					if v.speedx < 0 then
						xfrom, xto = xto, xfrom
						dir = -1
					end
					
					local tiles = lobjects["tile"]
					for x = xfrom, xto, dir do
						for y = ystart, ystart+math.ceil(v.height+0.0001) do
							--check if invisible block
							if inmap(x, y) and (not tilequads[map[x][y][1]]:getproperty("invisible", x, y) or j == "player") then
								local tk = tilekey(x, y)
								local t = tiles[tk]
								if t then
									--    Same object          Active        Not masked
									if (i ~= tk or j ~= "tile") and t.active and v.mask[t.category] ~= true then
										local collision1, collision2 = checkcollision(v, t, "tile", tk, j, i, dt, passed)
										if collision1 then
											horcollision = true
										elseif collision2 then
											vercollision = true
										end
									end
								end
							end
						end
					end
					
					--VS: LATE OBJECTS
					for _, h in ipairs(PHYSICS_LATE_LIST) do
						local u = objects[h]
						if u then
							local hor, ver = handlegroup(i, h, u as {any:Body}, body, j, dt, passed)
							if hor then
								horcollision = true
							end
							if ver then
								vercollision = true
							end
						end
					end
					
					-- Emancipation grill once per mover (not once per object-group)
					checkforemances(dt, body)
					
					--Move the object
					if vercollision == false then
						v.y = v.y + v.speedy*dt
					end
					
					if horcollision == false then
						v.x = v.x + v.speedx*dt
					end
					
					if v.gravitydirection and v.gravitydirection ~= math.pi/2 then
						v.speedx, v.speedy = converttostandard(v, v.speedx, v.speedy)
					end
					
					if vercollision == false then
						if v.previouslyonground and v.startfall and not v.jumping then
							v.previouslyonground = false
							if v.speedy >= 0 then
								(v.startfall as function(Entity, any))(v, i)
							end
						end
					elseif not v.previouslyonground and v.startfall then
						v.previouslyonground = true
					end
					
					--check if object is inside portal
					if v.portalable ~= false then
						inportal(v)
					end
					
					--GRAVITY
					v.speedy = v.speedy + (v.gravity or yacceleration)*dt*0.5
				end
			end
		end
	end
end
