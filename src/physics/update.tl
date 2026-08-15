-- Per-frame physics mover loop (extracted from physics.lua).
-- Depends at runtime on: objects, PHYSICS_LATE_*, convert*, checkportal*,
-- handlegroup, checkcollision, inmap, tilequads, map, tilekey, checkforemances, inportal.

require("physics.world")

if rawget(_G, "prof_push") == nil then
	rawset(_G, "prof_push", function(_: string) end)
	rawset(_G, "prof_pop", function(_: string|nil) end)
end

global function physicsupdate(dt: number)
	prof_push("physicsupdate")
	physics_world_prune()
	local lobjects = session.objects
	
	for gi = 1, #PHYSICS_GROUP_ORDER do
		local group_name = PHYSICS_GROUP_ORDER[gi]
		local w = lobjects[group_name]
		if w and group_name ~= "tile" then
			for _, i in ipairs(physics_group_keys_sorted(w)) do
				local v = w[i]
				if v.static == false and v.active then
					local body = v as Body
					local skip_map_physics = group_name == "player" and level_mapmode
					physics_world_upsert(v, group_name, i)
					if not skip_map_physics then
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
						
						if passed and group_name == "player" then
							playsound("portalenter")
						end
					end
					
					--COLLISIONS ROFL
					local horcollision = false
					local vercollision = false

					local sx = v.speedx or 0
					local sy = v.speedy or 0
					local smx = v.x + math.min(0, sx * dt)
					local smy = v.y + math.min(0, sy * dt)
					local smw = v.width + math.abs(sx * dt)
					local smh = v.height + math.abs(sy * dt)
					
					--VS OTHER OBJECTS PRE TILE GROUP
					for hi = 1, #PHYSICS_GROUP_ORDER do
						local h = PHYSICS_GROUP_ORDER[hi]
						local u = lobjects[h]
						if u and next(u as {any: any}) ~= nil and h ~= "tile" and not PHYSICS_LATE_SET[h as string] then
							local hor, ver = handlegroup(i, h, u as {any:Body}, body, group_name, dt, passed)
							if hor then
								horcollision = true
							end
							if ver then
								vercollision = true
							end
						end
					end
					
					--VS TILES (bump broadphase)
					local function tile_filter(item: any): boolean
						return physics_world_meta(item) == "tile"
					end
					local tile_items: {integer: any}
					local tile_len: number
					tile_items, tile_len = physics_world_query(smx, smy, smw, smh, tile_filter)
					local tiles = lobjects["tile"]
					for tii = 1, tile_len do
						local t = tile_items[tii as integer] as Body
						if t and t.active then
							local _mg: string|nil
							local tk: any
							_mg, tk = physics_world_meta(t)
							if tk and tiles and (tiles as {any: Body})[tk] == t then
								local tile_ent = t as Entity
								local mx = tile_ent.cox as number
								local my = tile_ent.coy as number
								if inmap(mx, my) and (not tilequads[session.map[mx][my][1]]:getproperty("invisible", mx, my) or group_name == "player") then
									if (i ~= tk or group_name ~= "tile") and v.mask[t.category] ~= true then
										local collision1, collision2 = checkcollision(v, tile_ent, "tile", tk, group_name, i, dt, passed)
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
						local u = session.objects[h]
						if u and next(u as {any: any}) ~= nil then
							local hor, ver = handlegroup(i, h, u as {any:Body}, body, group_name, dt, passed)
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

					physics_world_upsert(v, group_name, i)
					
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
					end -- not skip_map_physics
					if skip_map_physics then
						v.speedx = 0
						v.speedy = 0
					end
				end
			end
		end
	end
	prof_pop("physicsupdate")
end
