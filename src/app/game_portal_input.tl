--[[ portal / game input handlers ]]

global function game_keypressed(key: any)
	
	if key == "return" then
		game_joystickpressed(1, 4)
	end
	
	if key == "f" and debugbinds then
		playerobjs[1]:grow()
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
				love.audio.setVolume( volumesfx )
				music:setVolume( volumemusic )
			elseif pausemenuoptions[pausemenuselected as integer] == "game volume" then
				volumesfx = math.min(1, volumesfx + 0.1)
				love.audio.setVolume( volumesfx )
				music:setVolume( volumemusic )
				soundenabled = true
				playsound("coin")
			end
			
		elseif (key == "left" or key == "a") then
			if pausemenuoptions[pausemenuselected as integer] == "music volume" then
				volumemusic = math.max(volumemusic - 0.1, 0)
				love.audio.setVolume( volumesfx )
				music:setVolume( volumemusic )
			elseif pausemenuoptions[pausemenuselected as integer] == "game volume" then
				volumesfx = math.max(volumesfx - 0.1, 0)
				love.audio.setVolume( volumesfx )
				music:setVolume( volumemusic )
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

	for i = 1, players do
		-- Online remotes are driven by host-auth net input, not local keys.
		if playerobjs[i] and playerobjs[i].remote then
			-- skip
		elseif controls[i]["jump"][1] == key then
			playerobjs[i]:jump()
		elseif controls[i]["run"][1] == key then
			playerobjs[i]:fire()
		elseif controls[i]["reload"][1] == key then
			playerobjs[i]:removeportals()
		elseif controls[i]["use"][1] == key then
			playerobjs[i]:use()
		elseif controls[i]["left"][1] == key then
			playerobjs[i]:leftkey()
		elseif controls[i]["right"][1] == key then
			playerobjs[i]:rightkey()
		end

		if playerobjs[i] and not playerobjs[i].remote then
			if controls[i]["portal1"][i] == key then
				Weapons.fire(playerobjs[i], "l")
				return
			end

			if controls[i]["portal2"][i] == key then
				Weapons.fire(playerobjs[i], "r")
				return
			end

			if controls[i]["weaponnext"] and controls[i]["weaponnext"][1] == key then
				Weapons.switch(playerobjs[i], 1)
				return
			end
			if controls[i]["weaponprev"] and controls[i]["weaponprev"][1] == key then
				Weapons.switch(playerobjs[i], -1)
				return
			end
		end
	end
	
	if key == "escape" then
		if not editormode and testlevel then
			checkpointsub = false
			marioworld = testlevelworld
			mariolevel = testlevellevel
			testlevel = false
			editormode = true
			xpan = false
			ypan = false
			
			if (mariosublevel as number) > 0 then
				loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel) .. "_" .. tostring(mariosublevel))
			else
				loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel))
			end
			startlevel()
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

global function game_keyreleased(key: any)
	
	for i = 1, players do
		if playerobjs[i] and playerobjs[i].remote then
			-- skip
		elseif controls[i]["jump"][1] == key then
			playerobjs[i]:stopjump()
		end
	end
end

global function game_textinput(text: any)
	
	if editormode and not testlevel then
		editor_textinput(text)
	end
end

global function shootportal(plnumber: any, i: any, sourcex: any, sourcey: any, direction: any, mirrored?: any, bounces?: any)
	if playerobjs[plnumber].portalgundisabled then
		return
	end
	
	--check if available
	if not (playerobjs[plnumber].portalsavailable as {boolean})[i as integer] then
		return
	end
	
	--box
	if playerobjs[plnumber].pickup then
		return
	end
	-- per-weapon cooldown (also mirrors portaldelay for legacy)
	local pl = playerobjs[plnumber]
	if not pl.weapondelay then
		pl.weapondelay = {}
	end
	if ((pl.weapondelay as {string:number}).portal or 0) > 0 or (portaldelay[plnumber as number] or 0) > 0 then
		return
	else
		(pl.weapondelay as {string:number}).portal = portalgundelay
		portaldelay[plnumber as number] = portalgundelay
	end
	
	local color = playerobjs[plnumber].portal2color
	if i == 1 then
		color = playerobjs[plnumber].portal1color
	end
	
	if not mirrored then
		playerobjs[plnumber].lastportal = i as number
	end
	local sxn: number = sourcex as number
	local syn: number = sourcey as number
	local dirn: number = direction as number
	local cox, coy, side, tendency, x, y = traceline(sxn, syn, dirn, nil)
	
	local mirror = false
	if cox and tilequads[map[cox as number][coy as number][1]] and tilequads[map[cox as number][coy as number][1]]:getproperty("mirror", cox as number, coy as number) then
		mirror = true
	end
	
	playerobjs[plnumber].lastportal = i as number
	
	table.insert(portalprojectiles, portalprojectile:new(sourcex as number, sourcey as number, x as number, y as number, color, true, {playerobjs[plnumber].portal, i, cox, coy, side, tendency, x, y}, mirror, mirrored, bounces))
