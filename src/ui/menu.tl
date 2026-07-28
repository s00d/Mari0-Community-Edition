--[[ Menu UI (Teal port of root menu.lua). ]]

require "assets.spritebatch_util"

-- Cursor bar slides; labels stay fixed (no sliding text).
local menu_cursor_y: number = 0
local menu_cursor_ready: boolean = false
local menu_hover_a: number = 0
local menu_hover_i: integer|nil = nil
global mappack_skipped_count: number = 0

local function scroll_ease(cur: number, target: number, dt: number): number
	return menu_ease(cur, target, dt, 0.12)
end

local function main_layout(): {string:any}
	if not MENU_SCREENS.main then
		menu_defs_bind()
	end
	return menu_layout_main(MENU_SCREENS.main)
end

local function main_activate(index: integer)
	local lay = main_layout()
	local items = lay.items as {any}
	local raw = items[index]
	if not raw then
		return
	end
	local it = raw as {string:any}
	local act = it.action as function()|nil
	if act ~= nil then
		(act as function())()
	end
end

local function main_players_spinner(): {string:any}|nil
	local screen = MENU_SCREENS.main
	if not screen then
		return nil
	end
	local sp_raw = screen.spinners
	if not sp_raw then
		return nil
	end
	local sp = sp_raw as {any}
	local first = sp[1]
	if not first then
		return nil
	end
	return first as {string:any}
end

local function spin_call(which: string)
	local spin = main_players_spinner()
	if not spin then
		return
	end
	local s = spin as {string:any}
	local fn = s[which] as function()|nil
	if fn ~= nil then
		(fn as function())()
	end
end

-- Labels stay at fixed row Y. Selection bar / cursor are drawn separately (lerped).
local function draw_menu_item(r: {string:any}, state: string)
	local s = scale
	if state == "selected" then
		ui_set_color("text_accent")
	elseif r.disabled then
		ui_set_color("text_dim")
	else
		ui_set_color("text")
	end
	local label = r.label as string
	local text_x = (r.x as number) + UI.PAD + 8
	if (r.id as string) == "newgame" then
		local spin = main_players_spinner()
		local nstr = tostring(players)
		if spin then
			local getter = (spin as {string:any}).get as function(): string|nil
			if getter ~= nil then
				nstr = (getter as function(): string)()
			end
		end
		if players > 1 then
			properprint("_dir3", ((r.x as number) + UI.PAD) * s, ((r.y as number) + 4) * s)
		end
		properprint(nstr, ((r.x as number) + UI.PAD + 16) * s, ((r.y as number) + 4) * s)
		if players < 4 then
			properprint("_dir5", ((r.x as number) + UI.PAD + 32) * s, ((r.y as number) + 4) * s)
		end
		properprint(label, ((r.x as number) + UI.PAD + 56) * s, ((r.y as number) + 4) * s)
	else
		properprint(label, text_x * s, ((r.y as number) + 4) * s)
	end
	love.graphics.setColor(1, 1, 1, 1)
end

global function menu_load()
	loadconfig()
	love.audio.stop()
	editormode = false
	gamestate = "menu"
	menu_defs_bind()
	menu_cursor_ready = false
	menu_hover_a = 0
	menu_hover_i = nil
	ui_set_input_mode("kbd")
	
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	selection = 1
	coinanimation = 1
	love.graphics.setBackgroundColor(92 / 255, 148 / 255, 252 / 255)
	scrollsmoothrate = 4
	optionstab = 2
	optionsselection = 1
	skinningplayer = 1
	rgbselection = 1
	mappackselection = 1
	onlinemappackselection = 1
	toconvertmappackselection = 1
	mappackhorscroll = 0
	mappackhorscrollsmooth = 0
	colorsetedit = 1
	love.graphics.setBackgroundColor(backgroundcolor[1])
	
	controlstable = {"left", "right", "up", "down", "run", "jump", "reload", "use", "aimx", "aimy", "portal1", "portal2", "weaponnext", "weaponprev"} as {number:string}
	
	portalanimation = 1
	portalanimationtimer = 0
	portalanimationdelay = 0.08
	
	infmarioY = 0
	infmarioR = 0
	
	infmarioYspeed = 200
	infmarioRspeed = 4
	
	RGBchangespeed = 0.8
	huechangespeed = 0.5
	spriteset = 1
	
	portalcolors = {}
	for i = 1, players do
		portalcolors[i] = {}
	end
	
	continueavailable = false
	if love.filesystem.getInfo("suspend.txt") then
		continueavailable = true
	end
	-- selection is 1-based into visible items; default highlight stays on newgame
	local lay = main_layout()
	local items = lay.items as {any}
	selection = 1
	for i = 1, #items do
		if ((items[i] as {string:any}).id as string) == "newgame" then
			selection = i
			break
		end
	end

	mariolevel = 1
	marioworld = 1
	mariosublevel = 0

	mariolives = nil
	
	--load 1-1 as background
	loadbackgroundsafe("1-1.txt")
	
	(require("app.love_frame") as LoveFrameModule).request_skip_update()
	
	if (arcade or mkstation) and firstload then
		firstload = false
		if arcade then
			mappack = "smb"
		elseif mkstation then
		--	mappack = "portal"
		end
		game_load()
	end

	init_game_runtime_globals()
	local GlobalFreeze = require("core.global_freeze")
	if not GlobalFreeze.is_installed() then
		GlobalFreeze.install_writes_only()
	end
end

