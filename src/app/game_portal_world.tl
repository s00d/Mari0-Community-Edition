--[[ portal world geometry helpers ]]

global function modifyportalwalls()
	--Create and remove new stuff
	for a, b in pairs(portals) do
		local pb = b as portal
		for i = 1, 2 do
			if ((pb as {string:any})["x" .. i] as number) then
				if (b as {string:any})["facing" .. i] == "up" then
					objects["portalwall"][a .. "-" .. i .. "-1"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number)-1, 0, 1, true)
					objects["portalwall"][a .. "-" .. i .. "-2"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number), 1, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-3"] = portalwall:new(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number), 1, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-4"] = portalwall:new(((b as {string:any})["x" .. i] as number)+1, ((b as {string:any})["y" .. i] as number)-1, 0, 1, true)
					objects["portalwall"][a .. "-" .. i .. "-5"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number)-1, 0, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-6"] = portalwall:new(((b as {string:any})["x" .. i] as number)+1, ((b as {string:any})["y" .. i] as number)-1, 0, 0, true)
					
					modifyportaltiles(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number), 1, 0, portals[a], i, "remove")
				elseif (b as {string:any})["facing" .. i] == "down" then
					objects["portalwall"][a .. "-" .. i .. "-1"] = portalwall:new(((b as {string:any})["x" .. i] as number)-2, ((b as {string:any})["y" .. i] as number)-1, 1, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-2"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number)-1, 1, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-3"] = portalwall:new(((b as {string:any})["x" .. i] as number)-2, ((b as {string:any})["y" .. i] as number)-1, 0, 1, true)
					objects["portalwall"][a .. "-" .. i .. "-4"] = portalwall:new(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number)-1, 0, 1, true)
					objects["portalwall"][a .. "-" .. i .. "-5"] = portalwall:new(((b as {string:any})["x" .. i] as number)-2, ((b as {string:any})["y" .. i] as number), 0, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-6"] = portalwall:new(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number), 0, 0, true)
					
					modifyportaltiles(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number), -1, 0, portals[a], i, "remove")
				elseif (b as {string:any})["facing" .. i] == "left" then
					objects["portalwall"][a .. "-" .. i .. "-1"] = portalwall:new(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number)-2, 0, 1, true)
					objects["portalwall"][a .. "-" .. i .. "-2"] = portalwall:new(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number)-1, 0, 1, true)
					objects["portalwall"][a .. "-" .. i .. "-3"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number)-2, 1, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-4"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number), 1, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-5"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number), 0, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-6"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number)-2, 0, 0, true)
					
					modifyportaltiles(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number), 0, -1, portals[a], i, "remove")
				elseif (b as {string:any})["facing" .. i] == "right" then
					objects["portalwall"][a .. "-" .. i .. "-1"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number)-1, 0, 1, true)
					objects["portalwall"][a .. "-" .. i .. "-2"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number), 0, 1, true)
					objects["portalwall"][a .. "-" .. i .. "-3"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number)-1, 1, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-4"] = portalwall:new(((b as {string:any})["x" .. i] as number)-1, ((b as {string:any})["y" .. i] as number)+1, 1, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-5"] = portalwall:new(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number)-1, 0, 0, true)
					objects["portalwall"][a .. "-" .. i .. "-6"] = portalwall:new(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number)+1, 0, 0, true)
					
					modifyportaltiles(((b as {string:any})["x" .. i] as number), ((b as {string:any})["y" .. i] as number), 0, 1, portals[a], i, "remove")
				end
			end
		end
	end
	
	--remove conflicting portalwalls (only exist when both portals exists!)
	for _, b in pairs(portals) do
		for j = 1, 2 do
			local otherj = 1
			if j == 1 then
				otherj = 2
			end
			for c, d in pairs(portals) do
				for i = 1, 2 do
					--B.J PORTAL WILL REMOVE WALLS OF D.OTHERJ, SO B.OTHERJ MUST EXIST
					
					if ((b as {string:any})["x" .. j] as number) and ((b as {string:any})["x" .. otherj] as number) and ((d as {string:any})["x" .. i] as number) then
						local conside, conx, cony = (b as {string:any})["facing" .. j], ((b as {string:any})["x" .. j] as number), ((b as {string:any})["y" .. j] as number)
						
						for k = 1, 4 do
							local w = objects["portalwall"][c .. "-" .. i .. "-" .. k]
							if w then
								if conside == "right" then
									if w.x == conx and w.y == cony-1 and w.height == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
									if w.x == conx and w.y == cony and w.height == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
									if w.x == conx-1 and w.y == cony and w.width == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
								elseif conside == "left" then
									if w.x == conx-1 and w.y == cony-2 and w.height == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
									if w.x == conx-1 and w.y == cony-1 and w.height == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
									if w.x == conx-1 and w.y == cony-1 and w.width == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
								elseif conside == "up" then
									if w.x == conx-1 and w.y == cony-1 and w.width == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
									if w.x == conx and w.y == cony-1 and w.width == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
									if w.x == conx and w.y == cony-1 and w.height == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
								else
									if w.x == conx-2 and w.y == cony and w.width == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
									if w.x == conx-1 and w.y == cony and w.width == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
									if w.x == conx-1 and w.y == cony-1 and w.height == 1 then
										objects["portalwall"][c .. "-" .. i .. "-" .. k] = nil
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