end

global function game_mousepressed(x: any, y: any, button: any)
	if pausemenuopen then
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
		if editormode then
			editor_mousepressed(x, y, button)
		end
		
		if not noupdate and playerobjs[mouseowner] and playerobjs[mouseowner].controlsenabled and playerobjs[mouseowner].vine == false then
		
			if button == "l" or button == "r" and playerobjs[mouseowner] then
				--knockback
				if portalknockback then
					local xadd = math.sin(playerobjs[mouseowner].pointingangle)*30
					local yadd = math.cos(playerobjs[mouseowner].pointingangle)*30
					playerobjs[mouseowner].speedx = playerobjs[mouseowner].speedx + xadd
					playerobjs[mouseowner].speedy = playerobjs[mouseowner].speedy + yadd
					playerobjs[mouseowner].falling = true
					playerobjs[mouseowner].animationstate = "falling"
					playerobjs[mouseowner]:setquad()
				end
			end
		
			if button == "l" then
				Weapons.fire(playerobjs[mouseowner], "l")
			elseif button == "r" then
				Weapons.fire(playerobjs[mouseowner], "r")
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
			elseif playerobjs[mouseowner] then
				Weapons.switch(playerobjs[mouseowner], 1)
			end
		elseif button == "wu" then
			if bullettime then
				speedtarget = speedtarget + 0.1
				if speedtarget > 1 then
					speedtarget = 1
				end
			elseif speeddebug then
				speed = math.min(1, speed*2)
			elseif playerobjs[mouseowner] then
				Weapons.switch(playerobjs[mouseowner], -1)
			end
		end
	end
end

global function game_mousereleased(x: any, y: any, button: any)
	
	if editormode then
		editor_mousereleased(x, y, button)
	end
end

local function net_held_action(i: any, action: string): boolean|nil
	-- Offline singleplayer: never consult net_held (avoids extra lookups / wrong remote gating).
	if not (SERVER or CLIENT) then
		return nil
	end
	local slot = i as integer
	if not net_held or not net_held[slot] then
		return nil
	end
	return net_held[slot][action] == true
end

global function runkey(i: any): any
	local netv = net_held_action(i, "run")
	if netv ~= nil then
		return netv
	end
	if playerobjs and playerobjs[i] and playerobjs[i].remote then
		return false
	end
	return checkkey(controls[i]["run"])
end

global function rightkey(i: any): any
	local action = "right"
	if playerobjs[i].gravitydirection > math.pi/4*1 and playerobjs[i].gravitydirection <= math.pi/4*3 then
		action = "right"
	elseif playerobjs[i].gravitydirection > math.pi/4*3 and playerobjs[i].gravitydirection <= math.pi/4*5 then
		action = "down"
	elseif playerobjs[i].gravitydirection > math.pi/4*5 and playerobjs[i].gravitydirection <= math.pi/4*7 then
		action = "left"
	else
		action = "up"
	end
	local netv = net_held_action(i, action)
	if netv ~= nil then
		return netv
	end
	if playerobjs and playerobjs[i] and playerobjs[i].remote then
		return false
	end
	return checkkey(controls[i][action])
end

global function leftkey(i: any): any
	local action = "left"
	if playerobjs[i].gravitydirection > math.pi/4*1 and playerobjs[i].gravitydirection <= math.pi/4*3 then
		action = "left"
	elseif playerobjs[i].gravitydirection > math.pi/4*3 and playerobjs[i].gravitydirection <= math.pi/4*5 then
		action = "up"
	elseif playerobjs[i].gravitydirection > math.pi/4*5 and playerobjs[i].gravitydirection <= math.pi/4*7 then
		action = "right"
	else
		action = "down"
	end
	local netv = net_held_action(i, action)
	if netv ~= nil then
		return netv
	end
	if playerobjs and playerobjs[i] and playerobjs[i].remote then
		return false
	end
	return checkkey(controls[i][action])
