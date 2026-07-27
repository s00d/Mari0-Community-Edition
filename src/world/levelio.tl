-- Level file load/save (extracted from game.lua).
-- Globals, mappack format, tile/entity encoding, and LOVE_COLOR_MAX are unchanged.
-- Pure helpers below are safe to exercise without LÖVE.

require "assets.spritebatch_util"

local unpack = rawget(_G, "unpack") or table.unpack
local math_mod = math.fmod

-- Filename convention: N-M.txt / N-M_S.txt (no extension).
global function level_filename(world: number|string, level: number|string, sublevel?: number): string
	local w = tostring(world)
	local l = tostring(level)
	if not sublevel or sublevel == 0 then
		return w .. "-" .. l
	end
	return w .. "-" .. l .. "_" .. tostring(sublevel)
end

global function mappack_path(name: string): string
	return "mappacks/" .. name
end

global function mappack_level_path(mappack_name: string, world: number|string, level: number|string, sublevel?: number): string
	return mappack_path(mappack_name) .. "/" .. level_filename(world, level, sublevel) .. ".txt"
end

global function level_name(world: number|string, level: number|string, sublevel?: number): string
	return level_filename(world, level, sublevel)
end

global function level_detect_format_version(s: string): integer
	return string.match(s, BLOCKDELIMITER[1]) and 1 or 2
end

global function level_delimiters(v: integer): string, string, string, string, string
	return BLOCKDELIMITER[v], LAYERDELIMITER[v], CATEGORYDELIMITER[v], MULTIPLYDELIMITER[v], EQUALSIGN[v]
end

-- Split raw level text into version, height, tile tokens, and category sections.
global function level_split_file_contents(s: string): integer, number, {string}, {string}, string, string, string, string, string
	local v = level_detect_format_version(s)
	local blockdelimiter, layerdelimiter, categorydelimiter, multipledelimiter, equalsign = level_delimiters(v)
	local s2 = strsplit(s, categorydelimiter)
	local mapheight: number
	local t: {string}
	if string.find(s2[1] as string, blockdelimiter) then
		mapheight = 15
		t = strsplit(s2[1], blockdelimiter)
	else
		mapheight = tonumber(s2[1]) or 15
		t = strsplit(s2[2], blockdelimiter)
	end
	return v, mapheight, t, s2, blockdelimiter, layerdelimiter, categorydelimiter, multipledelimiter, equalsign
end

global function level_count_tile_entries(t: {any}, multipledelimiter: string): number
	local entries: number = 0
	for i = 1, #t do
		local parts = strsplit(t[i] as string, multipledelimiter)
		if parts[2] then
			entries = entries + (tonumber(parts[2] as string) or 0)
		else
			entries = entries + 1
		end
	end
	return entries
end

-- Decode tile tokens into map/coinmap tables (no objects, no tile-ID clamp).
-- Column-major order matches loadmap (x then wrap to next y).
global function level_decode_tile_tokens(t: {any}, mapwidth: number, mapheight: number, layerdelimiter: string, multipledelimiter: string): {number:{number:MapCell}}, {number:{number:boolean}}
	local map: {number:{number:MapCell}} = {}
	local coinmap: {number:{number:boolean}} = {}
	for x = 1, mapwidth do
		map[x] = {}
		coinmap[x] = {}
		for y = 1, mapheight do
			map[x][y] = {}
		end
	end

	local x, y = 1, 1
	for i = 1, #t do
		if string.find(t[i] as string, multipledelimiter) then
			local r = strsplit(tostring(t[i]), multipledelimiter)
			local coin = false
			if string.sub(r[1] as string, -1) == "c" then
				r[1] = string.sub(r[1] as string, 1, -2)
				coin = true
			end
			for _ = 1, tonumber(r[2]) do
				if coin then
					coinmap[x][y] = true
				end
				map[x][y][1] = tonumber(r[1])
				x = x + 1
				if x > mapwidth then
					x = 1
					y = y + 1
				end
			end
		else
			local r = strsplit(tostring(t[i]), layerdelimiter)
			if string.sub(r[1] as string, -1) == "c" then
				r[1] = string.sub(r[1] as string, 1, -2)
				coinmap[x][y] = true
			end
			for li = 1, #r do
				if tonumber(r[li]) then
					map[x][y][li] = tonumber(r[li])
				else
					map[x][y][li] = r[li]
				end
			end
			x = x + 1
			if x > mapwidth then
				x = 1
				y = y + 1
			end
		end
	end
	return map, coinmap
