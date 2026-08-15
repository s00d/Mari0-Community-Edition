--[[ Editor draw: overlay / status / menu panels / chrome (extracted from editor.tl). ]]

function editor_draw_overlay(emx: number, emy: number)
	if editorstate == "selection" then
		if selectiondragging or selectionwidth then
			local x, y, width, height: number, number, number, number = 0, 0, 0, 0
			x, y = selectionx, selectiony
			if selectiondragging then
				width, height = emx-selectionx, emy-selectiony
			else
				width, height = selectionwidth, selectionheight
			end
			x, y, width, height = editor_normalize_rect(x, y, width, height)
			
			if selectiondragging then
				drawrectangle(x/scale, y/scale, width/scale, height/scale)
			end
			
			local selectionlist = selectiongettiles(x, y, width, height)
			
			love.graphics.setColor(1, 1, 1, 0.4)
			for i = 1, #selectionlist do
				local v = selectionlist[i]
				if session.map[v.x][v.y][2] and entitylist[session.map[v.x][v.y][2]] and rightclickmenues[entitylist[session.map[v.x][v.y][2]].t] then
					love.graphics.rectangle("fill", (v.x-session.xscroll-1)*16*scale, (v.y-session.yscroll-1.5)*16*scale, 16*scale, 16*scale)
				end
			end
		end
		
	elseif not rightclickactive and not rightclickm and editorstate ~= "lightdraw" and not regiondragging then
		local x, y = getMouseTile(mouse.getX(), mouse.getY()-8*scale)
		
		if inmap(x, y+1) then
			
			if pastingtiles then
				-- draw mtclipboard
					for i, v in ipairs(mtclipboard) do
						for j, w in ipairs(v) do
							--w = tonumber(w)
							local quad = tilequads[w]:quad() --[[tilequads[w].quad]]
							if w == 1 and pastemode == false then 
								-- well, do nothing
								-- or better: draw empty tiles almost transparent
								love.graphics.setColor(1, 1, 1, 0.03)
								love.graphics.draw(tilequads[w].image, quad, math.floor((x-session.xscroll-1 + pastecenter[1])*16*scale+(i-1)*16*scale), ((y-session.yscroll-1 + pastecenter[2])*16+8)*scale+((j-1)*16*scale), 0, scale, scale)
							else
								love.graphics.setColor(1, 1, 1, 0.3)
								love.graphics.draw(tilequads[w].image, quad, math.floor((x-session.xscroll-1 + pastecenter[1])*16*scale+(i-1)*16*scale), ((y-session.yscroll-1 + pastecenter[2])*16+8)*scale+((j-1)*16*scale), 0, scale, scale)
							end
						end
					end
				--end
			end
			
			love.graphics.setColor(1, 1, 1, 0.8)
			if tileswitcherpressed then
				-- draw temporal overlay for all the tiles that will be switched
				
				local cox, coy = getMouseTile(love.mouse.getX(), love.mouse.getY()+8*scale)

				-- now replace everything thats == map[cox][coy][1] to: currenttile
				local mousetile = session.map[cox][coy][1]
				for i, v in ipairs(session.map as {{MapCell}}) do
					for j, w in ipairs(v) do
						local quad = tilequads[currenttile as number]:quad() --[[tilequads[w].quad]]
						if w[1] == mousetile then
							--print(i,j,w[1],"SWITCHED")
							love.graphics.draw(tilequads[currenttile as number].image, quad, (i-1)*16*scale-session.xscroll*16*scale, (((j-1)*16*scale)-8*scale)-session.yscroll*16*scale, 0, scale, scale)
						end
					end
				end
				
				
				
			elseif tileselection then
				if tileselectionclick1 == false then
					if pastingtiles == false then
						-- no clicks yet - draw layer on single block
						love.graphics.setColor(0.5, 1, 0.5, 0.3)
						love.graphics.rectangle("fill",math.floor((x-session.xscroll-1)*16*scale), (((y-1)*16+8)*scale)-session.yscroll*16*scale, 16*scale, 16*scale)
					end
				elseif tileselectionclick2 == false then
					-- first click done - draw area: click1xy->mousexy
					local lx1, ly1 = 0, 0
					lx1 = math.min(tileselectionclick1x as integer, x as integer)
					ly1 = math.min(tileselectionclick1y as integer, y as integer)
					
					love.graphics.setColor(0.44,0.44,1,0.44)
					love.graphics.rectangle("fill",math.floor((lx1-session.xscroll-1)*16*scale), (((ly1-1)*16+8)*scale)-session.yscroll*16*scale, (math.max(tileselectionclick1x, x)-lx1)*16*scale+16*scale, (math.max(tileselectionclick1y, y)-ly1)*16*scale+16*scale)
				else
					-- two clicks done
					local lx1, ly1, lx2, ly2 = 0, 0, 0, 0
					lx1 = math.min(tileselectionclick1x as integer, tileselectionclick2x as integer)
					ly1 = math.min(tileselectionclick1y as integer, tileselectionclick2y as integer)
					lx2 = math.max(tileselectionclick1x as integer, tileselectionclick2x as integer)
					ly2 = math.max(tileselectionclick1y as integer, tileselectionclick2y as integer)
					
					-- Laziness or cleverness?
					local px, py = math.floor((lx1-session.xscroll-1)*16*scale), ((ly1-session.yscroll-1)*16+8)*scale
					local pw, ph = (lx2-lx1)*16*scale+16*scale, (ly2-ly1)*16*scale+16*scale
					
					love.graphics.setColor(0.67,1,0.67,0.7)
					local timeOscilator = love.timer.getTime() % 2
					timeOscilator = 1 - math.abs( math.cos(timeOscilator * math.pi) )
					
					-- Highlight thing
					love.graphics.rectangle("fill", px - (2 + timeOscilator*3)*scale, py - (2 + timeOscilator*3)*scale, 5*scale, scale)
					love.graphics.rectangle("fill", px - (2 + timeOscilator*3)*scale, py - (1 + timeOscilator*3)*scale, scale, 4*scale)
					love.graphics.rectangle("fill", px + pw + (2 + timeOscilator*3 - 5)*scale, py - (2 + timeOscilator*3)*scale, 5*scale, scale)
					love.graphics.rectangle("fill", px + pw + (1 + timeOscilator*3)*scale, py - (1 + timeOscilator*3)*scale, scale, 4*scale)
					love.graphics.rectangle("fill", px - (2 + timeOscilator*3)*scale, py + ph + (1 + timeOscilator*3)*scale, 5*scale, scale)
					love.graphics.rectangle("fill", px - (2 + timeOscilator*3)*scale, py + ph + (1 + timeOscilator*3 - 4)*scale, scale, 4*scale)
					love.graphics.rectangle("fill", px + pw + (2 + timeOscilator*3 - 5)*scale, py + ph + (1 + timeOscilator*3)*scale, 5*scale, scale)
					love.graphics.rectangle("fill", px + pw + (1 + timeOscilator*3)*scale, py + ph + (1 + timeOscilator*3 - 4)*scale, scale, 4*scale)
					
					local saveColors = {1, 0.44, 0.44, 0.7}
					local selectColors = {0.67, 1, 0.67, 0.3}
					love.graphics.setColor(selectColors)
					
					if mtjustsaved > 0 then
						local _grad = gradient(selectColors, saveColors, mtjustsaved as number)
						local r = (_grad[1] or 1) as number
						local g = (_grad[2] or 1) as number
						local b = (_grad[3] or 1) as number
						local a = (_grad[4] or 1) as number
						love.graphics.setColor(r, g, b, a)
						
						mtjustsaved = math.max(mtjustsaved - love.timer.getDelta(), 0)
						if mtjustsaved == 0 then -- Negative 0 thing
							mtjustsaved = 0
						end
					end
					love.graphics.rectangle("fill", px, py, pw, ph)
				end
			elseif middlemode[1] then
				love.graphics.push()
				love.graphics.translate(-session.xscroll*16*scale, -session.yscroll*16*scale)
				if editentities and editenemies then
					for i = 1, #enemies do
						if enemies[i] == currenttile then
							currenttile = i
							break
						end
					end
					local ct = currenttile as number
					local offy = math.ceil(ct/22)-1
					local offx = ct-offy*22
					local cox, coy = getMouseTile(middlemode[2] as number, (middlemode[3] as number)-8*scale)
					for i = 1, #enemies do
						local v = enemiesdata[ enemies[i] ]
						love.graphics.setColor(1, 1, 1, 0.2)
						if i == currenttile then
							love.graphics.setColor(1, 1, 1, 0.8)
						end
						
						with_mask(function() love.graphics.rectangle("fill", (math.fmod((i-1), 22)-offx)*17*scale+cox*16*scale+scale, (math.floor((i-1)/22)-offy)*17*scale+coy*16*scale-8*scale, 16*scale, 16*scale) end, function()
							love.graphics.draw(v.graphic, v.quad, (math.fmod((i-1), 22)-offx)*17*scale+cox*16*scale+scale, (math.floor((i-1)/22)-offy)*17*scale+coy*16*scale-8*scale, 0, scale, scale)
						end)
						
						if i == currenttile then
							love.graphics.setColor(1, 0, 0, 0.6)
							drawrectangle((math.fmod((i-1), 22)-offx)*17+cox*16, (math.floor((i-1)/22)-offy)*17+coy*16-9, 18, 18)
						end
					end
					currenttile = enemies[(currenttile as integer)]
				elseif editentities then
					local list, id = 1, 1
					for i, v in ipairs(entitylistitems) do
						for j, w in ipairs(v.entries) do
							if w.i == currenttile then
								list = i
								id = j
							end
						end
					end
					
					local offy = list-1
					local offx = id
					local cox, coy = getMouseTile(middlemode[2] as number, (middlemode[3] as number)-8*scale)
					for i2, v in ipairs(entitylistitems) do
						for j, w in ipairs(v.entries) do
							local i = (i2-1)*22+j
							love.graphics.setColor(1, 1, 1, 0.2)
							if w.i == currenttile then
								love.graphics.setColor(1, 1, 1, 0.8)
							end
							love.graphics.draw(entityquads[w.i].image, entityquads[w.i].quad, (math.fmod((i-1), 22)-offx)*17*scale+cox*16*scale+scale, (math.floor((i-1)/22)-offy)*17*scale+coy*16*scale-8*scale, 0, scale, scale)
							if w.i == currenttile then
								love.graphics.setColor(1, 0, 0, 0.6)
								drawrectangle((math.fmod((i-1), 22)-offx)*17+cox*16, (math.floor((i-1)/22)-offy)*17+coy*16-9, 18, 18)
							end
						end
					end
				else
					local ctile = currenttile as number
					local offy = math.ceil(ctile/22)-1
					local offx = ctile-offy*22
					local cox, coy = getMouseTile(middlemode[2] as number, (middlemode[3] as number)-8*scale)
					for a = 1, tilelistcount+1 do
						local i = a+tileliststart-1
						love.graphics.setColor(1, 1, 1, 0.2)
						if i == ctile then
							love.graphics.setColor(1, 1, 1, 0.8)
						end
						love.graphics.draw(tilequads[i].image, tilequads[i]:quad(), (math.fmod((i-1), 22)-offx)*17*scale+cox*16*scale+scale, (math.floor((i-1)/22)-offy)*17*scale+coy*16*scale-8*scale, 0, scale, scale)
						if i == ctile then
							love.graphics.setColor(1, 0, 0, 0.6)
							drawrectangle((math.fmod((i-1), 22)-offx)*17+cox*16, (math.floor((i-1)/22)-offy)*17+coy*16-9, 18, 18)
						end
					end
				end
				love.graphics.pop()
			elseif pastingtiles == false then
				love.graphics.setColor(1, 1, 1, 0.8)
				local cox, coy = (middlemode[2] as number), (middlemode[3] as number)
				if love.mouse.isDown(3) then
					cox, coy = getMouseTile(love.mouse.getX(), love.mouse.getY()-8*scale)
				end
				if editentities == false then
					local ctile = currenttile as number
					local tileq = tilequads[ctile]:quad()
					if ctile > 10000 then
						tileq = tilequads[ctile]:quad()
					end
					for t1 = 1, brush[1] as number do
						for t2 = 1, brush[2] as number do
							love.graphics.draw(tilequads[ctile].image, tileq, math.floor((cox-session.xscroll-1+(t1-1))*16*scale), math.floor(((coy-session.yscroll-1+(t2-1))*16+8)*scale), 0, scale, scale)
						end
					end
				elseif editenemies == false then
					local ctile = currenttile as number
					for t1 = 1, brush[1] as number do
						for t2 = 1, brush[2] as number do
							love.graphics.draw(entityquads[ctile].image, entityquads[ctile].quad, math.floor((cox-session.xscroll-1+(t1-1))*16*scale), math.floor(((coy-session.yscroll-1+(t2-1))*16+8)*scale), 0, scale, scale)
						end
					end
				else
					local v = enemiesdata[currenttile as string]
					local xoff, yoff = (((v.spawnoffsetx or 0)+v.width/2-.5)*16 - v.offsetX + v.quadcenterX)*scale, (((v.spawnoffsety or 0)-v.height+1)*16-v.offsetY - v.quadcenterY)*scale
					for t1 = 1, brush[1] as number do
						for t2 = 1, brush[2] as number do
							love.graphics.draw(v.graphic, v.quad, math.floor((cox-session.xscroll-1+(t1-1))*16*scale+xoff), math.floor(((coy-session.yscroll+(t2-1))*16)*scale+yoff), 0, scale, scale)
						end
					end
				end
			end
		end
	end
	
