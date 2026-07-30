-- Collision resolution pipeline (extracted from physics.lua).
-- Depends at runtime on: aabb/aabt, inmap, convertto/fromstandard, prerotatecall,
-- and globals map/tilequads/yacceleration (and allowskip for purple gel).

global function checkcollision(v: Entity, t: Entity, h: any, g: any, j: any, i: any, dt: number, passed: any): boolean, boolean --v: b1table | t: b2table | h: b2type | g: b2id | j: b1type | i: b1id
	local hadhorcollision = false
	local hadvercollision = false
	local vsx = v.speedx or 0
	local vsy = v.speedy or 0
	
	if h ~= "tile" or (not tilequads[map[t.cox][t.coy][1]]:getproperty("slantupleft", t.cox, t.coy) and not tilequads[map[t.cox][t.coy][1]]:getproperty("slantupright", t.cox, t.coy)) then
		if math.abs(v.x+vsx*dt-t.x) < math.max(v.width, t.width)+1 and math.abs(v.y+vsy*dt-t.y) < math.max(v.height, t.height)+1 then
			--check if it's a passive collision (Object is colliding anyway)
			if not passed and aabb(v.x, v.y, v.width, v.height, t.x, t.y, t.width, t.height) then --passive collision! (oh noes!)
				if passivecollision(v, t, h, g, j, i, dt) then
					hadvercollision = true
				end
				
			elseif aabb(v.x + vsx*dt, v.y + vsy*dt, v.width, v.height, t.x, t.y, t.width, t.height) then
				if aabb(v.x + vsx*dt, v.y, v.width, v.height, t.x, t.y, t.width, t.height) then --Collision is horizontal!
					if horcollision(v, t, h, g, j, i, dt) then
						hadhorcollision = true
					end
					
				elseif aabb(v.x, v.y+vsy*dt, v.width, v.height, t.x, t.y, t.width, t.height) then --Collision is vertical!
					if vercollision(v, t, h, g, j, i, dt) then
						hadvercollision = true
					end
					
				else 
					--We're fucked, it's a diagonal collision! run!
					--Okay actually let's take this slow okay. Let's just see if we're moving faster horizontally than vertically, aight?
					local grav = yacceleration
					if v.gravity then
						grav = v.gravity
					end
					if math.abs(vsy-grav*dt) < math.abs(vsx) then
						--vertical collision it is.
						if vercollision(v, t, h, g, j, i, dt) then
							hadvercollision = true
						end
					else 
						--okay so we're moving mainly vertically, so let's just pretend it was a horizontal collision? aight cool.
						if horcollision(v, t, h, g, j, i, dt) then
							hadhorcollision = true
						end
					end
				end
			end
		end
	else
		if math.abs(v.x-t.x) < math.max(v.width, t.width)+1 and math.abs(v.y-t.y) < math.max(v.height, t.height)+1 then
			--check if it's a passive collision (Object is colliding anyway)
			local slant = "ul"
			if tilequads[map[t.cox][t.coy][1]]:getproperty("slantupright", t.cox, t.coy) then
				slant = "ur"
			end
			t.slant = slant
			local step = tilequads[map[t.cox][t.coy][1]]:getproperty("slopestep", t.cox, t.coy)
			;(t as {string:any}).slopestep = step
			if not passed and aabt(v.x, v.y, v.width, v.height, t.x, t.y, t.width, t.height, slant) then --passive collision! (oh noes!)
				if trianglepassivecollision(v, t, h, g, j, i, dt) then
					hadvercollision = true
				end
			elseif aabt(v.x + vsx*dt, v.y + vsy*dt, v.width, v.height, t.x, t.y, t.width, t.height, slant) then
				if trianglevercollision(v, t, h, g, j, i, dt) then
					hadvercollision = true
				end
			end	
		end
	end
	
	return hadhorcollision, hadvercollision
end

--- Cave Story 4-step slope surface Y (top of ramp). Legacy 45° when slopestep nil/0.
-- Ported semantics from doukutsu-rs physics slopes; see licenses/doukutsu-rs.MIT
global function slope_y(t: Entity, px: number): number
	local step = (t as {string:any}).slopestep as number|nil
	local f = math.max(0, math.min(1, px - t.x))
	if t.slant == "ul" then
		f = 1 - f
	end
	if type(step) == "number" and (step as number) >= 1 and (step as number) <= 4 then
		local s = step as number
		local base = (s - 1) / 4
		return t.y + 1 - (base + f / 4)
	end
	-- Legacy Mari0 full-tile 45°
	return t.y + f
end

