--[[ game_draw HUD / markers / pause / debug ]]

global function game_draw_hud(hidetime?: any): any
	
	local printfunction = properprint
	if custombackground then
		printfunction = properprintbackground
	end

	---UI
	love.graphics.setColor(1, 1, 1)
	love.graphics.translate(0, -yoffset*scale)
	if yoffset < 0 then
		love.graphics.translate(0, yoffset*scale)
	end
	
	if editormode == false then -- No point in showing this in the editor
		if not characters[mariocharacter[1]] then
			mariocharacter[1] = "mario"
		end
		printfunction(characters[mariocharacter[1]].name, uispace*.5 - 24*scale, 8*scale)
		printfunction(addzeros(marioscore, 6), uispace*0.5-24*scale, 16*scale)
		
		printfunction("*", uispace*1.5-8*scale, 16*scale)
		
		love.graphics.draw(coinanimationimg, coinanimationquads[spriteset][coinframe], uispace*1.5-16*scale, 16*scale, 0, scale, scale)
		printfunction(addzeros(mariocoincount, 2), uispace*1.5-0*scale, 16*scale)
		
		if mappackendless and endlessseed and endlessseed ~= 0 then
			printfunction("seed", uispace*2.5 - 16*scale, 8*scale)
			printfunction(tostring(endlessseed), uispace*2.5 - 20*scale, 16*scale)
		else
			printfunction("world", uispace*2.5 - 20*scale, 8*scale)
			printfunction(tostring(marioworld) .. "-" .. tostring(mariolevel), uispace*2.5 - 12*scale, 16*scale)
		end
	
		printfunction("time", uispace*3.5 - 16*scale, 8*scale)
		
		if not hidetime then
			if type(mariotime) == "number" then
				printfunction(addzeros(math.ceil(mariotime), 3), uispace*3.5-8*scale, 16*scale)
			else
				printfunction(mariotime, uispace*3.5-8*scale, 16*scale)
			end
		end
	end
	
	if players > 1 and mariolives then
		for i = 1, players do
			local x = (width*16)/players/2 + (width*16)/players*(i-1)
			if mariolivecount ~= false then
				printfunction("p" .. i .. " * " .. tostring(mariolives[i]), (x-string.len("p" .. i .. " * " .. tostring(mariolives[i]))*4+4)*scale, 25*scale)
				love.graphics.setColor(mariocolors[i][1] or {1, 1, 1})
				love.graphics.rectangle("fill", (x-string.len("p" .. i .. " * " .. tostring(mariolives[i]))*4-3)*scale, 25*scale, 7*scale, 7*scale)
				love.graphics.setColor(1, 1, 1, 1)
			end
		end
	end

	if Weapons and playerobjs[1] then
		Weapons.draw_hud(playerobjs[mouseowner] or playerobjs[1])
	end
end

drawui = game_draw_hud

global function game_draw_player_markers()
	--Player markers
	for i = 1, players do
		local v = playerobjs[i]
		if false and not v.dead and v.drawable and v.y < mapheight-.5 then
			--get if player offscreen
			local right, left, up, down = false, false, false, false
			if v.x > xscroll+width then
				right = true
			end
			
			if v.x+v.width < xscroll then
				left = true
			end
			
			if v.y > yscroll + .5 + height then
				down = true
			end
			
			if v.y+v.height < yscroll +.5 then
				up = true
			end
			
			if up or left or down or right then
				local x: number = 0
				local y: number = 0
				local angx, angy = 0, 0
				
				if right then
					x = width
					angx = 1
				elseif left then
					x = 0
					angx = -1
				end
				
				if up then
					y = 0
					angy = -1
				elseif down then
					y = height
					angy = 1
				end
				
				if not right and not left then
					x = v.x-xscroll+v.width/2
				end
				
				if not up and not down then
					y = v.y-yscroll-3/16
				end
				
				local r = -math.atan2(angx, angy)-math.pi/2
				
				--limit x or y if right angle
				if math.fmod(r, math.pi/2) == 0 then
					if up or down then
						x = math.max(x, 15/16)
						x = math.min(x, width-15/16)
					else
						y = math.max(y, 15/16)
						y = math.min(y, height-15/16)
					end
				end
				
				love.graphics.setColor(background)
				love.graphics.draw(markbaseimg, math.floor(x*16*scale), math.floor(y*16*scale), r, scale, scale, 0, 15)
				
				local dist = 21.5
				
				local xadd = math.cos(r)*dist
				local yadd = math.sin(r)*dist
				
				love.graphics.setColor(1, 1, 1)
				
				with_mask(function() love.graphics.circle("fill", math.floor((x*16+xadd)*scale), math.floor((y*16+yadd-.5)*scale), 13.5*scale) end, function()
				
				local playerx, playery = x*16+xadd, y*16+yadd+3
				
				--draw map
				for x = math.floor(v.x), math.floor(v.x)+3 do
					for y = math.floor(v.y), math.floor(v.y)+3 do
						if inmap(x, y) then
							tilenumber = map[x][y][1] as number
							
							if tilenumber ~= 0 and not tilequads[tilenumber]:getproperty("invisible", x, y) then
								local img: Image|nil = nil
								
								if tilenumber <= smbtilecount then
									img = smbtilesimg
								elseif tilenumber <= smbtilecount+portaltilecount then
									img = portaltilesimg
								elseif tilenumber <= smbtilecount+portaltilecount+customtilecount then
									img = customtilesimg
								elseif tilenumber <= smbtilecount+portaltilecount+customtilecount+modcustomtilecount[modcustomtiles as integer] then
									for i = 1, modcustomtiles as integer do
										if tilenumber <= smbtilecount+portaltilecount+customtilecount+modcustomtilecount[i as integer] then
											img = modcustomtilesimg[i as integer]
											break
										end
									end
								end
								
								love.graphics.draw(img, tilequads[tilenumber]:quad(), math.floor((x-1-v.x-6/16)*16*scale+playerx*scale), math.floor((y-1.5-v.y)*16*scale+playery*scale), 0, scale, scale)
							end
						end
					end
				end
				
				drawplayer(i, playerx, playery)
				end)
				
				love.graphics.setColor(v.colors[1] or {1, 1, 1})
				love.graphics.draw(markoverlayimg, math.floor(x*16*scale), math.floor(y*16*scale), r, scale, scale, 0, 15)
			end
		end
	love.graphics.setScissor()
	end
	