global function menu_update(dt: number)
	if gamestate == "menu" and not selectworldopen then
		local lay = main_layout()
		local rects = lay.rects as {any}
		local sel = math.max(1, math.min(selection as integer, #rects))
		selection = sel
		local target_y = ((rects[sel] as {string:any}).y as number)
		if not menu_cursor_ready then
			menu_cursor_y = target_y
			menu_cursor_ready = true
		else
			-- Smooth cursor bar only (~90ms); labels never slide.
			menu_cursor_y = menu_ease(menu_cursor_y, target_y, dt, 0.09)
		end
		local want_hover = (ui_input_mode == "mouse") and menu_hover_i ~= nil
		local hover_target = want_hover and 1 or 0
		menu_hover_a = menu_ease(menu_hover_a, hover_target, dt, 0.05)
	end

	--coinanimation
	coinanimation = coinanimation + dt*6.75
	while coinanimation >= 6 do
		coinanimation = coinanimation - 5
	end	
	coinframe = math.max(1, math.floor(coinanimation))
	
	--Animate animated tiles because I say so
	for i = 1, #animatedtiles do
		animatedtiles[i]:update(dt)
	end
	
	if mappackscroll then
		mappackscrollsmooth = scroll_ease(mappackscrollsmooth, mappackscroll, dt)
	end
	
	if onlinemappackscroll then
		onlinemappackscrollsmooth = scroll_ease(onlinemappackscrollsmooth, onlinemappackscroll, dt)
	end
	
	if toconvertmappackscroll then
		toconvertmappackscrollsmooth = scroll_ease(toconvertmappackscrollsmooth, toconvertmappackscroll, dt)
	end
	
	if mappackhorscroll ~= nil then
		mappackhorscrollsmooth = scroll_ease(mappackhorscrollsmooth or 0, mappackhorscroll, dt)
	end
	
	if gamestate == "options" and optionstab == 2 then
		portalanimationtimer = portalanimationtimer + dt
		while portalanimationtimer > portalanimationdelay do
			portalanimation = portalanimation + 1
			if portalanimation > 6 then
				portalanimation = 1
			end
			portalanimationtimer = portalanimationtimer - portalanimationdelay
		end
		
		infmarioY = infmarioY + infmarioYspeed*dt
		while infmarioY > 64 do
			infmarioY = infmarioY - 64
		end
		
		infmarioR = infmarioR + infmarioRspeed*dt
		while infmarioR > math.pi*2 do
			infmarioR = infmarioR - math.pi*2
		end
	
		if characters[mariocharacter[skinningplayer]].colorables and optionsselection > 5 and optionsselection < 9 then
			local colorRGB = optionsselection-5
			
			if (love.keyboard.isDown("right") or love.keyboard.isDown("d")) and mariocolors[skinningplayer][colorsetedit][colorRGB] < 1 then
				mariocolors[skinningplayer][colorsetedit][colorRGB] = mariocolors[skinningplayer][colorsetedit][colorRGB] + RGBchangespeed*dt
				if mariocolors[skinningplayer][colorsetedit][colorRGB] > 1 then
					mariocolors[skinningplayer][colorsetedit][colorRGB] = 1
				end
			elseif (love.keyboard.isDown("left") or love.keyboard.isDown("a")) and mariocolors[skinningplayer][colorsetedit][colorRGB] > 0 then
				mariocolors[skinningplayer][colorsetedit][colorRGB] = mariocolors[skinningplayer][colorsetedit][colorRGB] - RGBchangespeed*dt
				if mariocolors[skinningplayer][colorsetedit][colorRGB] < 0 then
					mariocolors[skinningplayer][colorsetedit][colorRGB] = 0
				end
			end
			
		elseif (characters[mariocharacter[skinningplayer]].colorables and optionsselection == 9) or (not characters[mariocharacter[skinningplayer]].colorables and optionsselection == 4) then
			if (love.keyboard.isDown("right") or love.keyboard.isDown("d")) and portalhues[skinningplayer][1] < 1 then
				portalhues[skinningplayer][1] = portalhues[skinningplayer][1] + huechangespeed*dt
				if portalhues[skinningplayer][1] > 1 then
					portalhues[skinningplayer][1] = 1
				end
				portalcolor[skinningplayer][1] = getrainbowcolor(portalhues[skinningplayer][1]) as {number}
				
			elseif (love.keyboard.isDown("left") or love.keyboard.isDown("a")) and portalhues[skinningplayer][1] > 0 then
				portalhues[skinningplayer][1] = portalhues[skinningplayer][1] - huechangespeed*dt
				if portalhues[skinningplayer][1] < 0 then
					portalhues[skinningplayer][1] = 0
				end
				portalcolor[skinningplayer][1] = getrainbowcolor(portalhues[skinningplayer][1]) as {number}
			end
			
		elseif (characters[mariocharacter[skinningplayer]].colorables and optionsselection == 10) or (not characters[mariocharacter[skinningplayer]].colorables and optionsselection == 5) then
			if (love.keyboard.isDown("right") or love.keyboard.isDown("d")) and portalhues[skinningplayer][2] < 1 then
				portalhues[skinningplayer][2] = portalhues[skinningplayer][2] + huechangespeed*dt
				if portalhues[skinningplayer][2] > 1 then
					portalhues[skinningplayer][2] = 1
				end
				portalcolor[skinningplayer][2] = getrainbowcolor(portalhues[skinningplayer][2]) as {number}
				
			elseif (love.keyboard.isDown("left") or love.keyboard.isDown("a")) and portalhues[skinningplayer][2] > 0 then
				portalhues[skinningplayer][2] = portalhues[skinningplayer][2] - huechangespeed*dt
				if portalhues[skinningplayer][2] < 0 then
					portalhues[skinningplayer][2] = 0
				end
				portalcolor[skinningplayer][2] = getrainbowcolor(portalhues[skinningplayer][2]) as {number}
			end
		end
	elseif gamestate == "onlinemenu" then
		onlinemenu_update(dt)
	elseif gamestate == "lobby" then
		lobby_update(dt)
	end
end

global function menu_draw()
	--GUI LIBRARY?! Never heard of that.
	--I'm not proud of this at all; But I'm even lazier than not proud. Seriously, don't take this as an example of what to do.
	
	drawlevel()
	drawui()
	
	for j = 1, players do
		local v = characters[mariocharacter[j]]
		local angle = 3
		if v.nopointing then
			angle = 1
		end
		
		local pid = j
		if pid > 4 then
			pid = 5
		end
		
		local portalcolor1, portalcolor2 = portalcolor[j][1], portalcolor[j][2]
		
		if players == 1 then
			portalcolor1, portalcolor2 = {60 / 255, 188 / 255, 252 / 255}, {232 / 255, 130 / 255, 30 / 255}
		end
		
		drawplayer(nil, (((startx[pid] as number)-xscroll)*16)+8*(j-1), (((starty[pid] as number)-yscroll)*16-12), scale,     v.smalloffsetX, v.smalloffsetY, 0, v.smallquadcenterX, v.smallquadcenterY, "idle", false, false, mariohats[j], v.animations, v.idle[angle], 0, false, false, mariocolors[j], 1, portalcolor1, portalcolor2, nil, nil, nil, nil, nil, nil, characters[mariocharacter[j]])
	end
	
	love.graphics.setColor(1, 1, 1, 1)
	drawforeground()
	
	if gamestate == "menu" then
		menu_draw_title()
	elseif gamestate == "mappackmenu" then
		menu_draw_mappackmenu()
	elseif gamestate == "options" then
		menu_draw_options()
	elseif gamestate == "onlinemenu" then
		onlinemenu_draw()
	elseif gamestate == "lobby" then
		lobby_draw()
	end
	love.graphics.translate(0, yoffset*scale)
end

global function menu_draw_title()
	love.graphics.draw(titleimg, 40*scale, 24*scale, 0, scale, scale)
	
	if updatenotification then
		love.graphics.setColor(1, 0, 0)
		properprint("version outdated!|go to stabyourself.net|to download latest", 220*scale, 90*scale)
		love.graphics.setColor(1, 1, 1, 1)
	end

	local lay = main_layout()
	local panel = lay.panel as {string:any}
	draw_panel(panel.x as number, panel.y as number, panel.w as number, panel.h as number)

	local rects = lay.rects as {any}
	local sel = selection as integer

	-- Floating selection bar (lerped Y). Labels stay put.
	if menu_cursor_ready and #rects > 0 then
		local r0 = rects[1] as {string:any}
		menu_draw_row_bg(r0.x as number, menu_cursor_y, r0.w as number, r0.h as number, "sel", 1)
		menu_draw_cursor((r0.x as number) + 2, menu_cursor_y + 4)
	end

	for i = 1, #rects do
		local r = rects[i] as {string:any}
		local state = "normal"
		if i == sel then
			state = "selected"
		elseif ui_input_mode == "mouse" and menu_hover_i == i and menu_hover_a > 0.05 then
			state = "hover"
			menu_draw_row_bg(r.x as number, r.y as number, r.w as number, r.h as number, "hover", menu_hover_a)
		end
		draw_menu_item(r, state)
	end

	local footer = lay.footer as {string:any}
	menu_draw_footer(footer.x as number, footer.y as number, footer.text as string)
	
	if selectworldopen then
		local sw = menu_layout_selectworld()
		local sp = sw.panel as {string:any}
		love.graphics.setColor(0, 0, 0, 0.4)
		love.graphics.rectangle("fill", 0, 0, 400 * scale, 224 * scale)
		draw_panel(sp.x as number, sp.y as number, sp.w as number, sp.h as number)
		local st = sw.title as {string:any}
		ui_set_color("text")
		properprint(st.text as string, (st.x as number) * scale, (st.y as number) * scale)
		for i = 1, 8 do
			local wx = (sp.x as number) + 16 + (i - 1) * 24
			local wy = (sp.y as number) + 40
			if selectworldcursor == i then
				menu_draw_row_bg(wx - 4, wy - 4, 20, 24, "sel", 1)
				ui_set_color("text_accent")
				properprint("v", wx * scale, (wy - 12) * scale)
			elseif reachedworlds[mappack][i] then
				ui_set_color("text")
			elseif selectworldexists[i] then
				ui_set_color("text_dim")
			else
				love.graphics.setColor(0.15, 0.15, 0.18, 1)
			end
			properprint(i, wx * scale, wy * scale)
		end
		love.graphics.setColor(1, 1, 1, 1)
	end
	
end

global function menu_draw_mappackmenu()
	menu_mappack_draw()
end

global function menu_draw_options()
	local body = menu_layout_options_rows(15)
	local panel = body.panel as {string:any}
	draw_panel(panel.x as number, panel.y as number, panel.w as number, panel.h as number)

	-- tab strip
	local tabs = menu_layout_options_tabs()
	menu_draw_tabs(tabs, optionstab, optionsselection == 1)
	menu_draw_rule((panel.x as number) + 8, 34, (panel.w as number) - 16)

	local foot_raw = body.footer
	if foot_raw then
		local foot = foot_raw as {string:any}
		menu_draw_footer(foot.x as number, foot.y as number, foot.text as string)
	end

	if optionstab == 1 then
		--CONTROLS
		menu_opt_color(optionsselection == 2)
		properprint("edit player:" .. skinningplayer, 74*scale, 40*scale)
		
		menu_opt_color(optionsselection == 3)
		
		if mouseowner == skinningplayer then
			properprint("uses the mouse: yes", 46*scale, 52*scale)
		else
			properprint("uses the mouse: no", 46*scale, 52*scale)
		end
		
		for i = 1, #controlstable do
			if mouseowner ~= skinningplayer or i <= 8 then		
				menu_opt_color(optionsselection == 3+i)
				
				properprint(controlstable[i], 30*scale, (70+(i-1)*12)*scale)
				
				local s = ""
				
				if controls[skinningplayer][controlstable[i]] then
					for j = 1, #controls[skinningplayer][controlstable[i]] do
						s = s .. tostring((((controls[skinningplayer] as {any:any})[controlstable[i as integer]] as {any})[j as integer]))
					end
				end
				if s == " " then
					s = "space"
				end
				properprint(s, 120*scale, (70+(i-1)*12)*scale)
			end
		end
			
		if keyprompt then
			love.graphics.setColor(0, 0, 0, 0.45)
			love.graphics.rectangle("fill", 0, 0, 400*scale, 224*scale)
			draw_panel(88, 88, 224, 72)
			love.graphics.setColor(1, 1, 1, 1)
			if controlstable[optionsselection-3] == "aimx" then
				properprint("move stick right", 104*scale, 104*scale)
			elseif controlstable[optionsselection-3] == "aimy" then
				properprint("move stick down", 104*scale, 104*scale)
			else
				properprint("press key for \"" .. controlstable[optionsselection-3] .. "\"", 104*scale, 104*scale)
			end
			properprint("press \"esc\" to cancel", 104*scale, 136*scale)
			
			if buttonerror then
				love.graphics.setColor(0.8, 0, 0)
				properprint("you can only set", 104*scale, 116*scale)
				properprint("buttons for this", 104*scale, 126*scale)
			elseif axiserror then
				love.graphics.setColor(0.8, 0, 0)
				properprint("you can only set", 104*scale, 116*scale)
				properprint("axes for this", 104*scale, 126*scale)
			end
		end
	elseif optionstab == 2 then
		--SKINS
		menu_opt_color(optionsselection == 2)
		
		properprint("edit player:" .. skinningplayer, 74*scale, 32*scale)
		
		--PREVIEW MARIO IN BIG. WITH BIG LETTERS
		local v = characters[mariocharacter[skinningplayer]]
		local angle = 3
		if v.nopointing then
			angle = 1
		end
		drawplayer(nil, 46, 32, scale*2,     v.smalloffsetX, v.smalloffsetY, 0, v.smallquadcenterX, v.smallquadcenterY, "idle", false, false, mariohats[skinningplayer], v.animations, v.idle[angle], 0, false, false, mariocolors[skinningplayer], 1, portalcolor[skinningplayer][1], portalcolor[skinningplayer][2], nil, nil, nil, nil, nil, nil, characters[mariocharacter[skinningplayer]])

		
		--PREVIEW PORTALS WITH FALLING MARIO BECAUSE I CAN AND IT LOOKS RAD
		love.graphics.setScissor(142*scale, 42*scale, 32*scale, 32*scale)
		
		for j = 1, 3 do
			--158*scale, (2+((j-1)*32)+infmarioY)*scale
			local v = characters[mariocharacter[skinningplayer]]
			local angle = 3
			if v.nopointing then
				angle = 1
			end
			drawplayer(nil, 158, ((j-1)*32)+infmarioY+2, scale,     v.smalloffsetX, v.smalloffsetY, infmarioR, v.smallquadcenterX, v.smallquadcenterY, "jumping", false, false, mariohats[skinningplayer], v.animations, v.jump[angle][1], 0, false, false, mariocolors[skinningplayer], 1, portalcolor[skinningplayer][1], portalcolor[skinningplayer][2], nil, nil, nil, 1, nil, nil, characters[mariocharacter[skinningplayer]])
		end
		
		local portalframe = portalanimation
		
		love.graphics.setColor(1, 1, 1, (80 - math.abs(portalframe-3)*10)/255)
		love.graphics.draw(portalglowimg, 174*scale, 59*scale, math.pi, scale, scale)
		love.graphics.draw(portalglowimg, 142*scale, 57*scale, 0, scale, scale)
		
		love.graphics.setColor(unpack(portalcolor[skinningplayer][1]))
		love.graphics.draw(portalimg, portalquad[portalframe as integer], 174*scale, 46*scale, math.pi, scale, scale)
		love.graphics.setColor(unpack(portalcolor[skinningplayer][2]))
		love.graphics.draw(portalimg, portalquad[portalframe as integer], 142*scale, 70*scale, 0, scale, scale)
		
		love.graphics.setScissor()
		
		--Character change
		menu_opt_color(optionsselection == 3)
		
		properprint("{", 65*scale, 54*scale)
		properprint("}", 110*scale, 54*scale)
		properprint(characters[mariocharacter[skinningplayer]].name, (118-#characters[mariocharacter[skinningplayer]].name*4)*scale, 80*scale)
		
		if v.colorables then
			--HAT
			menu_opt_color(optionsselection == 4)
			if (mariohats[skinningplayer] as {any})[1] == 0 then
				properprint("hat: none", (83)*scale, 90*scale)
			else
				properprint("hat: " .. tostring((mariohats[skinningplayer] as {any})[1]), (99-string.len(tostring((mariohats[skinningplayer] as {any})[1]))*4)*scale, 90*scale)
			end

			menu_opt_color(optionsselection == 5)
			
			--NEW SKIN CUSTOMIZATION
			local v = characters[mariocharacter[skinningplayer]]
			properprint("{ " .. (v.colorables as {any})[colorsetedit as integer] as string .. " }", 120*scale-string.len("{ " .. (v.colorables as {any})[colorsetedit as integer] as string .. " }")*4*scale, 105*scale)
			
			if optionsselection > 5 and optionsselection < 9 then
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.rectangle("fill", 39*scale, 114*scale + (optionsselection-6)*10*scale, 142*scale, 10*scale)
			end
		
			love.graphics.setColor(0.4, 0, 0)
			properprint("r", 40*scale, (116)*scale)
			love.graphics.setColor(1, 0, 0)	
			properprint("r", 39*scale, (115)*scale)
			
			love.graphics.setColor(0, 0.4, 0)
			properprint("g", 40*scale, (126)*scale)
			love.graphics.setColor(0, 1, 0)	
			properprint("g", 39*scale, (125)*scale)
			
			love.graphics.setColor(0, 0, 0.4)
			properprint("b", 40*scale, (136)*scale)
			love.graphics.setColor(0, 0, 1)	
			properprint("b", 39*scale, (135)*scale)
			
			love.graphics.setColor(0.4, 0, 0)
			love.graphics.rectangle("fill", 51*scale, (116)*scale, math.floor(129*scale * mariocolors[skinningplayer][colorsetedit][1]), 7*scale)
			love.graphics.setColor(1, 0, 0)
			love.graphics.rectangle("fill", 50*scale, (115)*scale, math.floor(129*scale * mariocolors[skinningplayer][colorsetedit][1]), 7*scale)
			
			love.graphics.setColor(0.4, 0.4, 0.4)
			local s = math.floor(mariocolors[skinningplayer][colorsetedit][1] * 255)
			properprint(s, 200*scale-string.len(tostring(s))*4*scale, 116*scale)
			
			love.graphics.setColor(0, 0.4, 0)
			love.graphics.rectangle("fill", 51*scale, (126)*scale, math.floor(129*scale * mariocolors[skinningplayer][colorsetedit][2]), 7*scale)
			love.graphics.setColor(0, 1, 0)
			love.graphics.rectangle("fill", 50*scale, (125)*scale, math.floor(129*scale * mariocolors[skinningplayer][colorsetedit][2]), 7*scale)
			
			love.graphics.setColor(0.4, 0.4, 0.4)
			local s = math.floor(mariocolors[skinningplayer][colorsetedit][2] * 255)
			properprint(s, 200*scale-string.len(tostring(s))*4*scale, 126*scale)
			
			love.graphics.setColor(0, 0, 0.4)
			love.graphics.rectangle("fill", 51*scale, (136)*scale, math.floor(129*scale * mariocolors[skinningplayer][colorsetedit][3]), 7*scale)
			love.graphics.setColor(0, 0, 1)
			love.graphics.rectangle("fill", 50*scale, (135)*scale, math.floor(129*scale * mariocolors[skinningplayer][colorsetedit][3]), 7*scale)
			
			love.graphics.setColor(0.4, 0.4, 0.4)
			local s = math.floor(mariocolors[skinningplayer][colorsetedit][3] * 255)
			properprint(s, 200*scale-string.len(tostring(s))*4*scale, 136*scale)
		end
		
		--Portalhuehues
		--hue
		local alpha = 0.4
		
		if characters[mariocharacter[skinningplayer]].colorables then
			if optionsselection == 9 then
				alpha = 1
			end
		else
			if optionsselection == 4 then
				alpha = 1
			end
		end
		
		love.graphics.setColor(1, 1, 1, alpha)
		
		properprint("coop portal 1 color:", 31*scale, 150*scale)
		
		love.graphics.draw(huebarimg, 32*scale, 170*scale, 0, scale, scale)
		
		--marker
		love.graphics.setColor(unpack(portalcolor[skinningplayer][1]))
		love.graphics.rectangle("fill", math.floor(29 + (portalhues[skinningplayer][1])*178)*scale, 161*scale, 7*scale, 6*scale)
		love.graphics.setColor(alpha, alpha, alpha)
		love.graphics.draw(huebarmarkerimg, math.floor(28 + (portalhues[skinningplayer][1])*178)*scale, 160*scale, 0, scale, scale)
		
		alpha = 0.4
		if characters[mariocharacter[skinningplayer]].colorables then
			if optionsselection == 10 then
				alpha = 1
			end
		else
			if optionsselection == 5 then
				alpha = 1
			end
		end
		
		love.graphics.setColor(1, 1, 1, alpha)
		
		properprint("coop portal 2 color:", 31*scale, 180*scale)
		
		love.graphics.draw(huebarimg, 32*scale, 200*scale, 0, scale, scale)
		
		--marker
		love.graphics.setColor(unpack(portalcolor[skinningplayer][2]))
		love.graphics.rectangle("fill", math.floor(29 + (portalhues[skinningplayer][2])*178)*scale, 191*scale, 7*scale, 6*scale)
		love.graphics.setColor(alpha, alpha, alpha)
		love.graphics.draw(huebarmarkerimg, math.floor(28 + (portalhues[skinningplayer][2])*178)*scale, 190*scale, 0, scale, scale)
	elseif optionstab == 3 then
		menu_opt_color(optionsselection == 2)
		properprint("size:", 30*scale, 40*scale)
		if fullscreen then
			if fullscreenmode == "touchfrominside" then
				properprint("letterbox", (180-string.len("letterbox")*8)*scale, 40*scale)
			else
				properprint("fullscreen", (180-string.len("fullscreen")*8)*scale, 40*scale)
			end
		else
			properprint("*" .. tostring(scale), (180-(string.len(tostring(scale))+1)*8)*scale, 40*scale)
		end
		
		
		menu_opt_color(optionsselection == 3)
		
		properprint("shader1:", 30*scale, 55*scale)
		if shaderssupported == false then
			properprint("unsupported", (180-string.len("unsupported")*8)*scale, 55*scale)
		else
			properprint(string.lower(shaderlist[currentshaderi1 as integer]), (180-string.len(shaderlist[currentshaderi1 as integer])*8)*scale, 55*scale)
		end
		
		menu_opt_color(optionsselection == 4)
		properprint("shader2:", 30*scale, 65*scale)
		if shaderssupported == false then
			properprint("unsupported", (180-string.len("unsupported")*8)*scale, 65*scale)
		else
			properprint(string.lower(shaderlist[currentshaderi2 as integer]), (180-string.len(shaderlist[currentshaderi2 as integer])*8)*scale, 65*scale)
		end
		
		ui_set_color("text_dim")
		properprint("shaders will really", 30*scale, 80*scale)
		properprint("reduce performance!", 30*scale, 90*scale)
		
		menu_opt_color(optionsselection == 5)
		properprint("game volume:", 30*scale, 105*scale)
		drawrectangle(138, 108, 90, 1)
		drawrectangle(138, 105, 1, 7)
		drawrectangle(227, 105, 1, 7)
		love.graphics.draw(volumesliderimg, math.floor((137+89*volumesfx)*scale), 105*scale, 0, scale, scale)
		
		menu_opt_color(optionsselection == 6)
		properprint("music volume:", 30*scale, 120*scale)
		drawrectangle(138, 123, 90, 1)
		drawrectangle(138, 120, 1, 7)
		drawrectangle(227, 120, 1, 7)
		love.graphics.draw(volumesliderimg, math.floor((137+89*volumemusic)*scale), 120*scale, 0, scale, scale)
		
		menu_opt_color(optionsselection == 7)
		
		properprint("reset game mappacks", 30*scale, 135*scale)
		
		menu_opt_color(optionsselection == 8)
		
		properprint("reset all settings", 30*scale, 150*scale)
		
		menu_opt_color(optionsselection == 9)
		
		properprint("vsync:", 30*scale, 165*scale)
		if vsync then
			properprint("on", (180-16)*scale, 165*scale)
		else
			properprint("off", (180-24)*scale, 165*scale)
		end
		
		ui_set_color("text_dim")
		properprint("you can lock the|mouse with f12", 30*scale, 180*scale)
		
		ui_set_color("text")
		properprint(versionstring, 134*scale, 207*scale)
	elseif optionstab == 4 then
		ui_set_color("text")
		if not gamefinished then
			properprint("unlock this by completing", 30*scale, 40*scale)
			properprint("the original levels pack!", 30*scale, 50*scale)
		else
			properprint("have fun with these!", 30*scale, 45*scale)
		end
		
		menu_opt_color(optionsselection == 2)
		
		properprint("mode:", 30*scale, 65*scale)
		properprint("{" .. playertype .. "}", (180-(string.len(playertype)+2)*8)*scale, 65*scale)
		
		menu_opt_color(optionsselection == 3)
		
		properprint("knockback:", 30*scale, 80*scale)
		if portalknockback then
			properprint("on", (180-16)*scale, 80*scale)
		else
			properprint("off", (180-24)*scale, 80*scale)
		end
		
		menu_opt_color(optionsselection == 4)
		
		properprint("bullettime:", 30*scale, 95*scale)
		properprint("use mousewheel", 30*scale, 105*scale)
		if bullettime then
			properprint("on", (180-16)*scale, 95*scale)
		else
			properprint("off", (180-24)*scale, 95*scale)
		end
		
		menu_opt_color(optionsselection == 5)
		
		properprint("huge mario:", 30*scale, 120*scale)
		if bigmario then
			properprint("on", (180-16)*scale, 120*scale)
		else
			properprint("off", (180-24)*scale, 120*scale)
		end
		
		menu_opt_color(optionsselection == 6)
		
		properprint("goomba attack:", 30*scale, 135*scale)
		if goombaattack then
			properprint("on", (180-16)*scale, 135*scale)
		else
			properprint("off", (180-24)*scale, 135*scale)
		end
		
		menu_opt_color(optionsselection == 7)
		
		properprint("sonic rainboom:", 30*scale, 150*scale)
		if sonicrainboom then
			properprint("on", (180-16)*scale, 150*scale)
		else
			properprint("off", (180-24)*scale, 150*scale)
		end
		
		menu_opt_color(optionsselection == 8)
		
		properprint("playercollision:", 30*scale, 165*scale)
		if playercollisions then
			properprint("on", (180-16)*scale, 165*scale)
		else
			properprint("off", (180-24)*scale, 165*scale)
		end
		
		menu_opt_color(optionsselection == 9)
		
		properprint("infinite time:", 30*scale, 180*scale)
		if infinitetime then
			properprint("on", (180-16)*scale, 180*scale)
		else
			properprint("off", (180-24)*scale, 180*scale)
		end
		
		menu_opt_color(optionsselection == 10)
		
		properprint("infinite lives:", 30*scale, 195*scale)
		if infinitelives then
			properprint("on", (180-16)*scale, 195*scale)
		else
			properprint("off", (180-24)*scale, 195*scale)
		end
	end
end


global function loadbackgroundsafe(background: any): any
	
	if loadbackground(background) == false then
		map = {}
		coinmap = {}
		mapwidth = width
		for x = 1, width do
			map[x] = {}
			coinmap[x] = {}
			for y = 1, 13 do
				map[x][y] = {1}
			end
		
			for y = 14, 15 do
				map[x][y] = {2}
			end
		end
		mapheight = 15
		startx = {3, 3, 3, 3, 3}
		starty = {13, 13, 13, 13, 13}
		custombackground = false
		backgroundi = 1
		love.graphics.setBackgroundColor(backgroundcolor[backgroundi as integer])
		notice.new("Couldn't properly load|background " .. tostring(background) .. "!", notice.red)
		
		xscroll = 0
		yscroll = 0
		
		create_tile_spritebatches()
	end
	
	generatespritebatch(0, 0)
	updatespritebatch()
end

global function loadbackground(backgroundlevel: any): any
	
	loadcustomimages(mappack_path(mappack) .. "/graphics")
	loadcustomsounds(mappack_path(mappack) .. "/sounds")
	loadcustombackgrounds()
	loadcustommusics()
	loadanimatedtiles()
	loadcustomtiles()
	loadmodcustomtiles()
	loadlevelscreens()
	
	blockbouncex = {}
	blockbouncey = {}
	
	marioscore = 0
	mariocoincount = 0
	marioworld = 1
	mariolevel = 1
	mariotime = 0 -- was "" display sentinel
	levelfinished = false
	
	startx = {3, 3, 3, 3, 3}
	starty = {13, 13, 13, 13, 13}
	
	coinframe = 1
	
	itemanimations = {}
	textentities = {}
	
	if not love.filesystem.getInfo(mappack_path(tostring(mappack)) .. "/" .. tostring(backgroundlevel)) then
		return false
	else
		if not loadmap((backgroundlevel as string):sub(1, -5)) then
			return false
		end
	end
	
	--Adjust start X scroll
	xscroll = (startx[1] as number)-(scrollingleftcomplete as number)-2
	if xscroll > mapwidth - width then
		xscroll = mapwidth - width
	end
	
	if xscroll < 0 then
		xscroll = 0
	end
	
	--and Y too
	yscroll = (starty[1] as number)-height+downscrollborder
	if yscroll > mapheight - height - 1 then
		yscroll = mapheight - height - 1
	end
	
	if yscroll < 0 then
		yscroll = 0
	end
	
	love.graphics.setBackgroundColor(background)
end

global function updatescroll()
	if mappacktype == "local" or mappacktype == nil then
		menu_mappack_move(0)
	end
end

global function onlineupdatescroll()
	if mappacktype == "online" then
		menu_mappack_move(0)
	end
end

global function toconvertupdatescroll()
	if mappacktype == "toconvert" then
		menu_mappack_move(0)
	end
end

global function mappacks()
	if mappackhorscroll == 0 then
		loadmappacks()
	elseif mappackhorscroll == 1 then
		loadonlinemappacks()
	elseif mappackhorscroll == 2 then
		loadtoconvertmappacks()
	end
	menu_mappack_setup_filter()
end

global function loadmappacks()
	mappacktype = "local"
	mappacklist = love.filesystem.getDirectoryItems( "mappacks" )
	
	local delete = {}
	for i = 1, #mappacklist do
		if love.filesystem.getInfo( mappack_path(mappacklist[i]) .. "/version.txt") or not love.filesystem.getInfo( mappack_path(mappacklist[i]) .. "/settings.txt") then
			table.insert(delete, i)
		end
	end
	mappack_skipped_count = #delete
	
	remove_indices_desc(mappacklist, delete)
	
	mappackicon = {}
	
	--get info
	mappackname = {}
	mappackauthor = {}
	mappackdescription = {}
	mappackbackground = {}
	
	for i = 1, #mappacklist do
		local iconpath = mappack_path(mappacklist[i]) .. "/icon.png"
		-- SE-era packs sometimes used Thumb.png instead of icon.png
		if not love.filesystem.getInfo(iconpath) then
			iconpath = mappack_path(mappacklist[i]) .. "/Thumb.png"
		end
		if not love.filesystem.getInfo(iconpath) then
			iconpath = mappack_path(mappacklist[i]) .. "/thumb.png"
		end
		if love.filesystem.getInfo(iconpath) then
			mappackicon[i] = AssetStore.load_image(iconpath)
		else
			mappackicon[i] = nil
		end
		
		mappackauthor[i] = ""
		mappackdescription[i] = ""
		if love.filesystem.getInfo( mappack_path(mappacklist[i]) .. "/settings.txt" ) then		
			local s = love.filesystem.read( mappack_path(mappacklist[i]) .. "/settings.txt" )
			local n, a, d = menu_parse_settings_text(s)
			if n then mappackname[i] = n end
			if a then mappackauthor[i] = a end
			if d then mappackdescription[i] = d end
		else
			mappackname[i] = mappacklist[i]
		end
	end
	
	table.insert(mappacklist, "custom_mappack")
	table.insert(mappackname, "{new mappack}")
	table.insert(mappackauthor, "you")
	table.insert(mappackdescription, "create a mappack from scratch withthis!")
	
	--get the current cursorposition
	for i = 1, #mappacklist do
		if mappacklist[i] == mappack then
			mappackselection = i
		end
	end
	
	mappack = mappacklist[mappackselection as integer]
	
	--load background
	--loadbackground("1-1.txt")
	
	mappackscroll = 0
	updatescroll()
	mappackscrollsmooth = mappackscroll
end

global function loadonlinemappacks()
	mappacktype = "online"
	downloadmappacks()
	onlinemappacklist = love.filesystem.getDirectoryItems( "mappacks" )
	
	local delete = {}
	for i = 1, #onlinemappacklist do
		if not love.filesystem.getInfo( mappack_path(onlinemappacklist[i]) .. "/version.txt") or not love.filesystem.getInfo( mappack_path(onlinemappacklist[i]) .. "/settings.txt") then
			table.insert(delete, i)
		end
	end
	
	remove_indices_desc(onlinemappacklist, delete)
	
	onlinemappackicon = {}
	
	--get info
	onlinemappackname = {}
	onlinemappackauthor = {}
	onlinemappackdescription = {}
	onlinemappackbackground = {}
	
	for i = 1, #onlinemappacklist do
		if love.filesystem.getInfo( mappack_path(onlinemappacklist[i]) .. "/icon.png" ) then
			onlinemappackicon[i] = AssetStore.load_image(mappack_path(onlinemappacklist[i]) .. "/icon.png")
		else
			onlinemappackicon[i] = nil
		end
		
		onlinemappackauthor[i] = nil
		onlinemappackdescription[i] = nil
		if love.filesystem.getInfo( mappack_path(onlinemappacklist[i]) .. "/settings.txt" ) then		
			local s = love.filesystem.read( mappack_path(onlinemappacklist[i]) .. "/settings.txt" )
			local n, a, d = menu_parse_settings_text(s)
			if n then onlinemappackname[i] = n end
			if a then onlinemappackauthor[i] = a end
			if d then onlinemappackdescription[i] = d end
		else
			onlinemappackname[i] = onlinemappacklist[i]
		end
	end
	
	--get the current cursorposition
	for i = 1, #onlinemappacklist do
		if onlinemappacklist[i] == mappack then
			onlinemappackselection = i
		end
	end
	
	if #onlinemappacklist >= 1 then
		mappack = onlinemappacklist[onlinemappackselection]
	end
	
	--load background
	--loadbackground("1-1.txt")
	
	onlinemappackscroll = 0
	onlineupdatescroll()
	onlinemappackscrollsmooth = onlinemappackscroll
end

global function loadtoconvertmappacks()
	mappacktype = "toconvert"
	toconvertmappacklist = love.filesystem.getDirectoryItems( "toconvert" )
	
	local delete = {}
	for i, v in pairs(toconvertmappacklist as {any:string}) do
		if tablecontains(mappacklist, v) then
			table.insert(delete, 1, i)
		end
	end
	
	for _, v in ipairs(delete as {any}) do
		table.remove(toconvertmappacklist, v as integer)
	end
	
	toconvertmappackicon = {}
	
	--get info
	toconvertmappackname = {}
	toconvertmappackauthor = {}
	toconvertmappackdescription = {}
	toconvertmappackbackground = {}
	
	for i = 1, #toconvertmappacklist do
		if love.filesystem.getInfo( "toconvert/" .. toconvertmappacklist[i] .. "/icon.png" ) then
			toconvertmappackicon[i] = AssetStore.load_image("toconvert/" .. toconvertmappacklist[i] .. "/icon.png")
		else
			toconvertmappackicon[i] = nil
		end
		
		toconvertmappackauthor[i] = ""
		toconvertmappackdescription[i] = ""
		if love.filesystem.getInfo( "toconvert/" .. toconvertmappacklist[i] .. "/settings.txt" ) then		
			local s = love.filesystem.read( "toconvert/" .. toconvertmappacklist[i] .. "/settings.txt" )
			local n, a, d = menu_parse_settings_text(s)
			if n then toconvertmappackname[i] = n end
			if a then toconvertmappackauthor[i] = a end
			if d then toconvertmappackdescription[i] = d end
		else
			toconvertmappackname[i] = toconvertmappacklist[i]
		end
	end
	
	--mappack = mappacklist[mappackselection as integer]
	
	--load background
	--loadbackground("1-1.txt")
	
	toconvertmappackscroll = 0
	toconvertupdatescroll()
	toconvertmappackscrollsmooth = toconvertmappackscroll
end

global function downloadmappacks(): any
	downloaderror = false
	local onlinedata, code = http.request("http://server.stabyourself.net/mari0/index2.php?mode=mappacks")
	
	if code ~= 200 then
		downloaderror = true
		return false
	elseif not onlinedata then
		downloaderror = true
		return false
	end
	
	local maplist: {string} = {}
	local versionlist: {number} = {}
	local latestversion = marioversion
	
	local split1 = strsplit(onlinedata as string, "<")
	for i = 2, #split1 do
		local split2 = strsplit(split1[i], ">")
		if split2[1] == "latestversion" then
			latestversion = tonumber(split2[2] as string) or latestversion
		elseif split2[1] == "mapfile" then
			table.insert(maplist, split2[2] as string)
		elseif split2[1] == "version" then
			table.insert(versionlist, tonumber(split2[2] as string) or 0)
		end
	end
	
	if latestversion > marioversion then
		outdated = true
		return false
	end
	
	success = true
	
	--download all mappacks
	for i = 1, #maplist do
		--check if current version is equal or newer
		local version: number = 0
		if love.filesystem.getInfo(mappack_path(maplist[i]) .. "/version.txt") then
			local data = love.filesystem.read(mappack_path(maplist[i]) .. "/version.txt")
			if data then
				version = tonumber(data) or 0
			end
		end
		
		if version < versionlist[i] then
			print("DOWNLOADING MAPPACK: " .. maplist[i])
			
			--draw
			currentdownload = i
			downloadcount = #maplist
			
			if love.filesystem.getInfo(mappack_path(maplist[i]) .. "/") then
				love.filesystem.remove(mappack_path(maplist[i]) .. "/")
			end
			
			love.filesystem.createDirectory(mappack_path(maplist[i]))
			local onlinedata, code = http.request("http://server.stabyourself.net/mari0/index2.php?mode=getmap&get=" .. maplist[i])
			
			if code == 200 then
				filecount = 0
				local checksums = {}
				
				local split1 = strsplit(onlinedata as string, "<")
				for j = 2, #split1 do
					local split2 = strsplit(split1[j], ">")
					if split2[1] == "asset" then
						filecount = filecount + 1
					elseif split2[1] == "checksum" then
						table.insert(checksums, split2[2])
					end
				end
				
				currentfiledownload = 1
				
				local split1 = strsplit(onlinedata as string, "<")
				for j = 2, #split1 do
					local split2 = strsplit(split1[j], ">")
					if split2[1] == "asset" then
						loadingonlinemappacks = true
						love.graphics.clear()
						love.draw()
						love.graphics.present()
						loadingonlinemappacks = false
						
						local target = mappack_path(maplist[i]) .. "/" .. (split2[2] as string):match("([^/]-)$")
						
						local tries = 0
						success = false
						while not success and tries < 3 do
							success = downloadfile(split2[2], target, (checksums as {any})[currentfiledownload as integer]) as boolean
							tries = tries + 1
						end
						
						if not success then
							break
						end
						currentfiledownload = currentfiledownload + 1
					end
				end
				if success then
					love.filesystem.write( mappack_path(maplist[i]) .. "/version.txt", tostring(versionlist[i]))
				end
			else
				success = false
			end
		end
		
		--Delete stuff and stuff.
		if not success then
			if love.filesystem.getInfo(mappack_path(maplist[i]) .. "/") then
				local list = love.filesystem.getDirectoryItems(mappack_path(maplist[i]) .. "/")
				for j = 1, #list do
					love.filesystem.remove(mappack_path(maplist[i]) .. "/" .. list[j])
				end
				
				love.filesystem.remove(mappack_path(maplist[i]) .. "/")
			end
			downloaderror = true
			break
		else
			print("Download successful.")
		end
	end
	
	return true
end

global function menu_keypressed(key: any)
	
	if gamestate == "menu" then -- data-driven main (see menu_defs); other screens still legacy
		if selectworldopen then
			if (key == "right" or key == "d") then
				local target = selectworldcursor+1
				while target < 9 and not (reachedworlds[mappack] as {any})[target as integer] do
					target = target + 1
				end
				if target < 9 then
					selectworldcursor = target
				end
			elseif (key == "left" or key == "a") then
				local target = selectworldcursor-1
				while target > 0 and not (reachedworlds[mappack] as {any})[target as integer] do
					target = target - 1
				end
				if target > 0 then
					selectworldcursor = target
				end
			elseif (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
				selectworldopen = false
				game_load(selectworldcursor)
			elseif key == "escape" then
				selectworldopen = false
			end
			return
		end
		local lay = main_layout()
		local n = #(lay.items as {any})
		if (key == "up" or key == "w") then
			if selection > 1 then
				selection = selection - 1
			end
		elseif (key == "down" or key == "s") then
			if selection < n then
				selection = selection + 1
			end
		elseif (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
			main_activate(selection as integer)
		elseif key == "escape" then
			local back = (MENU_SCREENS.main as {string:any}).back as function()|nil
			if back ~= nil then
				(back as function())()
			else
				love.event.quit()
			end
		elseif (key == "left" or key == "a") then
			spin_call("dec")
		elseif (key == "right" or key == "d") then
			spin_call("inc")
		end
	elseif gamestate == "mappackmenu" then
		-- don't steal keys while typing in filter
		local filter = guielements and guielements["mappackfilter"]
		if filter and filter.inputting and key ~= "escape" and key ~= "up" and key ~= "down" and key ~= "return" and key ~= "enter" and key ~= "kpenter" then
			if key == "backspace" then
				-- guielement keypress handles this via love.keypressed → guielements
			end
			-- still allow tab switch / navigation keys below for up/down/esc
		end
		if (key == "up" or key == "w") and not (filter and filter.inputting) then
			menu_mappack_move(-1)
		elseif (key == "down" or key == "s") and not (filter and filter.inputting) then
			menu_mappack_move(1)
		elseif key == "escape" or (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
			if filter and filter.inputting and key ~= "escape" then
				filter.inputting = false
				return
			end
			if key == "escape" and filter and filter.inputting then
				filter.inputting = false
				filter.value = ""
				return
			end
			if mappacktype == "toconvert" and (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
				local toconvert = toconvertmappacklist[toconvertmappackselection as integer]
				convertmappack(toconvert)
				mappack = toconvert
				gamestate = "menu"
				menu_mappack_teardown_filter()
				saveconfig()
				loadbackgroundsafe("1-1.txt")
			elseif key == "escape" or (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
				gamestate = "menu"
				menu_mappack_teardown_filter()
				saveconfig()
				if mappack == "custom_mappack" and key ~= "escape" then
					createmappack()
				end
				loadbackgroundsafe("1-1.txt")
			end
		elseif (key == "right" or key == "d") and not (filter and filter.inputting) then
			if mappackhorscroll == 0 then
				loadonlinemappacks()
				mappackhorscroll = 1
				menu_mappack_setup_filter()
			elseif mappackhorscroll == 1 then
				loadtoconvertmappacks()
				mappackhorscroll = 2
				menu_mappack_setup_filter()
			end
		elseif (key == "left" or key == "a") and not (filter and filter.inputting) then
			if mappackhorscroll == 1 then
				loadmappacks()
				mappackhorscroll = 0
				menu_mappack_setup_filter()
			elseif mappackhorscroll == 2 then
				loadonlinemappacks()
				mappackhorscroll = 1
				menu_mappack_setup_filter()
			end
		elseif key == "m" and not (filter and filter.inputting) then
			if not openSaveFolder("mappacks") then
				savefolderfailed = true
			end
		end
	elseif gamestate == "onlinemenu" then
		if CLIENT == false and SERVER == false then
			if key == "c" then
				client_load()
			elseif key == "s" then
				server_load()
			end
		elseif SERVER then
			if (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
				server_start()
			end
		end
	elseif gamestate == "options" then
		if optionsselection == 1 then
			if (key == "left" or key == "a") then
				if optionstab > 1 then
					optionstab = optionstab - 1
				end
			elseif (key == "right" or key == "d") then
				if optionstab < 4 then
					optionstab = optionstab + 1
				end
			end
		elseif optionsselection == 2 then
			if (key == "left" or key == "a") then
				if optionstab == 2 or optionstab == 1 then
					if skinningplayer > 1 then
						skinningplayer = skinningplayer - 1
					end
				end
			elseif (key == "right" or key == "d") then
				if optionstab == 2 or optionstab == 1 then
					if skinningplayer < 4 then
						skinningplayer = skinningplayer + 1
						if players > #(controls as {any}) then
							loadconfig()
						end
					end
				end
			end
		end
		
		if (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
			if optionstab == 1 then
				if optionsselection == 3 then
					if mouseowner == skinningplayer then
						mouseowner = 0
					else
						mouseowner = skinningplayer
					end
				elseif optionsselection > 3 then
					keypromptstart()
				end
			elseif optionstab == 3 then
				if optionsselection == 7 then
					reset_mappacks()
				elseif optionsselection == 8 then
					resetconfig()
				end
			end
		elseif (key == "down" or key == "s") then
			if optionstab == 1 then
				if skinningplayer ~= mouseowner then
					if optionsselection < 15 then
						optionsselection = optionsselection + 1
					else
						optionsselection = 1
					end
				else
					if optionsselection < 11 then
						optionsselection = optionsselection + 1
					else
						optionsselection = 1
					end
				end
			elseif optionstab == 2 then
				local limit = 5
				if characters[mariocharacter[skinningplayer]].colorables then
					limit = 10
				end
				
				if optionsselection < limit then
					optionsselection = optionsselection + 1
				else
					optionsselection = 1
				end
			elseif optionstab == 3 then
				if optionsselection < 9 then
					optionsselection = optionsselection + 1
				else
					optionsselection = 1
				end
			elseif optionstab == 4 and gamefinished then
				if optionsselection < 10 then
					optionsselection = optionsselection + 1
				else
					optionsselection = 1
				end
			end
		elseif (key == "up" or key == "w") then
			if optionsselection > 1 then
				optionsselection = optionsselection - 1
			else
				if optionstab == 1 then
					if skinningplayer ~= mouseowner then
						optionsselection = 15
					else
						optionsselection = 11
					end
				elseif optionstab == 2 then
					local limit = 5
					if characters[mariocharacter[skinningplayer]].colorables then
						limit = 10
					end
					optionsselection = limit
				elseif optionstab == 3 then
					optionsselection = 9
				elseif optionstab == 4 and gamefinished then
					optionsselection = 10
				end
			end
		elseif (key == "right" or key == "d") then
			if optionstab == 2 then
				if optionsselection == 3 then
					nextcharacter()
				elseif characters[mariocharacter[skinningplayer]].colorables and optionsselection == 4 then
					if ((mariohats[skinningplayer] as {any})[1] as number) < #(hat as {any}) then
						(mariohats[skinningplayer] as {any})[1] = ((mariohats[skinningplayer] as {any})[1] as number) + 1
					end
				elseif characters[mariocharacter[skinningplayer]].colorables and optionsselection == 5 then
					--next color set
					colorsetedit = colorsetedit + 1
					if colorsetedit > #characters[mariocharacter[skinningplayer]].colorables then
						colorsetedit = 1
					end
				end
			elseif optionstab == 3 then
				if optionsselection == 2 then
					if scale < 5 then
						changescale(scale+1)
					end
				elseif optionsselection == 3 then
					currentshaderi1 = currentshaderi1 + 1
					if currentshaderi1 > #shaderlist then
						currentshaderi1 = 1
					end
					if shaderlist[currentshaderi1 as integer] == "none" then
						shaders:set(1, nil)
					else
						shaders:set(1, shaderlist[currentshaderi1 as integer])
					end
					
				elseif optionsselection == 4 then
					currentshaderi2 = currentshaderi2 + 1
					if currentshaderi2 > #shaderlist then
						currentshaderi2 = 1
					end
					if shaderlist[currentshaderi2 as integer] == "none" then
						shaders:set(2, nil)
					else
						shaders:set(2, shaderlist[currentshaderi2 as integer])
					end
					
				elseif optionsselection == 5 then
					volumesfx = math.min(1, volumesfx + 0.1)
					love.audio.setVolume( volumesfx )
					music:setVolume( volumemusic )
					playsound("coin")
					soundenabled = true
				elseif optionsselection == 6 then
					volumemusic = math.min(1, volumemusic + 0.1)
					love.audio.setVolume( volumesfx )
					music:setVolume( volumemusic )
				elseif optionsselection == 9 then
					vsync = not vsync
					changescale(scale)
				end
			elseif optionstab == 4 then
				if optionsselection == 2 then
					playertypei = playertypei + 1
					if playertypei > #playertypelist then
						playertypei = 1
					end
					playertype = playertypelist[playertypei as integer] as string
					if playertype == "gelcannon" then
						sonicrainboom = false
					end
				elseif optionsselection == 3 then
					portalknockback = not portalknockback
				elseif optionsselection == 4 then
					bullettime = not bullettime
				elseif optionsselection == 5 then
					bigmario = not bigmario
				elseif optionsselection == 6 then
					goombaattack = not goombaattack
				elseif optionsselection == 7 then
					sonicrainboom = not sonicrainboom
					playertype = "portal"
					playertypei = 1
				elseif optionsselection == 8 then
					playercollisions = not playercollisions
				elseif optionsselection == 9 then
					infinitetime = not infinitetime
				elseif optionsselection == 10 then
					infinitelives = not infinitelives
				end
			end				
		elseif (key == "left" or key == "a") then
			if optionstab == 2 then
				if optionsselection == 3 then
					previouscharacter()
				elseif characters[mariocharacter[skinningplayer]].colorables and optionsselection == 4 then
					if ((mariohats[skinningplayer] as {any})[1] as number) > 0 then
						(mariohats[skinningplayer] as {any})[1] = ((mariohats[skinningplayer] as {any})[1] as number) - 1
					end
				elseif characters[mariocharacter[skinningplayer]].colorables and optionsselection == 5 then
					--previous color set
					colorsetedit = colorsetedit - 1
					if colorsetedit < 1 then
						colorsetedit = #characters[mariocharacter[skinningplayer]].colorables
					end
				end
			elseif optionstab == 3 then
				if optionsselection == 2 then
					if scale > 1 then
						changescale(scale-1)
					end
				elseif optionsselection == 3 then
					currentshaderi1 = currentshaderi1 - 1
					if currentshaderi1 < 1 then
						currentshaderi1 = #shaderlist
					end
					
					if shaderlist[currentshaderi1 as integer] == "none" then
						shaders:set(1, nil)
					else
						shaders:set(1, shaderlist[currentshaderi1 as integer])
					end
				elseif optionsselection == 4 then
					currentshaderi2 = currentshaderi2 - 1
					if currentshaderi2 < 1 then
						currentshaderi2 = #shaderlist
					end
					
					if shaderlist[currentshaderi2 as integer] == "none" then
						shaders:set(2, nil)
					else
						shaders:set(2, shaderlist[currentshaderi2 as integer])
					end
					
				elseif optionsselection == 5 then
					volumesfx = math.max(0, volumesfx - 0.1)
					if volume == 0 then
						soundenabled = false
					end
					love.audio.setVolume( volumesfx )
					music:setVolume( volumemusic )
					playsound("coin")
				elseif optionsselection == 6 then
					volumemusic = math.max(0, volumemusic - 0.1)
					love.audio.setVolume( volumesfx )
					music:setVolume( volumemusic )
				elseif optionsselection == 9 then
					vsync = not vsync
					changescale(scale)
				end
			elseif optionstab == 4 then
				if optionsselection == 2 then
					playertypei = playertypei - 1
					if playertypei < 1 then
						playertypei = #playertypelist
					end
					playertype = playertypelist[playertypei as integer] as string
					if playertype == "gelcannon" then
						sonicrainboom = false
					end
				elseif optionsselection == 3 then
					portalknockback = not portalknockback
				elseif optionsselection == 4 then
					bullettime = not bullettime
				elseif optionsselection == 5 then
					bigmario = not bigmario
				elseif optionsselection == 6 then
					goombaattack = not goombaattack
				elseif optionsselection == 7 then
					sonicrainboom = not sonicrainboom
					playertype = "portal"
					playertypei = 1
				elseif optionsselection == 8 then
					playercollisions = not playercollisions
				elseif optionsselection == 9 then
					infinitetime = not infinitetime
				elseif optionsselection == 10 then
					infinitelives = not infinitelives
				end
			end
		elseif key == "escape" then
			gamestate = "menu"
			saveconfig()
		end
	end
end

global function menu_keyreleased(_: any)
	

end

global function menu_mousepressed(x: any, y: any, button: any)
	local ux = (x as number) / scale
	local uy = (y as number) / scale
	if gamestate == "mappackmenu" then
		-- wheel + click handled inside mappack module
		menu_mappack_mousepressed(ux, uy, button)
		return
	end
	if button ~= "l" then
		return
	end
	if gamestate == "menu" then
		if selectworldopen then
			return
		end
		local lay = main_layout()
		local spin_kind = menu_hit_spinner(lay.spinner as {string:any}|nil, ux, uy)
		if spin_kind then
			if spin_kind == "cycle" and players >= 4 then
				players = 1
			elseif spin_kind == "cycle" then
				spin_call("inc")
			else
				spin_call(spin_kind)
			end
			-- also select newgame row
			local rects = lay.rects as {any}
			for i = 1, #rects do
				if (((rects[i] as {string:any}).id as string) == "newgame") then
					selection = i
					break
				end
			end
			return
		end
		local i = menu_hit(lay.rects as {any}, ux, uy)
		-- click activates only if hit == current selection
		if i and i == (selection as integer) then
			main_activate(i)
		elseif i then
			selection = i
		end
	elseif gamestate == "options" then
		-- tabs + rows via layout; guielement widgets if any still get love.mousepressed loop
		local tabs = menu_layout_options_tabs()
		for i = 1, #tabs do
			local t = tabs[i] as {string:any}
			if ux >= (t.x as number) and ux < (t.x as number) + (t.w as number)
				and uy >= (t.y as number) and uy < (t.y as number) + (t.h as number) then
				optionstab = t.id as integer
				optionsselection = 1
				return
			end
		end
		local maxsel = 9
		if optionstab == 1 then
			maxsel = (skinningplayer == mouseowner) and 11 or 15
		elseif optionstab == 2 then
			maxsel = 5
			if characters and mariocharacter and characters[mariocharacter[skinningplayer]] and characters[mariocharacter[skinningplayer]].colorables then
				maxsel = 10
			end
		elseif optionstab == 4 then
			maxsel = gamefinished and 10 or 1
		end
		local body = menu_layout_options_rows(maxsel)
		local hi = menu_hit(body.rows as {any}, ux, uy)
		if hi ~= nil then
			local rows = body.rows as {any}
			local row = rows[hi as integer] as {string:any}
			local sel = row.selection as integer
			if sel == optionsselection then
				-- activate via same path as enter
				menu_keypressed("return")
			else
				optionsselection = sel
			end
		end
	end
end

global function menu_mousemoved(x: number, y: number)
	if ui_input_mode ~= "mouse" then
		return
	end
	local ux = x / scale
	local uy = y / scale
	if gamestate == "menu" and not selectworldopen then
		local lay = main_layout()
		local i = menu_hit(lay.rects as {any}, ux, uy)
		menu_hover_i = i
		if i then
			selection = i
		end
	elseif gamestate == "mappackmenu" then
		menu_mappack_mousemoved(ux, uy)
	elseif gamestate == "options" then
		local maxsel = 9
		if optionstab == 1 then
			maxsel = (skinningplayer == mouseowner) and 11 or 15
		elseif optionstab == 2 then
			maxsel = 5
			if characters and mariocharacter and characters[mariocharacter[skinningplayer]] and characters[mariocharacter[skinningplayer]].colorables then
				maxsel = 10
			end
		elseif optionstab == 4 then
			maxsel = gamefinished and 10 or 1
		end
		local body = menu_layout_options_rows(maxsel)
		local hi = menu_hit(body.rows as {any}, ux, uy)
		if hi ~= nil then
			local rows = body.rows as {any}
			local row = rows[hi as integer] as {string:any}
			optionsselection = row.selection as integer
		end
	end
end

global function menu_mousereleased(_: any, _: any, _: any)
	

end

-- Map dpad / face buttons onto the same key paths (mode already set to kbd by love_callbacks)
global function menu_joystickpressed(_: any, button: any)
	local b = button as number
	if b == 1 or b == 0 then
		menu_keypressed("return")
	elseif b == 2 then
		menu_keypressed("escape")
	end
end

global function menu_joystickreleased(_: any, _: any)
	

end

global function menu_joystickaxis(_: any, _: any, value: any, _: any, _: any)
	-- treated as stick; love_callbacks already set kbd mode on press — axis uses thresholds
	local v = value as number
	if math.abs(v) < 0.5 then
		return
	end
end

global function menu_joystickhat(_: any, _: any, direction: any)
	ui_note_kbd()
	local d = direction as string
	if d == "u" then
		menu_keypressed("up")
	elseif d == "d" then
		menu_keypressed("down")
	elseif d == "l" then
		menu_keypressed("left")
	elseif d == "r" then
		menu_keypressed("right")
	end
end

global function keypromptenter(t: any, ...: any): any
	local arg: {any} = {...}
	if t == "key" and (arg[1] == ";" or arg[1] == "," or arg[1] == "," or arg[1] == "-") then
		return
	end
	buttonerror = false
	axiserror = false
	local buttononly = {"run", "jump", "reload", "use"}
	local axisonly = {"aimx", "aimy"}
	if t ~= "key" or arg[1] ~= "escape" then
		if t == "key" then
			if tablecontains(axisonly, controlstable[optionsselection-3]) then
				axiserror = true
			else
				controls[skinningplayer][controlstable[optionsselection-3]] = {arg[1]}
			end
		elseif t == "joybutton" then
			if tablecontains(axisonly, controlstable[optionsselection-3]) then
				axiserror = true
			else
				controls[skinningplayer][controlstable[optionsselection-3]] = {"joy", arg[1], "but", arg[2]}
			end
		elseif t == "joyhat" then
			if tablecontains(buttononly, controlstable[optionsselection-3]) then
				buttonerror = true
			elseif tablecontains(axisonly, controlstable[optionsselection-3]) then
				axiserror = true
			else
				controls[skinningplayer][controlstable[optionsselection-3]] = {"joy", arg[1], "hat", arg[2], arg[3]}
			end
		elseif t == "joyaxis" then
			if tablecontains(buttononly, controlstable[optionsselection-3]) then
				buttonerror = true
			else
				controls[skinningplayer][controlstable[optionsselection-3]] = {"joy", arg[1], "axe", arg[2], arg[3]}
			end
		end
	end
	
	if (not buttonerror and not axiserror) or arg[1] == "escape" then
		keyprompt = false
	end
end

global function keypromptstart()
	keyprompt = true
	buttonerror = false
	axiserror = false
	
	--save number of stuff
	prompt = {}
	prompt.joystick = {}
	prompt.joysticks = love.joystick.getJoystickCount()
	
	for i, js in ipairs(love.joystick.getJoysticks()) do
		prompt.joystick[i] = {}
		prompt.joystick[i].hats = js:getHatCount()
		prompt.joystick[i].axes = js:getAxisCount()
		
		local validhats: {integer} = {}
		for j = 1, prompt.joystick[i].hats as integer do
			if js:getHat(j) == "c" then
				table.insert(validhats, j)
			end
		end
		prompt.joystick[i].validhats = validhats
		
		local axisposition: {number} = {}
		for j = 1, prompt.joystick[i].axes as integer do
			table.insert(axisposition, js:getAxis(j))
		end
		prompt.joystick[i].axisposition = axisposition
	end
end

global function downloadfile(url: any, target: any, checksum: any): any
	
	local data, code = http.request(url as string)
	
	if code ~= 200 then
		return false
	end
	
	if (checksum as string) ~= (sha1 as function(string): string)(data as string) then
		print("Checksum doesn't match!")
		return false
	end
	
	if data then
		love.filesystem.write(target as string, data as string)
		return true
	else
		return false
	end
end

global function reset_mappacks()
	delete_mappack("smb")
	delete_mappack("portal")
	
	loadbackgroundsafe("1-1.txt")
	
	playsound("oneup")
end

global function delete_mappack(pack: any): any
	
	if not love.filesystem.getInfo(mappack_path(pack as string) .. "/") then
		return false
	end
	
	local list = love.filesystem.getDirectoryItems(mappack_path(pack as string) .. "/")
	for i = 1, #list do
		love.filesystem.remove(mappack_path(pack as string) .. "/" .. list[i])
	end
	
	love.filesystem.remove(mappack_path(pack as string) .. "/")
end

global function createmappack()
	local i = 1
	while love.filesystem.getInfo(mappack_path("custom_mappack_" .. i) .. "/") do
		i = i + 1
	end
	
	mappack = "custom_mappack_" .. i
	
	love.filesystem.createDirectory(mappack_path(tostring(mappack)) .. "/")
	
	local s = ""
	s = s .. "name=new mappack" .. "\n"
	s = s .. "author=you" .. "\n"
	s = s .. "description=the newest best  mappack?" .. "\n"
	
	love.filesystem.write(mappack_path(mappack) .. "/settings.txt", s)
	
	--Create folders for all sorts of stuff.
	local folderlist = {"animated", "animations", "backgrounds", "enemies", "graphics", "levelscreens", "music", "sounds"}
	
	for _, v in pairs(folderlist as {any:any}) do
		love.filesystem.createDirectory(mappack_path(tostring(mappack)) .. "/" .. tostring(v) .. "/")
	end
end

global function resetconfig()
	defaultconfig()
	
	changescale(scale)
	love.audio.setVolume(volume)
	currentshaderi1 = 1
	currentshaderi2 = 1
	shaders:set(1, nil)
	shaders:set(2, nil)
	saveconfig()
	loadbackgroundsafe("1-1.txt")
end

global function selectworld()
	if not reachedworlds[mappack] then
		game_load()
	end
	
	local noworlds = true
	for i = 2, 8 do
		if reachedworlds[mappack][i] then
			noworlds = false
			break
		end
	end
	
	if noworlds then
		game_load()
		return
	end
	
	selectworldopen = true
	selectworldcursor = 1
	
	selectworldexists = {}
	for i = 1, 8 do
		if love.filesystem.getInfo(mappack_level_path(tostring(mappack), i, 1)) then
			selectworldexists[i] = true
		end
	end
end

global function previouscharacter()
	--get current character
	local char: any
	for i = 1, #characterlist do
		if characterlist[i as integer] == mariocharacter[skinningplayer] then
			char = i
			break
		end
	end
	
	if not char then return end
	
	if (char as number) > 1 then
		changecharacter((char as number) - 1)
	else
		changecharacter(#characterlist)
	end
end

global function nextcharacter()
	--get current character
	local char: any
	for i = 1, #characterlist do
		if characterlist[i as integer] == mariocharacter[skinningplayer] then
			char = i
			break
		end
	end
	
	if not char then return end
	
	if (char as number) < #characterlist then
		changecharacter((char as number) + 1)
	else
		changecharacter(1)
	end
end

global function changecharacter(i: any)
	
	mariocharacter[skinningplayer] = characterlist[i as integer]
	
	--change colors
	mariocolors[skinningplayer] = {}
	if characters[characterlist[i as integer]].defaultcolors then
		if characters[characterlist[i as integer]].defaultcolors[skinningplayer] then
			for j = 1, #characters[characterlist[i as integer]].defaultcolors[skinningplayer] do
				mariocolors[skinningplayer][j] = {characters[characterlist[i as integer]].defaultcolors[skinningplayer][j][1], characters[characterlist[i as integer]].defaultcolors[skinningplayer][j][2], characters[characterlist[i as integer]].defaultcolors[skinningplayer][j][3]}
			end
		end
	end
	
	if characters[characterlist[i as integer]].defaulthat then
		mariohats[skinningplayer] = { characters[characterlist[i as integer]].defaulthat}
	end
	
	colorsetedit = 1
end

-- convertmappack / loadmapold / convertentity live in world.mappack_convert
-- (entity remaps in world.entity_remap). Menu UI still calls convertmappack(name).

return { ported = true }
