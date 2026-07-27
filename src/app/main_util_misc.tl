--[[ scale / print / custom media / helpers ]]

global function loadcustomimages(...: any): any
	local path = select(1, ...) as string
	-- Restore image defaults via AssetStore, then apply mappack overrides.
	assets:restore_image_defaults()
	for _, s in ipairs(imagelist) do
		(_G as {string:any})[s .. "img"] = assets:get_image(s)
	end
	overwrittenimages = {}

	local fl = love.filesystem.getDirectoryItems(path)
	for i = 1, #fl do
		local v = fl[i]
		if love.filesystem.getInfo(path .. "/" .. v, "file") then
			local s = string.sub(v, 1, -5)
			if tablecontains(imagelist, s) then
				assets:override_image(s, path .. "/" .. v)
				(_G as {string:any})[s .. "img"] = assets:get_image(s)
				table.insert(overwrittenimages, s)
			end
		end
	end
	
	--tiles
	tilequads = {}
	rgblist = {}
	
	--add smb tiles
	local imgwidth, imgheight = smbtilesimg:getWidth(), smbtilesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local imgdata: ImageData
	if love.filesystem.getInfo(path .. "/smbtiles.png") then
		imgdata = love.image.newImageData(path .. "/smbtiles.png")
	else
		imgdata = love.image.newImageData("assets/graphics/DEFAULT/smbtiles.png")
	end
	
	for y = 1, height do
		for x = 1, width do
			table.insert(tilequads as {TileQuad}, quad:new(smbtilesimg, imgdata, x, y, imgwidth, imgheight) as TileQuad)
			local r, g, b = getaveragecolor(imgdata, x, y)
			table.insert(rgblist, {r / LOVE_COLOR_MAX, g / LOVE_COLOR_MAX, b / LOVE_COLOR_MAX})
		end
	end
	smbtilecount = width*height
	
	--add portal tiles
	local imgwidth, imgheight = portaltilesimg:getWidth(), portaltilesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local imgdata: ImageData
	if love.filesystem.getInfo(path .. "/portaltiles.png") then
		imgdata = love.image.newImageData(path .. "/portaltiles.png")
	else
		imgdata = love.image.newImageData("assets/graphics/DEFAULT/portaltiles.png")
	end
	
	for y = 1, height do
		for x = 1, width do
			table.insert(tilequads as {TileQuad}, quad:new(portaltilesimg, imgdata, x, y, imgwidth, imgheight) as TileQuad)
			local r, g, b = getaveragecolor(imgdata, x, y)
			table.insert(rgblist, {r / LOVE_COLOR_MAX, g / LOVE_COLOR_MAX, b / LOVE_COLOR_MAX})
		end
	end
	portaltilecount = width*height
end

global function loadcustomsounds(...: any): any
	local path = select(1, ...) as string
	assets:restore_sound_defaults()
	for _, id in ipairs(soundstoload) do
		if assets.sounds[id] then
			local src = assets:get_sound(id)
			if soundlist[id] then
				soundlist[id].source = src as SoundSource
			end
			defaultsoundslist[id] = src
		end
	end
	overwrittensounds = {}
	
	local fl = love.filesystem.getDirectoryItems(path)
	for i = 1, #fl do
		local v = fl[i]
		if love.filesystem.getInfo(path .. "/" .. v, "file") then
			local s = string.sub(v, 1, -5)
			local full = path .. "/" .. v
			if soundlist[s] then
				assets:override_sound(s, full)
				soundlist[s].source = assets:get_sound(s) as SoundSource
				table.insert(overwrittensounds, s)
			else
				assets:register_sound(s, full)
				soundlist[s] = {}
				soundlist[s].source = assets:get_sound(s) as SoundSource
				soundlist[s].lastplayed = 0
			end
		end
	end
end

global function changescale(...: any): any
	local s, init = ...
	scale = s as number
	
	if not init then
		if width*16*scale > desktopsize.width then
			if fullscreen and fullscreenmode == "full" then
				scale = scale - 1
				return
			end
			
			if fullscreen and fullscreenmode == "touchfrominside" then
				fullscreenmode = "full"
				scale = scale - 1
				return
			end
			
			fullscreen = true
			
			scale = scale - 1
			fullscreenmode = "touchfrominside"
			
		elseif fullscreen then
			if fullscreenmode == "full" then
				fullscreenmode = "touchfrominside"
				scale = scale + 1
				return
			else
				fullscreen = false
			end
			scale = scale + 1
			fullscreenmode = "full"
			
		end
	end
	
	if fullscreen then
		love.window.setMode(desktopsize.width, desktopsize.height, {fullscreen=fullscreen, vsync=vsync--[[, fsaa=fsaa]]})
	else
		uispace = math.floor(width*16*scale/4)
		love.window.setMode(width*16*scale, height*16*scale, {fullscreen=fullscreen, vsync=vsync--[[, fsaa=fsaa]]}) --25x14 blocks (15 blocks actual height)
	end

	completecanvas = love.graphics.newCanvas()
	(completecanvas as Canvas):setFilter("linear", "linear")
	
	gamewidth, gameheight = love.window.getMode()
	if shaders then
		shaders:refresh()
	end
	
	if generatespritebatch then
		generatespritebatch()
	end
