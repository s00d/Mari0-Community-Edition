--[[ Teal port of root levelscreen.lua ]]

-- One-frame defer so the black splash can present before heavy loadlevel work.
-- Arm on first update; load on the next. Skiplevelscreen loads sync immediately.
local pending_level_load: string|number|nil = nil
local pending_level_armed = false
local levelscreen_timeout_handle: any = nil

local function cancel_levelscreen_timeout()
	if levelscreen_timeout_handle then
		HumpTimer.cancel(levelscreen_timeout_handle)
		levelscreen_timeout_handle = nil
	end
end

local function queue_level_load(level: string|number)
	pending_level_load = level
	pending_level_armed = false
end

local function flush_pending_level_load()
	if pending_level_load == nil then
		return
	end
	local level = pending_level_load
	pending_level_load = nil
	pending_level_armed = false
	loadlevel(level)
end

global function levelscreen_load(reason: any, levelarg?: any)
	
	--check if lives left
	livesleft = false
	for i = 1, players do
		if mariolivecount == false or (mariolives[i] as number) > 0 then
			livesleft = true
		end
	end
	
	if reason == "sublevel" then
		gamestate = "sublevelscreen"
		blacktime = sublevelscreentime
		sublevelscreen_level = levelarg as number
	elseif reason == "vine" then
		gamestate = "sublevelscreen"
		blacktime = sublevelscreentime
		sublevelscreen_level = levelarg as number
	elseif livesleft then
		gamestate = "levelscreen"
		blacktime = levelscreentime
		if reason == "next" then --next level
			checkpointsub = false
			checkpointx = {}
			checkpointy = {}
			respawnsublevel = mariosublevel or 0
			
			--check if next level doesn't exist
			if mariosublevel > 0 and not love.filesystem.getInfo(mappack_level_path(mappack, marioworld, mariolevel, mariosublevel)) then
				gamestate = "mappackfinished"
				blacktime = gameovertime
				music:play("princessmusic.ogg")
			elseif not love.filesystem.getInfo(mappack_level_path(mappack, marioworld, mariolevel)) then
				gamestate = "mappackfinished"
				blacktime = gameovertime
				music:play("princessmusic.ogg")
			end
		end
	else
		gamestate = "gameover"
		blacktime = gameovertime
		playsound("gameover")
	end
	
	if editormode then
		blacktime = 0
	end
	
	if reason ~= "initial" then
		updatesizes()
	end
	
	if marioworld == 1 or mariolevel == 1 then
		blacktime = blacktime * 1.5
	end
	
	coinframe = 1
	
	love.graphics.setBackgroundColor(0, 0, 0)
	levelscreentimer = 0
	
	--reached worlds
	local updated = false
	if not reachedworlds[mappack] then
		reachedworlds[mappack] = {}
	end
	
	if marioworld ~= "M" and not reachedworlds[mappack][marioworld] then
		reachedworlds[mappack][marioworld] = true
		updated = true
	end
	
	if updated then
		saveconfig()
	end
	
	-- Queue level load (defer one frame so splash can present first).
	if gamestate == "levelscreen" then
		if respawnsublevel ~= 0 then
			queue_level_load(tostring(marioworld) .. "-" .. tostring(mariolevel) .. "_" .. respawnsublevel)
		else
			queue_level_load(tostring(marioworld) .. "-" .. tostring(mariolevel))
		end
	elseif gamestate == "sublevelscreen" then
		queue_level_load(sublevelscreen_level)
	end
	
	if skiplevelscreen and gamestate ~= "gameover" and gamestate ~= "mappackfinished" then
		cancel_levelscreen_timeout()
		flush_pending_level_load()
		startlevel(gamestate == "levelscreen")
	else
		cancel_levelscreen_timeout()
		levelscreen_timeout_handle = HumpTimer.after(blacktime, function()
			levelscreen_timeout_handle = nil
			if gamestate == "levelscreen" or gamestate == "sublevelscreen" then
				flush_pending_level_load()
				startlevel(gamestate == "levelscreen")
			else
				menu_load()
			end
		end)
	end
end

