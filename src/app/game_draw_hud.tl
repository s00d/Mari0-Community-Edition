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
		
		printfunction("world", uispace*2.5 - 20*scale, 8*scale)
		printfunction(tostring(marioworld) .. "-" .. tostring(mariolevel), uispace*2.5 - 12*scale, 16*scale)
	
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
	love.graphics.setColor(0, 0, 0, 0.4)
	love.graphics.rectangle("fill", 0, 0, width*16*scale, height*16*scale)
	
	love.graphics.setColor(0, 0, 0)
	
	local menuwidth = 120
	local menuheight = 170
	love.graphics.rectangle("fill", (width*8*scale)-menuwidth/2*scale, (96*scale)-75*scale, menuwidth*scale, menuheight*scale)
	love.graphics.setColor(1, 1, 1)
	drawrectangle(width*8-(menuwidth/2)+1, 96-74, menuwidth-2, menuheight-2)
	
	for i = 1, #pausemenuoptions do
		love.graphics.setColor(0.4, 0.4, 0.4, 1)
		if pausemenuselected == i and not menuprompt and not desktopprompt then
			love.graphics.setColor(1, 1, 1, 1)
			properprint(">", (width*8*scale)-(menuwidth/2-5)*scale, (96*scale)-60*scale+(i-1)*25*scale)
		end
		properprint(pausemenuoptions[i as integer], (width*8*scale)-(menuwidth/2-15)*scale, (96*scale)-60*scale+(i-1)*25*scale)
		properprint(pausemenuoptions2[i as integer], (width*8*scale)-(menuwidth/2-15)*scale, (96*scale)-50*scale+(i-1)*25*scale)
		
		if pausemenuoptions[i as integer] == "music volume" or pausemenuoptions[i as integer] == "game volume" then
			drawrectangle((width*8)-42, 52+(i-1)*25, 74, 1)
			drawrectangle((width*8)-42, 49+(i-1)*25, 1, 7)
			drawrectangle((width*8)+32, 49+(i-1)*25, 1, 7)
			love.graphics.draw(volumesliderimg, math.floor(((width*8)-43+74*(pausemenuoptions[i as integer] == "music volume" and volumemusic or volumesfx))*scale),
								(96*scale)-47*scale+(i-1)*25*scale, 0, scale, scale)
		end
	end
	
	if menuprompt then
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("fill", (width*8*scale)-100*scale, (112*scale)-25*scale, 200*scale, 50*scale)
		love.graphics.setColor(1, 1, 1, 1)
		drawrectangle((width*8)-99, 112-24, 198, 48)
		properprint("quit to menu?", (width*8*scale)-string.len("quit to menu?")*4*scale, (112*scale)-10*scale)
		if pausemenuselected2 == 1 then
			properprint(">", (width*8*scale)-51*scale, (112*scale)+4*scale)
			love.graphics.setColor(1, 1, 1, 1)
			properprint("yes", (width*8*scale)-44*scale, (112*scale)+4*scale)
			love.graphics.setColor(0.4, 0.4, 0.4, 1)
			properprint("no", (width*8*scale)+28*scale, (112*scale)+4*scale) 
		else
			properprint(">", (width*8*scale)+20*scale, (112*scale)+4*scale)
			love.graphics.setColor(0.4, 0.4, 0.4, 1)
			properprint("yes", (width*8*scale)-44*scale, (112*scale)+4*scale)
			love.graphics.setColor(1, 1, 1, 1)
			properprint("no", (width*8*scale)+28*scale, (112*scale)+4*scale)
		end
	end
	
	if desktopprompt then
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("fill", (width*8*scale)-100*scale, (112*scale)-25*scale, 200*scale, 50*scale)
		love.graphics.setColor(1, 1, 1, 1)
		drawrectangle((width*8)-99, 112-24, 198, 48)
		properprint("quit to desktop?", (width*8*scale)-string.len("quit to desktop?")*4*scale, (112*scale)-10*scale)
		if pausemenuselected2 == 1 then
			properprint(">", (width*8*scale)-51*scale, (112*scale)+4*scale)
			love.graphics.setColor(1, 1, 1, 1)
			properprint("yes", (width*8*scale)-44*scale, (112*scale)+4*scale)
			love.graphics.setColor(0.4, 0.4, 0.4, 1)
			properprint("no", (width*8*scale)+28*scale, (112*scale)+4*scale)
		else
			properprint(">", (width*8*scale)+20*scale, (112*scale)+4*scale)
			love.graphics.setColor(0.4, 0.4, 0.4, 1)
			properprint("yes", (width*8*scale)-44*scale, (112*scale)+4*scale)
			love.graphics.setColor(1, 1, 1, 1)
			properprint("no", (width*8*scale)+28*scale, (112*scale)+4*scale)
		end
	end
	
	if suspendprompt then
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("fill", (width*8*scale)-100*scale, (112*scale)-25*scale, 200*scale, 50*scale)
		love.graphics.setColor(1, 1, 1, 1)
		drawrectangle((width*8)-99, 112-24, 198, 48)
		properprint("suspend game? this can", (width*8*scale)-string.len("suspend game? this can")*4*scale, (112*scale)-20*scale)
		properprint("only be loaded once!", (width*8*scale)-string.len("only be loaded once!")*4*scale, (112*scale)-10*scale)
		if pausemenuselected2 == 1 then
			properprint(">", (width*8*scale)-51*scale, (112*scale)+4*scale)
			love.graphics.setColor(1, 1, 1, 1)
			properprint("yes", (width*8*scale)-44*scale, (112*scale)+4*scale)
			love.graphics.setColor(0.4, 0.4, 0.4, 1)
			properprint("no", (width*8*scale)+28*scale, (112*scale)+4*scale)
		else
			properprint(">", (width*8*scale)+20*scale, (112*scale)+4*scale)
			love.graphics.setColor(0.4, 0.4, 0.4, 1)
			properprint("yes", (width*8*scale)-44*scale, (112*scale)+4*scale)
			love.graphics.setColor(1, 1, 1, 1)
			properprint("no", (width*8*scale)+28*scale, (112*scale)+4*scale)
		end
	end
end

