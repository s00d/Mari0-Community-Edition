--[[ Love callbacks extracted from main.lua ]]

local LoveFrame = require("app.love_frame")

local function joystick_slot(joystick: Joystick): integer|nil
	local sticks = love.joystick.getJoysticks() as {Joystick}
	local jid = joystick:getID()
	for i, v in ipairs(sticks) do
		if v:getID() == jid then
			return i
		end
	end
	return nil
end

function love.update(dt: any)
	local dt = dt as number
	local frame_dt = math.min(0.5, dt) --ignore any dt higher than half a second
	
	if recording then
		frame_dt = recordtarget as number
	end
	
	dt = targetdt as number
	
	if not LoveFrame.begin_update() then
		return
	end

	if music then
		music:update(frame_dt)
	end

	if HumpTimer then
		HumpTimer.update(frame_dt)
	end
	if Flux then
		Flux.update(frame_dt)
	end
	if ui_input_update then
		ui_input_update(frame_dt)
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
			audio_set_pitch(speed)
			audio_apply_volumes()
		else	
			love.audio.setVolume(0)
		end
	end
	
	-- Bullet time scales step accumulation, not per-step dt (see game_update).
	LoveFrame.add_time(frame_dt * speed)
	
	local max_physics_steps = 5
	local steps = 0
	while LoveFrame.has_pending_step(targetdt) and steps < max_physics_steps do
		if not LoveFrame.try_step(targetdt) then
			break
		end
		steps = steps + 1
		
		if frameskip then
			if (frameskip as number) > skippedframes then
				skippedframes = skippedframes + 1
				return
			else
				skippedframes = 0
			end
		end
		
		keyprompt_update()
		
		if Gamestate then
			Gamestate.update(dt)
		end
		
		for _, v in pairs(guielements) do
			v:update(dt as number)
		end
		
		-- Net: offline no-op; host/client after Net.host / Net.join
		if Net and Net.update then
			Net.update(dt as number)
		end
		
		notice.update(dt as number)
		
		--No longer needed
		--love.window.setTitle("FPS:" .. love.timer.getFPS() .. " - Send feedback/issues to crash@stabyourself.net")
	end
	if steps >= max_physics_steps and LoveFrame.has_pending_step(targetdt) then
		LoveFrame.clear_debt()
	end
	-- Pace LuaJIT GC once per rendered frame (not per physics substep).
	if gcpace_step then
		gcpace_step()
	end
end

function love.draw()
	shaders:predraw()
	
	if Gamestate then
		Gamestate.draw()
	end
	
	notice.draw()
	
	shaders:postdraw()
		
	love.graphics.setColor(1, 1, 1)
	
	if recording then
		local frame = recordframe
		if love.graphics.captureScreenshot then
			love.graphics.captureScreenshot(function(shot: ImageData)
				if shot then
					shot:encode("recording/" .. tostring(frame) .. ".png")
				end
			end)
			recordframe = recordframe + 1
		end

		if recordframe % 100 == 0 then
			collectgarbage("collect")
		end
	end
end

function love.keypressed(key: any, scancode: any, _: any)
	-- Layout-independent: scancode is physical key position (Love 11)
	if type(scancode) == "string" then
		key = scancode
	end
	if key == "space" then key = " " end
	if key == "k" then
		savelevel()
	end

	if key == "y" and debugbinds then
		if sys_down("alt") then
			recording = not recording
		end
	end
	
	if key == "lctrl" and debugbinds then
		debug.debug()
		return
	end
	
	if replaysystem then
		if key == "k" then
			session.playerobjs[1]:savereplaydata()
		end
	end
	
	if keyprompt then
		keypromptenter("key", key)
		return
	end

	for _, v in pairs(guielements) do
		if v:keypress(string.lower(key as string)) then
			return
		end
	end
	
	if key == "f12" then
		love.mouse.setGrabbed(not love.mouse.isGrabbed())
	end

	if Gamestate then
		Gamestate.call("keypressed", key)
	end
end

function love.keyreleased(key: any, scancode: any)
	if type(scancode) == "string" then
		key = scancode
	end
	if key == "space" then key = " " end
	if Gamestate then
		Gamestate.call("keyreleased", key)
	end