global function modifyportaltiles(x: any, y: any, xplus: any, yplus: any, port: any, i: any, mode: any)
	local xn = x as number
	local yn = y as number
	local xp = xplus as number
	local yp = yplus as number
	local p = port as portal
	if not x or not y then
		return
	end
	if i == 1 then
		if p.facing2 ~= false then
			if mode == "add" then
				objects["tile"][tilekey(xn, yn)] = tile:new(xn-1, yn-1) as Entity
				objects["tile"][tilekey(xn+xp, yn+yp)] = tile:new(xn-1+xp, yn-1+yp) as Entity
			else
				objects["tile"][tilekey(xn, yn)] = nil
				objects["tile"][tilekey(xn+xp, yn+yp)] = nil
			end
		end
	else
		if p.facing1 ~= false then
			if mode == "add" then
				objects["tile"][tilekey(xn, yn)] = tile:new(xn-1, yn-1) as Entity
				objects["tile"][tilekey(xn+xp, yn+yp)] = tile:new(xn-1+xp, yn-1+yp) as Entity
			else
				objects["tile"][tilekey(xn, yn)] = nil
				objects["tile"][tilekey(xn+xp, yn+yp)] = nil
			end
		end
	end
end

global function getportalposition(_: any, xin: any, yin: any, sidein: any, tendency: any, mirexc?: any): number|boolean, number|nil, string|nil
	local x = xin as number
	local y = yin as number
	local side = sidein as string
	--returns the "optimal" position according to the parsed arguments (or false if no possible position was found)
	local xplus: number = 0
	local yplus: number = 0
	if side == "up" then
		yplus = -1
	elseif side == "right" then
		xplus = 1
	elseif side == "down" then
		yplus = 1
	elseif side == "left" then
		xplus = -1
	end
	if mirexc and getTile(x, y, true, true, side, nil, nil, mirexc) == "mirror" then
		return x, y, "mirror"
	end
	if side == "up" or side == "down" then
		if tendency == -1 then
			if getTile(x-1, y, true, true, side) == true and getTile(x, y, true, true, side) == true and getTile(x-1, y+yplus, nil, false, side, true) == false and getTile(x, y+yplus, nil, false, side, true) == false then
				if side == "up" then
					return x-1, y
				else
					return x, y
				end
			elseif getTile(x, y, true, true, side) == true and getTile(x+1, y, true, true, side) == true and getTile(x, y+yplus, nil, false, side, true) == false and getTile(x+1, y+yplus, nil, false, side, true) == false then
				if side == "up" then
					return x, y
				else
					return x+1, y
				end
			end
		else
			if getTile(x, y, true, true, side) == true and getTile(x+1, y, true, true, side) == true and getTile(x, y+yplus, nil, false, side, true) == false and getTile(x+1, y+yplus, nil, false, side, true) == false then
				if side == "up" then
					return x, y
				else
					return x+1, y
				end
			elseif getTile(x-1, y, true, true, side) == true and getTile(x, y, true, true, side) == true and getTile(x-1, y+yplus, nil, false, side, true) == false and getTile(x, y+yplus, nil, false, side, true) == false then
				if side == "up" then
					return x-1, y
				else
					return x, y
				end
			end
		end
	else
		if tendency == -1 then
			if getTile(x, y-1, true, true, side) == true and getTile(x, y, true, true, side) == true and getTile(x+xplus, y-1, nil, false, side, true) == false and getTile(x+xplus, y, nil, false, side, true) == false then
				if side == "right" then
					return x, y-1
				else
					return x, y
				end
			elseif getTile(x, y, true, true, side) == true and getTile(x, y+1, true, true, side) == true and getTile(x+xplus, y, nil, false, side, true) == false and getTile(x+xplus, y+1, nil, false, side, true) == false then
				if side == "right" then
					return x, y
				else
					return x, y+1
				end
			end
		else
			if getTile(x, y, true, true, side) == true and getTile(x, y+1, true, true, side) == true and getTile(x+xplus, y, nil, false, side, true) == false and getTile(x+xplus, y+1, nil, false, side, true) == false then
				if side == "right" then
					return x, y
				else
					return x, y+1
				end
			elseif getTile(x, y-1, true, true, side) == true and getTile(x, y, true, true, side) == true and getTile(x+xplus, y-1, nil, false, side, true) == false and getTile(x+xplus, y, nil, false, side, true) == false then
				if side == "right" then
					return x, y-1
				else
					return x, y
				end
			end
		end
	end
	
	return false
