--[[ Editor map I/O: resize, maps list, multitile files (extracted from editor.tl). ]]

function loadmtobjects()
	-- get multitile objects!
	multitileobjects = nil
	multitileobjects = {}
	multitileobjectnames = nil
	multitileobjectnames = {}
	if love.filesystem.getInfo(mappack_path(mappack) .. "/objects.txt") then
		local data = ((love.filesystem.read(mappack_path(mappack) .. "/objects.txt")) or "") as string
		if #data > 0 then
			data = string.sub(data, 1, -2)
			--print(data)
			local split1 = strsplit(data, "\n")
			local split2: {string} = {}
			local split3: {string} = {}
			for i = 1, #split1 do
				-- objects
				split2 = strsplit(split1[i], "=") as {string}
				table.insert(multitileobjectnames, split2[1])
				-- rows
				if string.find(split1[i] as string,":") then
					split3 = strsplit(split2[2], ":") as {string}
				else
					split3 = {split2[2]}
				end
				local ox = {}
				local oo = {}
				for j = 1, #split3 do
					ox = {}
					local split4 = strsplit(split3[j], ",")
					for u = 1, #split4 do
						table.insert(ox, tonumber(split4[u]))
						--print(split4[u]..",")
					end
					table.insert(oo, ox)
					--print(":")
				end
				table.insert(multitileobjects, oo)
			end
		end
	end
end

function loadmtgroups()
	multitilegroups = nil
	multitilegroups = {}
	if love.filesystem.getInfo(mappack_path(mappack) .. "/groups.txt") then
		local data = ((love.filesystem.read(mappack_path(mappack) .. "/groups.txt")) or "") as string
		if #data > 0 then
			data = string.sub(data, 1, -2)
			local split1 = strsplit(data, "\n")
			local split2: {string} = {}
			local split3: {string} = {}
			for i = 1, #split1 do
				-- groups
				split2 = strsplit(split1[i], "=") as {string}
				-- rows
				if string.find(split1[i] as string,":") then
					split3 = strsplit(split2[2], ":") as {string}
				else
					split3 = {split2[2]}
				end
				local ox = {}
				local oo = {}
				for j = 1, #split3 do
					ox = {}
					local split4 = strsplit(split3[j], ",")
					for u = 1, #split4 do
						table.insert(ox, tonumber(split4[u]))
					end
					table.insert(oo, ox)
				end
				multitilegroups[split2[1]] = oo
			end
		end
	end
end

function openchangewidth()
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["maptopup"].active = true
	guielements["maptopdown"].active = true
	guielements["mapbottomup"].active = true
	guielements["mapbottomdown"].active = true
	guielements["mapleftleft"].active = true
	guielements["mapleftright"].active = true
	guielements["maprightleft"].active = true
	guielements["maprightright"].active = true
	guielements["mapwidthapply"].active = true
	guielements["mapwidthcancel"].active = true

	changemapwidthmenu = true
	newmapwidth = session.mapwidth
	newmapheight = session.mapheight
	newmapoffsetx = 0
	newmapoffsety = 0
end