end

function love.textinput(text: any)
	if Gamestate then
		local results = { pcall(function()
			Gamestate.call("textinput", text)
		end) }
		if not results[1] then
			local err = tostring(results[2])
			print("textinput error [" .. tostring(gamestate) .. "]: " .. err)
			if Logger and Logger.error then
				(Logger.error as function(...: any))("textinput", tostring(gamestate), err)
			end
		end
	end

	if guielements then
		for _, v in pairs(guielements) do
			v:textinput(text as string)
		end
	end
end

function love.wheelmoved(_: any, y: any)
	if (y as number) > 0 then
		love.mousepressed(love.mouse.getX(), love.mouse.getY(), "wu")
	elseif (y as number) < 0 then
		love.mousepressed(love.mouse.getX(), love.mouse.getY(), "wd")
	end
end

function love.mousemoved(x: any, y: any, dx: any, dy: any)
	if not ui_note_mouse_move(dx as number, dy as number, x as number, y as number) then
		return
	end
	if Gamestate then
		Gamestate.call("mousemoved", mouseui_x, mouseui_y, dx, dy)
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
	x, y = screen_to_ui(x, y)
	if Gamestate then
		Gamestate.call("mousepressed", x, y, button)
	end
	
	if animationguilines and editormenuopen and not changemapwidthmenu and not guielements["animationselectdrop"].extended then
		for _, v in pairs(animationguilines) do
			for _, w in pairs(v as {any:any}) do
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
			
			for _, v in pairs(animationguilines) do
				for _, w in pairs(v as {any:any}) do						
					if (w as guielement):click(x, y, button) then
						return
					end
				end
			end
		end
	end
	
	for _, v in pairs(guielements) do
		if v.priority then
			if v:click(x, y, button) then
				return
			end
		end
	end
	
	for _, v in pairs(guielements) do
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
	x, y = screen_to_ui(x, y)
	if Gamestate then
		Gamestate.call("mousereleased", x, y, button)
	end
	
	for _, v in pairs(guielements) do
		v:unclick(x, y, button)
	end
end

function love.joystickpressed(joystick: any, button: any)
	local slot = joystick_slot(joystick as Joystick)
	if not slot then
		return
	end
	if keyprompt then
		keypromptenter("joybutton", slot, button)
		return
	end
	if Gamestate then
		Gamestate.call("joystickpressed", slot, button)
	end
end

function love.joystickreleased(joystick: any, button: any)
	local slot = joystick_slot(joystick as Joystick)
	if not slot then
		return
	end
	if Gamestate then
		Gamestate.call("joystickreleased", slot, button)
	end
end

function love.joystickaxis(joystick: any, axis: any, value: any)
	local slot = joystick_slot(joystick as Joystick)
	if not slot then
		return
	end
	local stickmoved = false
	local shouldermoved = false
	local adz = ((axisDeadZones as {any:any})[slot] as {any:any})[axis] as {string:any}
	if math.abs(value as number) > joystickaimdeadzone and adz["stick"] then
		stickmoved = true
		adz["stick"] = false
	elseif math.abs(value as number) < joystickaimdeadzone and not adz["stick"] then
		adz["stick"] = true
	end
	if (value as number) > 0 and adz["shoulder"] then
		shouldermoved = true
		adz["shoulder"] = false
	elseif (value as number) < 0 and not adz["shoulder"] then
		adz["shoulder"] = true
	end
	if Gamestate then
		Gamestate.call("joystickaxis", slot, axis, value, stickmoved, shouldermoved)
	end
end

function love.joystickhat(joystick: any, hat: any, direction: any)
	local slot = joystick_slot(joystick as Joystick)
	if not slot then
		return
	end
	if Gamestate then
		Gamestate.call("joystickhat", slot, hat, direction)
	end
end

-- love.gamepadpressed = love.joystickpressed
-- love.gamepadreleased = love.joystickreleased
-- love.gamepadaxis = love.joystickaxis

function love.focus(_: any)
	--[[if not f and gamestate == "game"and not editormode and not levelfinished and not everyonedead  then
		pausemenuopen = true
		paused = love.audio.pause()
	end--]]
end

function love.quit()
	
end