end

global function game_draw_debug()
	--Physics debug
	if physicsdebug or incognito then
		local lw = love.graphics.getLineWidth()
		love.graphics.setLineWidth(1)
		for _, v in pairs(objects) do
			for _, k in pairs(v) do
				if k.width then
					if xscroll >= k.x-width and k.x+k.width > xscroll then
						if k.active then
							love.graphics.setColor(1, 1, 1)
						else
							love.graphics.setColor(1, 0, 0)
						end
						if incognito then
							love.graphics.rectangle("fill", math.floor((k.x-xscroll)*16*scale)+.5, math.floor((k.y-yscroll-.5)*16*scale)+.5, k.width*16*scale-1, k.height*16*scale-1)
						else
							love.graphics.rectangle("line", math.floor((k.x-xscroll)*16*scale)+.5, math.floor((k.y-yscroll-.5)*16*scale)+.5, k.width*16*scale-1, k.height*16*scale-1)
						end
					end
				end
			end
		end
		love.graphics.setLineWidth(lw)
	end
	
	--Use region debug
	if userectdebug then
		love.graphics.setColor(1, 1, 1, 0.4)
		for _, k in pairs(userects) do
			local rect = k as {any:any}
			love.graphics.rectangle("fill", ((rect.x as number)-xscroll)*16*scale, ((rect.y as number)-yscroll-.5)*16*scale, (rect.width as number)*16*scale, (rect.height as number)*16*scale)
		end
		love.graphics.setColor(1, 1, 1, 1)
	end
	
	
	--portalwalldebug
	if portalwalldebug then
		for _, v in pairs(portals) do
			for k = 1, 2 do
				for i = 1, 6 do
					if objects["portalwall"][v.number .. "-" .. k .. "-" .. i] then
						objects["portalwall"][v.number .. "-" .. k .. "-" .. i]:draw()
					end
				end
			end
		end
	end

end

global function game_draw_pausemenu()
	love.graphics.setColor(0, 0, 0, 0.48)
	love.graphics.rectangle("fill", 0, 0, width*16*scale, height*16*scale)

	local screen_w = width * 16
	local lay = menu_layout_pause(screen_w)
	local panel = lay.panel as {string:any}
	draw_panel(panel.x as number, panel.y as number, panel.w as number, panel.h as number)

	local title_raw = lay.title
	if title_raw then
		local title = title_raw as {string:any}
		ui_set_color("text_accent")
		properprint(title.text as string, (title.x as number) * scale, (title.y as number) * scale)
		menu_draw_rule((panel.x as number) + 8, (panel.y as number) + 20, (panel.w as number) - 16)
	end

	local rects = lay.rects as {any}
	local prompting = menuprompt or desktopprompt or suspendprompt
	for i = 1, #pausemenuoptions do
		local raw = rects[i]
		local y = 40 + (i - 1) * 24
		local x = (panel.x as number)
		local selected = pausemenuselected == i and not prompting
		if raw then
			local r = raw as {string:any}
			y = r.y as integer
			x = r.x as number
			if selected then
				menu_draw_row_bg(r.x as number, r.y as number, r.w as number, r.h as number, "sel", 1)
				menu_draw_cursor((r.x as number) + 4, (r.y as number) + 4)
			end
		end
		if selected then
			ui_set_color("text_accent")
		else
			ui_set_color("text")
		end
		properprint(pausemenuoptions[i as integer], (x + 16) * scale, (y + 2) * scale)
		ui_set_color("text_dim")
		properprint(pausemenuoptions2[i as integer], (x + 16) * scale, (y + 12) * scale)
		
		if pausemenuoptions[i as integer] == "music volume" or pausemenuoptions[i as integer] == "game volume" then
			love.graphics.setColor(1, 1, 1, 1)
			drawrectangle((width*8)-42, y + 14, 74, 1)
			drawrectangle((width*8)-42, y + 11, 1, 7)
			drawrectangle((width*8)+32, y + 11, 1, 7)
			love.graphics.draw(volumesliderimg, math.floor(((width*8)-43+74*(pausemenuoptions[i as integer] == "music volume" and volumemusic or volumesfx))*scale),
								(y + 13) * scale, 0, scale, scale)
		end
	end
	love.graphics.setColor(1, 1, 1, 1)
	
	local cx = width * 8
	if menuprompt then
		menu_draw_yesno("quit to menu?", pausemenuselected2 == 1, nil, cx)
	end
	
	if desktopprompt then
		menu_draw_yesno("quit to desktop?", pausemenuselected2 == 1, nil, cx)
	end
	
	if suspendprompt then
		menu_draw_yesno("suspend game?", pausemenuselected2 == 1, "can only load once!", cx)
	end
end