global function trianglevercollision(v: Entity, t: Entity, _: any, g: any, j: any, i: any, dt: number): any
	local px = v.x + (v.speedx or 0) * dt
	if t.slant == "ul" then
		px = px + v.width
	end
	if v.floorcollide then
		if v:floorcollide(j, v, g, i) ~= false then
			if v.speedy then
				v.speedy = 0
			end
			v.y = slope_y(t, px) - v.height
			return true
		end
	else
		if v.speedy then
			v.speedy = 0
		end
		v.y = slope_y(t, px) - v.height
		return true
	end
end

global function trianglepassivecollision(v: Entity, t: Entity, h: any, g: any, j: any, i: any, dt: number): any
	trianglevercollision(v, t, h, g, j, i, dt)
end

global function passivecollision(v: Entity, t: Entity, h: any, g: any, j: any, i: any, _: number): boolean
	if v.passivecollide then
		v:passivecollide(h, t, i, g)
		if t.passivecollide then
			t:passivecollide(j, v, i, g)
		end
	else
		if v.floorcollide then
			if v:floorcollide(h, t, i, g) ~= false then
				if v.speedy > 0 then
					v.speedy = 0
				end
				v.y = t.y - v.height
				return true
			end
		else
			if v.speedy > 0 then
				v.speedy = 0
			end
			v.y = t.y - v.height
			return true
		end
	end
	
	return false
end

global function horcollision(v: Entity, t: Entity, h: any, g: any, j: any, i: any, _: number): boolean
	if v.speedx < 0 then
		--move object RIGHT (because it was moving left)
		
		if collisionexists("right", t) then
			if callcollision("right", t, j, v, g, i) ~= false then
				if t.speedx and t.speedx > 0 then
					t.speedx = 0
				end
			end
		else
			if t.speedx and t.speedx > 0 then
				t.speedx = 0
			end
		end
		if collisionexists("left", v) then
			if callcollision("left", v, h, t, i, g) ~= false then
				if v.speedx < 0 then
					v.speedx = 0
				end
				v.x = t.x + t.width
				return true
			end
		else
			if v.speedx < 0 then
				v.speedx = 0
			end
			v.x = t.x + t.width
			return true
		end
	else
		--move object LEFT (because it was moving right)
		
		if collisionexists("left", t) then
			if callcollision("left", t, j, v, g, i) ~= false then
				if t.speedx and t.speedx < 0 then
					t.speedx = 0
				end
			end
		else
			if t.speedx and t.speedx < 0 then
				t.speedx = 0
			end
		end
		
		if collisionexists("right", v) then
			if callcollision("right", v, h, t, i, g) ~= false then
				if v.speedx > 0 then
					v.speedx = 0
				end
				v.x = t.x - v.width
				return true
			end
		else
			if v.speedx > 0 then
				v.speedx = 0
			end
			v.x = t.x - v.width
			return true
		end
	end
	
	return false
end

global function vercollision(v: Entity, t: Entity, h: any, g: any, j: any, i: any, _: number): boolean
	if v.speedy < 0 then
		--move object DOWN (because it was moving up)
		if collisionexists("floor", t) then
			if callcollision("floor", t, j, v, g, i) ~= false then
				if t.speedy and t.speedy > 0 then
					t.speedy = 0
				end
			end
		else
			if t.speedy and t.speedy > 0 then
				t.speedy = 0
			end
		end
		
		if collisionexists("ceil", v) then
			if callcollision("ceil", v, h, t, i, g) ~= false then
				if v.speedy < 0 then
					v.speedy = 0
				end
				v.y = t.y  + t.height
				return true
			end
		else
			if v.speedy < 0 then
				v.speedy = 0
			end
			v.y = t.y  + t.height
			return true
		end
	else					
		if collisionexists("ceil", t) then
			if callcollision("ceil", t, j, v, g, i) ~= false then
				if t.speedy and t.speedy < 0 then
					t.speedy = 0
				end
			end
		else	
			if t.speedy and t.speedy < 0 then
				t.speedy = 0
			end
		end
		if collisionexists("floor", v) then
			if callcollision("floor", v, h, t, i, g) ~= false then
				if v.speedy > 0 then
					v.speedy = 0
				end
				v.y = t.y - v.height
				return true
			end
		else
			if v.speedy > 0 then
				v.speedy = 0
			end
			v.y = t.y - v.height
			return true
		end
	end
	return false
end