end

global function downkey(i: any): any
	local action = "down"
	if playerobjs[i].gravitydirection > math.pi/4*1 and playerobjs[i].gravitydirection <= math.pi/4*3 then
		action = "down"
	elseif playerobjs[i].gravitydirection > math.pi/4*3 and playerobjs[i].gravitydirection <= math.pi/4*5 then
		action = "left"
	elseif playerobjs[i].gravitydirection > math.pi/4*5 and playerobjs[i].gravitydirection <= math.pi/4*7 then
		action = "up"
	else
		action = "right"
	end
	local netv = net_held_action(i, action)
	if netv ~= nil then
		return netv
	end
	if playerobjs and playerobjs[i] and playerobjs[i].remote then
		return false
	end
	return checkkey(controls[i][action])
end

global function upkey(i: any): any
	local action = "up"
	if playerobjs[i].gravitydirection > math.pi/4*1 and playerobjs[i].gravitydirection <= math.pi/4*3 then
		action = "up"
	elseif playerobjs[i].gravitydirection > math.pi/4*3 and playerobjs[i].gravitydirection <= math.pi/4*5 then
		action = "right"
	elseif playerobjs[i].gravitydirection > math.pi/4*5 and playerobjs[i].gravitydirection <= math.pi/4*7 then
		action = "down"
	else
		action = "left"
	end
	local netv = net_held_action(i, action)
	if netv ~= nil then
		return netv
	end
	if playerobjs and playerobjs[i] and playerobjs[i].remote then
		return false
	end
	return checkkey(controls[i][action])
end

global function checkkey(s: any): any
	local ctrl = (s as {any})
	if ctrl[1] == "joy" then
		local j = love.joystick.getJoysticks()[ctrl[2] as integer]
		if not j then
			return false
		end
		
		if ctrl[3] == "hat" then
			if string.match(j:getHat(ctrl[4] as number), ctrl[5] as string) then
				return true
			else
				return false
			end
		elseif ctrl[3] == "but" then
			if ((j as {string:any}).isDown as function(any, any): boolean)(j, ctrl[4]) then
				return true
			else
				return false
			end
		elseif ctrl[3] == "axe" then
			if ctrl[5] == "pos" then
				if j:getAxis(ctrl[4] as number) > joystickdeadzone then
					return true
				else
					return false
				end
			else
				if j:getAxis(ctrl[4] as number) < -joystickdeadzone then
					return true
				else
					return false
				end
			end
		end
	elseif ctrl[1] then
		if love.keyboard.isDown(ctrl[1] as string) then
			return true
		else 
			return false
		end
	end
end

global function game_joystickpressed(joystick: any, button: any)
	if pausemenuopen then
		return
	end
	if endpressbutton then
		endgame()
		return
	end
	
	for i = 1, players do
		if not noupdate and playerobjs[i].controlsenabled and not playerobjs[i].vine and not playerobjs[i].remote then
			local s1 = controls[i]["jump"]
			local s2 = controls[i]["run"]
			local s3 = controls[i]["reload"]
			local s4 = controls[i]["use"]
			local s5 = controls[i]["left"]
			local s6 = controls[i]["right"]
			if s1[1] == "joy" and joystick == s1[2] and s1[3] == "but" and button == s1[4] then
				playerobjs[i]:jump()
				return
			elseif s2[1] == "joy" and joystick == s2[2] and s2[3] == "but" and button == s2[4] then
				playerobjs[i]:fire()
				return
			elseif s3[1] == "joy" and joystick == s3[2] and s3[3] == "but" and button == s3[4] then
				playerobjs[i]:removeportals()
				return
			elseif s4[1] == "joy" and joystick == s4[2] and s4[3] == "but" and button == s4[4] then
				playerobjs[i]:use()
				return
			elseif s5[1] == "joy" and joystick == s5[2] and s5[3] == "but" and button == s5[4] then
				playerobjs[i]:leftkey()
				return
			elseif s6[1] == "joy" and joystick == s6[2] and s6[3] == "but" and button == s6[4] then
				playerobjs[i]:rightkey()
				return
			end
			
			if i ~= mouseowner then
				local s = controls[i]["portal1"]
				if s and s[1] == "joy" then
					if s[3] == "but" then
						if joystick == s[2] and button == s[4] then
							Weapons.fire(playerobjs[i], "l")
							return
						end
					end
				end
				
				local s = controls[i]["portal2"]
				if s and s[1] == "joy" then
					if s[3] == "but" then
						if joystick == s[2] and button == s[4] then
							Weapons.fire(playerobjs[i], "r")
							return
						end
					end
				end

				local sn = controls[i]["weaponnext"]
				if sn and sn[1] == "joy" and sn[3] == "but" and joystick == sn[2] and button == sn[4] then
					Weapons.switch(playerobjs[i], 1)
					return
				end
				local sp = controls[i]["weaponprev"]
				if sp and sp[1] == "joy" and sp[3] == "but" and joystick == sp[2] and button == sp[4] then
					Weapons.switch(playerobjs[i], -1)
					return
				end
			end
		end
	end
