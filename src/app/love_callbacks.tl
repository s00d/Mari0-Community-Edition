--[[ Love callbacks extracted from main.lua ]]

function love.update(dt: any)
	local dt = dt as number
	if music then
		music:update()
	end
	realdt = dt
	dt = math.min(0.5, dt) --ignore any dt higher than half a second
	
	if recording then
		dt = recordtarget as number
	end
	
	steptimer = steptimer + dt
	dt = targetdt as number
	
	if skipupdate then
		steptimer = 0
		skipupdate = false
		return
	end
	
	--speed
	if bullettime and speed ~= speedtarget then
		if speed > speedtarget then
			speed = math.max(speedtarget, speed+(speedtarget-speed)*dt*5)
		elseif speed < speedtarget then
			speed = math.min(speedtarget, speed+(speedtarget-speed)*dt*5)
		end
		
		if math.abs(speed-speedtarget) < 0.02 then
			speed = speedtarget
		end
		
		if speed > 0 then
			for i, v in pairs(soundlist) do
				v.source:setPitch( speed )
			end
			music.pitch = speed
			love.audio.setVolume(volumesfx)
			music:setVolume(volumemusic)
		else	
			love.audio.setVolume(0)
			music:setVolume(0)
		end
	end
	
	while steptimer >= targetdt do
		steptimer = steptimer - targetdt
		
		if frameskip then
			if (frameskip as number) > skippedframes then
				skippedframes = skippedframes + 1
				return
			else
				skippedframes = 0
			end
		end
		
		keyprompt_update()
		
		-- Prefer Gamestate handlers when registered; legacy branches as fallback
		local gs_handled = false
		if Gamestate then
			local gname = (Gamestate.get as function(): any)()
			local h = (Gamestate.handlers as {any:any})[gname]
			if h and (h as {string:any}).update then
				(Gamestate.update as function(...: any): any)(dt)
				gs_handled = true
			end
		end
		if not gs_handled then
			if gamestate == "menu" or gamestate == "mappackmenu" or gamestate == "onlinemenu" or gamestate == "options" or gamestate == "lobby" then
				menu_update(dt as number)
			elseif gamestate == "levelscreen" or gamestate == "gameover" or gamestate == "sublevelscreen" or gamestate == "mappackfinished" then
				levelscreen_update(dt)
			elseif gamestate == "game" then
				game_update(dt)	
			elseif gamestate == "intro" then
				intro_update(dt)	
			end
		end
		
		for i, v in pairs(guielements) do
			v:update(dt as number)
		end
		
		--netplay_update(dt)
		
		notice.update(dt as number)
		
		--No longer needed
		--love.window.setTitle("FPS:" .. love.timer.getFPS() .. " - Send feedback/issues to crash@stabyourself.net")
	end
end

function love.draw()
	shaders:predraw()
	
	local gs_handled = false
	if Gamestate then
		local h = (Gamestate.handlers as {any:any})[(Gamestate.get as function(): any)()]
		if h and (h as {string:any}).draw then
			(Gamestate.draw as function(): any)()
			gs_handled = true
		end
	end
	if not gs_handled then
		if gamestate == "menu" or gamestate == "mappackmenu" or gamestate == "onlinemenu" or gamestate == "options" or gamestate == "lobby" then
			menu_draw()
		elseif gamestate == "levelscreen" or gamestate == "gameover" or gamestate == "mappackfinished" then
			levelscreen_draw()
		elseif gamestate == "game" then
			game_draw()
		elseif gamestate == "intro" then
			intro_draw()
		end
	end
	
	notice.draw()
	
	shaders:postdraw()
		
	love.graphics.setColor(1, 1, 1)
	
	if recording then
		screenshotimagedata = love.graphics.newScreenshot( )
		(screenshotimagedata as ImageData):encode("recording/" .. tostring(recordframe) .. ".png")
		recordframe = recordframe + 1
		screenshotimagedata = nil
		
		if recordframe%100 == 0 then
			collectgarbage("collect")
		end
	end
end

