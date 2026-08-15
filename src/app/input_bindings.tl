--[[ Baton input + UI pointer coords. controls[slot][action] = baton sources. ]]

local BatonMod = require("baton")

global ui_input_mode: string = "kbd"
global mouseui_x: number = 0
global mouseui_y: number = 0

global function screen_to_ui(x: number, y: number): number, number
	if fullscreen then
		if fullscreenmode == "full" then
			x = x / (desktopsize.width / (width * 16 * scale))
			y = y / (desktopsize.height / (height * 16 * scale))
		else
			x = x / (touchfrominsidescaling / scale)
			y = y / (touchfrominsidescaling / scale) - touchfrominsidemissing / 2
		end
	end
	return x, y
end

global function ui_set_input_mode(mode: string)
	ui_input_mode = mode
end

global function ui_note_mouse_move(dx: number, dy: number, x: number, y: number): boolean
	if (math.abs(dx) + math.abs(dy)) < 1 then
		return false
	end
	local ux, uy = screen_to_ui(x, y)
	mouseui_x, mouseui_y = ux, uy
	ui_input_mode = "mouse"
	return true
end

global function ui_note_kbd()
	ui_input_mode = "kbd"
end

global INPUT_ACTIONS = {
	"left", "right", "up", "down",
	"jump", "run", "reload", "use",
	"portal1", "portal2",
	"weaponnext", "weaponprev",
	"aimx", "aimy",
} as {string}

local baton_players: {integer: BatonInput} = {}
local sys_baton: BatonInput|nil = nil

local function rebuild_sys()
	sys_baton = BatonMod.new({
		controls = {
			shift = {"key:lshift", "key:rshift"},
			alt = {"key:lalt", "key:ralt"},
			ctrl = {"key:lctrl", "key:rctrl"},
			left = {"key:left"},
			right = {"key:right"},
			up = {"key:up"},
			down = {"key:down"},
			f1 = {"key:f1"},
		},
		deadzone = 0.3,
	}) as BatonInput
end

local function joystick_for(slot: integer): Joystick|nil
	if not love or not love.joystick or not love.joystick.getJoysticks then
		return nil
	end
	local raw: any = controls and controls[slot]
	if not raw or not raw.joy then
		return nil
	end
	local idx = raw.joy as integer
	local sticks = love.joystick.getJoysticks() as {Joystick}
	if idx < 1 or idx > #sticks then
		return nil
	end
	return sticks[idx]
end

local function rebuild_slot(slot: integer)
	local row = controls and controls[slot] as {string:any}|nil
	if not row then
		return
	end
	local cfg: {string: {string}} = {}
	for _, action in ipairs(INPUT_ACTIONS) do
		local sources = (row as {any:any})[action] as {string}|nil
		if not sources then
			sources = {}
		end
		cfg[action] = sources
	end
	baton_players[slot] = BatonMod.new({
		controls = cfg,
		joystick = joystick_for(slot),
		deadzone = (joystickdeadzone as number) or 0.3,
	}) as BatonInput
end

global function input_bindings_rebuild(slot: integer)
	if not sys_baton then
		rebuild_sys()
	end
	if slot == 0 then
		for i = 1, 4 do
			rebuild_slot(i)
		end
		return
	end
	rebuild_slot(slot)
end

global function input_bindings_init()
	rebuild_sys()
	input_bindings_rebuild(0)
end

-- Editor/menu modifiers + arrow keys (not player-rebinding).
global function sys_down(action: string): boolean
	if not sys_baton then
		rebuild_sys()
	end
	local p = sys_baton as BatonInput|nil
	if p == nil then
		return false
	end
	return (p as BatonInput):down(action)
end

-- Baton player for slot (use :get / :down / :pressed). Bindings table stays in `controls`.
global function input_player(slot: integer): any
	return baton_players[slot]
end