end

global function getTile(x: number, y: number, _?: any, portalcheck?: any, facing?: any, ignoregrates?: any, _?: any, mirexc?: any): any, any --returns masktable value of block (As well as the ID itself as second return parameter) also includes a portalcheck and returns false if a portal is on that spot.
	if portalcheck then
		for _, v in pairs(portals) do
			--Get the extra block of each portal
			local portal1xplus, portal1yplus, portal2xplus, portal2yplus = portal_pair_offsets(v.facing1, v.facing2)
			
			if v.x1 ~= false then
				if (x == v.x1 or x == (v.x1 as number)+portal1xplus) and (y == v.y1 or y == (v.y1 as number)+portal1yplus) and (facing == nil or v.facing1 == facing) then
					return false
				end
			end
		
			if v.x2 ~= false then
				if (x == v.x2 or x == (v.x2 as number)+portal2xplus) and (y == v.y2 or y == (v.y2 as number)+portal2yplus) and (facing == nil or v.facing2 == facing) then
					return false
				end
			end
		end
	end
	
	--check for tubes
	for _, v in pairs(objects["geldispenser"]) do
		if (x == v.cox or x == v.cox+1) and (y == v.coy or y == v.coy+1) then
			if portalcheck then
				return false
			else
				return true
			end
		end
	end
	
	for _, v in pairs(objects["cubedispenser"]) do
		if (x == v.cox or x == v.cox+1) and (y == v.coy or y == v.coy+1) then
			if portalcheck then
				return false
			else
				return true
			end
		end
	end
	
	--bonusstage thing for keeping it from fucking up by allowing portals to be shot next to the vine in 4-2_2 for example
	if bonusstage then
		if y == mapheight and (x == 4 or x == 6) then
			if portalcheck then
				return false
			else
				return true
			end
		end
	end
	
	if x <= 0 or y <= 0 or y >= mapheight+1 or x > mapwidth then
		return false, 1
	end
	
	if tilequads[map[x][y][1] as number]:getproperty("invisible", x, y) then
		return false
	end
	
	if portalcheck then
		local side: string = ""
		if facing == "up" then
			side = "top"
		elseif facing == "right" then
			side = "right"
		elseif facing == "down" then
			side = "bottom"
		elseif facing == "left" then
			side = "left"
		end
		
		--To stop people from portalling under the vine, which caused problems, but was fixed elsewhere (and betterer)
		--[[for i, v in pairs(objects["vine"]) do
			if x == v.cox and y == v.coy and side == "top" then
				return false, 1
			end
		end--]]
		
		if map[x][y]["portaloverride"] and map[x][y]["portaloverride"][side] then
			return true, map[x][y][1]
		end
		
		if map[x][y]["gels"] and map[x][y]["gels"][side] == 3 then
			return true, map[x][y][1]
		elseif tilequads[map[x][y][1] as number]:getproperty("mirror", x, y) and mirexc then
			return "mirror"
		else
			return tilequads[map[x][y][1] as number]:getproperty("collision", x, y) and tilequads[map[x][y][1] as number]:getproperty("portalable", x, y) and tilequads[map[x][y][1] as number]:getproperty("grate", x, y) == false and tilequads[map[x][y][1] as number]:getproperty("mirror", x, y) == false, map[x][y][1]
		end
	else
		if ignoregrates then
			return tilequads[map[x][y][1] as number]:getproperty("collision", x, y) and tilequads[map[x][y][1] as number]:getproperty("grate", x, y) == false, map[x][y][1]
		else
			return tilequads[map[x][y][1] as number]:getproperty("collision", x, y), map[x][y][1]
		end
	end