end

global function game_joystickreleased(joystick: any, button: any)
	for i = 1, players do
		local s = controls[i]["jump"]
		if s[1] == "joy" then
			if s[3] == "but" then
				if joystick == s[2] and button == s[4] then
					playerobjs[i]:stopjump()
					return
				end
			end
		end
	end
end

global function game_joystickaxis(joystick: any, axis: any, value: any, stickmoved: any, shouldermoved: any)
	if pausemenuopen then
		return
	end
	if endpressbutton then
		endgame()
		return
	end

	for i = 1, players do
		if not noupdate and playerobjs[i].controlsenabled then
			local s1 = controls[i]["left"]
			local s2 = controls[i]["right"]
			if s1[1] == "joy" and joystick == s1[2] and s1[3] == "axe" and s1[4] == axis and stickmoved and (value as number) < 0 then
				playerobjs[i]:leftkey()
				return
			elseif s2[1] == "joy" and joystick == s2[2] and s2[3] == "axe" and s2[4] == axis and stickmoved and (value as number) > 0 then
				playerobjs[i]:rightkey()
				return
			end
			
			if i ~= mouseowner then
				local s = controls[i]["portal1"]
				if s and s[1] == "joy" then
					if s[3] == "axe" and s[4] == axis then
						if joystick == s[2] and shouldermoved then
							Weapons.fire(playerobjs[i], "l")
							return
						end
					end
				end
				
				local s = controls[i]["portal2"]
				if s and s[1] == "joy" then
					if s[3] == "axe" and s[4] == axis then
						if joystick == s[2] and shouldermoved then
							Weapons.fire(playerobjs[i], "r")
							return
						end
					end
				end
			end
		end
	end
end

global function game_joystickhat(joystick: any, hat: any, direction: any)
	if pausemenuopen then
		return
	end
	if endpressbutton then
		endgame()
		return
	end

	for i = 1, players do
		if not noupdate and playerobjs[i].controlsenabled then
			local s1 = controls[i]["left"]
			local s2 = controls[i]["right"]
			if s1[1] == "joy" and joystick == s1[2] and s1[3] == "hat" and s1[4] == hat and (s1[5] as string):find(direction as string) then
				playerobjs[i]:leftkey()
				return
			elseif s2[1] == "joy" and joystick == s2[2] and s2[3] == "hat" and s2[4] == hat and (s2[5] as string):find(direction as string) then
				playerobjs[i]:rightkey()
				return
			end
		end
		
		if i ~= mouseowner then
			local s = controls[i]["portal1"]
			if s and s[1] == "joy" then
				if s[3] == "hat" and s[4] == hat then
					if joystick == s[2] and (s[5] as string):find(direction as string) then
						Weapons.fire(playerobjs[i], "l")
						return
					end
				end
			end
			
			local s = controls[i]["portal2"]
			if s and s[1] == "joy" then
				if s[3] == "hat" and s[4] == hat then
					if joystick == s[2] and (s[5] as string):find(direction as string) then
						Weapons.fire(playerobjs[i], "r")
						return
					end
				end
			end
		end
	end
end