global function collisionscalls(dir: any, obj: Entity, a: any, b: Entity, c: any, d: any): any
	local r: any = nil
	
	if obj.gravitydirection > math.pi/4*1 and obj.gravitydirection <= math.pi/4*3 then
		if dir == "floor" then
			if obj.floorcollide then
				r = obj:floorcollide(a, b, c, d)
			end
		elseif dir == "left" then
			if obj.leftcollide then
				r = obj:leftcollide(a, b, c, d)
			end
		elseif dir == "ceil" then
			if obj.ceilcollide then
				r = obj:ceilcollide(a, b, c, d)
			end
		elseif dir == "right" then
			if obj.rightcollide then
				r = obj:rightcollide(a, b, c, d)
			end
		end
	elseif obj.gravitydirection > math.pi/4*3 and obj.gravitydirection <= math.pi/4*5 then
		if dir == "floor" then
			if obj.rightcollide then
				r = obj:rightcollide(a, b, c, d)
			end
		elseif dir == "left" then
			if obj.floorcollide then
				r = obj:floorcollide(a, b, c, d)
			end
		elseif dir == "ceil" then
			if obj.leftcollide then
				r = obj:leftcollide(a, b, c, d)
			end
		elseif dir == "right" then
			if obj.ceilcollide then
				r = obj:ceilcollide(a, b, c, d)
			end
		end
	elseif obj.gravitydirection > math.pi/4*5 and obj.gravitydirection <= math.pi/4*7 then
		if dir == "floor" then
			if obj.ceilcollide then
				r = obj:ceilcollide(a, b, c, d)
			end
		elseif dir == "left" then
			if obj.rightcollide then
				r = obj:rightcollide(a, b, c, d)
			end
		elseif dir == "ceil" then
			if obj.floorcollide then
				r = obj:floorcollide(a, b, c, d)
			end
		elseif dir == "right" then
			if obj.leftcollide then
				r = obj:leftcollide(a, b, c, d)
			end
		end
	else
		if dir == "floor" then
			if obj.leftcollide then
				r = obj:leftcollide(a, b, c, d)
			end
		elseif dir == "left" then
			if obj.ceilcollide then
				r = obj:ceilcollide(a, b, c, d)
			end
		elseif dir == "ceil" then
			if obj.rightcollide then
				r = obj:rightcollide(a, b, c, d)
			end
		elseif dir == "right" then
			if obj.floorcollide then
				r = obj:floorcollide(a, b, c, d)
			end
		end
	end
	
	return r
end