end

global function newRecoloredImage(...: any): any
	local path, tablein, tableout = ...
	local tin = tablein as {any}
	local tout = tableout as {any}
	local imagedata = love.image.newImageData( path as string )
	local width, height = imagedata:getWidth(), imagedata:getHeight()
	
	for y = 0, height-1 do
		for x = 0, width-1 do
			local oldr, oldg, oldb, olda = imagedata:getPixel(x, y)
			
			if olda > 0.5*LOVE_COLOR_MAX then
				for i = 1, #tin do
					local tin_i = tin[i] as {any}
					if oldr == tin_i[1] and oldg == tin_i[2] and oldb == tin_i[3] then
						local r, g, b = unpack(tout[i] as {any})
						imagedata:setPixel(x, y, (r as number) * LOVE_COLOR_MAX, (g as number) * LOVE_COLOR_MAX, (b as number) * LOVE_COLOR_MAX, olda)
					end
				end
			end
		end
	end
	
	return AssetStore.load_image_data(imagedata)
end

global function getaveragecolor(...: any): number, number, number
	local imgdata, cox, coy = ...
	local idata = imgdata as ImageData
	local cx = cox as number
	local cy = coy as number
	local xstart = (cx-1)*17
	local ystart = (cy-1)*17
	
	local r: number = 0
	local g: number = 0
	local b: number = 0
	
	local count: number = 0
	
	for x = xstart, xstart+15 do
		for y = ystart, ystart+15 do
			local pr, pg, pb, a = idata:getPixel(x, y)
			if a > 0.5*LOVE_COLOR_MAX then
				r, g, b = r+pr, g+pg, b+pb
				count = count + 1
			end
		end
	end
	
	r, g, b = r/count, g/count, b/count
	
	return r, g, b
end

global function keyprompt_update(...: any): any
	if keyprompt then
		local js = love.joystick.getJoysticks()
		for i = 1, prompt.joysticks do
			local pj = prompt.joystick[i]
			local hats = pj.validhats as {integer}
			local ji = i as integer
			for j = 1, #hats do
				local dir = js[ji]:getHat(hats[j as integer])
				if dir ~= "c" then
					keypromptenter("joyhat", i, hats[j as integer], dir)
					return
				end
			end
			
			local axes = pj.axes as integer
			local axispos = pj.axisposition as {integer:number}
			for j = 1, axes do
				local value = js[ji]:getAxis(j)
				if value > axispos[j] + joystickdeadzone then
					keypromptenter("joyaxis", i, j, "pos")
					return
				elseif value < axispos[j] - joystickdeadzone then
					keypromptenter("joyaxis", i, j, "neg")
					return
				end
			end
		end
	end
end

global function print_r(t: any, indent: any): any --Not by me
	local indent = (indent or '') as string
	for key,value in pairs(t as {any:any}) do
		io.write(indent,'[',tostring(key),']') 
		if type(value)=="table" then io.write(':\n') print_r(value,indent..'\t')
		else io.write(' = ',tostring(value),'\n') end
	end
end

global function openSaveFolder(subfolder: any): any --By Slime
	local path = love.filesystem.getSaveDirectory()
	path = subfolder and path.."/"..(subfolder as string) or path
	
	local cmdstr: string|nil = nil
	local successval = 0
	
	if os.getenv("WINDIR") then -- lolwindows
		--cmdstr = "Explorer /root,%s"
		if path:match("LOVE") then --hardcoded to fix ISO characters in usernames and made sure release mode doesn't mess anything up -saso
			cmdstr = "Explorer %%appdata%%\\LOVE\\mari0_se"
		else
			cmdstr = "Explorer %%appdata%%\\mari0_se"
		end
		path = path:gsub("/", "\\")
		successval = 1
	elseif os.getenv("HOME") then
		if path:match("/Library/Application Support") then -- OSX
			cmdstr = "open \"%s\""
		else -- linux?
			cmdstr = "xdg-open \"%s\""
		end
	end
	
	-- returns true if successfully opened folder
	return cmdstr ~= nil and (os.execute((cmdstr as string):format(path)) as any) == successval
end