end

global function getPortal(x: number, y: number, dir?: any): number|boolean, number|nil, any, any, any, any, any, any --returns the block where you'd come out when you'd go in the argument's block
	for _, v in pairs(portals) do
		if v.x1 ~= false and v.x2 ~= false then
			--Get the extra block of each portal
			local portal1xplus, portal1yplus, portal2xplus, portal2yplus = portal_pair_offsets(v.facing1, v.facing2)
			
			if v.x1 ~= false and (not dir or v.facing1 == dir) then
				if (x == v.x1 or x == (v.x1 as number)+portal1xplus) and (y == v.y1 or y == (v.y1 as number)+portal1yplus) and (facing == nil or v.facing1 == facing) then
					if v.facing1 ~= v.facing2 then
						local xplus: number = 0
						local yplus: number = 0
						if v.facing1 == "left" or v.facing1 == "right" then
							if y == v.y1 then
								if v.facing2 == "left" or v.facing2 == "right" then
									yplus = portal2yplus
								else
									xplus = portal2xplus
								end
							end
							
							return (v.x2 as number)+xplus, (v.y2 as number)+yplus, v.facing2, v.facing1, v.x2, v.y2, v.x1, v.y1
						else
							if x == v.x1 then
								if v.facing2 == "left" or v.facing2 == "right" then
									yplus = portal2yplus
								else
									xplus = portal2xplus
								end
							end
							
							return (v.x2 as number)+xplus, (v.y2 as number)+yplus, v.facing2, v.facing1, v.x2, v.y2, v.x1, v.y1
						end	
					else
						return (v.x2 as number)+(x-(v.x1 as number)), (v.y2 as number)+(y-(v.y1 as number)), v.facing2, v.facing1, v.x2, v.y2, v.x1, v.y1
					end
				end
			end
		
			if v.x2 ~= false and (not dir or v.facing2 == dir) then
				if (x == v.x2 or x == (v.x2 as number)+portal2xplus) and (y == v.y2 or y == (v.y2 as number)+portal2yplus) and (facing == nil or v.facing2 == facing) then
					if v.facing1 ~= v.facing2 then
						local xplus: number = 0
						local yplus: number = 0
						if v.facing2 == "left" or v.facing2 == "right" then
							if y == v.y2 then
								if v.facing1 == "left" or v.facing1 == "right" then
									yplus = portal1yplus
								else
									xplus = portal1xplus
								end
							end
							
							return (v.x1 as number)+xplus, (v.y1 as number)+yplus, v.facing1, v.facing2, v.x1, v.y1, v.x2, v.y2
						else
							if x == v.x2 then
								if v.facing1 == "left" or v.facing1 == "right" then
									yplus = portal1yplus
								else
									xplus = portal1xplus
								end
							end
							
							return (v.x1 as number)+xplus, (v.y1 as number)+yplus, v.facing1, v.facing2, v.x1, v.y1, v.x2, v.y2
						end	
					else
						return (v.x1 as number)+(x-(v.x2 as number)), (v.y1 as number)+(y-(v.y2 as number)), v.facing1, v.facing2, v.x1, v.y1, v.x2, v.y2
					end
				end
			end
		end
	end
	
	return false
end