global function ui_input_update(_dt: number)
	local sys = sys_baton as BatonInput|nil
	if sys ~= nil then
		(sys as BatonInput):update()
	end
	for i = 1, players do
		local p = baton_players[i]
		if not p then
			-- skip
		elseif pausemenuopen or noupdate then
			p:update()
		else
			p:update()
			local pl = session.playerobjs and session.playerobjs[i]
			if not pl or pl.remote or not pl.controlsenabled then
				-- skip
			else
				if p:pressed("jump") then
					pl:jump()
				end
				if p:released("jump") then
					pl:stopjump()
				end
				if p:pressed("run") then
					pl:fire()
				end
				if p:pressed("reload") then
					pl:removeportals()
				end
				if p:pressed("use") then
					pl:use()
				end
				if p:pressed("left") then
					pl:leftkey()
				end
				if p:pressed("right") then
					pl:rightkey()
				end
				if p:pressed("weaponnext") then
					Weapons.switch(pl, 1)
				end
				if p:pressed("weaponprev") then
					Weapons.switch(pl, -1)
				end
				if i ~= mouseowner then
					local can_fire = not pl.vine
					if pl.grapple then
						local w = Weapons and Weapons.current(pl)
						can_fire = w ~= nil and w.id == "hookshot"
					end
					if can_fire then
						if p:pressed("portal1") then
							Weapons.fire(pl, "l")
						end
						if p:pressed("portal2") then
							Weapons.fire(pl, "r")
						end
					end
				end
			end
		end
	end
end

global function ui_action_down(slot: integer, action: string): boolean
	local p = baton_players[slot]
	return p ~= nil and p:down(action)
end

global function ui_action_get(slot: integer, action: string): number
	local p = baton_players[slot]
	if not p then
		return 0
	end
	return p:get(action)
end

global function binding_display(source: string): string
	local kind, val = source:match("^(.-):(.+)$")
	if kind == "key" then
		return val
	elseif kind == "button" then
		return "btn" .. val
	elseif kind == "hat" then
		return "hat" .. val
	elseif kind == "axis" then
		return "ax" .. val
	elseif kind == "mouse" then
		return "mouse" .. val
	end
	return source
end

local function net_held_action(i: integer, action: string): boolean|nil
	if not Net or not Net.is_online or not Net.is_online() then
		return nil
	end
	return Net.held_for(i, action)
end

local function gravity_action(i: integer, base: string): string
	local pl = session.playerobjs[i]
	if not pl then
		return base
	end
	local g = pl.gravitydirection
	if base == "left" then
		if g > math.pi/4*1 and g <= math.pi/4*3 then
			return "left"
		elseif g > math.pi/4*3 and g <= math.pi/4*5 then
			return "up"
		elseif g > math.pi/4*5 and g <= math.pi/4*7 then
			return "right"
		end
		return "down"
	elseif base == "right" then
		if g > math.pi/4*1 and g <= math.pi/4*3 then
			return "right"
		elseif g > math.pi/4*3 and g <= math.pi/4*5 then
			return "down"
		elseif g > math.pi/4*5 and g <= math.pi/4*7 then
			return "left"
		end
		return "up"
	elseif base == "up" then
		if g > math.pi/4*1 and g <= math.pi/4*3 then
			return "up"
		elseif g > math.pi/4*3 and g <= math.pi/4*5 then
			return "right"
		elseif g > math.pi/4*5 and g <= math.pi/4*7 then
			return "down"
		end
		return "left"
	end
	-- down
	if g > math.pi/4*1 and g <= math.pi/4*3 then
		return "down"
	elseif g > math.pi/4*3 and g <= math.pi/4*5 then
		return "left"
	elseif g > math.pi/4*5 and g <= math.pi/4*7 then
		return "up"
	end
	return "right"
end

local function polled(i: integer, action: string): boolean
	local netv = net_held_action(i, action)
	if netv ~= nil then
		return netv
	end
	if session.playerobjs[i] and session.playerobjs[i].remote then
		return false
	end
	return ui_action_down(i, action)
end

global function runkey(i: any): any
	return polled(i as integer, "run")
end

global function rightkey(i: any): any
	return polled(i as integer, gravity_action(i as integer, "right"))
end

global function leftkey(i: any): any
	return polled(i as integer, gravity_action(i as integer, "left"))
end

global function downkey(i: any): any
	return polled(i as integer, gravity_action(i as integer, "down"))
end

global function upkey(i: any): any
	return polled(i as integer, gravity_action(i as integer, "up"))
end