global function levelscreen_update(dt: number)
	-- Frame 1: arm. Frame 2: load. Gives love.run one present of the black splash
	-- before enemies/map/GC work (avoids "frozen until minimize" on Love 12 Metal).
	if pending_level_load ~= nil then
		if pending_level_armed then
			flush_pending_level_load()
		else
			pending_level_armed = true
		end
	end

	levelscreentimer = levelscreentimer + dt
end

global function levelscreen_draw()
	--black background
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", 0, 0, width*16*scale, height*16*scale)
	love.graphics.setColor(1, 1, 1)

	if levelscreenback then
		love.graphics.draw(levelscreenback, 0, 0, 0, scale, scale)
	end
	
	if levelscreentimer < blacktime - blacktimesub and levelscreentimer > blacktimesub then
		if gamestate == "levelscreen" then
			local lay = menu_layout_levelscreen(width * 16)
			local p = lay.panel as {string:any}
			draw_panel(p.x as number, p.y as number, p.w as number, p.h as number)
			ui_set_color("text_accent")
			properprint("world " .. tostring(marioworld) .. "-" .. tostring(mariolevel), (width/2*16)*scale-40*scale, 64*scale - (players-1)*6*scale)
			ui_set_color("text")
			
			if not arcade and not mkstation then
				for i = 1, players do
					local x = width/2*16-29
					local y = 97 + (i-1)*20 - (players-1)*8
							
					local v = characters[mariocharacter[i]]
					local angle = 3
					if v.nopointing then
						angle = 1
					end
					
					local pid = i
					if pid > 4 then
						pid = 5
					end
					
					
					
					drawplayer(nil, x+6, y+11, scale,     v.smalloffsetX, v.smalloffsetY, 0, v.smallquadcenterX, v.smallquadcenterY, "idle", false, false, mariohats[i], v.animations, v.idle[angle], 0, false, false, mariocolors[i], 1, portalcolor[i][1], portalcolor[i][2], nil, nil, nil, nil, nil, nil, characters[mariocharacter[i]])
					
					love.graphics.setColor(1, 1, 1, 1)
					if mariolivecount == false then
						properprint("*  inf", (width/2*16)*scale-8*scale, y*scale+7*scale)
					else
						properprint("*  " .. mariolives[i], (width/2*16)*scale-8*scale, y*scale+7*scale)
					end
				end
			end
			
			
			if mappack == "smb" and marioworld == 1 and mariolevel == 1 then
				local run_bindings = controls[1]["run"] as {integer: string}
				local s = "remember that you can run with "
				for i = 1, #run_bindings do
					s = s .. binding_display(run_bindings[i])
					if i ~= #run_bindings then
						s = s .. "-"
					end
				end
				ui_set_color("text_dim")
				properprint(s, (width/2*16)*scale-string.len(s)*4*scale, 200*scale)
			end
			
			if mappack == "portal" and marioworld == 1 and mariolevel == 1 then
				local reload_bindings = controls[1]["reload"] as {integer: string}
				local s = "you can remove your portals with "
				for i = 1, #reload_bindings do
					s = s .. binding_display(reload_bindings[i])
					if i ~= #reload_bindings then
						s = s .. "-"
					end
				end
				ui_set_color("text_dim")
				properprint(s, (width/2*16)*scale-string.len(s)*4*scale, 190*scale)
				
				local use_bindings = controls[1]["use"] as {integer: string}
				local s = "you can grab cubes and push buttons with "
				for i = 1, #use_bindings do
					s = s .. binding_display(use_bindings[i])
					if i ~= #use_bindings then
						s = s .. "-"
					end
				end
				properprint(s, (width/2*16)*scale-string.len(s)*4*scale, 200*scale)
			end
			
		elseif gamestate == "mappackfinished" then
			ui_set_color("text_accent")
			properprint("congratulations!", (width/2*16)*scale-64*scale, 120*scale)
			ui_set_color("text")
			properprint("you have finished this mappack!", (width/2*16)*scale-128*scale, 140*scale)
		else
			local s = "game over"
			ui_set_color("text_accent")
			properprint(s, (width/2*16)*scale-40*scale, 120*scale)
		end		
		love.graphics.translate(0, -yoffset*scale)
		if yoffset < 0 then
			love.graphics.translate(0, yoffset*scale)
		end
		
		drawui(true)
	end
end
