--[[ scale / print / custom media / helpers ]]

global function loadcustomimages(...: any): any
	local path = ...
	-- Restore image defaults via AssetStore, then apply mappack overrides.
	assets:restore_image_defaults()
	for _, s in ipairs(imagelist) do
		_G[s .. "img"] = assets:get_image(s)
	end
	overwrittenimages = {}

	local fl = love.filesystem.getDirectoryItems(path)
	for i = 1, #fl do
		local v = fl[i]
		if love.filesystem.getInfo(path .. "/" .. v, "file") then
			local s = string.sub(v, 1, -5)
			if tablecontains(imagelist, s) then
				assets:override_image(s, path .. "/" .. v)
				_G[s .. "img"] = assets:get_image(s)
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
	local imgdata
	if love.filesystem.getInfo(path .. "/smbtiles.png") then
		imgdata = love.image.newImageData(path .. "/smbtiles.png")
	else
		imgdata = love.image.newImageData("assets/graphics/DEFAULT/smbtiles.png")
	end
	
	for y = 1, height do
		for x = 1, width do
			table.insert(tilequads, quad:new(smbtilesimg, imgdata, x, y, imgwidth, imgheight))
			local r, g, b = getaveragecolor(imgdata, x, y)
			table.insert(rgblist, {r / LOVE_COLOR_MAX, g / LOVE_COLOR_MAX, b / LOVE_COLOR_MAX})
		end
	end
	smbtilecount = width*height
	
	--add portal tiles
	local imgwidth, imgheight = portaltilesimg:getWidth(), portaltilesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local imgdata
	if love.filesystem.getInfo(path .. "/portaltiles.png") then
		imgdata = love.image.newImageData(path .. "/portaltiles.png")
	else
		imgdata = love.image.newImageData("assets/graphics/DEFAULT/portaltiles.png")
	end
	
	for y = 1, height do
		for x = 1, width do
			table.insert(tilequads, quad:new(portaltilesimg, imgdata, x, y, imgwidth, imgheight))
			local r, g, b = getaveragecolor(imgdata, x, y)
			table.insert(rgblist, {r / LOVE_COLOR_MAX, g / LOVE_COLOR_MAX, b / LOVE_COLOR_MAX})
		end
	end
	portaltilecount = width*height
end

global function loadcustomsounds(...: any): any
	local path = ...
	assets:restore_sound_defaults()
	for _, id in ipairs(soundstoload) do
		if assets.sounds[id] then
			local src = assets:get_sound(id)
			if soundlist[id] then
				soundlist[id].source = src
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
				soundlist[s].source = assets:get_sound(s)
				table.insert(overwrittensounds, s)
			else
				assets:register_sound(s, full)
				soundlist[s] = {}
				soundlist[s].source = assets:get_sound(s)
				soundlist[s].lastplayed = 0
			end
		end
	end
end

global function changescale(...: any): any
	local s, init = ...
	scale = s
	
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
	completecanvas:setFilter("linear", "linear")
	
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
	local imagedata = love.image.newImageData( path )
	local width, height = imagedata:getWidth(), imagedata:getHeight()
	
	for y = 0, height-1 do
		for x = 0, width-1 do
			local oldr, oldg, oldb, olda = imagedata:getPixel(x, y)
			
			if olda > 0.5*LOVE_COLOR_MAX then
				for i = 1, #tablein do
					if oldr == tablein[i][1] and oldg == tablein[i][2] and oldb == tablein[i][3] then
						local r, g, b = unpack(tableout[i])
						imagedata:setPixel(x, y, r * LOVE_COLOR_MAX, g * LOVE_COLOR_MAX, b * LOVE_COLOR_MAX, olda)
					end
				end
			end
		end
	end
	
	return AssetStore.load_image(imagedata)
end

global function getaveragecolor(...: any): any
	local imgdata, cox, coy = ...
	local xstart = (cox-1)*17
	local ystart = (coy-1)*17
	
	local r, g, b = 0, 0, 0
	
	local count = 0
	
	for x = xstart, xstart+15 do
		for y = ystart, ystart+15 do
			local pr, pg, pb, a = imgdata:getPixel(x, y)
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
			for j = 1, #prompt.joystick[i].validhats do
				local dir = js[i]:getHat(prompt.joystick[i].validhats[j])
				if dir ~= "c" then
					keypromptenter("joyhat", i, prompt.joystick[i].validhats[j], dir)
					return
				end
			end
			
			for j = 1, prompt.joystick[i].axes do
				local value = js[i]:getAxis(j)
				if value > prompt.joystick[i].axisposition[j] + joystickdeadzone then
					keypromptenter("joyaxis", i, j, "pos")
					return
				elseif value < prompt.joystick[i].axisposition[j] - joystickdeadzone then
					keypromptenter("joyaxis", i, j, "neg")
					return
				end
			end
		end
	end
end

global function print_r (t, indent) --Not by me
	local indent=indent or ''
	for key,value in pairs(t) do
		io.write(indent,'[',tostring(key),']') 
		if type(value)=="table" then io.write(':\n') print_r(value,indent..'\t')
		else io.write(' = ',tostring(value),'\n') end
	end
end