global function game_keypressed(key: any)
	if key == "return" then
		game_joystickpressed(1, 4)
	end

	if metroidmode and key == "m" then
		if metroidmapopen then metroidmap_close() else metroidmap_toggle() end
		return
	end
	if metroidmapopen then
		if key == "escape" or key == "m" then metroidmap_close() end
		return
	end

	if key == "f" and debugbinds then
		session.playerobjs[1]:grow()
	end

	if pausemenuopen then
		if menuprompt then
			if (key == "left" or key == "a") then
				pausemenuselected2 = 1
			elseif (key == "right" or key == "d") then
				pausemenuselected2 = 2
			elseif (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
				if pausemenuselected2 == 1 then
					love.audio.stop()
					pausemenuopen = false
					saveconfig()
					menuprompt = false
					menu_load()
				else
					menuprompt = false
				end
			elseif key == "escape" then
				menuprompt = false
			end
			return
		elseif desktopprompt then
			if (key == "left" or key == "a") then
				pausemenuselected2 = 1
			elseif (key == "right" or key == "d") then
				pausemenuselected2 = 2
			elseif (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
				if pausemenuselected2 == 1 then
					love.audio.stop()
					love.event.quit()
				else
					desktopprompt = false
				end
			elseif key == "escape" then
				desktopprompt = false
			end
			return
		elseif suspendprompt then
			if (key == "left" or key == "a") then
				pausemenuselected2 = 1
			elseif (key == "right" or key == "d") then
				pausemenuselected2 = 2
			elseif (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
				if pausemenuselected2 == 1 then
					love.audio.stop()
					suspendgame()
					suspendprompt = false
					pausemenuopen = false
					saveconfig()
				else
					suspendprompt = false
				end
			elseif key == "escape" then
				suspendprompt = false
			end
			return
		end
		if (key == "down" or key == "s") then
			if pausemenuselected < #pausemenuoptions then
				pausemenuselected = pausemenuselected + 1
			end
		elseif (key == "up" or key == "w") then
			if pausemenuselected > 1 then
				pausemenuselected = pausemenuselected - 1
			end
		elseif (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
			if pausemenuoptions[pausemenuselected as integer] == "resume" then
				pausemenuopen = false
				saveconfig()
				love.audio.play(paused)
			elseif pausemenuoptions[pausemenuselected as integer] == "suspend" then
				suspendprompt = true
				pausemenuselected2 = 1
			elseif pausemenuoptions2[pausemenuselected as integer] == "menu" then
				menuprompt = true
				pausemenuselected2 = 1
			elseif pausemenuoptions2[pausemenuselected as integer] == "desktop" then
				desktopprompt = true
				pausemenuselected2 = 1
			end
		elseif key == "escape" then
			pausemenuopen = false
			saveconfig()
			love.audio.play(paused)
		elseif (key == "right" or key == "d") then
			if pausemenuoptions[pausemenuselected as integer] == "music volume" then
				volumemusic = math.min(1, volumemusic + 0.1)
				audio_apply_volumes()
			elseif pausemenuoptions[pausemenuselected as integer] == "game volume" then
				volumesfx = math.min(1, volumesfx + 0.1)
				audio_apply_volumes()
				soundenabled = true
				playsound("coin")
			end
		elseif (key == "left" or key == "a") then
			if pausemenuoptions[pausemenuselected as integer] == "music volume" then
				volumemusic = math.max(volumemusic - 0.1, 0)
				audio_apply_volumes()
			elseif pausemenuoptions[pausemenuselected as integer] == "game volume" then
				volumesfx = math.max(volumesfx - 0.1, 0)
				audio_apply_volumes()
				if volumesfx == 0 then
					soundenabled = false
				end
				playsound("coin")
			end
		end
		return
	end

	if endpressbutton then
		endpressbutton = false
		endgame()
		return
	end

	if key == "escape" then
		if not editormode and testlevel then
			local shift = sys_down("shift")
			if editor_test_restore and session.objects and session.objects["player"] and session.objects["player"][1] then
				local pl = session.objects["player"][1] as {string:any}
				(editor_test_restore as {string:any}).death_x = pl.x
				(editor_test_restore as {string:any}).death_y = pl.y
			end
			checkpointsub = false
			marioworld = testlevelworld
			mariolevel = testlevellevel
			testlevel = false
			editormode = true
			camera_pan_stop()
			if (mariosublevel as number) > 0 then
				loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel) .. "_" .. tostring(mariosublevel))
			else
				loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel))
			end
			startlevel()
			editor_apply_test_restore(shift)
			return
		elseif not editormode and not everyonedead then
			pausemenuopen = true
			paused = love.audio.pause()
			playsound("pause")
		end
	end

	if key == "t" and editordebug then
		editormode = not editormode
	end

	if editormode then
		editor_keypressed(key)
	end