function mapwidthapply()
	changemapwidthmenu = false
	session.objects["tile"] = {}
	
	local newmap = {}
	local newcoinmap = {}
	for x = 1, newmapwidth do
		newmap[x] = {}
		newcoinmap[x] = {}
		for y = 1, newmapheight do
			local oldx, oldy = x-newmapoffsetx, y-newmapoffsety
			if inmap(oldx, oldy) then
				newmap[x][y] = session.map[oldx][oldy]
				newcoinmap[x][y] = session.coinmap[oldx][oldy]
			else
				newmap[x][y] = {1, portaloverride={0, 0}}
				init_map_cell_gels(newmap[x][y] as MapCell)
			end
			
			if tilequads[newmap[x][y][1]]:getproperty("collision", x, y) then
				physics_world_set_tile(tilekey(x, y), tile:new(x-1, y-1, 1, 1, true) as Entity)
			end
		end
	end
	
	session.objects["player"][1].x = session.objects["player"][1].x + newmapoffsetx
	session.objects["player"][1].y = session.objects["player"][1].y + newmapoffsety
	
	session.xscroll = session.xscroll + newmapoffsetx
	session.yscroll = session.yscroll + newmapoffsety
	
	if session.xscroll < 0 then
		session.xscroll = 0
	end
	
	if session.xscroll > session.mapwidth-width then
		session.xscroll = math.max(0, session.mapwidth-width)
		hitrightside()
	end
	
	session.map = newmap
	session.coinmap = newcoinmap
	session.mapwidth = newmapwidth
	session.mapheight = newmapheight
	
	--Update animatedtimers
	animatedtimers = {}
	animatedbooltimers = {}
	for x = 1, session.mapwidth do
		if not animatedtimers[x] then
			animatedtimers[x] = {}
		end
	end
	for x = 1, session.mapwidth do
		if not animatedbooltimers[x] then
			animatedbooltimers[x] = {}
		end
	end
	
	--move all them links!
	for x = 1, session.mapwidth do
		for y = 1, session.mapheight do
			for i, v in pairs(session.map[x][y] as {any:any}) do
				if v == "link" then
					local ii = (i as number)
					session.map[x][y][(ii+2) as integer] = (session.map[x][y][(ii+2) as integer] as number) + newmapoffsetx
					session.map[x][y][(ii+3) as integer] = (session.map[x][y][(ii+3) as integer] as number) + newmapoffsety
				end
			end
		end
	end
	
	session.objects["screenboundary"]["right"].x = session.mapwidth
	physics_world_refresh()
	generatespritebatch(0, 0)
	
	--editorclose()
	
	maintab()
end

function mapwidthcancel()
	changemapwidthmenu = false
	--editorclose()
	maintab()
end

function changenewmapsize(side: any, dir: any)
	if side == "top" then
		if dir == "up" then
			newmapheight = newmapheight + 1
			newmapoffsety = newmapoffsety + 1
		else
			if newmapheight > 15 then
				newmapheight = newmapheight - 1
				newmapoffsety = newmapoffsety - 1
			end
		end
	elseif side == "bottom" then
		if dir == "up" then
			if newmapheight > 15 then
				newmapheight = newmapheight - 1
			end
		else
			newmapheight = newmapheight + 1
		end
	elseif side == "left" then
		if dir == "left" then
			newmapwidth = newmapwidth + 1
			newmapoffsetx = newmapoffsetx + 1
		else
			if newmapwidth > 1 then
				newmapwidth = newmapwidth - 1
				newmapoffsetx = newmapoffsetx - 1
			end
		end
	elseif side == "right" then
		if dir == "left" then
			if newmapwidth > 1 then
				newmapwidth = newmapwidth - 1
			end
		else
			newmapwidth = newmapwidth + 1
		end
	end
end


function mapnumberclick(i: number, j: number, k: any)
	if editormode then
		marioworld = tonumber(i) as number
		mariolevel = tonumber(j) as number
		editorloadopen = true
		local needs_to_be_saved = false
		if k then
			k = tonumber(k)
			needs_to_be_saved = loadlevel(i .. "-" .. j .. "_" .. (k as number))
		else
			needs_to_be_saved = loadlevel(i .. "-" .. j)
		end
		startlevel()
		if needs_to_be_saved then
			savelevel()
			getmaps()
		end
	end
end