global function callcollision(dir: any, obj: Entity, a: any, b: Entity, c: any, d: any): any
	if not obj.gravitydirection then
		if dir == "floor" then
			return obj:floorcollide(a, b, c, d)
		elseif dir == "left" then
			return obj:leftcollide(a, b, c, d)
		elseif dir == "ceil" then
			return obj:ceilcollide(a, b, c, d)
		elseif dir == "right" then
			return obj:rightcollide(a, b, c, d)
		end
	end
	
	obj.speedx, obj.speedy = converttostandard(obj, obj.speedx, obj.speedy)
	
	local r: any = nil
	
	--PRE ROTATION CALLS!!! WOAAAH
	if prerotatecall(a, b) then
		r = collisionscalls(dir, obj, a, b, c, d)
	end
	
	if a == "tile" then
		local purplegel = false
		local x, y = b.cox, b.coy
		
		--Find a more suitable block if available	
		if dir == "floor" or dir == "ceil" then
			if inmap(x+1, y) and tilequads[map[x+1][y][1]]:getproperty("collision", x+1, y) and obj.x+obj.width/2+.5 > x + .5 then
				x = x + 1
			elseif inmap(x-1, y) and tilequads[map[x-1][y][1]]:getproperty("collision", x-1, y) and obj.x+obj.width/2+.5 < x - .5 then
				x = x - 1
			end
		end
		if dir == "left" or dir == "right" then
			if inmap(x, y+1) and tilequads[map[x][y+1][1]]:getproperty("collision", x, y+1) and obj.y+obj.height/2+.5 > y + .5 then
				y = y + 1
			elseif inmap(x, y-1) and tilequads[map[x][y-1][1]]:getproperty("collision", x, y-1) and obj.y+obj.height/2+.5 < y - .5 then
				y = y - 1
			end
		end		
		
		if not obj.runframe or obj.size == 1 then --cheap check for player
			local sidesn = map[x][y].gelSides
			if sidesn then
				local sides = sidesn as {number:number}
				if dir == "left" and gel_has(sides[GEL_SIDE_RIGHT], "adhere") then
					if obj.gravitydirection == 0 then
						obj.speedx = -obj.speedx
					end
					obj.gravitydirection = math.pi
					purplegel = true
				elseif dir == "floor" and gel_has(sides[GEL_SIDE_TOP], "adhere") then
					if obj.gravitydirection == math.pi*1.5 then
						obj.speedx = -obj.speedx
					end
					obj.gravitydirection = math.pi/2
					purplegel = true
					allowskip = false
				elseif dir == "right" and gel_has(sides[GEL_SIDE_LEFT], "adhere") then
					if obj.gravitydirection == math.pi then
						obj.speedx = -obj.speedx
					end
					obj.gravitydirection = 0
					purplegel = true
				elseif dir == "ceil" and gel_has(sides[GEL_SIDE_BOTTOM], "adhere") then
					if obj.gravitydirection == math.pi/2 then
						obj.speedx = -obj.speedx
					end
					obj.gravitydirection = math.pi*1.5
					purplegel = true
				end
			end
		end

		-- Opt-in bounce/speed gel for non-mario bodies (strangler: mario keeps its path).
		if (obj as {string:any}).gelreactive and map[x] and map[x][y] then
			local sidesn = map[x][y].gelSides
			if sidesn then
				local sides = sidesn as {number:number}
				if dir == "floor" then
					gel_react_floor(obj as {string:any}, sides[GEL_SIDE_TOP])
				elseif dir == "left" then
					gel_react_side(obj as {string:any}, sides[GEL_SIDE_RIGHT], GEL_SIDE_RIGHT)
				elseif dir == "right" then
					gel_react_side(obj as {string:any}, sides[GEL_SIDE_LEFT], GEL_SIDE_LEFT)
				end
			end
		end
		
		if purplegel then
			obj.speedy = 0
		elseif obj.gravitydirection ~= math.pi/2 then
			--check if wall is a side. and stuff.
			local resetgravity = false
			
			if obj.gravitydirection > math.pi/4*1 and obj.gravitydirection <= math.pi/4*3 then --down
				if dir == "ceil" or dir == "floor" then
					resetgravity = true
				end
			elseif obj.gravitydirection > math.pi/4*3 and obj.gravitydirection <= math.pi/4*5 then --left
				if dir == "right" or dir == "left" then
					resetgravity = true
				end
			elseif obj.gravitydirection > math.pi/4*5 and obj.gravitydirection <= math.pi/4*7 then --up
				if dir == "floor" or dir == "ceil" then
					resetgravity = true
				end
			else --right
				if dir == "left" or dir == "right" then
					resetgravity = true
				end
			end
			
			if resetgravity and not (obj as {string:any}).upsidedown then
				obj.gravitydirection = math.pi/2
				obj.speedy = 0
				obj.speedx = -obj.speedx
			end
		end
	elseif obj.gravitydirection ~= math.pi/2 and (not b.gravitydirection or b.gravitydirection ~= obj.gravitydirection) then
		--Player vs box hardcode fix
		if (a == "box" and obj.category == 3) or (a == "player" and obj.category == 9) then
			
		elseif not (obj as {string:any}).upsidedown then
			obj.gravitydirection = math.pi/2
			obj.speedy = 0
			obj.speedx = -obj.speedx
		end
	end
	
	--AFTER ROTATION CALLS!!! WOAAAH
	if not prerotatecall(a, b) then
		r = collisionscalls(dir, obj, a, b, c, d)
	end
	
	obj.speedx, obj.speedy = convertfromstandard(obj, obj.speedx, obj.speedy)
	
	return r
end

global function collisionexists(dir: any, obj: Entity): any
	if not obj.gravitydirection or (obj.gravitydirection > math.pi/4*1 and obj.gravitydirection <= math.pi/4*3) then
		if dir == "floor" then
			return obj.floorcollide
		elseif dir == "left" then
			return obj.leftcollide
		elseif dir == "ceil" then
			return obj.ceilcollide
		elseif dir == "right" then
			return obj.rightcollide
		end
	elseif obj.gravitydirection > math.pi/4*3 and obj.gravitydirection <= math.pi/4*5 then
		if dir == "floor" then
			return obj.rightcollide
		elseif dir == "left" then
			return obj.floorcollide
		elseif dir == "ceil" then
			return obj.leftcollide
		elseif dir == "right" then
			return obj.ceilcollide
		end
	elseif obj.gravitydirection > math.pi/4*5 and obj.gravitydirection <= math.pi/4*7 then
		if dir == "floor" then
			return obj.ceilcollide
		elseif dir == "left" then
			return obj.rightcollide
		elseif dir == "ceil" then
			return obj.floorcollide
		elseif dir == "right" then
			return obj.leftcollide
		end
	else
		if dir == "floor" then
			return obj.leftcollide
		elseif dir == "left" then
			return obj.ceilcollide
		elseif dir == "ceil" then
			return obj.rightcollide
		elseif dir == "right" then
			return obj.floorcollide
		end
	end
end

