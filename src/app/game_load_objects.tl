--[[ game_load object helpers / audio / UI bits ]]

global function drawreplay(...: any): any
	local args = {...}
	local j = args[1] as integer
	local i = args[2]
	local self = ((replaydata[j] as {string:any}).data as {any})[i as integer] as {string:any}
	local angleframe = 1
	
	if not self["drawable"] then
		return
	end
	
	if self["level"] ~= mariolevel or self["world"] ~= marioworld or self["sublevel"] ~= mariosublevel then
		return
	end
	
	local char = replaychar[j]
	
	if j == 1 and firstreplayblue then
		replaychar[j] = characters.mario
	end
	
	if replaychar[j].nopointing then
		angleframe = 1
	else
		angleframe = getAngleFrame(self["pointingangle"] as number, self["rotation"] as number) as integer
	end
	
	local animationstate = self["animationstate"]
	local size = self["size"]
	local quad: any = nil
	
	if (size as number) == 1 then
		if self["infunnel"] then
			quad = replaychar[j].jump[angleframe][self["jumpframe"] as integer]
		elseif self["underwater"] and (self["animationstate"] == "jumping" or self["animationstate"] == "falling") then
			quad = replaychar[j].swim[angleframe][self["swimframe"] as integer]
		elseif animationstate == "running" or animationstate == "falling" then
			quad = replaychar[j].run[angleframe][self["runframe"] as integer]
		elseif animationstate == "idle" then
			quad = replaychar[j].idle[angleframe]
		elseif animationstate == "sliding" then
			quad = replaychar[j].slide[angleframe]
		elseif animationstate == "jumping" then
			quad = replaychar[j].jump[angleframe][self["jumpframe"] as integer]
		elseif animationstate == "climbing" then
			quad = replaychar[j].climb[angleframe][self["climbframe"] as integer]
		elseif animationstate == "dead" then
			quad = replaychar[j].die[angleframe]
		elseif animationstate == "grow" then
			quad = replaychar[j].grow[angleframe]
		end
	elseif (size as number) > 1 then
		if self["infunnel"] then
			quad = replaychar[j].bigjump[angleframe][self["jumpframe"] as integer]
		elseif self["underwater"] and (self["animationstate"] == "jumping" or self["animationstate"] == "falling") then
			quad = replaychar[j].bigswim[angleframe][self["swimframe"] as integer]
		elseif self["ducking"] then
			quad = replaychar[j].bigduck[angleframe]
		elseif (self["fireanimationtimer"] as number) < fireanimationtime then
			quad = replaychar[j].bigfire[angleframe]
		else
			if animationstate == "running" or animationstate == "falling" then
				quad = replaychar[j].bigrun[angleframe][self["runframe"] as integer]
			elseif animationstate == "idle" then
				quad = replaychar[j].bigidle[angleframe]
			elseif animationstate == "sliding" then
				quad = replaychar[j].bigslide[angleframe]
			elseif animationstate == "climbing" then
				quad = replaychar[j].bigclimb[angleframe][self["climbframe"] as integer]
			elseif animationstate == "jumping" then
				quad = replaychar[j].bigjump[angleframe][self["jumpframe"] as integer]
			end
		end
	end
	
	local graphic: any = nil
	local biggraphic = replaychar[j].nogunbiganimations
	if (self["size"] as number) == 1 then
		graphic = replaychar[j].nogunanimations
	else
		graphic = replaychar[j].nogunbiganimations
	end
	
	if self["customscissor"] then
		local cs = self["customscissor"] as {number}
		love.graphics.setScissor(math.floor((cs[1]-xscroll)*16*scale), math.floor((cs[2]-.5-yscroll)*16*scale), cs[3]*16*scale, cs[4]*16*scale)
	end
	
	if true then
		self["pointingangle"] = -math.pi
		if self["animationdirection"] == "left" then
			self["pointingangle"] = math.pi
		end
	end
	
	drawplayer(nil, ((self["x"] as number)-xscroll+6/16)*16, (self["y"] as number)*16, scale, self["offsetX"], self["offsetY"], self["rotation"], self["quadcenterX"], self["quadcenterY"], self["animationstate"], self["underwater"], self["ducking"], self["hats"], graphic, quad, self["pointingangle"], self["shot"], self["upsidedown"], self["colors"], self["lastportal"], self["portal1color"], self["portal2color"], self["runframe"], self["swimframe"], self["climbframe"], self["jumpframe"], biggraphic, self["fireanimationtimer"], replaychar[j])
	love.graphics.setScissor()
	replaychar[j] = char