function getmaps()
	existingmaps = {}
	largestworld = 0
	mapbuttons = {}
	local yadd: number = 2
	local worlds: number = 0
	local levels: number = 0
	local sublevels: number = 0
	local files = love.filesystem.getDirectoryItems(mappack_path(mappack))
	editor_filter_map_files(files)
	table.sort(files, mapsort)
	for i = 1, #files do
		if string.match(files[i], "(%d+)-(%d+).txt") then
			local ws, ls = string.match(files[i], "(%d+)-(%d+).txt")
			worlds = (tonumber(ws) or 0) as number
			levels = (tonumber(ls) or 0) as number
			sublevels = 0
			mapbuttons["text" .. worlds .. "-" .. levels] = guielement:new("text", 4, yadd+21, "world " .. worlds .. "-" .. levels)
			mapbuttons["text" .. worlds .. "-" .. levels].starty = yadd+21
			mapbuttons["plus" .. worlds .. "-" .. levels] = guielement:new("button", 62+(string.len(tostring(worlds))+string.len(tostring(levels)))*8, yadd+19, "+", mapnumberclick, 0, {worlds, levels, 1})
			mapbuttons["plus" .. worlds .. "-" .. levels].starty = yadd+19
			yadd = yadd + 10
			local mapkey = worlds .. "-" .. levels .. "_" .. (sublevels or 0)
			if love.filesystem.getInfo(mappack_path(mappack) .. "/" .. level_name(worlds, levels) .. ".png") then
				mapbuttons[mapkey] = guielement:new("button", 4, yadd+21, AssetStore.load_image(mappack_path(mappack) .. "/" .. level_name(worlds, levels) .. ".png"), mapnumberclick, 0, {worlds, levels})
			else
				mapbuttons[mapkey] = guielement:new("button", 4, yadd+21, "no preview", mapnumberclick, 0, {worlds, levels})
			end
			mapbuttons[mapkey].starty = yadd+21
			yadd = yadd + 20
			if largestworld < worlds then
				largestworld = worlds
			end
			if existingmaps[worlds] == nil or (existingmaps[worlds] as number) < levels then
				existingmaps[worlds] = levels
			end
		elseif string.match(files[i], "(%d+)-(%d+)_(%d+).txt") then
			local ws, ls, ss = string.match(files[i], "(%d+)-(%d+)_(%d+).txt")
			worlds = (tonumber(ws) or 0) as number
			levels = (tonumber(ls) or 0) as number
			sublevels = (tonumber(ss) or 0) as number
			if not mapbuttons["text" .. worlds .. "-" .. levels] then
				mapbuttons["text" .. worlds .. "-" .. levels] = guielement:new("text", 4, yadd+21, "world " .. worlds .. "-" .. levels, {0.5, 0.5, 0.5})
				mapbuttons["text" .. worlds .. "-" .. levels].starty = yadd+21
				mapbuttons["plus" .. worlds .. "-" .. levels] = guielement:new("button", 62+(string.len(tostring(worlds))+string.len(tostring(levels)))*8, yadd+19, "+", mapnumberclick, 0, {worlds, levels, (sublevels as number) + 1})
				mapbuttons["plus" .. worlds .. "-" .. levels].starty = yadd+19
				yadd = yadd + 10
			end
			mapbuttons["text" .. worlds .. "-" .. levels .. "_" .. sublevels] = guielement:new("text", 4, yadd+26, "sub " .. sublevels, {0.5, 0.5, 0.5})
			mapbuttons["text" .. worlds .. "-" .. levels .. "_" .. sublevels].starty = yadd+26
			if love.filesystem.getInfo(mappack_path(mappack) .. "/" .. worlds .. "-" .. levels .. "_" .. sublevels ..".png") then
				mapbuttons[worlds .. "-" .. levels .. "_" .. sublevels] = guielement:new("button", 54, yadd+21, AssetStore.load_image(mappack_path(mappack) .. "/" .. level_name(worlds, levels, sublevels) .. ".png"), mapnumberclick, 0, {worlds, levels, sublevels})
				mapbuttons[worlds .. "-" .. levels .. "_" .. sublevels].starty = yadd+21
			else
				mapbuttons[worlds .. "-" .. levels .. "_" .. sublevels] = guielement:new("button", 54, yadd+21, "no preview", mapnumberclick, 0, {worlds, levels, sublevels})
				mapbuttons[worlds .. "-" .. levels .. "_" .. sublevels].starty = yadd+24
			end
			yadd = yadd + 20
			
			if mapbuttons["plus" .. worlds .. "-" .. levels] and (mapbuttons["plus" .. worlds .. "-" .. levels].arguments[3] as number) < (sublevels as number) + 1 then
				mapbuttons["plus" .. worlds .. "-" .. levels].arguments[3] = (sublevels as number) + 1
			end
		end
	end

	mapsymissing = math.max(0, yadd-200)
end

function newlevel()	
	local i = tonumber(guielements["mapsworldbox"].value)
	local j = tonumber(guielements["mapslevelbox"].value)
	
	if i ~= nil and j ~= nil then
		mapnumberclick(i, j)
	elseif i == nil and j ~= nil then
		mapnumberclick(marioworld, j)
	elseif i ~= nil and j == nil then
		mapnumberclick(i, ((existingmaps[i] as number) or 0)+1)
	elseif marioworld ~= nil and existingmaps[marioworld as number] ~= nil then
		mapnumberclick(marioworld, (existingmaps[marioworld as number] as number)+1)
	else
		mapnumberclick(1, 1)
	end