end

global function game_keyreleased(_key: any)
end

global function game_textinput(text: any)
	if editormode and not testlevel then
		editor_textinput(text)
	end
end

global function game_mousepressed(x: any, y: any, button: any)
	if pausemenuopen then
		if button ~= "l" then
			return
		end
		local ux = (x as number) / scale
		local uy = (y as number) / scale
		if menuprompt or desktopprompt or suspendprompt then
			local cx = width * 8
			if uy >= 100 and uy <= 130 then
				if ux < cx then
					pausemenuselected2 = 1
					game_keypressed("return")
				else
					pausemenuselected2 = 2
					game_keypressed("return")
				end
			end
			return
		end
		local lay = menu_layout_pause(width * 16)
		local i = menu_hit(lay.rects as {any}, ux, uy)
		if i then
			if i == pausemenuselected then
				game_keypressed("return")
			else
				pausemenuselected = i
			end
		end
		return
	end

	if frameskip then
		if button == "wu" then
			frameskip = math.max(0, (frameskip as number) - 1)
			return
		elseif button == "wd" then
			frameskip = (frameskip as number) + 1
			return
		end
	end

	if editormode then
		editor_mousepressed(x, y, button)
	else
		if not noupdate and session.playerobjs[mouseowner] and session.playerobjs[mouseowner].controlsenabled and session.playerobjs[mouseowner].vine == false then
			local pl = session.playerobjs[mouseowner]
			local allow_fire = not pl.grapple
			if pl.grapple then
				local curw = Weapons and Weapons.current(pl)
				allow_fire = curw ~= nil and curw.id == "hookshot"
			end
			if allow_fire then
				if button == "l" or button == "r" and session.playerobjs[mouseowner] then
					if portalknockback then
						local xadd = math.sin(session.playerobjs[mouseowner].pointingangle)*30
						local yadd = math.cos(session.playerobjs[mouseowner].pointingangle)*30
						session.playerobjs[mouseowner].speedx = session.playerobjs[mouseowner].speedx + xadd
						session.playerobjs[mouseowner].speedy = session.playerobjs[mouseowner].speedy + yadd
						session.playerobjs[mouseowner].falling = true
						session.playerobjs[mouseowner].animationstate = "falling"
						session.playerobjs[mouseowner]:setquad()
					end
				end
				if button == "l" then
					Weapons.fire(session.playerobjs[mouseowner], "l")
				elseif button == "r" then
					Weapons.fire(session.playerobjs[mouseowner], "r")
				end
			end
		end
		if button == "wd" then
			if bullettime then
				speedtarget = speedtarget - 0.1
				if speedtarget < 0.1 then
					speedtarget = 0.1
				end
			elseif speeddebug then
				speed = math.max(0, speed/2)
			elseif session.playerobjs[mouseowner] then
				Weapons.switch(session.playerobjs[mouseowner], 1)
			end
		elseif button == "wu" then
			if bullettime then
				speedtarget = speedtarget + 0.1
				if speedtarget > 1 then
					speedtarget = 1
				end
			elseif speeddebug then
				speed = math.min(1, speed*2)
			elseif session.playerobjs[mouseowner] then
				Weapons.switch(session.playerobjs[mouseowner], -1)
			end
		end
	end
end

global function game_mousereleased(x: any, y: any, button: any)
	if editormode then
		editor_mousereleased(x, y, button)
	end
end

global function game_joystickpressed(_joystick: any, _button: any)
	if pausemenuopen then
		return
	end
	if endpressbutton then
		endgame()
	end
end

global function game_joystickreleased(_joystick: any, _button: any)
end

global function game_joystickaxis(_joystick: any, _axis: any, _value: any, _stickmoved: any, _shouldermoved: any)
	if pausemenuopen then
		return
	end
	if endpressbutton then
		endgame()
	end
end

global function game_joystickhat(_joystick: any, _hat: any, _direction: any)
	if pausemenuopen then
		return
	end
	if endpressbutton then
		endgame()
	end
end