global function insideportal(x: number, y: number, width: number, height: number): any, any --returns whether an object is in, and which, portal.
	if width == nil then
		width = 12/16
	end
	if height == nil then
		height = 12/16
	end
	for i, v in pairs(portals) do
		if v.x1 ~= false and v.x2 ~= false then
			for j = 1, 2 do				
				local portalx: number = 0
				local portaly: number = 0
				local portalfacing: any = false
				local xplus: number = 0
				local yplus: number = 0
				if j == 1 then
					portalx = v.x1 as number
					portaly = v.y1 as number
					portalfacing = v.facing1
				else
					portalx = v.x2 as number
					portaly = v.y2 as number
					portalfacing = v.facing2
				end
				
				if portalfacing == "up" then
					xplus = 1
				elseif portalfacing == "down" then
					xplus = -1
				elseif portalfacing == "left" then
					yplus = -1
				end
				
				if portalfacing == "right" then
					if (math.floor(y) == portaly or math.floor(y) == portaly-1) and inrange(x, portalx-width, portalx, false) then
						return portals[i], j
					end
				elseif portalfacing == "left" then
					if (math.floor(y) == portaly-1 or math.floor(y) == portaly-2) and inrange(x, portalx-1-width, portalx-1, false) then
						return portals[i], j
					end
				elseif portalfacing == "up" then
					if inrange(y, portaly-height-1, portaly-1, false) and inrange(x, portalx-1.5-.2, portalx+.5+.2, true) then
						return portals[i], j
					end	
				elseif portalfacing == "down" then
					if inrange(y, portaly-height, portaly, false) and inrange(x, portalx-2, portalx-.5, true) then
						return portals[i], j
					end	
				end
				
				--widen rect by 3 pixels?
				
			end
		end
	end
	
	return false
end

global function moveoutportal(_i?: any) --pushes objects out of the portal i in.
	for i, v in pairs(objects) do
		if i ~= "tile" and i ~= "portalwall" then
			for _, w in pairs(v) do
				if w.active and w.static == false then
					local p1: any = nil
					local p2: any = nil
					p1, p2 = insideportal(w.x, w.y, w.width, w.height)
					
					if p1 ~= false then
						local portalent = p1 as portal
						local portalfacing: any = false
						local portalx: number = 0
						local portaly: number = 0
						if p2 == 1 then
							portalfacing = portalent.facing1
							portalx = portalent.x1 as number
							portaly = portalent.y1 as number
						else
							portalfacing = portalent.facing2
							portalx = portalent.x2 as number
							portaly = portalent.y2 as number
						end
						
						if portalfacing == "right" then
							w.x = portalx
						elseif portalfacing == "left" then
							w.x = portalx - 1 - w.width
						elseif portalfacing == "up" then
							w.y = portaly - 1 - w.height
						elseif portalfacing == "down" then
							w.y = portaly
						end
					end
				end
			end
		end
	end
end