end

function savestate()
	while #(savestates as {any}) >= maxstates do
		table.remove(savestates, 1)
	end
	local t: {any:any} = {}
	t.coinmap = {} as {any}
	for x = 1, #session.map do
		t[x] = {}
		;(t.coinmap as {any})[x] = {}
		for y = 1, #session.map[x] do
			(t[x] as {any})[y] = {}
			;((t.coinmap as {any})[x] as {any})[y] = session.coinmap[x][y]
			for i, v in pairs(session.map[x][y] as {any:any}) do
				((t[x] as Dyn)[y] as Dyn)[i] = v as Dyn
			end
		end
	end
	table.insert(savestates, t)
end

function loadstate(s: any)
	local si = (s or currentstate) as number
	currentstate = si
	
	local v = savestates[si as integer] as Dyn
	session.map = {}
	session.coinmap = {}
	for x = 1, #(v as {any}) do
		session.map[x] = {}
		session.coinmap[x] = {}
		local col = v[x] as {any}
		for y = 1, #col do
			session.map[x][y] = {} as MapCell
			session.coinmap[x][y] = ((v["coinmap"] as {any})[x] as {any})[y] as boolean
			for i, w in pairs(col[y] as {any:any}) do
				session.map[x][y][i as integer] = w
			end
		end
	end
	
	generatespritebatch(0, 0)
end

--[[function getmaps() VANILLA GETMAPS
	existingmaps = {}
	mapbuttons = {}
	local yadd = 0
	for i = 1, 8 do --world
		existingmaps[i] = {}
		for j = 1, 4 do --level
			mapbuttons["text" .. i .. "-" .. j] = guielement:new("text", 4, yadd+21, "world " .. i .. "-" .. j)
			mapbuttons["text" .. i .. "-" .. j].starty = yadd+21
			
			yadd = yadd + 10
			existingmaps[i][j] = {}
			for k = 0, 5 do --sublevel
				local s = i .. "-" .. j
				
				local xadd = 0
				
				if k ~= 0 then
					s = s .. "_" .. k
				end
				
				if love.filesystem.getInfo(mappack_level_path(mappack, i, j, k), "file") then
					if k ~= 0 then
						mapbuttons["text" .. i .. "-" .. j .. "_" .. k] = guielement:new("text", 4, yadd+26, "sub " .. k, {0.5, 0.5, 0.5})
						mapbuttons["text" .. i .. "-" .. j .. "_" .. k].starty = yadd+26
						xadd = 50
					end
					
					if love.filesystem.getInfo(mappack_path(mappack) .. "/" .. level_name(i, j, k) .. ".png", "file") then
						mapbuttons[i .. "-" .. j .. "_" .. k] = guielement:new("button", 4+xadd, yadd+21, AssetStore.load_image(mappack_path(mappack) .. "/" .. level_name(i, j, k) .. ".png"), mapnumberclick, 0, {i, j, k})
					else
						mapbuttons[i .. "-" .. j .. "_" .. k] = guielement:new("button", 4+xadd, yadd+21, "no preview", mapnumberclick, 0, {i, j, k})
					end
					mapbuttons[i .. "-" .. j .. "_" .. k].starty = yadd+21
					yadd = yadd + 20
				end
			end
		end
	end
	
	mapsymissing = math.max(0, yadd-200)
end]]


