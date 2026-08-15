--[[ Single SoT: register domain handlers on Gamestate (no app.states/* layer). ]]

local function menu_konami_keypressed(key: any)
	ui_note_kbd()
	table.insert(konamitable, key as string)
	table.remove(konamitable, 1)
	local s = ""
	for i = 1, #konamitable do
		s = s .. tostring(konamitable[i])
	end

	if sha1(s) == konamihash then
		playsound("konami")
		gamefinished = true
		saveconfig()
		notice.new("Cheats unlocked!")
		enable_debugbinds()
	end
	menu_keypressed(key)
end

local function game_mousemoved(x: any, y: any, _dx: any, _dy: any)
	if pausemenuopen and not menuprompt and not desktopprompt and not suspendprompt then
		local ux = (x as number) / scale
		local uy = (y as number) / scale
		local lay = menu_layout_pause(width * 16)
		local i = menu_hit(lay.rects as {any}, ux, uy)
		if i then
			pausemenuselected = i
		end
	end
end

local function register(GS: GamestateModule)
	GS.register("intro", {
		update = intro_update,
		draw = intro_draw,
		keypressed = function()
			intro_keypressed()
		end,
		mousepressed = function()
			intro_mousepressed()
		end,
	})

	local with_mouse_move: {string:function} = {
		update = menu_update,
		draw = menu_draw,
		keypressed = menu_konami_keypressed,
		mousepressed = menu_mousepressed,
		mousemoved = menu_mousemoved,
	}

	local with_joy: {string:function} = {
		update = menu_update,
		draw = menu_draw,
		keypressed = menu_konami_keypressed,
		keyreleased = menu_keyreleased,
		mousepressed = menu_mousepressed,
		mousemoved = menu_mousemoved,
		mousereleased = menu_mousereleased,
		joystickpressed = function(slot: any, button: any)
			ui_note_kbd()
			menu_joystickpressed(slot, button)
		end,
		joystickreleased = menu_joystickreleased,
		joystickaxis = menu_joystickaxis,
		joystickhat = menu_joystickhat,
	}

	local onlinemenu_keypressed = function(key: any)
		if key == "escape" then
			Net.quit()
			return
		end
		menu_konami_keypressed(key)
	end

	GS.register("menu", with_joy)
	GS.register("options", with_joy)
	GS.register("mappackmenu", with_mouse_move)
	GS.register("onlinemenu", {
		update = menu_update,
		draw = menu_draw,
		keypressed = onlinemenu_keypressed,
		mousepressed = menu_mousepressed,
	})

	GS.register("lobby", {
		update = menu_update,
		draw = menu_draw,
		keypressed = function(key: any)
			if key == "escape" then
				Net.quit()
			end
		end,
	})

	for _, name in ipairs({"levelscreen", "gameover", "sublevelscreen", "mappackfinished"}) do
		GS.register(name, {
			update = levelscreen_update,
			draw = levelscreen_draw,
		})
	end

	GS.register("game", {
		update = game_update,
		draw = game_draw,
		keypressed = game_keypressed,
		keyreleased = game_keyreleased,
		textinput = game_textinput,
		mousepressed = game_mousepressed,
		mousereleased = game_mousereleased,
		mousemoved = game_mousemoved,
		joystickpressed = game_joystickpressed,
		joystickreleased = game_joystickreleased,
		joystickaxis = game_joystickaxis,
		joystickhat = game_joystickhat,
	})
end

return { register = register }