global function getupdate(...: any): any
	local onlinedata, code = http.request("http://server.stabyourself.net/mari0/?mode=mappacks")
	if code ~= 200 then
		return false
	elseif not onlinedata then
		return false
	end
	
	local latestversion: any = nil
	
	local split1 = strsplit(onlinedata as string, "<")
	for i = 2, #split1 do
		local split2 = strsplit(split1[i], ">")
		if split2[1] == "latestversion" then
			latestversion = tonumber(split2[2])
		end
	end
	
	if latestversion and (latestversion as number) > marioversion then
		return true
	end
	return false
end

global function properprint(s: any, x: any, y: any, sc: any): any
	local scale = (sc or scale) as number
	local startx = x as number
	local xx = x as number
	local yy = y as number
	local ss = tostring(s)
	local skip = 0
	for i = 1, string.len(ss) do
		if skip > 0 then
			skip = skip - 1
		else
			local char = string.sub(ss, i, i)
			if string.sub(ss, i, i+3) == "_dir" and tonumber(string.sub(ss, i+4, i+4)) then
				love.graphics.draw(directionsimg, directionsquad[tonumber(string.sub(ss, i+4, i+4)) as integer], xx+((i-1)*8+1)*scale, yy, 0, scale, scale)
				skip = 4
			elseif char == "|" then
				xx = startx-((i)*8)*scale
				yy = yy + 10*scale
			elseif fontquads[char] then
				love.graphics.draw(fontimage, fontquads[char], xx+((i-1)*8+1)*scale, yy, 0, scale, scale)
			end
		end
	end
end

global function properprintbackground(...: any): any
	local s, x, y, include, color, sc = ...
	local scale = (sc or scale) as number
	local startx = x as number
	local xx = x as number
	local yy = y as number
	local ss = tostring(s)
	local skip = 0
	for i = 1, string.len(ss) do
		if skip > 0 then
			skip = skip - 1
		else
			local char = string.sub(ss, i, i)
			if char == "|" then
				xx = startx-((i)*8)*scale
				yy = yy + 10*scale
			elseif fontquadsback[char] then
				love.graphics.draw(fontimageback, fontquadsback[char], xx+((i-1)*8)*scale, yy-1*scale, 0, scale, scale)
			end
		end
	end
	
	if include ~= false then
		properprint(s, xx, yy, scale)
	end
end

global function loadcustombackgrounds(...: any): any
	custombackgrounds = {}

	custombackgroundimg = {}
	custombackgroundwidth = {}
	custombackgroundheight = {}
	local fl = love.filesystem.getDirectoryItems("mappacks/" .. mappack .. "/backgrounds")
	
	for i = 1, #fl do
		local v = "mappacks/" .. mappack .. "/backgrounds/" .. fl[i]
		
		if love.filesystem.getInfo(v, "file") and v ~= ".DS_STORE" and v ~= ".DS_S" then
			if string.sub(v, -5, -5) == "1" then
				local name = string.sub(fl[i], 1, -6)
				local bg = string.sub(v, 1, -6)
				local i = 1
				
				custombackgroundimg[name] = {}
				custombackgroundwidth[name] = {}
				custombackgroundheight[name] = {}
					
				while love.filesystem.getInfo(bg .. i .. ".png") do
					local img = AssetStore.load_image(bg .. i .. ".png") as Image
					custombackgroundimg[name][i] = img
					custombackgroundwidth[name][i] = img:getWidth()/16
					custombackgroundheight[name][i] = img:getHeight()/16
					i = i + 1
				end
				table.insert(custombackgrounds, name)
			else
				local name = string.sub(fl[i], 1, -5)
				local bg = string.sub(v, 1, -5)
				local img = AssetStore.load_image(bg .. ".png") as Image
				
				custombackgroundimg[name] = {img}
				custombackgroundwidth[name] = {img:getWidth()/16}
				custombackgroundheight[name] = {img:getHeight()/16}
				
				table.insert(custombackgrounds, name)
			end
		end
	end
end

global function loadlevelscreens(...: any): any
	levelscreens = {}
	
	local fl = love.filesystem.getDirectoryItems("mappacks/" .. mappack .. "/levelscreens")
	
	for i = 1, #fl do
		local v = "mappacks/" .. mappack .. "/levelscreens/" .. fl[i]
		if love.filesystem.getInfo(v, "file") then
			table.insert(levelscreens, string.lower(string.sub(fl[i], 1, -5)))
		end
	end
end