function savemtobject(objecttable: {{any}}, name: string|nil, file: string|nil)
	-- 1 read objects file
	file = file or "objects"
	
	local data: string = ""
	local datalines: {string} = {}
	if love.filesystem.getInfo(mappack_path(mappack) .. "/" .. file .. ".txt") then
		data = (love.filesystem.read(mappack_path(mappack) .. "/" .. file .. ".txt") or "") as string
	else
		data = ""
	end
	if name then
		data = data .. name .. "="
	else
		datalines = strsplit(data, "\n") as {string}
		data = data .. "object " .. tostring(#datalines) .. " } mtobjsize="
	end
	-- 2 append new object (with \n at the end!)
	local s: {any} = {}
	local m: number = 0
	local n: number = 0
	for i = 1, #objecttable do
		s = objecttable[i] -- x's
		for j = 1, #s do
			data = data .. tostring(s[j]) .. ","
			n = j
		end
		data = string.sub(data, 1, -2)
		data = data .. ":"
		m = i
	end
	data = string.sub(data, 1, -2)
	data = string.gsub(data, "mtobjsize", m .. " * " .. n)
	data = data .. "\n"
	love.filesystem.write(mappack_path(mappack) .. "/" .. file .. ".txt", data)
	mtjustsaved = 1
end

function objectclipboardcopy(objecttable: {{any}})
	local data: string = ""
	-- 2 append new object (with \n at the end!)
	local s: {any} = {}
	local m: number = 0
	local n: number = 0
	for i = 1, #objecttable do
		s = objecttable[i] -- x's
		for j = 1, #s do
			data = data .. tostring(s[j]) .. ","
			n = j
		end
		data = string.sub(data, 1, -2)
		data = data .. ":"
		m = i
	end
	data = string.sub(data, 1, -2)
	love.system.setClipboardText(data)
end

function moveline(file: string, line: any, direction: string): boolean|nil
	if not love.filesystem.getInfo(file) then
		return false
	end
	if direction ~= "up" then
		direction = "down"
	end
	
	-- cant move first one up
	if line == 1 and direction == "up" then
		return false
	end
	
	local linenum = tonumber(line) or 0
	
	local data: string = (love.filesystem.read(file) or "") as string
	data = string.sub(data, 1, -2)
	local newdata = ""
	local split1 = strsplit(data, "\n")
	
	-- cant move last one down
	if linenum == #split1 and direction == "down" then
		return false
	end
	
	local linetmp1 = split1[linenum as integer]
	local changeto: number = 0
	local linetmp2 = ""
	if direction == "up" then
		changeto = linenum-1
		linetmp2 = split1[changeto as integer] as string
	else
		changeto = linenum+1
		linetmp2 = split1[changeto as integer] as string
	end
	
	for i, _ in ipairs(split1) do
		if i == linenum then
			newdata = newdata .. linetmp2 .. "\n"
		elseif i == changeto then
			newdata = newdata .. (linetmp1 as string) .. "\n"
		else
			newdata = newdata .. (split1[i] as string) .. "\n"
		end
	end
	love.filesystem.write(file, newdata)
	return nil
end

function deleteline(file: string, line: any): boolean|nil
	if not love.filesystem.getInfo(file) then
		return false
	end
	local linenum = tonumber(line) or 0
	local data: string = (love.filesystem.read(file) or "") as string
	data = string.sub(data, 1, -2)
	local newdata = ""
	local split1 = strsplit(data, "\n")
	for i, _ in ipairs(split1) do
		if i ~= linenum then
			newdata = newdata .. (split1[i] as string) .. "\n"
		end
	end
	love.filesystem.write(file, newdata)
	return nil
end

function renameline(file: string, line: any, newName: string): boolean|nil
	if not love.filesystem.getInfo(file) then
		return false
	end
	local linenum = tonumber(line) or 0
	local data: string = (love.filesystem.read(file) or "") as string
	data = string.sub(data, 1, -2)
	local newdata = ""
	local split1 = strsplit(data, "\n")
	for i, _ in ipairs(split1) do
		if i == linenum then
			local split2 = strsplit(split1[i], "=") as {string}
			newdata = newdata .. (newName as string) .. "=" .. (split2[#split2] as string) .. "\n"
		else
			newdata = newdata .. (split1[i] as string) .. "\n"
		end
	end
	love.filesystem.write(file, newdata)
	return nil
end

function changeline(file: string, linenumber: any, newstring: string): boolean|nil
	if not love.filesystem.getInfo(file) then
		return false
	end
	local linenum = tonumber(linenumber) or 0
	local data: string = (love.filesystem.read(file) or "") as string
	data = string.sub(data, 1, -2)
	local newdata = ""
	local split1 = strsplit(data, "\n")
	for i, _ in ipairs(split1) do
		if i ~= linenum then
			newdata = newdata .. (split1[i] as string) .. "\n"
		else
			newdata = newdata .. newstring .. "\n"
		end
	end
	love.filesystem.write(file, newdata)
	return nil
end