end

function editor_draw_linking(mx: number, my: number)
	if rightclickactive and not regiondragging then
		local cox, coy = getMouseTile(mx, my+8*scale)
		
		local table1: {any} = {}
		for _, v in pairs(outputsi) do
			table.insert(table1, v)
		end
		
		for x = math.floor(session.xscroll), math.floor(session.xscroll)+width+1 do
			for y = math.floor(session.yscroll), math.floor(session.yscroll)+height+1 do
				for _, v in ipairs(table1) do
					if inmap(x, y) and #session.map[x][y] > 1 and session.map[x][y][2] == v then
						if cox == x and coy == y and tablecontains(outputsi, session.map[x][y][2]) then
							love.graphics.setColor(1, 1, 0.6, 1)
						elseif tablecontains(outputsi, session.map[x][y][2]) then
							love.graphics.setColor(1, 1, 0.6, 0.6)
						end
						love.graphics.rectangle("fill", math.floor((x-1-session.xscroll)*16*scale), ((y-1-session.yscroll)*16-8)*scale, 16*scale, 16*scale)
					end
				end
			end
		end
	end
	
	if drawalllinks then
		local added: number = 0
		for x = 1, session.mapwidth do
			for y = 1, session.mapheight do
				local ltx, lty = x, y
				local lx1, ly1 = editor_link_screen_pos(ltx, lty)
				local lx2, ly2 = 0.0, 0.0
				
				local drawtable: {{any}} = {}
				
				for i = 1, #session.map[ltx][lty] do
					if session.map[ltx][lty][i] == "link" and tonumber(session.map[ltx][lty][i+2]) and tonumber(session.map[ltx][lty][i+3]) then
						lx2, ly2 = math.floor(((session.map[ltx][lty][i+2] as number)-session.xscroll-.5)*16*scale), math.floor(((session.map[ltx][lty][i+3] as number)-session.yscroll-1)*16*scale)
						
						local t = session.map[ltx][lty][i+1]
						added = (added as number) + 0.2
						local color = getrainbowcolor(0.7)
						table.insert(drawtable, {lx1, ly1, lx2, ly2, t, color})
					end
				end
				
				table.sort(drawtable, function(a: {any}, b: {any}): boolean return math.abs((a[3] as number)-(a[1] as number))>math.abs((b[3] as number)-(b[1] as number)) end)
				
				for i = 1, #drawtable do
					local dx1 = drawtable[i][1] as number
					local dy1 = drawtable[i][2] as number
					local dx2 = drawtable[i][3] as number
					local dy2 = drawtable[i][4] as number
					local t = drawtable[i][5]
					local c = drawtable[i][6] as {number}
					local r, g, b = c[1], c[2], c[3]
					love.graphics.setColor(r, g, b, math.max(0, 1-rightclicka))
					
					if math.fmod(i, 2) == 0 then
						drawlinkline2(dx1, dy1, dx2, dy2)
					else
						drawlinkline(dx1, dy1, dx2, dy2)
					end
					properprintbackground(t as string, math.floor(dx2-string.len(t as string)*4*scale), dy2+10*scale, true, {r, g, b, math.max(0, (1-rightclicka))})
				end
			end
		end
	end
	
	if ((rightclickactive or rightclickm ~= nil) and editorstate ~= "lightdraw") or rightclicka > 0 then
		local ltx, lty = 0.0, 0.0
		local lx1, ly1 = 0.0, 0.0
		local lx2, ly2 = 0.0, 0.0
		if rightclickm then
			ltx = (rightclickm as rightclickmenu).tx as number
			lty = (rightclickm as rightclickmenu).ty as number
			lx1, ly1 = editor_link_screen_pos(ltx, lty)
		else
			ltx = linktoolX
			lty = linktoolY
			lx1, ly1 = editor_link_screen_pos(ltx, lty)
		end
		
		local drawtable: {{any}} = {}
		
		if session.map[ltx] and session.map[ltx][lty] then
			for i = 1, #session.map[ltx][lty] do
				if session.map[ltx][lty][i] == "link" and tonumber(session.map[ltx][lty][i+2]) and tonumber(session.map[ltx][lty][i+3]) then
					lx2, ly2 = math.floor(((session.map[ltx][lty][i+2] as number)-session.xscroll-.5)*16*scale), math.floor(((session.map[ltx][lty][i+3] as number)-session.yscroll-1)*16*scale)
					
					local t = session.map[ltx][lty][i+1]
					table.insert(drawtable, {lx1, ly1, lx2, ly2, t})
				end
			end
		end
		
		table.sort(drawtable, function(a: {any}, b: {any}): boolean return math.abs((a[3] as number)-(a[1] as number))>math.abs((b[3] as number)-(b[1] as number)) end)
		
		for i = 1, #drawtable do
			local dx1 = drawtable[i][1] as number
			local dy1 = drawtable[i][2] as number
			local dx2 = drawtable[i][3] as number
			local dy2 = drawtable[i][4] as number
			local t = drawtable[i][5]
			love.graphics.setColor(0.5, 0.5, i/#drawtable, rightclicka)
			
			if math.fmod(i, 2) == 0 then
				drawlinkline2(dx1, dy1, dx2, dy2)
			else
				drawlinkline(dx1, dy1, dx2, dy2)
			end
			
			properprintbackground(t as string, math.floor(dx2-string.len(t as string)*4*scale), dy2+10*scale, true, {0, 0, 0, rightclicka})
		end
		
		if linktoolt then
			local px1, py1 = editor_link_screen_pos(linktoolX, linktoolY)
			local px2, py2 = mx, my
			
			love.graphics.setColor(255 / 255, 172 / 255, 47 / 255, 1)
			
			drawlinkline(px1, py1, px2, py2)
			
			love.graphics.setColor(200 / 255, 140 / 255, 30 / 255, 1)
			
			love.graphics.draw(linktoolpointerimg, px2-math.ceil(scale/2), py2, 0, scale, scale, 3, 3)
			
			properprintbackground(linktoolt as string, math.floor(px2+4*scale), py2-4*scale, true)
		end
		
		--faithplate paths
		if entitylist[session.map[ltx][lty][2] as number].t == "faithplate" then
			local yoff = -8/16
			local x = ltx
			local y = lty-1
			local pointstable: {{string:number}} = {{x=x, y=y+yoff}}
			
			local speedx, speedy = 0.0, 0.0
			if rightclickm then
				speedx = (((rightclickm as rightclickmenu).t[2] as guielement).value) as number
				speedy = -((((rightclickm as rightclickmenu).t[4] as guielement).value) as number)
			else
				speedx = tonumber(session.map[ltx][lty][3]) or 0
				speedy = -(tonumber(session.map[ltx][lty][4]) or 0)
			end
			
			local step = 1/60
			
			repeat
				x, y = x+speedx*step, y+speedy*step
				speedy = speedy + yacceleration*step
				table.insert(pointstable, {x=x, y=y+yoff})
			until y > session.yscroll+height+.5
			
			love.graphics.setColor(62 / 255, 213 / 255, 244 / 255, 0.6*rightclicka)
			for i = 1, #pointstable-1 do
				local v = pointstable[i]
				local w = pointstable[i+1]
				love.graphics.line((v.x-session.xscroll)*16*scale, (v.y-session.yscroll-.5)*16*scale, (w.x-session.xscroll)*16*scale, (w.y-session.yscroll-.5)*16*scale)
			end
		end
	end
	if rightclickm then
		(rightclickm as rightclickmenu):draw()
	end
	
end

function editor_draw_status()
	-- EDITOR UI
	local mode, submode = editor_mode_labels(editorstate, editenemies, editentities, advanceddrawtool)
	love.graphics.setColor(1, 1, .8, .75)
	properprint(" editor mode", 10*scale, 10*scale)
	if submode then
		properprint("tool submode", 10*scale, 18*scale)
	end
	properprint("f1 for help", (400-10-8*11)*scale, 10*scale)
	
	love.graphics.setColor(1, 1, 1, .75)
	properprint(":" .. mode, (10+12*8)*scale, 10*scale)
	if submode then
		properprint(":" .. (submode as string), (10+12*8)*scale, 18*scale)
	end
	
	if sys_down("f1") and not rightclickm then
		love.graphics.setColor(0, 0, 0, .85)
		love.graphics.rectangle("fill", helpui[1]*scale, helpui[2]*scale, (helpui[3]-helpui[1])*scale, (helpui[4]-helpui[2])*scale)
		love.graphics.setColor(1, 1, 1, 1)
		drawrectangle(helpui[1] + 1, helpui[2] + 1, helpui[3]-helpui[1]-2, helpui[4]-helpui[2]-2)
		properprint("better editor shortcuts:", helpui[1]*scale+4*scale, helpui[2]*scale+5*scale)
		
		local keys = {
			--Shortcut, description, line breaks             | <-Width limit
			{"ctrl+click","selects region of tiles in-editor.", 0},
			{"q","switch between tiles, entities and enemies.", 0},
			{"0-9","on the tile/entity/enemy screen, 1-9 sets|" ..
				   "the tile's hotkey bind, 0 resets it.|" ..
				   "in-editor, switches to the bound tile.", 2},
			{"ctrl+s","saves the selected tiles as an object,|" ..
					  "found in the objects tab.", 1},--     |
			{"ctrl+g","transforms the selected tiles into a|" ..
					  "group bound to the top-left-most tile.", 1},
			{"u","on the tile screen, removes the tile group|" ..
				 "bound to the highlighted tile.", 1},--     |
			{"ctrl+z/ctrl+y","undo/redo the last changes.", 0},
			{"tab / p","toggle palette / props docks.", 0},
			{"t","test level from cursor position.", 0},
			{"alt+paint","place raw tile (skip autotile).", 0},
			{"ctrl+c/ctrl+x/ctrl+v","copy/cut/paste region.", 0},
			{"shift+1-5","enemy mods: wing/big/fast/ice/stack.", 0},
			{"ctrl+a","select the entire level.", 0},--      |
			{"middle click drag","navigates in-editor between|" ..
								 "tiles/entities/enemies.", 1},
		}
		
		local offset = 0
		for i, v in ipairs(keys) do
			love.graphics.setColor(0, 0, 0, 1)
			properprint(v[1], helpui[1]*scale+8*scale-scale, helpui[2]*scale+23*scale + (i-1)*13*scale + offset*10*scale)
			properprint(v[1], helpui[1]*scale+8*scale+scale, helpui[2]*scale+23*scale + (i-1)*13*scale + offset*10*scale)
			properprint(v[1], helpui[1]*scale+8*scale, helpui[2]*scale+23*scale-scale + (i-1)*13*scale + offset*10*scale)
			properprint(v[1], helpui[1]*scale+8*scale, helpui[2]*scale+23*scale+scale + (i-1)*13*scale + offset*10*scale)
			love.graphics.setColor(1, 1, .8, 1)
			properprint(v[1], helpui[1]*scale+8*scale, helpui[2]*scale+23*scale + (i-1)*13*scale + offset*10*scale)
			
			love.graphics.setColor(1, 1, 1, 1)
			properprint(" : ", helpui[1]*scale+8*scale + string.len(v[1])*8*scale, helpui[2]*scale+23*scale + (i-1)*13*scale + offset*10*scale)
			properprint(v[2], helpui[1]*scale+8*scale + (string.len(v[1])+3)*8*scale, helpui[2]*scale+23*scale + (i-1)*13*scale + offset*10*scale)
			
			offset = offset + v[3]
		end
		love.graphics.setColor(1, 1, 1, 1)
	end
end

function editor_draw_menu(emx: number, emy: number)
	if changemapwidthmenu then
		editor_draw_menu_changewidth()
		return
	end

	layout_recalc(editorstate, true)
	local L = EDITOR_LAYOUT
	local dock = L and L.dock_mode

	if dock then
		-- Side docks; canvas stays visible (no fullscreen modal cover).
		if not L.palette_collapsed and L.palette.w >= 24 then
			draw_panel(L.palette.x, L.palette.y, L.palette.w, L.palette.h)
		end
		if not L.props_collapsed and L.props.w >= 24 then
			draw_panel(L.props.x, L.props.y, L.props.w, L.props.h)
		end
		if L.minimap.w >= 24 and L.minimap.h >= 16 then
			-- thin strip under canvas
			local c = UI.COL.panel
			love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * 0.9)
			love.graphics.rectangle("fill", L.minimap.x*scale, L.minimap.y*scale, L.minimap.w*scale, L.minimap.h*scale)
		end
		if L.hint.w >= 24 then
			ui_set_color("text_dim")
			properprint("tab palette  p props  t test cursor  alt raw  shift+1-5 mods", (L.hint.x+8)*scale, (L.hint.y+4)*scale)
			-- recent tiles strip
			if EDITOR_RECENT_TILES and #EDITOR_RECENT_TILES > 0 and not editentities then
				love.graphics.setColor(1, 1, 1, 0.85)
				for i = 1, math.min(6, #EDITOR_RECENT_TILES) do
					local tid = EDITOR_RECENT_TILES[i]
					if tilequads[tid] then
						love.graphics.draw(tilequads[tid].image, tilequads[tid]:quad(), (L.hint.x + 8 + (i - 1) * 17) * scale, (L.hint.y - 18) * scale, 0, scale, scale)
					end
				end
			end
			love.graphics.setColor(1, 1, 1, 1)
		end
	else
		-- animations / maps / objects: denser overlay (keep usable)
		if minimapdragging == false then
			if draw_panel then
				draw_panel(0, 16, 400, 192)
			else
				love.graphics.setColor(0, 0, 0, 0.9)
				love.graphics.rectangle("fill", 1*scale, 18*scale, 398*scale, 205*scale)
			end
		else
			love.graphics.setColor(0, 0, 0, 0.9)
			love.graphics.rectangle("fill", 1*scale, 18*scale, 398*scale, (18+minimapheight*2)*scale)
		end
	end

	if editorstate == "tiles" then
		editor_draw_menu_tiles(emx, emy)
	elseif editorstate == "main" then
		editor_draw_menu_main(emx, emy)
	elseif editorstate == "maps" then
		editor_draw_menu_maps()
	elseif editorstate == "tools" then
		editor_draw_menu_tools()
	elseif editorstate == "animations" then
		editor_draw_menu_animations(emx, emy)
	elseif editorstate == "objects" then
		editor_draw_menu_objects(emx, emy)
	elseif editorstate == "lightdrawcustomize" then
		editor_draw_menu_lightdrawcustomize()
	end
end

function editor_draw_menu_changewidth()
	local w = width*16-52
	local h = height*16-52
	
	local s = math.min(w/newmapwidth, h/newmapheight)
	
	w = newmapwidth*s
	h = newmapheight*s
	
	local mapx, mapy = (width*16 - w)/2, (height*16 - h)/2
	
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", (mapx-2)*scale, (mapy-2)*scale, (w+4)*scale, (h+4)*scale)
	
	
	--minimap
	for x = 1, session.mapwidth do
		for y = 1, session.mapheight do
			if x > -newmapoffsetx and x <= newmapwidth-newmapoffsetx and y > -newmapoffsety and y <= newmapheight-newmapoffsety then
				local id = session.map[x][y][1]
				if id ~= nil and rgblist[id] and id ~= 0 and tilequads[id]:getproperty("invisible", x, y) == false then
					love.graphics.setColor(unpack(rgblist[id as number] as {any}))
					love.graphics.rectangle("fill", (mapx+(x-1+newmapoffsetx)*s)*scale, (mapy+(y-1+newmapoffsety)*s)*scale, s*scale, s*scale)
				end
			end
		end
	end
	
	love.graphics.setColor(1, 0, 0, 1)
	drawrectangle(mapx-1, mapy-1, w+2, h+2)
	
	love.graphics.setColor(1, 1, 1)
	properprintbackground("old width: " .. session.mapwidth, 26*scale, (mapy-21)*scale, true)
	properprintbackground("old height: " .. session.mapheight, 26*scale, (mapy-11)*scale, true)
	
	properprintbackground("new width: " .. newmapwidth, 26*scale, (mapy+h+4)*scale, true)
	properprintbackground("new height: " .. newmapheight, 26*scale, (mapy+h+14)*scale, true)
	
	--button positioning
	guielements["maptopup"].x, guielements["maptopup"].y = width*8-5, mapy-24
	guielements["maptopdown"].x, guielements["maptopdown"].y = width*8-5, mapy-13
	
	guielements["mapbottomup"].x, guielements["mapbottomup"].y = width*8-5, mapy+h+2
	guielements["mapbottomdown"].x, guielements["mapbottomdown"].y = width*8-5, mapy+h+13
	
	guielements["mapleftleft"].x, guielements["mapleftleft"].y = mapx-24, height*8-5
	guielements["mapleftright"].x, guielements["mapleftright"].y = mapx-13, height*8-5
	
	guielements["maprightleft"].x, guielements["maprightleft"].y = mapx+w+2, height*8-5
	guielements["maprightright"].x, guielements["maprightright"].y = mapx+w+13, height*8-5
	
	guielements["mapwidthapply"].x, guielements["mapwidthapply"].y = width*8+10, mapy+h+4
	guielements["mapwidthcancel"].x, guielements["mapwidthcancel"].y = width*8+65, mapy+h+4
end

function editor_draw_menu_tiles(_: number, _: number)
	
	--TILES
	love.graphics.setColor(1, 1, 1)
	local cols = tilelist_cols or 22
	local ox = tilelist_ox or 5
	local oy = tilelist_oy or 38
	local area_w = cols * 17 + 1
	local area_h = 165
	local L = EDITOR_LAYOUT
	if L and L.dock_mode and L.palette.w > 0 then
		area_w = math.max(17, math.floor(L.palette.w - 16))
		area_h = math.max(17, math.floor(L.palette.h - 40))
	end
	
	drawrectangle(ox - 1, oy - 1, area_w, area_h)
	
	love.graphics.setScissor(ox*scale, oy*scale, area_w*scale, area_h*scale)
	
	if editentities then
		if editenemies then
			for i = 1, #enemies do
				local v = enemiesdata[enemies[i]]
				
				with_mask(function() love.graphics.rectangle("fill", math.fmod((i-1), cols)*17*scale+ox*scale, math.floor((i-1)/cols)*17*scale+oy*scale-tilesoffset, 16*scale, 16*scale) end, function()
					love.graphics.draw(v.graphic, v.quad, math.fmod((i-1), cols)*17*scale+ox*scale, math.floor((i-1)/cols)*17*scale+oy*scale-tilesoffset, 0, scale, scale)
				end)
				local hotkey = hasHotkey(3, i)
				if hotkey then
					love.graphics.setColor(1, 0, 0, .5)
					drawrectangle(math.fmod((i-1), cols)*17+ox, math.floor((i-1)/cols)*17+oy-tilesoffset/scale, 16, 16)
					love.graphics.setColor(1, 1, 1)
				end
			end
		else
			--ENTITIES
			for _, v in ipairs(entitylistitems) do
				properprint(v.t, (5)*scale, (v.entries[1].y+30)*scale-tilesoffset)
				for _, k in ipairs(v.entries) do
					local hotkey = hasHotkey(2, k.i)
					love.graphics.draw(entityquads[k.i].image, entityquads[k.i].quad, (k.x+5)*scale, (k.y+38)*scale-tilesoffset, 0, scale, scale)
					if hotkey then
						love.graphics.setColor(1, 0, 0, .5)
						drawrectangle(k.x+5, k.y+38-tilesoffset/scale, 16, 16)
						love.graphics.setColor(1, 1, 1, 1)
					end
					if k:gethighlight(mouse.getX(), mouse.getY()) then
						if hotkey then
							love.graphics.setColor(1, 0, 0, .5)
						else
							love.graphics.setColor(1, 1, 1, 0.5)
						end
						love.graphics.rectangle("fill", (k.x+5)*scale, (k.y+38)*scale-tilesoffset, 16*scale, 16*scale)
						love.graphics.setColor(1, 1, 1, 1)
						if hotkey then
							properprint(hotkey, (k.x+5)*scale+7*scale, (k.y+38)*scale-tilesoffset+8*scale)
						end
					end
				end
			end
		end
	else
		if animatedtilelist then
			for i = 1, tilelistcount+1 do
				love.graphics.draw(tilequads[i+tileliststart-1+10000].image, tilequads[i+tileliststart-1+10000]:quad(), math.fmod((i-1), cols)*17*scale+ox*scale, math.floor((i-1)/cols)*17*scale+oy*scale-tilesoffset, 0, scale, scale)
				if multitilegroups[tostring(i+tileliststart-1+10000)] then
					love.graphics.setColor(0, .5, 0)
					drawrectangle(math.fmod((i-1), cols)*17+ox, math.floor((i-1)/cols)*17+oy-tilesoffset/scale, 16, 16)
					love.graphics.setColor(1, 1, 1)
				end
				local hotkey = hasHotkey(1, i+tileliststart-1+10000)
				if hotkey then
					love.graphics.setColor(1, 0, 0, .5)
					drawrectangle(math.fmod((i-1), cols)*17+ox, math.floor((i-1)/cols)*17+oy-tilesoffset/scale, 16, 16)
					love.graphics.setColor(1, 1, 1)
				end
			end
		else
			for i = 1, tilelistcount+1 do
				love.graphics.draw(tilequads[i+tileliststart-1].image, tilequads[i+tileliststart-1]:quad(), math.fmod((i-1), cols)*17*scale+ox*scale, math.floor((i-1)/cols)*17*scale+oy*scale-tilesoffset, 0, scale, scale)
				if multitilegroups[tostring(i+tileliststart-1)] then
					love.graphics.setColor(0, .5, 0)
					drawrectangle(math.fmod((i-1), cols)*17+ox, math.floor((i-1)/cols)*17+oy-tilesoffset/scale, 16, 16)
					love.graphics.setColor(1, 1, 1)
				end
				local hotkey = hasHotkey(1, i+tileliststart-1)
				if hotkey then
					love.graphics.setColor(1, 0, 0, .5)
					drawrectangle(math.fmod((i-1), cols)*17+ox, math.floor((i-1)/cols)*17+oy-tilesoffset/scale, 16, 16)
					love.graphics.setColor(1, 1, 1)
				end
			end
		end
	end
	
	local tile = gettilelistpos(mouse.getX(), mouse.getY()) as number
	if editentities == false then
		if tile and tile <= tilelistcount+1 then
			local hotkey = hasHotkey(1, (tile as number)+tileliststart-1+(animatedtilelist and 10000 or 0))
			if hotkey then
				love.graphics.setColor(1, 0, 0, .5)
			else
				love.graphics.setColor(1, 1, 1, 0.5)
			end
			love.graphics.rectangle("fill", (ox+math.fmod(((tile as number)-1), cols)*17)*scale, (oy+math.floor(((tile as number)-1)/cols)*17)*scale-tilesoffset, 16*scale, 16*scale)
			if hotkey then
				love.graphics.setColor(1, 1, 1, 1)
				properprint(hotkey, (ox+math.fmod(((tile as number)-1), cols)*17)*scale+7*scale, (oy+math.floor(((tile as number)-1)/cols)*17)*scale-tilesoffset+8*scale)
			end
		end
	elseif editenemies then
		if tile and tile <= #enemies then
			local hotkey = hasHotkey(3, tile)
			if hotkey then
				love.graphics.setColor(1, 0, 0, .5)
			else
				love.graphics.setColor(1, 1, 1, 0.5)
			end
			love.graphics.rectangle("fill", (ox+math.fmod(((tile as number)-1), cols)*17)*scale, (oy+math.floor(((tile as number)-1)/cols)*17)*scale-tilesoffset, 16*scale, 16*scale)
			if hotkey then
				love.graphics.setColor(1, 1, 1, 1)
				properprint(hotkey, (ox+math.fmod(((tile as number)-1), cols)*17)*scale+7*scale, (oy+math.floor(((tile as number)-1)/cols)*17)*scale-tilesoffset+8*scale)
			end
		end
	end
	
	love.graphics.setScissor()
	
	love.graphics.setColor(1, 1, 1)
	if editentities then
		if editenemies then
			if enemies[tile as integer] then
				if enemiesdata[enemies[tile as integer]].description then
					local newstring = enemies[tile as integer] .. " - " .. tostring(enemiesdata[enemies[tile as integer]].description)
					if string.len(newstring) > 49 then
						newstring = string.sub(newstring, 1, 49) .. "|" .. string.sub(newstring, 50, 98)
					end
					properprint(newstring, ox*scale, (oy+area_h+4)*scale)
				else
					properprint(enemies[tile as integer], ox*scale, (oy+area_h+4)*scale)
				end
			end
		else
			local ent = getentityhighlight(mouse.getX(), mouse.getY())
			if ent then
				local newstring = entitylist[(ent as EntityListEntry).i].description or ""
				if string.len(newstring) > 49 then
					newstring = string.sub(newstring, 1, 49) .. "|" .. string.sub(newstring, 50, 98)
				end
				properprint(newstring, ox*scale, (oy+area_h+4)*scale)
			end
		end
	elseif animatedtilelist then
		if tile and animatedtiles[tile as integer] then
			properprint("frames: " .. #(animatedtiles[tile as integer].delays as {any}), ox*scale, (oy+area_h+4)*scale)
			local t: number = 0
			for i = 1, #(animatedtiles[tile as integer].delays as {any}) do
				t = t + ((animatedtiles[tile as integer].delays as {any})[i] as number)
			end
			properprint("total time: " .. t, ox*scale, (oy+area_h+14)*scale)
		end
	else
		if tile and tilequads[(tile as number)+tileliststart-1] and (tile as number)+tileliststart-1 <= tilelistcount+tileliststart then
			--Local variables
			local propertylist = {"collision", "invisible", "breakable", "coinblock", "coin", "slantupleft", "slantupright", "mirror", "grate", "platform", "water", "bridge", "spikesleft", "spikestop","spikesright", "spikesbottom", "foreground", "big"}
			local propertytable = {}
			local longestpropertylength = 0
			local propertycount = -10
			local s = ""
			--2*2 Tile
			
			--Unportalable
			if not tilequads[(tile as number)+tileliststart-1]:getproperty("portalable") then
				table.insert(propertytable, "unportalable")
				propertycount = propertycount + 10
				if 12 >= longestpropertylength then
					longestpropertylength = 12
				end
			end
			--Properties
			for i = 1, #propertylist do
				if tilequads[(tile as number)+tileliststart-1]:getproperty(propertylist[i]) then
					table.insert(propertytable, propertylist[i])
					propertycount = propertycount + 10
					if string.len(propertylist[i]) >= longestpropertylength then
						longestpropertylength = string.len(propertylist[i])
					end
				end
			end
			--Eraser
			if (tile as number)+tileliststart-1 == 1 then
				table.insert(propertytable, "eraser")
				propertycount = propertycount + 10
				if 6 >= longestpropertylength then
					longestpropertylength = 6
				end
			end
			--I should probably remove this
			if propertycount == -10 then
				table.insert(propertytable, "none")
				propertycount = 0
				longestpropertylength = 4
			end
			--Generate property string
			for i = 1, #propertytable do
				local addspaces = ""
				for _ = 1, -(string.len(propertytable[i]) - longestpropertylength) do
					addspaces = addspaces .. " "
				end
				s = s .. addspaces .. propertytable[i] .. "|"
			end
			--Cutoff prevention
			local y = love.mouse.getY()-8*scale - (propertycount/2)*scale + 5*scale
			local x = love.mouse.getX() - (longestpropertylength)*8*scale
			if x <= 0 then
				x = 0
			end
			--Finally actually draw it
			properprint("tile id: " .. (tile as number)+tileliststart-1, ox*scale, (oy+area_h+4)*scale)
			properprintbackground(s, x, y, false)
			properprint(s, x, y)
		end
	end
	love.graphics.setColor(1, 1, 1)
end

function editor_draw_menu_main(_: number, _: number)

	--MINIMAP
	love.graphics.setColor(1, 1, 1)
	properprint("minimap", 3*scale, 21*scale)
	love.graphics.rectangle("fill", minimapx*scale, minimapy*scale, 394*scale, minimapheight*2*scale+4*scale)
	love.graphics.setColor(unpack(background))
	love.graphics.rectangle("fill", (minimapx+2)*scale, (minimapy+2)*scale, 390*scale, minimapheight*2*scale)
	
	local lmap = session.map
	
	love.graphics.setScissor((minimapx+2)*scale, (minimapy+2)*scale, 390*scale, minimapheight*2*scale)
	
	for x = 1, session.mapwidth do --blocks
		for y = math.floor(session.yscroll)+1, math.min(session.mapheight, math.ceil(session.yscroll)+16) do
			if x-minimapscroll > 0 and x-minimapscroll < 196 then
				local id = lmap[x][y][1]
				if id ~= nil and id ~= 0 and tilequads[id]:getproperty("invisible", x, y) == false then
					if rgblist[id] then
						love.graphics.setColor(unpack(rgblist[id as number] as {any}))
						love.graphics.rectangle("fill", (minimapx+x*2-minimapscroll*2)*scale, (minimapy+(y+1)*2-(math.floor(session.yscroll)+1)*2-math.fmod(session.yscroll, 1)*2)*scale, 2*scale, 2*scale)
					end
				end
			end
		end
	end
	
	love.graphics.setScissor()
	
	love.graphics.setColor(1, 0, 0)
	drawrectangle(session.xscroll*2+minimapx-minimapscroll*2, minimapy, (width+2)*2, minimapheight*2+4)
	drawrectangle(session.xscroll*2+minimapx-minimapscroll*2+1, minimapy+1, (width+1)*2, minimapheight*2+2)
	love.graphics.setColor(1, 1, 1)
	
	if minimapdragging == false then
		properprint("portalgun:", 8*scale, 189*scale)
		properprint(mariotimelimit, 29*scale, 177*scale)
		properprint("timelimit", 8*scale, 166*scale)
		properprint("spriteset", 8*scale, 141*scale)
		properprint("music", 8*scale, 116*scale)
		properprint("background color", 8*scale, 66*scale)
		
		if custombackground then
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.setColor(0.6, 0.6, 0.6, 1)
		end
		properprint("scrollfactor", 199*scale, 142*scale)
		
		if customforeground then
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.setColor(0.6, 0.6, 0.6, 1)
		end
		properprint("scrollfactor", 199*scale, 172*scale)
		
		love.graphics.setColor(1, 1, 1, 1)
		properprint("levelscreen:", 198*scale, 187*scale)
	end
end

function editor_draw_menu_maps()
	--[[love.graphics.setColor(1, 1, 1)
	for i = 1, 8 do
		properprint("w" .. i, ((i-1)*49 + 19)*scale, 23*scale)
	end
	properprint("do not forget to save your current map before|changing!", 5*scale, 120*scale)--]]
	
	local scroll = (guielements["mapscrollbar"].value as number) * mapsymissing
	love.graphics.setScissor(mapbuttonarea[1]*scale, mapbuttonarea[2]*scale, (mapbuttonarea[3]-mapbuttonarea[1])*scale, (mapbuttonarea[4]-mapbuttonarea[2])*scale)
	
	for _, v in pairs(mapbuttons) do
		v.y = v.starty - scroll
		v:draw()
	end
	
	properprint("-", 351*scale, 22*scale)
	love.graphics.setScissor()
end

function editor_draw_menu_tools()
	love.graphics.setColor(1, 1, 1)
	properprint("mappack title:", 5*scale, 106*scale)
	properprint("author:", 5*scale, 131*scale)
	properprint("description:", 5*scale, 156*scale)
	
	properprint("lives:", 150*scale, 106*scale)
	if mariolivecount == false then
		properprint("inf", 210*scale, 106*scale)
	else
		properprint(mariolivecount, 210*scale, 106*scale)
	end
	
	properprint("editor settings:", 149*scale, 121*scale)
	
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.setLineStyle("rough")
	love.graphics.line(148*scale, 118*scale, 397*scale, 118*scale)

end

function editor_draw_menu_animations(_: number, _: number)
	if #animations > 0 then
		love.graphics.setScissor(animationguiarea[1]*scale, animationguiarea[2]*scale, (animationguiarea[3]-animationguiarea[1])*scale, (animationguiarea[4]-animationguiarea[2])*scale)
		local completeheight = 14+#animationguilines.triggers*13+12+#animationguilines.conditions*13+12+#animationguilines.actions*13
		local offy = math.max(0, (guielements["animationsscrollbarver"].value as number)/1*(completeheight-(animationguiarea[4]-animationguiarea[2])))
		local completewidth = 0
		for _, v in pairs(animationguilines) do
			for _, w in ipairs(v) do
				local width = 32+animationlineinset
				for j, _ in ipairs(w.elements) do
					width = width + w.elements[j].width
				end
				if width > completewidth then
					completewidth = width as integer
				end
			end
		end
		
		local offx = -math.max(0, (guielements["animationsscrollbarhor"].value as number)/1*(completewidth-(animationguiarea[3]-animationguiarea[1])))
		
		love.graphics.setColor(1, 1, 1)
		
		local y = animationguiarea[2]+1-offy
		y = y + 2
		
		addanimationtriggerbutton.x = animationguiarea[1]+2+offx
		addanimationtriggerbutton.y = y-2
		addanimationtriggerbutton:draw()
		
		properprint("triggers:", (animationguiarea[1]+13+offx)*scale, y*scale)
		y = y + 10
		
		for _, v in ipairs(animationguilines.triggers) do
			v:draw((animationguiarea[1]+animationlineinset+offx), y)
			y = y + 13
		end
		y = y + 2
		
		addanimationconditionbutton.x = animationguiarea[1]+2+offx
		addanimationconditionbutton.y = y-2
		addanimationconditionbutton:draw()
		
		properprint("conditions:", (animationguiarea[1]+13+offx)*scale, y*scale)
		y = y + 10
		
		for _, v in ipairs(animationguilines.conditions) do
			v:draw((animationguiarea[1]+animationlineinset+offx), y)
			y = y + 13
		end
		y = y + 2
		
		addanimationactionbutton.x = animationguiarea[1]+2+offx
		addanimationactionbutton.y = y-2
		addanimationactionbutton:draw()
		
		properprint("actions:", (animationguiarea[1]+13+offx)*scale, y*scale)
		y = y + 10
		
		for _, v in ipairs(animationguilines.actions) do
			v:draw((animationguiarea[1]+animationlineinset+offx), y)
			y = y + 13
		end
		
		for _, v in pairs(animationguilines) do
			for _, w in ipairs(v) do
				for _, fuck in pairs(w.elements as {any:any}) do
					if (fuck as animationguielement).gui and not (fuck as animationguielement).gui.priority then
						(fuck as animationguielement).gui:draw()
					end
				end
			end
		end
		
		love.graphics.setScissor()
		
		love.graphics.setColor(0.35, 0.35, 0.35)
		drawrectangle(animationguiarea[1]-10, animationguiarea[4], 10, 10)
	end
end

function editor_draw_menu_objects(_: number, _: number)
	love.graphics.setScissor(objectsguiarea[1]*scale, objectsguiarea[2]*scale, (objectsguiarea[3]-objectsguiarea[1])*scale, (objectsguiarea[4]-objectsguiarea[2])*scale)
	
	local mtbutton = getmtbutton(love.mouse.getX())
	for i = 1, #multitileobjects do
		love.graphics.setColor(1, 1, 1, 1)
		properprint(multitileobjectnames[i], (objectsguiarea[1]+3)*scale, math.floor(i-1)*17*scale+(objectsguiarea[2]+3)*scale-multitilesoffset)
		properprint("r", (objectsguiarea[3]-15*4)*scale, math.floor(i-1)*17*scale+(objectsguiarea[2]+3)*scale-multitilesoffset)
		properprint("_dir4", (objectsguiarea[3]-15*3)*scale, math.floor(i-1)*17*scale+(objectsguiarea[2]+3)*scale-multitilesoffset)
		properprint("_dir6", (objectsguiarea[3]-15*2)*scale, math.floor(i-1)*17*scale+(objectsguiarea[2]+3)*scale-multitilesoffset)
		properprint("x", (objectsguiarea[3]-15*1)*scale, math.floor(i-1)*17*scale+(objectsguiarea[2]+3)*scale-multitilesoffset)
	end
	if guielements["renamebar"].active then
		guielements["renamebar"]:draw()
	end
	
	love.graphics.setScissor()
	
	love.graphics.setColor(0.35, 0.35, 0.35)
	drawrectangle(objectsguiarea[1], objectsguiarea[2], objectsguiarea[3]-objectsguiarea[1], objectsguiarea[4]-objectsguiarea[2])
	
	if mtbutton == 1 then
		properprint("rename", 10*scale, 210*scale)
	elseif mtbutton == 2 then
		properprint("move up", 10*scale, 210*scale)
	elseif mtbutton == 3 then
		properprint("move down", 10*scale, 210*scale)
	elseif mtbutton == 4 then
		properprint("delete", 10*scale, 210*scale)
	end	
end

function editor_draw_menu_lightdrawcustomize()
	-- love.graphics.setColor(0.5, 0.5, 0.5)
	-- properprint("more coming soon", 5*scale, 55*scale)
	
	-- I'm cancelling this stroke-inducing nightmare
	
	-- guielements["tabtools"].textcolor = {math.random(),math.random(),math.random()}
	-- guielements["tabtools"].fillcolor = {math.random(),math.random(),math.random()}
	-- guielements["tabtools"].bordercolor = {math.random(),math.random(),math.random()}
end


-- GUI tabs, region drag, entity tooltips (after map/tool content).
function editor_draw_chrome()
	if minimapdragging == false then
		--GUI not priority
		for i, v in pairs(guielements) do
			if not v.priority and v.active and i ~= "renamebar" then
				v:draw()
			end
		end

		--GUI priority
		for _, v in pairs(guielements) do
			if v.priority and v.active then
				v:draw()
			end
		end
	else
		for _, v in ipairs({"tabmain", "tabtiles", "tabtools", "tabmaps", "tabanimations", "tabobjects", "autoscrollcheckbox"} as {string}) do
			guielements[v]:draw()
		end
	end

	if editorstate == "animations" and editormenuopen and not changemapwidthmenu then
		for _, v in pairs(animationguilines) do
			for _, w in ipairs(v) do
				for _, fuck in pairs(w.elements as {any:any}) do
					if (fuck as animationguielement).gui and (fuck as animationguielement).gui.priority then
						(fuck as animationguielement).gui:draw()
					end
				end
			end
		end
	end

	if regiondragging then
		(regiondragging as RegionDragging):draw()
	end

	if editentities and not editenemies and editorstate == "tiles" and editormenuopen and entitytooltipobject then
		(entitytooltipobject as entitytooltip):draw(math.max(0, tooltipa))
	end
end