global function loadcustommusics(...: any): any
	musiclist = {"none.ogg", "overworld.ogg", "underground.ogg", "castle.ogg", "underwater.ogg", "starmusic.ogg"}
	local fl = love.filesystem.getDirectoryItems("mappacks/" .. mappack .. "/music")
	custommusics = {}
	
	for i = 1, #fl do
		local v = fl[i]
		if (v:match(".ogg") or v:match(".mp3") or v:match(".mod")) and v:sub(-9, -5) ~= "-fast" then
			table.insert(musiclist, v)
			--music:load(v) --Sometimes I come back to code and wonder why things are commented out. This is one of those cases. But it works so eh.
		end
	end
end

global function loadanimatedtiles(...: any): any
	if animatedtilecount then
		for i = 1, animatedtilecount do
			tilequads[i + 10000] = nil
		end
	end
	
	local function loadfolder(folder: any)
		local i = 1
		local fold = folder as string
		while love.filesystem.getInfo(fold .. "/" .. i .. ".png") do
			local v = fold .. "/" .. i .. ".png"
			if love.filesystem.getInfo(v, "file") and string.sub(v, -4) == ".png" then
				if love.filesystem.getInfo(string.sub(v, 1, -5) .. ".txt", "file") then
					animatedtilecount = animatedtilecount + 1
					local number = animatedtilecount+10000
					local t = animatedquad:new(v, love.filesystem.read(string.sub(v, 1, -5) .. ".txt"), number)
					tilequads[number] = t as TileQuad
					table.insert(animatedtiles, t)
				end
			end
			i = i + 1
		end
	end
	
	animatedtilecount = 0
	animatedtiles = {}
	loadfolder("assets/graphics/animated")
	loadfolder("mappacks/" .. mappack .. "/animated")
end

global function loadcustomtiles(...: any): any
	if love.filesystem.getInfo("mappacks/" .. mappack .. "/tiles.png") then
		customtiles = true
		customtilesimg = AssetStore.load_image("mappacks/" .. mappack .. "/tiles.png")
		local imgwidth, imgheight = customtilesimg:getWidth(), customtilesimg:getHeight()
		local width = math.floor(imgwidth/17)
		local height = math.floor(imgheight/17)
		local imgdata = love.image.newImageData("mappacks/" .. mappack .. "/tiles.png")
		
		for y = 1, height do
			for x = 1, width do
				table.insert(tilequads as {any}, quad:new(customtilesimg, imgdata, x, y, imgwidth, imgheight) as TileQuad)
				local r, g, b = getaveragecolor(imgdata, x, y)
				table.insert(rgblist, {r / LOVE_COLOR_MAX, g / LOVE_COLOR_MAX, b / LOVE_COLOR_MAX})
			end
		end
		customtilecount = width*height
	else
		customtiles = false
		customtilecount = 0
	end
end

global function loadmodcustomtiles(...: any): any
	local files = love.filesystem.getDirectoryItems("mappacks/" .. mappack .. "/tiles")
	for i,j in ipairs(files) do
		print(i,j)
		if string.sub(j, -4) ~= ".png" then
			table.remove(files, i)
			print(true)
		end
	end
	if files ~= nil then
		modcustomtiles = #files
		modcustomtilesimg = {}
		modcustomtilecount = {}
		for i = 1, modcustomtiles as integer do
			modcustomtilesimg[i] = AssetStore.load_image("mappacks/" .. mappack .. "/tiles/" .. files[i]) as Image
			local imgwidth, imgheight = modcustomtilesimg[i]:getWidth(), modcustomtilesimg[i]:getHeight()
			local width = math.floor(imgwidth/17)
			local height = math.floor(imgheight/17)
			local imgdata = love.image.newImageData("mappacks/" .. mappack .. "/tiles/" .. files[i])
			
			for y = 1, height do
				for x = 1, width do
					table.insert(tilequads as {any}, quad:new(modcustomtilesimg[i], imgdata, x, y, imgwidth, imgheight) as TileQuad)
					local r, g, b = getaveragecolor(imgdata, x, y)
					table.insert(rgblist, {r, g, b})
				end
			end
			modcustomtilecount[i] = (modcustomtilecount[(i-1) as integer] or 0) + width*height
		end
	else
		modcustomtiles = false
		modcustomtilecount = {0}
	end
end

global function dbprint(x: any): any --debugprint; set debugprints=true to enable
	if Logger then
		Logger.debug(x)
	elseif debugprints then
		print(x)
	end
end

global function add(...: any): any
	local desc = ...
	print(tostring(desc or "") .. "\n" .. tostring(round((love.timer.getTime()-starttime)*1000)) .. "ms\tlines " .. tostring((lastline as number)+1) .. " - " .. tostring(debug.getinfo(2).currentline-1) .. "\n")
	lastline = debug.getinfo(2).currentline as number
	totaltime = totaltime + round((love.timer.getTime()-starttime)*1000)
	starttime = love.timer.getTime()
end

