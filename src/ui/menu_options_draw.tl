--[[ Menu options tab draw (extracted from menu.tl). ]]

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
				
				local binding = controls[skinningplayer][controlstable[i]] as {integer: string}|nil
				local s = ""
				
				if binding then
					local b = binding as {integer: string}
					for j = 1, #b do
						s = s .. binding_display(b[j])
					end
				end
				if s == " " or s == "space" then
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