end

global function drawplayer(...: any): any
	local i, x, y, cscale, offsetX, offsetY, rotation, quadcenterX, quadcenterY, animationstate, underwater, ducking, hats, graphic, quad, pointingangle, shot, upsidedown, colors, lastportal, portal1color, portal2color, runframe, swimframe, climbframe, jumpframe, biggraphic, fireanimationtimer, char = ...
	x = (x as number)-6

	local scale = scale
	if cscale then
		scale = cscale as number
	end
	
	local v
	
	if not offsetX then
		v = playerobjs[i]
	else
		v = {offsetX=offsetX, offsetY=offsetY, rotation=rotation, quadcenterX=quadcenterX, quadcenterY=quadcenterY, animationstate=animationstate, underwater=underwater, ducking=ducking, hats=hats, graphic=graphic, quad=quad, pointingangle=pointingangle, shot=shot, upsidedown=upsidedown, colors=colors, lastportal=lastportal, portal1color=portal1color, portal2color=portal2color, runframe=runframe, swimframe=swimframe, climbframe=climbframe, jumpframe=jumpframe, biggraphic=biggraphic, fireanimationtimer=fireanimationtimer, char=char}
		if v.char and v.graphic == v.char.biggraphic then
			v.size = 2
		else
			v.size = 1
		end
	end
	
	if (not objects or not playerobjs[i] or playerobjs[i].portalsavailable[1] or playerobjs[i].portalsavailable[2]) then
		if v.pointingangle > 0 then
			dirscale = -scale
		else
			dirscale = scale
		end
	else
		if playerobjs[i].animationdirection == "right" then
			dirscale = scale
		else
			dirscale = -scale
		end
	end
	
	local horscale = scale
	if v.shot or v.upsidedown then
		horscale = -scale
	end
	
	if type(v.graphic) == "table" then
		for k = 1, #v.graphic do
			if v.colors[k] then
				love.graphics.setColor(v.colors[k])
			else
				love.graphics.setColor(1, 1, 1)
			end
			love.graphics.draw(v.graphic[k], v.quad, math.floor((x+v.offsetX)*scale), math.floor((y-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
		end
	else
		if v.graphic and v.quad then
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(v.graphic, v.quad, math.floor((x+v.offsetX)*scale), math.floor((y-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
		end	
	end
	
	
	if v.drawhat ~= false then
		local offsets = gethatoffset(v.char, v.graphic, v.animationstate, v.runframe, v.jumpframe, v.climbframe, v.swimframe, v.underwater, v.infunnel, v.fireanimationtimer, v.ducking)
		
		if offsets and #v.hats > 0 then
			local yadd: number = 0
			for i = 1, #v.hats do
				if v.hats[i] ~= 0 then
					if v.hats[i] == 1 then
						love.graphics.setColor(v.colors[1])
					else
						love.graphics.setColor(1, 1, 1)
					end
					if v.graphic == v.biggraphic or v.animationstate == "grow" then
						love.graphics.draw(bighat[v.hats[i]].graphic, math.floor((x+v.offsetX)*scale), math.floor((y-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX - bighat[v.hats[i]].x + offsets[1], v.quadcenterY - bighat[v.hats[i]].y + offsets[2] + yadd)
						yadd = yadd + bighat[v.hats[i]].height
					else
						local debugtable: {number:any} = {x, v.offsetX, y, v.offsetY, v.quadcenterX, hat[v.hats[i]].x, offsets[1], v.quadcenterY, hat[v.hats[i]].y, offsets[2], yadd}
						--TIMETRIAL
						for i, v in pairs(debugtable) do
							if type(v) == "table" then
								return
							end
						end
						
						love.graphics.draw(hat[v.hats[i]].graphic, math.floor((x+v.offsetX)*scale), math.floor((y-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX - hat[v.hats[i]].x + offsets[1], v.quadcenterY - hat[v.hats[i]].y + offsets[2] + yadd)
						yadd = yadd + hat[v.hats[i]].height
					end
				end
			end
		end
	end
	
	if type(v.graphic) == "table" then
		if v.graphic[0] then
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(v.graphic[0], v.quad, math.floor((x+v.offsetX)*scale), math.floor((y-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
		end
		if v.graphic.dot then
			love.graphics.setColor(unpack(v["portal" .. v.lastportal .. "color"]))
			love.graphics.draw(v.graphic["dot"], v.quad, math.floor((x+v.offsetX)*scale), math.floor((y-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
		end	
	end
end

global function reachedx(...: any): any
	local currentx = (... as number)
	if not currentx or currentx <= (lastrepeat as number)+width then
		return
	end
	
	lastrepeat = math.floor(currentx)-width
	--castlerepeat?
	--get mazei
	local mazei = 0
	
	for j = 1, #mazeends do
		if mazeends[j] < currentx then
			mazei = j
		end
	end
	
	--check if maze was solved!
	for i = 1, players do
		if playerobjs[i].mazevar == mazegates[mazei] then
			local actualmaze = 0
			for j = 1, #mazestarts do
				if playerobjs[i].x > mazestarts[j] then
					actualmaze = j
				end
			end
			mazesolved[actualmaze] = true
			for j = 1, players do
				playerobjs[j].mazevar = 0
			end
			break
		end
	end
	
	if not mazesolved[mazei] or mazeinprogress then --get if inside maze
		if not mazesolved[mazei] then
			mazeinprogress = true
		end
		
		local x = math.ceil(currentx)
		
		if repeatX == 0 then -- any
			repeatX = mazestarts[mazei]
		end
		
		table.insert(map, x as integer, {{1}, {1}, {1}, {1}, {1}, {1}, {1}, {1}, {1}, {1}, {1}, {1}, {1}, {1}, {1}} as {MapCell})
		table.insert(coinmap, x as integer, {})
		for y = 1, mapheight do
			local cell = map[x][y] as Dyn
			local src = map[repeatX as number][y] as Dyn
			for j = 1, #(map[repeatX as number][y] as {any}) do
				cell[j] = src[j]
				coinmap[x][y] = coinmap[repeatX as number][y]
			end
			cell["gels"] = {}
			cell["portaloverride"] = {}
			
			for cox = mapwidth, x, -1 do
				--move objects
				if objects["tile"][tilekey(cox, y)] then
					objects["tile"][tilekey(cox + 1, y)] = tile:new(cox, y-1) as Entity
					objects["tile"][tilekey(cox, y)] = nil
				end
			end
			
			--create object for block
			if tilequads[map[repeatX as number][y][1]]:getproperty("collision", repeatX, y) then
				objects["tile"][tilekey(x, y)] = tile:new(x-1, y-1) as Entity
			end
		end
		mapwidth = mapwidth + 1
		repeatX = (repeatX as number) + 1
		if flagx then
			flagx = (flagx as number) + 1
			flagimgx = flagimgx + 1
			objects["screenboundary"]["flag"].x = objects["screenboundary"]["flag"].x + 1
		end
		
		if axex then
			axex = (axex as number) + 1
			objects["screenboundary"]["axe"].x = objects["screenboundary"]["axe"].x + 1
		end
		
		if firestartx then
			firestartx = (firestartx as number) + 1
		end
		
		objects["screenboundary"]["right"].x = objects["screenboundary"]["right"].x + 1
		
		--move mazestarts and ends
		for i = 1, #mazestarts do
			mazestarts[i] = mazestarts[i]+1
			mazeends[i] = mazeends[i]+1
		end
		
		--check for endblock
		local x = math.ceil(currentx)
		for y = 1, mapheight do
			if map[x][y][2] and entitylist[map[x][y][2]].t == "mazeend" then
				if mazesolved[mazei] then
					repeatX = mazestarts[mazei+1]
				end
				mazeinprogress = false
			end
		end
		
		--reset thingie
		
		local x = math.ceil(currentx)-1
		for y = 1, mapheight do
			if map[x][y][2] and entitylist[map[x][y][2]].t == "mazeend" then
				for j = 1, players do
					playerobjs[j].mazevar = 0
				end
			end
		end
	end
	
	--ENEMY STUFF
	--[[if editormode == false and currentx < mapwidth then
		for y = 1, mapheight do
			spawnenemy(currentx, y)
		end
		if goombaattack then
			local randomtable = {}
			for y = 1, mapheight do
				table.insert(randomtable, y)
			end
			while #randomtable > 0 do
				local rand = math.random(#randomtable)
				if tilequads[map[currentx][randomtable[rand] ][1] ]:getproperty("collision", currentx, randomtable[rand]) then
					table.remove(randomtable, rand)
				else
					table.insert(objects["goomba"], goomba:new(currentx-.5, math.random(13)))
					break
				end
			end
		end
	end--]]
end

global function properprint2(...: any): any
	local s, x, y = ...
	for i = 1, string.len(tostring(s)) do
		if fontquads[string.sub(s as string, i, i)] then
			love.graphics.draw(fontimage2, font2quads[string.sub(s as string, i, i)], (x as number)+((i-1)*4)*scale, y as number, 0, scale, scale)
		end
	end
end

global function playsound(...: any): any
	local sound = ...
	if not soundlist[sound] then
		return
	end

	if soundenabled then
		if delaylist[sound as string] then
			local currenttime = love.timer.getTime()
			if currenttime-(soundlist[sound as string].lastplayed as number) > (delaylist[sound as string] as number) then
				soundlist[sound].lastplayed = currenttime
			else
				return
			end
		end
		
		soundlist[sound].source:stop()
		soundlist[sound].source:seek(0)
		soundlist[sound].source:play()
	end
end

global function drawrectangle(x: any, y: any, width: any, height: any): any
	love.graphics.rectangle("fill", (x as number)*scale, (y as number)*scale, (width as number)*scale, scale)
	love.graphics.rectangle("fill", (x as number)*scale, (y as number)*scale, scale, (height as number)*scale)
	love.graphics.rectangle("fill", (x as number)*scale, ((y as number)+(height as number)-1)*scale, (width as number)*scale, scale)
	love.graphics.rectangle("fill", ((x as number)+(width as number)-1)*scale, (y as number)*scale, scale, (height as number)*scale)
end

global function playmusic(...: any): any
	if not editormode and musicname then
		if (mariotime as number) <= 99 and (mariotime as number) > 0 then
			music:play(musicname, true)
		else
			music:play(musicname)
		end
	end
end

global function stopmusic(...: any): any
	if musicname then
		if (mariotime as number) <= 99 and (mariotime as number) > 0 then
			music:stop(musicname, true)
		else
			music:stop(musicname)
		end
	end
end

global function updatesizes(...: any): any
	mariosizes = {}
	if not objects then
		for i = 1, players do
			mariosizes[i] = 1 as any
		end
	else
		for i = 1, players do
			mariosizes[i] = playerobjs[i].size
		end
	end
end

global function updateranges(...: any): any
	for i, v in pairs(objects["laser"]) do
		(v as Entity):updaterange()
	end
	for i, v in pairs(objects["lightbridge"]) do
		(v as Entity):updaterange()
	end
	for i, v in pairs(objects["funnel"]) do
		(v as Entity):updaterange()
	end
end

global function createdialogbox(...: any): any
	local text, speaker = ...
	dialogboxes = {}
	table.insert(dialogboxes, dialogbox:new(text, speaker) as Entity)
end

