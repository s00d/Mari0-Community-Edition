--[[ Editor mouse/keyboard input (extracted from editor.tl). ]]

function editor_mousepressed(x: number, y: number, button: any)
	if regiondragging then
		if (regiondragging as RegionDragging):mousepressed(x, y, button) then
			finishregion()
		end
		return
	end
	
	if rightclickm then
		allowdrag = false
		if button == "r" or not (rightclickm as rightclickmenu):mousepressed(x, y, button) then
			closerightclickmenu()
			return
		else
			return
		end
	end
	
	if button == "l" or button == "r" then
		while currentstate < #(savestates as {any}) do
			table.remove(savestates)
		end
	end
	
	if changemapwidthmenu then
		return
	end
	
	if mapbuttons then
		for _, v in pairs(mapbuttons) do
			v:click(x, y, button)
		end
	end
	
	if button == "l" then
		editor_mousepressed_left(x, y)
	elseif button == "m" then
		middlemode = {false, x, y}
		love.mouse.setVisible(true)
	elseif button == "wu" then
		editor_mousepressed_wheel_up(x, y)
	elseif button == "wd" then
		editor_mousepressed_wheel_down(x, y)
	elseif button == "r" then
		editor_mousepressed_right(x, y)
	end
end

function editor_mousepressed_left(x: number, y: number)
	if editormenuopen == false then
		if editorstate == "lightdraw" then
			lightdrawX, lightdrawY = getMouseTile(x, y+8*scale)
			lightdrawtable = {{x=lightdrawX, y=lightdrawY}}
		elseif rightclickactive then
			finishlinking(x, y)
		elseif editorstate == "selection" then
			selectionstart()
		else
			-- Unified drag: move/resize/paint without mode switches
			local palette_active = currenttile ~= nil and (editentities or (type(currenttile) == "number" and (currenttile as number) > 1))
			if editor_drag_begin and not pastingtiles and not tileselection then
				editor_drag_begin(x, y, palette_active == true)
				if EDITOR_DRAG and ((EDITOR_DRAG as EditorDragState).kind == "move" or (EDITOR_DRAG as EditorDragState).kind == "resize") then
					allowdrag = false
					return
				end
			end
			local cox, coy = getMouseTile(x, y+8*scale)
			if inmap(cox, coy) then					
				local lx1: number = 0
				local ly1: number = 0
				local lx2: number = 0
				local ly2: number = 0
				local slx1: number = 0
				local sly1: number = 0
				local slx2: number = 0
				local sly2: number = 0
				lx1 = math.min(tileselectionclick1x as integer, tileselectionclick2x as integer)
				ly1 = math.min(tileselectionclick1y as integer, tileselectionclick2y as integer)
				lx2 = math.max(tileselectionclick1x as integer, tileselectionclick2x as integer)
				ly2 = math.max(tileselectionclick1y as integer, tileselectionclick2y as integer)
				
				slx1 = math.floor((lx1-session.xscroll-1)*16*scale)
				sly1 = ((ly1-session.yscroll-1)*16+8)*scale
				slx2 = slx1 + ((lx2-lx1)*16*scale+16*scale)
				sly2 = sly1 + (ly2-ly1)*16*scale+16*scale
				
				-- left click on the selected area
				if tileselectionclick1 == true and tileselectionclick2 == true and x > slx1 and x < slx2 and y > sly1 and y < sly2 then
					-- if tiles are selected and click is inside area: move
					mtclipboard = getTiles({slx1+8*scale, sly1+8*scale},{slx2+8*scale, sly2+8*scale})
					emptySelection()
					-- get x, y of the click inside the selection
					pastecenter =  {-(math.floor((x-slx1)/(16*scale))),-(math.floor((y-sly1)/(16*scale)))}
					--print(pastecenter[1], pastecenter[2])
					--print(x, y, slx1, sly1)
					pastingtiles = true
					editentities = false
					
					-- clear selection
					tileselectionclick1 = false
					tileselectionclick1x = 0
					tileselectionclick1y = 0	
					tileselectionclick2 = false
					tileselectionclick2x = 0
					tileselectionclick2y = 0
					
					allowdrag = false
					
				elseif pastingtiles then
					editor_undo_begin()
					local paste_x0: number|nil = nil
					local paste_y0: number|nil = nil
					local paste_x1: number|nil = nil
					local paste_y1: number|nil = nil
					for i, v in pairs(mtclipboard as {any:any}) do
						for j, w in pairs(v as {any:any}) do
							if w == 1 and pastemode == false then
								-- nothing
							else
								currenttile = (mtclipboard[i as integer] as {any})[j as integer]
								local px = x+((i as number)-1 + pastecenter[1])*16*scale
								local py = y+((j as number)-1 + pastecenter[2])*16*scale
								local cx, cy = getMouseTile(px, py+8*scale)
								if paste_x0 == nil then paste_x0, paste_y0, paste_x1, paste_y1 = cx, cy, cx, cy end
								paste_x0 = math.min(paste_x0 as number, cx)
								paste_y0 = math.min(paste_y0 as number, cy)
								paste_x1 = math.max(paste_x1 as number, cx)
								paste_y1 = math.max(paste_y1 as number, cy)
								placetile(px, py)
							end
						end
					end
					if paste_x0 and autotile_region then
						autotile_region(paste_x0 as number, paste_y0 as number, paste_x1 as number, paste_y1 as number)
					end
					editor_undo_commit()
					allowdrag = false
				elseif tileselection and pastingtiles == false then
					local xx, yy = getMouseTile(love.mouse.getX(), love.mouse.getY()-8*scale)
					if tileselectionclick1 == false then
						tileselectionclick1x = xx
						tileselectionclick1y = yy
						tileselectionclick1 = true
					elseif tileselectionclick2 == false then
						tileselectionclick2x = xx
						tileselectionclick2y = yy
						tileselectionclick2 = true
					else
						if not pastingtiles then
							-- reset tile selection
							tileselectionclick1 = false
							tileselectionclick1x = 0
							tileselectionclick1y = 0	
							tileselectionclick2 = false
							tileselectionclick2x = 0
							tileselectionclick2y = 0
						end
						allowdrag = false
					end
				elseif not (pastingtiles or tileselection) then
					if tileswitcherpressed then
						local cox, coy = getMouseTile(love.mouse.getX(), love.mouse.getY()+8*scale)
						if inmap(cox, coy) == false then
							-- not much
						else
							editentities = false
							tilesall()
							-- now replace everything thats == map[cox][coy][1] to: currenttile
							local mousetile = session.map[cox][coy][1]
							for i, v in ipairs(session.map as {{MapCell}}) do
								for j, w in ipairs(v) do
									if w[1] == mousetile then
										session.map[i][j][1] = currenttile
									end
								end
							end
							generatespritebatch(0, 0)
							--local x, y = love.mouse.getPosition()
							--placetile(x, y)
						end
					else
						if session.coinmap[cox][coy] then
							editorcoinstart = true
						else
							editorcoinstart = false
						end
						for t1 = 1, brush[1] do
							for t2 = 1, brush[2] do
								placetile(x+(t1-1)*16*scale, y+(t2-1)*16*scale)
							end
						end
					end
				end
			end
		end
	else
		if editorstate == "tiles" then
			local tile = gettilelistpos(x, y) as number
			local keep_dock = EDITOR_LAYOUT and EDITOR_LAYOUT.dock_mode
			if editentities == false then
				if tile and tile <= tilelistcount+1 then
					if animatedtilelist then
						currenttile = tile + tileliststart-1+10000
					else
						currenttile = tile + tileliststart-1
					end
					if not keep_dock then
						editorclose()
					end
					allowdrag = false
				end
			else
				if editenemies then
					if tile and tile <= #enemies then
						currenttile = enemies[tile as integer]
						if not keep_dock then
							editorclose()
						end
						allowdrag = false
					end
				else
					local ent = getentityhighlight(x, y)
					if ent then
						currenttile = (ent as EntityListEntry).i
						if not keep_dock then
							editorclose()
						end
						allowdrag = false
					end
				end
			end
		elseif editorstate == "main" then
			if y >= minimapy*scale and y < (minimapy+34)*scale then
				if x >= minimapx*scale and x < (minimapx+394)*scale then
					minimapdragging = true
					toggleautoscroll(false)
				end
			end
		elseif editorstate == "objects" then
			local tile = getlistpos(x, y)
			local mtbutton = getmtbutton(x)
			--editmtobjects = false
			--editentities = false
			if tile then
				if mtbutton == 0 then
					if not guielements["renamebar"].active then
						allowdrag = false
						editorclose()
						mtclipboard = ((multitileobjects as {any})[((tile as number)+1) as integer] as {{any}})
						--for i, v in pairs(mtclipboard as {any:any}) do
							--for j, w in pairs(v as {any:any}) do
								--print(w)
							--end
						--end
						pastecenter = {0, 0}
						pastingtiles = true
						editentities = false
						editenemies = false
					elseif guielements["renamebar"].tile ~= tile then
						guielements["renamebar"].active = false
					else
						guielements["renamebar"]:click(x, y, button)
					end
				else
					if mtbutton == 1 then
						guielements["renamebar"].active = true
						guielements["renamebar"].value = (multitileobjectnames as {any})[((tile as number)+1) as integer]
						guielements["renamebar"].tile = tile as number
						guielements["renamebar"].y = objectsguiarea[2]+1-multitilesoffset/scale + ((tile as number)*17)
						guielements["renamebar"].func = function(): any
							if guielements["renamebar"].value ~= "" then
								guielements["renamebar"].value = string.gsub((guielements["renamebar"].value as string), "=", " ")
								renameline(mappack_path(mappack) .. "/objects.txt",(tile as number)+1,guielements["renamebar"].value)
							end
							guielements["renamebar"].active = false
							loadmtobjects()
							return nil
						end
					elseif mtbutton == 2 then
						moveline(mappack_path(mappack) .. "/objects.txt",(tile as number)+1,"up")
						loadmtobjects()
					elseif mtbutton == 3 then
						moveline(mappack_path(mappack) .. "/objects.txt",(tile as number)+1,"down")
						loadmtobjects()
					elseif mtbutton == 4 then
						deleteline(mappack_path(mappack) .. "/objects.txt", (tile as number)+1)
						if guielements["renamebar"] and guielements["renamebar"].active then
							guielements["renamebar"].active = false
						end
						loadmtobjects()
					end
				end
			end
		end
	end