function love.keypressed(key: any, scancode: any, isrepeat: any)
	-- Layout-independent: scancode is physical key position (Love 11)
	if type(scancode) == "string" then
		key = scancode
	end
	if key == "space" then key = " " end
	if key == "k" then
		savelevel()
	end

	if key == "y" and debugbinds then
		if love.keyboard.isDown("lalt") then
			recording = not recording
		end
	end
	
	if key == "lctrl" and debugbinds then
		debug.debug()
		return
	end
	
	if replaysystem then
		if key == "k" then
			playerobjs[1]:savereplaydata()
		end
	end
	
	if keyprompt then
		keypromptenter("key", key)
		return
	end

	for i, v in pairs(guielements) do
		if v:keypress(string.lower(key as string)) then
			return
		end
	end
	
	if key == "f12" then
		love.mouse.setGrabbed(not love.mouse.isGrabbed())
	end
	
	if gamestate == "lobby" or gamestate == "onlinemenu" then
		if key == "escape" then
			net_quit()
			return
		end
	end
	
	if gamestate == "menu" or gamestate == "mappackmenu" or gamestate == "onlinemenu" or gamestate == "options" then
		table.insert(konamitable, key)
		table.remove(konamitable, 1)
		local s = ""
		for i = 1, #konamitable do
			s = s .. tostring(konamitable[i])
		end
		
		if (sha1 as function(string): any)(s) == (konamihash as any) then --Before you wonder how dumb this is; This used to be a different code than konami because I thought it'd be fun to make people figure it out before they can tell others how to easily unlock cheats (without editing files). It wasn't, really.
			playsound("konami")
			gamefinished = true
			saveconfig()
			notice.new("Cheats unlocked!")
		end
		menu_keypressed(key)
	elseif gamestate == "game" then
		game_keypressed(key)
	elseif gamestate == "intro" then
		intro_keypressed()
	end
end

function love.keyreleased(key: any, scancode: any)
	if type(scancode) == "string" then
		key = scancode
	end
	if key == "space" then key = " " end
	if gamestate == "menu" or gamestate == "options" then
		menu_keyreleased(key)
	elseif gamestate == "game" then
		game_keyreleased(key)
	end
end

function love.textinput(text: any)
	local g = _G as {string:any}
	local name = (gamestate as string) .. "_textinput"
	if g[name] and type(g[name]) == "function" then
		local ok = pcall(function() (g[name] as function(any): any)(text) end) -- I don't wanna cause a crash
		if not ok then end
	end
	
	if guielements then
		for _, v in pairs(guielements) do
			v:textinput(text as string)
		end
	end
end

function love.wheelmoved(x: any, y: any)
	if (y as number) > 0 then
		love.mousepressed(love.mouse.getX(), love.mouse.getY(), "wu")
	elseif (y as number) < 0 then
		love.mousepressed(love.mouse.getX(), love.mouse.getY(), "wd")
	end
end

function love.mousepressed(...: any)
	local x, y, button = ...
	local x = x as number
	local y = y as number
	-- Love 11 passes numeric buttons; legacy handlers still use "l"/"r"/"m".
	if button == 1 then button = "l"
	elseif button == 2 then button = "r"
	elseif button == 3 then button = "m"
	end
	if fullscreen then
		if fullscreenmode == "full" then
			x, y = x/(desktopsize.width/(width*16*scale)), y/(desktopsize.height/(height*16*scale))
		else
			x, y = x/(touchfrominsidescaling/scale), y/(touchfrominsidescaling/scale)-touchfrominsidemissing/2
		end
	end
	if gamestate == "menu" or gamestate == "mappackmenu" or gamestate == "onlinemenu" or gamestate == "options" then
		menu_mousepressed(x, y, button)
	elseif gamestate == "game" then
		game_mousepressed(x, y, button)
	elseif gamestate == "intro" then
		intro_mousepressed()
	end
	
	if animationguilines and editormenuopen and not changemapwidthmenu and not guielements["animationselectdrop"].extended then
		local b = false
		for i, v in pairs(animationguilines) do
			for k, w in pairs(v as {any:any}) do
				if (w as guielement):haspriority() then
					(w as guielement):click(x, y, button)
					return
				end
			end
		end
		
		if x >= animationguiarea[1]*scale and y >= animationguiarea[2]*scale and x < animationguiarea[3]*scale and y < animationguiarea[4]*scale then
			addanimationtriggerbutton:click(x, y, button)
			addanimationconditionbutton:click(x, y, button)
			addanimationactionbutton:click(x, y, button)
			
			for i, v in pairs(animationguilines) do
				for k, w in pairs(v as {any:any}) do						
					if (w as guielement):click(x, y, button) then
						return
					end
				end
			end
		end
	end
	
	for i, v in pairs(guielements) do
		if v.priority then
			if v:click(x, y, button) then
				return
			end
		end
	end
	
	for i, v in pairs(guielements) do
		if not v.priority then
			if v:click(x, y, button) then
				return
			end
		end
	end