end

-- Pure tile-body serializer (same run-length / layer encoding as savemap).
global function level_serialize_maptiles(m: {number:{number:MapCell}}, cm: {number:{number:any}}, mw: number, mh: number, v: integer): string
	local s = ""
	local mul = 1
	local prev: string|nil = nil

	for y = 1, mh do
		for x = 1, mw do
			local cell = m[x][y]
			local current = tostring(cell[1]) .. (cm[x][y] and "c" or "")

			--check if previous is the same
			if #cell == 1 then
				if prev == current and (y ~= mh or x ~= mw) then
					mul = mul + 1
				elseif prev == current and y == mh and x == mw then
					mul = mul + 1
					s = s .. (prev as string) .. MULTIPLYDELIMITER[v] .. mul
				else
					if prev then
						if mul > 1 then
							s = s .. (prev as string) .. MULTIPLYDELIMITER[v] .. mul
						else
							s = s .. (prev as string)
						end

						if y ~= mh or x ~= mw then
							s = s .. BLOCKDELIMITER[v]
						end
					end
					prev = current
					mul = 1
					if y == mh and x == mw then
						if prev then
							s = s .. BLOCKDELIMITER[v]
						end
						s = s .. (prev as string)
					end
				end
			else
				if prev then
					if mul > 1 then
						s = s .. (prev as string) .. MULTIPLYDELIMITER[v] .. mul
					else
						s = s .. (prev as string)
					end

					s = s .. BLOCKDELIMITER[v]
				end
				prev = nil
				mul = 1

				for i = 1, #cell do
					local entry = cell[i]
					local n = tonumber(entry)
					if n and n < 0 then
						s = s .. "m" .. tostring(math.abs(n))
					else
						s = s .. tostring(entry)
					end

					if i == 1 and cm[x][y] then
						s = s .. "c"
					end

					if i ~= #cell then
						s = s .. LAYERDELIMITER[v]
					end
				end

				if y ~= mh or x ~= mw then
					s = s .. BLOCKDELIMITER[v]
				end
			end
		end
	end
	return s
end

-- Parse a full level string into map/coinmap/dimensions (no LÖVE / no entities).
global function level_parse_tiles_only(s: string): LevelTilesParse|nil, string|nil
	local v, mapheight, t, s2, _, layerdelimiter, _, multipledelimiter, equalsign = level_split_file_contents(s)
	mapheight = mapheight or 15
	local entries = level_count_tile_entries(t, multipledelimiter)
	if math_mod(entries, mapheight) ~= 0 then
		return nil, "Incorrect number of entries: " .. #t
	end
	local mapwidth = entries / mapheight
	local decoded_map, decoded_coinmap = level_decode_tile_tokens(t, mapwidth, mapheight, layerdelimiter, multipledelimiter)
	return {
		v = v,
		mapwidth = mapwidth,
		mapheight = mapheight,
		map = decoded_map,
		coinmap = decoded_coinmap,
		categories = s2,
		equalsign = equalsign,
	}
end