global function traceline(sourcex: number, sourcey: number, radians: number, _?: any): number|boolean, number|boolean, string|boolean, number|boolean, number, number
	local _: number = 0
	local _: number = 0
	local _: any = false
	local currentblock: {number} = {}
	local x, y = sourcex, sourcey
	currentblock[1] = math.floor(x)
	currentblock[2] = math.floor(y+1)
		
	local emancecollide = false
	for _, v in pairs(emancipationgrills) do
		if v:getTileInvolved(currentblock[1]+1, currentblock[2]) then
			emancecollide = true
		end
	end
	
	local doorcollide = false
	for _, v in pairs(objects["door"]) do
		if v.dir == "hor" then
			if v.open == false and (v.cox == currentblock[1] or v.cox == currentblock[1]+1) and v.coy == currentblock[2] then
				doorcollide = true
			end
		else
			if v.open == false and v.cox == currentblock[1]+1 and (v.coy == currentblock[2] or v.coy == currentblock[2]+1) then
				doorcollide = true
			end
		end
	end
	
	if emancecollide or doorcollide then
		return false, false, false, false, x, y
	end
	
	local side: string = ""
	
	while currentblock[1]+1 > 0 and currentblock[1]+1 <= mapwidth and (flagx == false or currentblock[1]+1 <= (flagx as number) or radians > 0) and (axex == false or currentblock[1]+1 <= (axex as number)) and (currentblock[2] > 0 or currentblock[2] >= math.floor(sourcey+0.5)) and currentblock[2] < mapheight+1 do --while in map range
		local oldy = y
		local oldx = x
		
		--calculate X and Y diff..
		local ydiff: number = 0
		local xdiff: number = 0
		local side1: string = ""
	local side2: string = ""
		
		if inrange(radians, -math.pi/2, math.pi/2, true) then --up
			ydiff = (y-(currentblock[2]-1)) / math.cos(radians)
			y = currentblock[2]-1
			side1 = "down"
		else
			ydiff = (y-(currentblock[2])) / math.cos(radians)
			y = currentblock[2]
			side1 = "up"
		end
		
		if inrange(radians, 0, math.pi, true) then --left
			xdiff = (x-(currentblock[1])) / math.sin(radians)
			x = currentblock[1]
			side2 = "right"
		else
			xdiff = (x-(currentblock[1]+1)) / math.sin(radians)
			x = currentblock[1]+1
			side2 = "left"
		end
		
		--smaller diff wins
		
		if xdiff < ydiff then
			y = oldy - math.cos(radians)*xdiff
			side = side2
		else
			x = oldx - math.sin(radians)*ydiff
			side = side1
		end
		
		if side == "down" then
			currentblock[2] = currentblock[2]-1
		elseif side == "up" then
			currentblock[2] = currentblock[2]+1
		elseif side == "left" then
			currentblock[1] = currentblock[1]+1
		elseif side == "right" then
			currentblock[1] = currentblock[1]-1
		end
		
		local collide, _ = getTile(currentblock[1]+1, currentblock[2])
		local emancecollide = false
		for _, v in pairs(emancipationgrills) do
			if v:getTileInvolved(currentblock[1]+1, currentblock[2]) then
				emancecollide = true
			end
		end
		
		local doorcollide = false
		for _, v in pairs(objects["door"]) do
			if v.dir == "hor" then
				if v.open == false and (v.cox == currentblock[1] or v.cox == currentblock[1]+1) and v.coy == currentblock[2] then
					doorcollide = true
				end
			else
				if v.open == false and v.cox == currentblock[1]+1 and (v.coy == currentblock[2] or v.coy == currentblock[2]+1) then
					doorcollide = true
				end
			end
		end
		
		-- < 0 rechts
		
		--Check for ceilblocker
		if y < 0 then
			if entitylist[map[currentblock[1]][1][2]] and entitylist[map[currentblock[1]][1][2]].t == "ceilblocker" then
				return false, false, false, false, x, y
			end
		end
		
		if collide == true and tilequads[map[currentblock[1]+1][currentblock[2]][1]]:getproperty("grate", currentblock[1]+1, currentblock[2]) == false then
			break
		elseif emancecollide or doorcollide then
			return false, false, false, false, x, y
		elseif (radians <= 0 and x > xscroll + width) or (radians >= 0 and x < xscroll) then
			return false, false, false, false, x, y
		end
	end
	
	if currentblock[1]+1 > 0 and currentblock[1]+1 <= mapwidth and (currentblock[2] > 0 or currentblock[2] >= math.floor(sourcey+0.5))  and currentblock[2] < mapheight+1 and currentblock[1] ~= nil then
		local tendency: number = 0
	
		--get tendency
		if side == "down" or side == "up" then
			if math.fmod(x, 1) > 0.5 then
				tendency = 1
			else
				tendency = -1
			end
		elseif side == "left" or side == "right" then
			if math.fmod(y, 1) > 0.5 then
				tendency = 1
			else
				tendency = -1
			end
		end
		
		return currentblock[1]+1, currentblock[2], side, tendency, x, y
	else
		return false, false, false, false, x, y
	end
end

global function checkportalremove(x: any, y: any)
	for _, v in pairs(portals) do
		--Get the extra block of each portal
		local portal1xplus, portal1yplus, portal2xplus, portal2yplus = portal_pair_offsets(v.facing1, v.facing2)
		
		if v.x1 ~= false then
			if (x == v.x1 or x == (v.x1 as number)+portal1xplus) and (y == v.y1 or y == (v.y1 as number)+portal1yplus) then--and (facing == nil or v.facing1 == facing) then
				v:removeportal(1)
			end
		end
	
		if v.x2 ~= false then
			if (x == v.x2 or x == (v.x2 as number)+portal2xplus) and (y == v.y2 or y == (v.y2 as number)+portal2yplus) then--and (facing == nil or v.facing2 == facing) then
				v:removeportal(2)
			end
		end
	end
end