end

function editor_mousepressed_wheel_up(_: number, _: number)
	if not editormenuopen then
		if sys_down("shift") then
			brush[1] = math.min(brushmax, brush[1]+1)
			brush[2] = math.min(brushmax, brush[2]+1)
		elseif editentities then
			if editenemies then
				--get which current tile
				local curr = 1
				while enemies[curr] ~= currenttile and curr > 0 do
					curr = curr + 1
				end
				
				if curr-1 == 0 then
					curr = #enemies+1
				end
				
				currenttile = enemies[curr-1]
			else
				local list = 1
				local id = 1
				for i, v in ipairs(entitylistitems) do
					for j, w in ipairs(v.entries) do
						if w.i == currenttile then
							list = i
							id = j
						end
					end
				end
				id = math.min(id+1, #entitylistitems[list].entries)
				currenttile = entitylistitems[list].entries[id].i
			end
		-- elseif animatedtilelist then
			-- if currenttile > 10000 then
				-- currenttile = (currenttile as number) - 1
				-- if (currenttile as number) == 10000 then
					-- currenttile = 10000+animatedtilecount
				-- end
			-- end
		else
			if (currenttile as number) > 0 and (currenttile as number) <= 10000 then
				currenttile = (currenttile as number) - 1
				if (currenttile as number) == 0 then
					currenttile = smbtilecount+portaltilecount+customtilecount+(modcustomtilecount[modcustomtiles as integer] or 0)
				end
			else
				currenttile = (currenttile as number) - 1
				if (currenttile as number) == 10000 then
					currenttile = 10000+animatedtilecount
				end
			end
		end
	end
	
end

function editor_mousepressed_wheel_down(_: number, _: number)
	if not editormenuopen then
		if sys_down("shift") then
			brush[1] = math.max(1, brush[1]-1)
			brush[2] = math.max(1, brush[2]-1)
		elseif editentities then
			if editenemies then
				--get which current tile
				local curr = 1
				while enemies[curr] ~= currenttile and curr < #enemies do
					curr = curr + 1
				end
				
				if curr+1 > #enemies then
					curr = 0
				end
				
				currenttile = enemies[curr+1]
			else
				local list = 1
				local id = 1
				for i, v in ipairs(entitylistitems) do
					for j, w in ipairs(v.entries) do
						if w.i == currenttile then
							list = i
							id = j
						end
					end
				end
				id = math.max(1, id-1)
				currenttile = entitylistitems[list].entries[id].i
			end
		-- elseif animatedtilelist then
			-- if (currenttile as number) <= 10000+animatedtilecount then
				-- currenttile = (currenttile as number) + 1
				-- if currenttile == 10001+animatedtilecount then
					-- currenttile = 10001
				-- end
			-- end
		else
			if (currenttile as number) <= smbtilecount+portaltilecount+customtilecount+(modcustomtilecount[modcustomtiles as integer] or 0) then
				currenttile = (currenttile as number) + 1
				if (currenttile as number) > smbtilecount+portaltilecount+customtilecount+(modcustomtilecount[modcustomtiles as integer] or 0) then
					currenttile = 1
				end
			else
				if (currenttile as number) <= 10000+animatedtilecount then
					currenttile = (currenttile as number) + 1
					if currenttile == 10001+animatedtilecount then
						currenttile = 10001
					end
				end
			end
		end
	end
	
end

function editor_mousepressed_right(x: number, y: number)
	if editormenuopen == false then
		local tileX, tileY = getMouseTile(x, y+8*scale)
		if inmap(tileX, tileY) == false then
			return
		end
		
		if editorstate ~= "lightdraw" then
			local r = session.map[tileX][tileY]
			if #r > 1 then
				local tile = r[2]
				if entitylist[tile] and rightclickmenues[entitylist[tile].t] then
					local tileX, tileY = getMouseTile(x, y+8*scale)
					rightclickm = rightclickmenu:new(x/scale, y/scale, rightclickmenues[entitylist[r[2]].t], tileX, tileY)
					rightclickactive = false
					linktoolfadeouttime = linktoolfadeouttimefast
					linktoolX, linktoolY = tileX, tileY
				end
			else
				local cox, coy = getMouseTile(x, y+8*scale)
				
				if session.objects["player"][1] and not session.objects["player"][1].vine and not session.objects["player"][1].grapple then
					session.objects["player"][1].x = cox-1+2/16
					session.objects["player"][1].y = coy-session.objects["player"][1].height
					session.objects["player"][1].vine = false
				end
			end
		end
	else
		if editorstate == "main" then
			if y >= (minimapy+2)*scale and y < (minimapy+32)*scale then
				if x >= (minimapx+2)*scale and x < (minimapx+392)*scale then
					local x, y = editor_minimap_tile_from_click(x, y, scale, minimapx, minimapy, minimapscroll, session.yscroll)
					
					if session.objects["player"][1] then
						session.objects["player"][1].x = x-1+2/16
						session.objects["player"][1].y = y-1+2/16
					end
				end
			end
		end
	end
end


function editor_mousereleased(x: number, y: number, button: any)
	if regiondragging then
		if (regiondragging as RegionDragging):mousereleased(x, y, button) then
			regiondragging = nil
		end
		return
	end

	if button == "l" and editor_drag_end then
		editor_drag_end(x, y)
	end
	
	if button == "l" or button == "r" then
		editor_undo_commit()
		savestate()
		currentstate = #savestates
	end
	
	if button == "l" then
		if selectiondragging then
			selectionend()
		end
			
		if rightclickm then
			(rightclickm as rightclickmenu):mousereleased(x, y, button)
		end
		guirepeattimer = 0
		minimapdragging = false
	elseif button == "m" then
		if middlemode[1] == false then
			local cox, coy = getMouseTile(love.mouse.getX(), love.mouse.getY()+8*scale)
			if inmap(cox, coy) == false then
				return
			end
			if not editentities then
				tilesall()
				currenttile = session.map[cox][coy][1]
				
				if currenttile == 1 and session.coinmap[cox][coy] then
					currenttile = 116 -- Let's be nice to the map maker, alright?
				end
			elseif not editenemies then
				tilesentities()
				generateentitylist()
				currenttile = session.map[cox][coy][2]
				if type(currenttile) ~= "number" then currenttile = 1 end
			else
				tilesenemies()
				currenttile = session.map[cox][coy][2]
				local ok = false
				for _, v in ipairs(enemies as {string}) do
					if v == currenttile then
						ok = true
					end
				end
				if not ok then currenttile = enemies[1] end
			end
		end
		middlemode[1] = false
		love.mouse.setVisible(true)
	end
	allowdrag = true
	hprev = 0
	vprev = 0
	
	if animationguilines and editormenuopen and not changemapwidthmenu then
		for _, v in pairs(animationguilines) do
			for _, w in ipairs(v) do					
				w:unclick(x, y, button)
			end
		end
	end
end

function editor_keypressed(key: string)
	if selectionwidth then
		if key == "delete" then
			-- selectiongettiles uses pixel coords; do not discard scaled sizes into `_`.
			local selectionlist = selectiongettiles(selectionx, selectiony, selectionwidth, selectionheight)
			
			for i = 1, #selectionlist do
				for j = 2, #session.map[selectionlist[i].x][selectionlist[i].y] do
					session.map[selectionlist[i].x][selectionlist[i].y][j] = nil
				end
			end
		end
	end
	
	if rightclickm then
		(rightclickm as rightclickmenu):keypressed(key)
	end
	
	-- if guielements["renamebar"].active then
		-- guielements["renamebar"]:keypress(key)
	-- end
	
	if ctrlpressed then
		if key == "s" then
			if tileselectionclick1 and tileselectionclick2 then
				savemtobject(getSelectedTiles())
				loadmtobjects()
				notice.new("Saved as object!", notice.white, 2)
			end
		elseif key == "g" then --Completely stolen from HEC
			if tileselectionclick1 and tileselectionclick2 then
				local group = getSelectedTiles()
				local name = group[1][1]
				
				--Deletes any group corresponding to the tile
				if love.filesystem.getInfo(mappack_path(mappack) .. "/groups.txt") then
					local txt = ((love.filesystem.read(mappack_path(mappack) .. "/groups.txt")) or "") as string
					local s = strsplit(txt, "\n")
					for i = 1, #s do
						local s2 = strsplit(s[i], "=")
						if s2[1] == name then
							deleteline(mappack_path(mappack) .. "/groups.txt", i) --Just to guarantee
							break
						end
					end
				end
				
				savemtobject(group, tostring(name), "groups")
				loadmtgroups()
				notice.new("Saved as group!", notice.white, 2)
			end
		elseif key == "c" or key == "x" then
			if tileselectionclick1 == true and tileselectionclick2 == true then
				
				mtclipboard = getSelectedTiles()
				if clipboardenabled then
					objectclipboardcopy(getSelectedTiles())
				end
				
				if key == "x" then
					emptySelection()
				end
				
				notice.new("Copied to clipboard!", notice.white, 2)
			end
		elseif key == "v" then
			if pastingtiles == false and next(mtclipboard) ~= nil then
				pastecenter = {0, 0}
				pastingtiles = true
				editentities = false
				-- clear selection
				tileselectionclick1 = false
				tileselectionclick1x = 0
				tileselectionclick1y = 0	
				tileselectionclick2 = false
				tileselectionclick2x = 0
				tileselectionclick2y = 0
			end
		elseif key == "a" then
			tileselection = true
			tileselectionclick1 = true
			tileselectionclick1x = 1
			tileselectionclick1y = 0	
			tileselectionclick2 = true
			tileselectionclick2x = session.mapwidth
			tileselectionclick2y = 14
		end
	elseif editormenuopen then
		if key == "u" then
			if editorstate == "tiles" then
				local x, y = love.mouse.getPosition()
				local tile = gettilelistpos(x, y) as number
				if editentities then
					-- nothing
				elseif editmtobjects then
					-- nothing
				else
					if tile and tile <= tilelistcount+1 then
						local name = tostring(tile)
						if love.filesystem.getInfo(mappack_path(mappack) .. "/groups.txt") then
							local txt = ((love.filesystem.read(mappack_path(mappack) .. "/groups.txt")) or "") as string
							local s = strsplit(txt, "\n")
							for i = 1, #s do
								local s2 = strsplit(s[i], "=")
								if s2[1] == name then
									deleteline(mappack_path(mappack) .. "/groups.txt", i)
									break
								end
							end
						end
						loadmtgroups()
					end
				end
			end
		else
			for i = 0, 9 do
				if key == tostring(i) then
					if editorstate == "tiles" then
						local x, y = love.mouse.getPosition()
						local tile = gettilelistpos(x, y) as number
						if editentities and editenemies then
							if tile and tile <= #enemies then
								changeHotKey(i,3,tile)
								saveHotKeys()
							end
						elseif editentities then
							local ent = getentityhighlight(x, y)
							
							if ent and (ent as EntityListEntry).i and (ent as EntityListEntry).i <= entitiescount then
								changeHotKey(i,2,(ent as EntityListEntry).i)
								saveHotKeys()
							end
						elseif not editmtobjects then
							if animatedtilelist then
								if tile and tile <= tilelistcount+1 then
									changeHotKey(i,1,tile + tileliststart-1+10000)
									saveHotKeys()
								end
							else
								if tile and tile <= tilelistcount+1 then
									changeHotKey(i,1,tile + tileliststart-1)
									saveHotKeys()
								end
							end
						end
					end
				end
			end
		end
	end
	
	if animationguilines then
		for _, v in pairs(animationguilines) do
			for _, w in ipairs(v) do
				w:keypressed(key)
			end
		end
	end
	
	-- Dock toggles (work with menu open or closed)
	if key == "tab" then
		layout_toggle_palette()
		return
	elseif key == "p" and not ctrlpressed and editormenuopen then
		layout_toggle_props()
		return
	elseif key == "t" and not ctrlpressed and not editormenuopen then
		test_level_from_cursor()
		return
	elseif key == "]" and editormenuopen then
		local p = build_palettes(nil)
		local cat = editor_cycle_palette_category(p)
		notice.new("category: " .. tostring(cat), notice.white, 1)
		return
	elseif key == "[" and editormenuopen then
		local p = build_palettes(nil)
		local cats = palette_entity_categories(p)
		local cur = EDITOR_PALETTE_CATEGORY
		local idx = 1
		for i = 1, #cats do if cats[i] == cur then idx = i; break end end
		idx = idx - 1
		if idx < 1 then idx = #cats end
		EDITOR_PALETTE_CATEGORY = cats[idx]
		notice.new("category: " .. EDITOR_PALETTE_CATEGORY, notice.white, 1)
		return
	elseif (sys_down("shift")) and not editormenuopen and ENEMY_MODIFIER_ORDER then
		for i = 1, 5 do
			if key == tostring(i) then
				local mod = ENEMY_MODIFIER_ORDER[i]
				local cox, coy = getMouseTile(love.mouse.getX(), love.mouse.getY()-8*scale)
				if enemy_drop_modifier and enemy_drop_modifier(mod, cox, coy) then
					notice.new("mod +" .. mod, notice.white, 1)
				end
				return
			end
		end
	end

	if key == "escape" then
		if tileselection or pastingtiles then
			tileselection = false
			pastingtiles = false
			tileselectionclick1 = false
			tileselectionclick1x = 0
			tileselectionclick1y = 0	
			tileselectionclick2 = false
			tileselectionclick2x = 0
			tileselectionclick2y = 0
		elseif rightclickm then
			closerightclickmenu()
		elseif changemapwidthmenu then
			mapwidthcancel()
		elseif guielements["renamebar"].active then
			guielements["renamebar"].active = false
		else
			if editormenuopen then
				editorclose()
			else
				editoropen()
			end
		end
	end
	
	if not editormenuopen then
		local shiftpressed = ((sys_down("shift")) and true) or false
		if key == "q" then
			currenttile = 1
			if editentities and editenemies then
				tilesall()
			elseif editentities then
				tilesenemies()
				currenttile = enemies[1]
			else
				generateentitylist()
				tilesentities()
			end
		elseif key == "left" and shiftpressed then
			brush[1] = math.max(1, brush[1]-1)
		elseif key == "right" and shiftpressed then
			brush[1] = math.min(brushmax, brush[1]+1)
		elseif key == "up" and shiftpressed then
			brush[2] = math.max(1, brush[2]-1)
		elseif key == "down" and shiftpressed then
			brush[2] = math.min(brushmax, brush[2]+1)
		elseif key == "z" and ctrlpressed then
			local ok = editor_undo()
			if not ok then
				ok = (currentstate > 1 and true) or false
				currentstate = math.max(1, currentstate-1)
				loadstate()
			end
			if ok then
				notice.new("Changes undone!", notice.white, 1)
			end
		elseif key == "y" and ctrlpressed then
			local ok = editor_redo()
			if not ok then
				ok = (currentstate < #(savestates as {any}) and true) or false
				currentstate = math.min(#(savestates as {any}), (currentstate as number)+1)
				loadstate()
			end
			if ok then
				notice.new("Changes redone!", notice.white, 1)
			end
		else
			for i = 1, 9 do
				if key == tostring(i) then --HOTKEY
					local hk = hotkeys[key] as {any}
					if hk then
						if hk[1] == 1 then --TILES
							editorstate = "tiles"
							tilesall()
							currenttile = hk[2]
							if (currenttile as number) >= 10000 then
								animatedtilelist = true
								tilesanimated()
							end
						elseif hk[1] == 2 then --ENTITIES
							editorstate = "tiles"
							generateentitylist()
							tilesentities()
							currenttile = hk[2]
						elseif hk[1] == 3 then --ENEMIES
							editorstate = "tiles"
							tilesenemies()
							currenttile = enemies[hk[2] as integer]
						end
					end
				end
			end
		end
	end
end

function editor_textinput(text: string)
	if rightclickm then
		(rightclickm as rightclickmenu):textinput(text)
	end
	
	-- if guielements["renamebar"].active then
		-- guielements["renamebar"]:textinput(text)
	-- end

	if animationguilines then
		for _, v in pairs(animationguilines) do
			for _, w in ipairs(v) do
				w:textinput(text)
			end
		end
	end
end