global function loadmap(filename: string, createobjects?: boolean): boolean
	print("**************************" .. string.rep("*", #((mappack as string) .. filename)))
	local s: string|nil = nil
	if mappackendless then
		-- Fixed arena stitch; seed shown in console / endlessseed.
		local seed = endlessseed
		if not seed or seed == 0 then
			seed = math.floor((os.time() % 1000000) + (os.clock() * 1000))
		end
		local gen = endless_generate_for_mappack(mappack as string, seed as number)
		endlessseed = gen["seed"] as number
		s = gen["level_text"] as string
		print("* Endless seed " .. tostring(gen["seed"]) .. "  arena " .. tostring(gen["mapwidth"]) .. "x" .. tostring(gen["mapheight"]) .. " *")
	else
		local level_path = mappack_path(mappack as string) .. "/" .. filename .. ".txt"
		print("* Loading " .. level_path .. " *")
		if not love.filesystem.getInfo(level_path) then
			print(level_path .. " not found!")
			return false
		end
		s = love.filesystem.read(level_path)
	end

	local _, parsed_height, t, s2, _, layerdelimiter, _, multipledelimiter, equalsign = level_split_file_contents(s as string)
	mapheight = parsed_height
	
	map = {}
	unstatics = {}
	
	create_tile_spritebatches()
	
	--get mapwidth
	local entries = level_count_tile_entries(t, multipledelimiter)
	
	mapheight = mapheight or 15
	if math.fmod(entries, mapheight) ~= 0 then
		print("Incorrect number of entries: " .. #t)
		return false
	end
	
	mapwidth = entries / mapheight
	coinmap = {}
	
	for x = 1, mapwidth do
		map[x] = {}
		coinmap[x] = {}
		for y = 1, mapheight do
			map[x][y] = {} as MapCell
			init_map_cell_gels(map[x][y])
			map[x][y]["portaloverride"] = {}
		end
	end
	
	local x, y = 1, 1
	for i = 1, #t do
		if string.find(t[i], multipledelimiter) then --new stuff!
			local r = strsplit(tostring(t[i]), multipledelimiter)
			
			local coin = false
			if string.sub(r[1] as string, -1) == "c" then
				r[1] = string.sub(r[1] as string, 1, -2)
				coin = true
			end
			
			for _ = 1, tonumber(r[2]) do
				if coin then
					coinmap[x][y] = true
				end
			
				if (tonumber(r[1]) > smbtilecount+portaltilecount+customtilecount+(modcustomtilecount[modcustomtiles as integer] or 0) and tonumber(r[1]) <= 10000) or tonumber(r[1]) > 10000+animatedtilecount then
					r[1] = "1"
				end
				
				map[x][y][1] = tonumber(r[1])
				
			
				--create object for block
				if createobjects and tilequads[tonumber(r[1])]:getproperty("collision", x, y) == true then
					objects["tile"][tilekey(x, y)] = tile:new(x-1, y-1) as Entity
				end
				
				x = x + 1
				if x > mapwidth then
					x = 1
					y = y + 1
				end
			end
			
		else --Old stuff.
			local r = strsplit(tostring(t[i]), layerdelimiter)
			
			if string.sub(r[1] as string, -1) == "c" then
				r[1] = string.sub(r[1] as string, 1, -2)
				coinmap[x][y] = true
			end
			
			if (tonumber(r[1]) > smbtilecount+portaltilecount+customtilecount+(modcustomtilecount[modcustomtiles as integer] or 0) and tonumber(r[1]) <= 10000) or tonumber(r[1]) > 10000+animatedtilecount then
				r[1] = "1"
			end
			
			for i = 1, #r do
				if tonumber(r[i]) then
					map[x][y][i] = tonumber(r[i])
				else
					map[x][y][i] = r[i]
				end
			end
			
			--create object for block
			if createobjects and tilequads[tonumber(r[1])]:getproperty("collision", x, y) == true then
				objects["tile"][tilekey(x, y)] = tile:new(x-1, y-1) as Entity
			end
			
			x = x + 1
			if x > mapwidth then
				x = 1
				y = y + 1
			end
		end
	end
	
	--ANIMATED TIMERS
	animatedtimers = {}
	animatedbooltimers = {}
	for x = 1, mapwidth do
		animatedtimers[x] = {}
		animatedbooltimers[x] = {}
	end

	for i = 1, #animatedtiles do
		if animatedtiles[i].cache then
			animatedtiles[i].cache = {}
		end
	end
	
	for y = 1, mapheight do
		for x = 1, mapwidth do
			local r = map[x][y]
			
			if (r[1] as number) > 10000 then
				if tilequads[r[1]].triggered then
					animatedtimers[x][y] = animatedtimer:new(x, y, r[1])
				elseif  tilequads[r[1]].boolean then
					animatedbooltimers[x][y] = animatedbooltimer:new(x, y, r[1])
				elseif tilequads[r[1]].cache then
					table.insert((tilequads[r[1]] as animatedquad).cache as {any}, {x=x,y=y})
				end
			end
			
			if tilequads[r[1] ]:getproperty("coin", x, y) then
				coinmap[x][y] = true
			end
			
			if #r > 1 then 
				if entitylist[r[2]] then
					local et = entitylist[r[2]].t
					dispatch_map_entity_spawn(et, x, y, r, createobjects, editormode)
				end
			end
		end
	end
	
	-- Pair start/end markers into zones (supports multiple fish/bullet zones per level)
	flyingfishzones = buildstartendzones(flyingfishstarts, flyingfishends)
	bulletbillzones = buildstartendzones(bulletbillstarts, bulletbillends)
	
	if createobjects then
		--Add links
		for _, v in pairs(objects) do
			for _, w in pairs(v) do
				if w.link then
					w:link()
				end
			end
		end
		
		--emancipation links
		for _, v in pairs(emancipationgrills) do
			v:link()
		end
		
		--textlinks
		for _, v in pairs(textentities) do
			v:link()
		end
	end
	
	if flagx then
		flagimgx = (flagx as number)+8/16
		flagimgy = flagy-10+1/16
	end
	
	for x = 0, -30, -1 do
		map[x] = {}
		for y = 1, mapheight-2 do
			map[x][y] = {1} as MapCell
		end
		
		for y = mapheight-1, mapheight do
			map[x][y] = {2} as MapCell
			if createobjects then
				objects["tile"][tilekey(x, y)] = tile:new(x-1, y-1) as Entity
			end
		end
	end
	
	--background
	background = {unpack(backgroundcolor[1] as {any})} as {number}
	custombackground = false
	
	--portalgun
	portalsavailable = {true, true}
	levelweapons = {} as {string}
	
	levelscreenback = nil
	levelscreenbackname = nil
	
	--MORE STUFF
	for i = 3, #s2 do
		s3 = strsplit(s2[i], equalsign)
		if s3[1] == "backgroundr" then
			background[1] = (tonumber(s3[2] as string) or 0) / 255
		elseif s3[1] == "backgroundg" then
			background[2] = (tonumber(s3[2] as string) or 0) / 255
		elseif s3[1] == "backgroundb" then
			background[3] = (tonumber(s3[2] as string) or 0) / 255
		elseif s3[1] == "background" then
			background = {unpack(backgroundcolor[tonumber(s3[2] as string) as integer] as {any})} as {number}
		elseif s3[1] == "spriteset" then
			spriteset = tonumber(s3[2]) as integer
		elseif s3[1] == "intermission" then
			intermission = true
		elseif s3[1] == "haswarpzone" then
			haswarpzone = true
		elseif s3[1] == "underwater" then
			underwater = true
		elseif s3[1] == "music" then
			if tonumber(s3[2]) then
				local mi = tonumber(s3[2])
				musicname = musiclist[mi as integer] as string
			else
				musicname = s3[2]
			end
		elseif s3[1] == "bonusstage" then
			bonusstage = true
		elseif s3[1] == "custombackground" or s3[1] == "portalbackground" then
			custombackground = true
			if s3[2] and custombackgroundimg[s3[2]] then
				custombackground = s3[2]
			end
		elseif s3[1] == "customforeground" then
			customforeground = true
			if s3[2] and custombackgroundimg[s3[2]] then
				customforeground = s3[2]
			end
		elseif s3[1] == "timelimit" then
			mariotimelimit = tonumber(s3[2])
		elseif s3[1] == "scrollfactor" then
			scrollfactor = tonumber(s3[2])
		elseif s3[1] == "fscrollfactor" then
			fscrollfactor = tonumber(s3[2])
		elseif s3[1] == "portalgun" then
			if s3[2] == "none" then
				portalsavailable = {false, false}
			elseif s3[2] == "blue" then
				portalsavailable = {true, false}
			elseif s3[2] == "orange" then
				portalsavailable = {false, true}
			end
		elseif s3[1] == "weapons" then
			-- optional: weapons=portal,gravitygun
			levelweapons = {}
			local parts = strsplit(s3[2] as string, ",")
			for i = 1, #parts do
				local id = (parts[i] as string):match("^%s*(.-)%s*$")
				if id and id ~= "" then
					table.insert(levelweapons as {string}, id)
				end
			end
		elseif s3[1] == "levelscreenback" then
			local screen_path = mappack_path(mappack) .. "/levelscreens/" .. s3[2] .. ".png"
			if love.filesystem.getInfo(screen_path) then
				levelscreenbackname = s3[2]
				levelscreenback = {}
				levelscreenback = AssetStore.load_image(screen_path)
			end
		end
	end
	
	print("* DONE!" .. string.rep(" ", #((mappack as string) .. filename)+17) .. " *")
	print("**************************" .. string.rep("*", #((mappack as string) .. filename)))
	return true
end

global function savemap(filename: string, silent?: boolean)
	local v = 1
	local s = mapheight .. CATEGORYDELIMITER[v] .. level_serialize_maptiles(map, coinmap, mapwidth, mapheight, v)
	
	--options
	s = s .. CATEGORYDELIMITER[v] .. "backgroundr" .. EQUALSIGN[v] ..  background[1] * 255
	s = s .. CATEGORYDELIMITER[v] .. "backgroundg" .. EQUALSIGN[v] ..  background[2] * 255
	s = s .. CATEGORYDELIMITER[v] .. "backgroundb" .. EQUALSIGN[v] ..  background[3] * 255
	s = s .. CATEGORYDELIMITER[v] .. "spriteset" .. EQUALSIGN[v] .. tostring(spriteset)
	if musicname then
		s = s .. CATEGORYDELIMITER[v] .. "music" .. EQUALSIGN[v] ..  musicname
	end
	if intermission then
		s = s .. CATEGORYDELIMITER[v] .. "intermission"
	end
	if bonusstage then
		s = s .. CATEGORYDELIMITER[v] .. "bonusstage"
	end
	if haswarpzone then
		s = s .. CATEGORYDELIMITER[v] .. "haswarpzone"
	end
	if underwater then
		s = s .. CATEGORYDELIMITER[v] .. "underwater"
	end
	if custombackground then
		if custombackground == true then
			s = s .. CATEGORYDELIMITER[v] .. "custombackground"
		else
			s = s .. CATEGORYDELIMITER[v] .. "custombackground" .. EQUALSIGN[v] .. tostring(custombackground)
		end
	end
	if customforeground then
		if customforeground == true then
			s = s .. CATEGORYDELIMITER[v] .. "customforeground"
		else
			s = s .. CATEGORYDELIMITER[v] .. "customforeground" .. EQUALSIGN[v] .. tostring(customforeground)
		end
	end
	s = s .. CATEGORYDELIMITER[v] .. "timelimit" .. EQUALSIGN[v] ..  mariotimelimit
	s = s .. CATEGORYDELIMITER[v] .. "scrollfactor" .. EQUALSIGN[v] ..  scrollfactor
	s = s .. CATEGORYDELIMITER[v] .. "fscrollfactor" .. EQUALSIGN[v] ..  fscrollfactor
	if not portalsavailable[1] or not portalsavailable[2] then
		local ptype = "none"
		if portalsavailable[1] then
			ptype = "blue"
		elseif portalsavailable[2] then
			ptype = "orange"
		end
		
		s = s .. CATEGORYDELIMITER[v] .. "portalgun" .. EQUALSIGN[v] ..  ptype
	end
	if levelweapons and #(levelweapons as {any}) > 0 then
		local ws = table.concat(levelweapons as {string}, ",")
		s = s .. CATEGORYDELIMITER[v] .. "weapons" .. EQUALSIGN[v] .. ws
	end
	
	if levelscreenbackname then
		s = s .. CATEGORYDELIMITER[v] .. "levelscreenback" .. EQUALSIGN[v] .. tostring(levelscreenbackname)
	end
	
	--tileset
	
	love.filesystem.createDirectory( "mappacks" )
	love.filesystem.createDirectory( mappack_path(mappack) )
	
	local level_path = mappack_path(mappack as string) .. "/" .. filename .. ".txt"
	love.filesystem.write(level_path, s)
	
	--preview
	
	previewimg = renderpreview()
	previewimg:encode("png", mappack_path(mappack as string) .. "/" .. filename .. ".png")
	
	if not silent then
		print("Map saved as " .. level_path)
		notice.new("Map saved!", notice.white, 2)
	end
end

global function renderpreview(): ImageData
	local out = love.image.newImageData(mapwidth, height+1)
	
	--find startpoint
	local starty = 13
	
	for x = 1, mapwidth do
		for y = 1, mapheight do
			if map[x][y][2] and entitylist[map[x][y][2]] and entitylist[map[x][y][2]].t == "spawn" then
				starty = y as integer
				break
			end
		end
	end
	
	yadd = math.max(0, math.min(mapheight-height-1, starty-math.floor(height/2)))
	
	for x = 1, mapwidth do --blocks
		for y = 1, 15 do
			local id = map[x][y+yadd][1]
			if id ~= nil and id ~= 0 and rgblist[id] and tilequads[id]:getproperty("invisible", x, y+yadd) == false then
				local r, g, b = unpack(rgblist[id] as {any})
				out:setPixel(x-1, y-1, (r as number) * LOVE_COLOR_MAX, (g as number) * LOVE_COLOR_MAX, (b as number) * LOVE_COLOR_MAX, LOVE_COLOR_MAX)
			else
				local r, g, b = unpack(background as {any})
				out:setPixel(x-1, y-1, (r as number) * LOVE_COLOR_MAX, (g as number) * LOVE_COLOR_MAX, (b as number) * LOVE_COLOR_MAX, LOVE_COLOR_MAX)
			end
		end
	end
	
	return out
end

global function savelevel()
	savemap(level_filename(marioworld, mariolevel, mariosublevel))
end