end

function love.mousereleased(...: any)
	local x, y, button = ...
	local x = x as number
	local y = y as number
	if button == 1 then button = "l"
	elseif button == 2 then button = "r"
	elseif button == 3 then button = "m"
	end
	x, y = desktopsize.width/(width*16*scale)*x, desktopsize.height/(height*16*scale)*y
	if gamestate == "menu" or gamestate == "options" then
		menu_mousereleased(x, y, button)
	elseif gamestate == "game" then
		game_mousereleased(x, y, button)
	end
	
	for i, v in pairs(guielements) do
		v:unclick(x, y, button)
	end
end

function love.joystickpressed(joystick: any, button: any)
	local joysticks,found = love.joystick.getJoysticks(),false
	for i,v in ipairs(joysticks) do
		if (v as Joystick):getID() == (joystick as Joystick):getID() then
			joystick,found = i,true
			break
		end
	end
	
	if found then
		if keyprompt then
			keypromptenter("joybutton", joystick, button)
		elseif gamestate == "menu" or gamestate == "options" then
			menu_joystickpressed(joystick, button)
		elseif gamestate == "game" then
			game_joystickpressed(joystick, button)
		end
	end
end

function love.joystickreleased(joystick: any, button: any)
	local joysticks,found = love.joystick.getJoysticks(),false
	for i,v in ipairs(joysticks) do
		if (v as Joystick):getID() == (joystick as Joystick):getID() then
			joystick,found = i,true
			break
		end
	end
	
	if found then
		if gamestate == "menu" or gamestate == "options" then
			menu_joystickreleased(joystick, button)
		elseif gamestate == "game" then
			game_joystickreleased(joystick, button)
		end
	end
end

function love.joystickaxis(joystick: any, axis: any, value: any)
	local joysticks,found = love.joystick.getJoysticks(),false
	for i,v in ipairs(joysticks) do
		if (v as Joystick):getID() == (joystick as Joystick):getID() then
			joystick,found = i,true
			break
		end
	end
	
	if found then
		local stickmoved = false
		local shouldermoved = false
		
		local adz = ((axisDeadZones as {any:any})[joystick] as {any:any})[axis] as {string:any}
		--If this axis is a stick, get whether it just moved out of its deadzone
		if math.abs(value as number) > joystickaimdeadzone and adz["stick"] then
			stickmoved = true
			adz["stick"] = false
		elseif math.abs(value as number) < joystickaimdeadzone and not adz["stick"] then
			adz["stick"] = true
		end

		--If this axis is a shoulder, get whether it just moved out of its deadzone
		if (value as number) > 0 and adz["shoulder"] then
			shouldermoved = true
			adz["shoulder"] = false
		elseif (value as number) < 0 and not adz["shoulder"] then
			adz["shoulder"] = true
		end

		if gamestate == "menu" or gamestate == "options" then
			menu_joystickaxis(joystick, axis, value, stickmoved, shouldermoved)
		elseif gamestate == "game" then
			game_joystickaxis(joystick, axis, value, stickmoved, shouldermoved)
		end
	end
end

function love.joystickhat(joystick: any, hat: any, direction: any)
	local joysticks,found = love.joystick.getJoysticks(),false
	for i,v in ipairs(joysticks) do
		if (v as Joystick):getID() == (joystick as Joystick):getID() then
			joystick,found = i,true
			break
		end
	end
	
	if found then
		if gamestate == "menu" or gamestate == "options" then
			menu_joystickhat(joystick, hat, direction)
		elseif gamestate == "game" then
			game_joystickhat(joystick, hat, direction)
		end
	end
end

-- love.gamepadpressed = love.joystickpressed
-- love.gamepadreleased = love.joystickreleased
-- love.gamepadaxis = love.joystickaxis

function love.focus(f: any)
	--[[if not f and gamestate == "game"and not editormode and not levelfinished and not everyonedead  then
		pausemenuopen = true
		paused = love.audio.pause()
	end--]]
end

function love.quit()
	
end