global function openSaveFolder(subfolder) --By Slime
	local path = love.filesystem.getSaveDirectory()
	path = subfolder and path.."/"..subfolder or path
	
	local cmdstr
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
	return cmdstr and os.execute(cmdstr:format(path)) == successval
end

global function getupdate(...: any): any
	local onlinedata, code = http.request("http://server.stabyourself.net/mari0/?mode=mappacks")
	if code ~= 200 then
		return false
	elseif not onlinedata then
		return false
	end
	
	local latestversion
	
	local split1 = strsplit(onlinedata, "<")
	for i = 2, #split1 do
		local split2 = strsplit(split1[i], ">")
		if split2[1] == "latestversion" then
			latestversion = tonumber(split2[2])
		end
	end
	
	if latestversion and latestversion > marioversion then
		return true
	end
	return false
end

global function properprint(s, x, y, sc)
	local scale = sc or scale
	local startx = x
	local skip = 0
	for i = 1, string.len(tostring(s)) do
		if skip > 0 then
			skip = skip - 1
		else
			local char = string.sub(s, i, i)
			if string.sub(s, i, i+3) == "_dir" and tonumber(string.sub(s, i+4, i+4)) then
				love.graphics.draw(directionsimg, directionsquad[tonumber(string.sub(s, i+4, i+4))], x+((i-1)*8+1)*scale, y, 0, scale, scale)
				skip = 4
			elseif char == "|" then
				x = startx-((i)*8)*scale
				y = y + 10*scale
			elseif fontquads[char] then
				love.graphics.draw(fontimage, fontquads[char], x+((i-1)*8+1)*scale, y, 0, scale, scale)
			end
		end
	end
end

global function properprintbackground(...: any): any
	local s, x, y, include, color, sc = ...
	local scale = sc or scale
	local startx = x
	local skip = 0
	for i = 1, string.len(tostring(s)) do
		if skip > 0 then
			skip = skip - 1
		else
			local char = string.sub(s, i, i)
			if char == "|" then
				x = startx-((i)*8)*scale
				y = y + 10*scale
			elseif fontquadsback[char] then
				love.graphics.draw(fontimageback, fontquadsback[char], x+((i-1)*8)*scale, y-1*scale, 0, scale, scale)
			end
		end
	end
	
	if include ~= false then
		properprint(s, x, y, scale)
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
					custombackgroundimg[name][i] = AssetStore.load_image(bg .. i .. ".png")
					custombackgroundwidth[name][i] = custombackgroundimg[name][i]:getWidth()/16
					custombackgroundheight[name][i] = custombackgroundimg[name][i]:getHeight()/16
					i = i + 1
				end
				table.insert(custombackgrounds, name)
			else
				local name = string.sub(fl[i], 1, -5)
				local bg = string.sub(v, 1, -5)
				
				custombackgroundimg[name] = {AssetStore.load_image(bg .. ".png")}
				custombackgroundwidth[name] = {custombackgroundimg[name][1]:getWidth()/16}
				custombackgroundheight[name] = {custombackgroundimg[name][1]:getHeight()/16}
				
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
	
	local function loadfolder(folder)
		local i = 1
		while love.filesystem.getInfo(folder .. "/" .. i .. ".png") do
			local v = folder .. "/" .. i .. ".png"
			if love.filesystem.getInfo(v, "file") and string.sub(v, -4) == ".png" then
				if love.filesystem.getInfo(string.sub(v, 1, -5) .. ".txt", "file") then
					animatedtilecount = animatedtilecount + 1
					local number = animatedtilecount+10000
					local t = animatedquad:new(v, love.filesystem.read(string.sub(v, 1, -5) .. ".txt"), number)
					tilequads[number] = t
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
				table.insert(tilequads, quad:new(customtilesimg, imgdata, x, y, imgwidth, imgheight))
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
	for i,j in pairs(files) do
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
		for i = 1, modcustomtiles do
			modcustomtilesimg[i] = AssetStore.load_image("mappacks/" .. mappack .. "/tiles/" .. files[i])
			local imgwidth, imgheight = modcustomtilesimg[i]:getWidth(), modcustomtilesimg[i]:getHeight()
			local width = math.floor(imgwidth/17)
			local height = math.floor(imgheight/17)
			local imgdata = love.image.newImageData("mappacks/" .. mappack .. "/tiles/" .. files[i])
			
			for y = 1, height do
				for x = 1, width do
					table.insert(tilequads, quad:new(modcustomtilesimg[i], imgdata, x, y, imgwidth, imgheight))
					local r, g, b = getaveragecolor(imgdata, x, y)
					table.insert(rgblist, {r, g, b})
				end
			end
			modcustomtilecount[i] = (modcustomtilecount[i-1] or 0) + width*height
		end
	else
		modcustomtiles = false
		modcustomtilecount = {0}
	end
end

global function dbprint(x) --debugprint; set debugprints=true to enable
	if Logger then
		Logger.debug(x)
	elseif debugprints then
		print(x)
	end
end

global function add(...: any): any
	local desc = ...
	print((desc or "") .. "\n" .. round((love.timer.getTime()-starttime)*1000) .. "ms\tlines " .. lastline+1 .. " - " .. debug.getinfo(2).currentline-1 .. "\n")
	lastline = debug.getinfo(2).currentline
	totaltime = totaltime + round((love.timer.getTime()-starttime)*1000)
	starttime = love.timer.getTime()
end

