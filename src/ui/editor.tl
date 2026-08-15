--[[ Level editor (Teal port of root editor.lua + util.editorutil). ]]

global editor_test_restore: {string:any}|nil = nil

global function test_level_from_cursor()
	if editor_clear_cheats then editor_clear_cheats() end
	local cox, coy = getMouseTile(love.mouse.getX(), love.mouse.getY()-8*scale)
	editor_capture_test_restore({ cursor_x = cox, cursor_y = coy })
	savelevel()
	editorclose()
	editormode = false
	testlevel = true
	testlevelworld = marioworld as number
	testlevellevel = mariolevel
	autoscroll = true
	if mariosublevel ~= 0 then
		loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel) .. "_" .. tostring(mariosublevel))
	else
		loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel))
	end
	startlevel()
	-- Warp player 1 to cursor tile if possible
	if session.objects and session.objects["player"] and session.objects["player"][1] and inmap(cox, coy) then
		session.objects["player"][1].x = cox - 1 + 2 / 16
		session.objects["player"][1].y = coy - 1 + 2 / 16
		session.xscroll = math.max(0, cox - width / 2)
		session.yscroll = math.max(0, coy - height / 2)
		if splitxscroll then splitxscroll[1] = session.xscroll end
	end
end

function editor_load()
	-- Play mode: skip heavy rightclick menu / UI rebuild every level transition.
	-- Still clear minimapdragging — game_update only scrolls when it is false
	-- (nil == false is false in Lua, which freezes the camera).
	if not editormode then
		minimapdragging = false
		if musiclist[#musiclist] ~= "princessmusic.ogg" then
			musiclist[#musiclist+1] = "princessmusic.ogg"
		end
		return
	end

	currentanimation = 1
	tilecount1 = 168
	tilecount2 = 74
	
	brush = {1, 1}
	brushmax = 10
	
	middlemode = {false, 0, 0}
	
	tooltipa = 0
	
	tilesoffset = 0
	multitilesoffset = 0
	
	minimapscroll = 0
	minimapx = 3
	minimapy = 30
	minimapheight = 15
	
	currenttile = 1
	
	rightclicka = 0
	
	minimapscrollspeed = 30
	minimapdragging = false
	
	allowdrag = true
	
	savestates = {}
	maxstates = 15
	currentstate = 1

	-- Dock layout + cell undo + autotile (Mario Maker-ish)
	layout_recalc(nil, nil)
	editor_undo_clear()
	autotile_load_mappack(nil)
	
	tileswitcherkey = (function(): string
		local use_src = controls[1]["use"]
		if type(use_src) == "table" then
			local use_arr = use_src as {integer: string}
			if use_arr[1] then
				local key = (use_arr[1] as string):match("^key:(.+)$")
				if key then
					return key
				end
			end
		end
		return "e"
	end)()
	
	if musiclist[#musiclist] ~= "princessmusic.ogg" then
		musiclist[#musiclist+1] = "princessmusic.ogg"
	end

	rightclickmenues.pipe = {
		{t="text", value="destination:"},
		{t="input", default="1"},
		{t="text", value="note: 1 is main"}
	}
	

	rightclickmenues.vine = {
		{t="text", value="destination:"},
		{t="input", default="1"},
		{t="text", value="note: 1 is main"}
	}

	rightclickmenues.pipespawn = {
		{t="text", value="source:"},
		{t="input", default="1"},
		{t="text", value="note: 1 is main"}
	}

	rightclickmenues.warppipe = {
		{t="text", value="world:"},
		{t="input", default="1"},
		{t="text", value="level:"},
		{t="input", default="1"}
	}

	powerlinedrawtable = {
		{"up", "down", 43, true},
		{"down", "up", 43, true},
		{"left", "right", 44, true},
		{"right", "left", 44, true},
		{"up", "right", 45, true},
		{"right", "up", 45, true},
		{"right", "down", 46, true},
		{"down", "right", 46, true},
		{"down", "left", 47, true},
		{"left", "down", 47, true},
		{"left", "up", 48, true},
		{"up", "left", 48, true}}
	
	tileselection = false
	tileselectionclick1 = false
	tileselectionclick1x = 0
	tileselectionclick1y = 0	
	tileselectionclick2 = false
	tileselectionclick2x = 0
	tileselectionclick2y = 0
	
	mtsavehighlighttime = 5
	mtsavetimer = 0
	mtjustsaved = 0
	
	pastingtiles = false
	pastemode = false -- 1 transparent, 2 opaque
	pastecenter = {0, 0}
	mtclipboard = {} -- fill with x, y, tile
	
	splitxscroll = {0, 0}
	
	animationguiarea =  {12, 33, 399, 212}
	objectsguiarea = {5, 21, 378, 203}
	mapbuttonarea =  {4, 21, 381, 220}
	animationlineinset = 14
	
	secretcheckboxtext = {"secret feature", "really secret feature", "super secret feature", "very secret feature", "don't enable this", "exit editor", "copy enemies", "copy entities", "all of the above", "play music in editor", "shmuck bait", "disable tiles", "enable tiles", "goombas are cats", "hat stacking", "auto-update", "horizontal tileset scrollbar", "show mazes", "play space jam while editing", "get rid of this checkbox", "old editor", "disable better editor", "1.6 editor", "enable autocorrect", "make cool maps like willware", "snes mode", "disable crashing", "enable this checkbox", "enable the super secret checkbox", ""}
	
	guielements["tabmain"] = guielement:new("button", 1, 1, "main", maintab, 3)
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"] = guielement:new("button", 43, 1, "tiles", tilestab, 3)
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"] = guielement:new("button", 93, 1, "tools", toolstab, 3)
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"] = guielement:new("button", 143, 1, "maps", mapstab, 3)
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"] = guielement:new("button", 185, 1, "animations", animationstab, 3)
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"] = guielement:new("button", 275, 1, "objects", objectstab, 3)
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	
	--MAIN
	--left side
	guielements["colorsliderr"] = guielement:new("scrollbar", 17, 75, 101, 11, 11, background[1], "hor")
	guielements["colorsliderr"].backgroundcolor = {1, 0, 0}
	guielements["colorsliderg"] = guielement:new("scrollbar", 17, 87, 101, 11, 11, background[2], "hor")
	guielements["colorsliderg"].backgroundcolor = {0, 1, 0}
	guielements["colorsliderb"] = guielement:new("scrollbar", 17, 99, 101, 11, 11, background[3], "hor")
	guielements["colorsliderb"].backgroundcolor = {0, 0, 1}
	
	for i = 1, #backgroundcolor do
		guielements["defaultcolor" .. i] = guielement:new("button", 125+(math.fmod(i-1, 3))*12, 63+(math.ceil(i/3))*12, "", defaultbackground, 0, {i}, 1, 8)
		guielements["defaultcolor" .. i].fillcolor = backgroundcolor[i]
	end
	
	local args = {unpack(musiclist)}
	local musici = 1
	for i = 1, #args do
		if args[i] == musicname then
			musici = i
		end
		args[i] = string.lower(string.sub(args[i] as string, 1, -5))
	end
	
	guielements["musicdropdown"] = guielement:new("dropdown", 17, 125, 11, changemusic, musici, unpack(args))
	guielements["spritesetdropdown"] = guielement:new("dropdown", 17, 150, 11, changespriteset, spriteset, "overworld", "underground", "castle", "underwater")
	guielements["timelimitdecrease"] = guielement:new("button", 17, 175, "{", decreasetimelimit, 0, nil, nil, nil, true)
	guielements["timelimitincrease"] = guielement:new("button", 31 + string.len(tostring(mariotimelimit))*8, 175, "}", increasetimelimit, 0, nil, nil, nil, true)
	
	local i = 1
	if portalsavailable[1] and not portalsavailable[2] then
		i = 2
	elseif not portalsavailable[1] and portalsavailable[2] then
		i = 3
	elseif not portalsavailable[1] and not portalsavailable[2] then
		i = 4
	end
	guielements["portalgundropdown"] = guielement:new("dropdown", 87, 187, 6, changeportalgun, i, "both", "blue", "orange", "none")
	
	--right side
	guielements["autoscrollcheckbox"] = guielement:new("checkbox", 290, 20, toggleautoscroll, autoscroll, "follow mario")
	
	guielements["intermissioncheckbox"] = guielement:new("checkbox", 200, 66, toggleintermission, intermission, "intermission")
	guielements["warpzonecheckbox"] = guielement:new("checkbox", 200, 81, togglewarpzone, haswarpzone, "warpzone text")
	guielements["underwatercheckbox"] = guielement:new("checkbox", 200, 96, toggleunderwater, underwater, "underwater")
	guielements["bonusstagecheckbox"] = guielement:new("checkbox", 200, 111, togglebonusstage, bonusstage, "bonus stage")
	guielements["custombackgroundcheckbox"] = guielement:new("checkbox", 200, 126, togglecustombackground, custombackground, "background:")
	guielements["customforegroundcheckbox"] = guielement:new("checkbox", 200, 156, togglecustomforeground, customforeground, "foreground:")
	
	--bottom
	guielements["savebutton"] = guielement:new("button", 10, 200, "save", savelevel, 2)
	guielements["menubutton"] = guielement:new("button", 54, 200, "return to menu", editorexit, 2)
	guielements["testbutton"] = guielement:new("button", 204, 200, "test level", test_level, 2)
	guielements["testcursorbutton"] = guielement:new("button", 204, 184, "test cursor", test_level_from_cursor, 2)
	guielements["clearcheckbutton"] = guielement:new("button", 10, 184, "clear check", editor_run_clearcheck_ui, 2)
	guielements["widthbutton"] = guielement:new("button", 296, 200, "change size", openchangewidth, 2)
	
	guielements["savebutton"].bordercolor = {1, 0, 0}
	guielements["savebutton"].bordercolorhigh = {1, 0.5, 0.5}
	
	--maybe I should use webkit next time
	--hahahahhahahaha no
	
	--mapsize stuff
	guielements["maptopup"] = guielement:new("button", 0, 0, "_dir4", changenewmapsize, nil, {"top", "up"}, nil, 8, 0.02)
	guielements["maptopdown"] = guielement:new("button", 0, 0, "_dir6", changenewmapsize, nil, {"top", "down"}, nil, 8, 0.02)
	guielements["mapleftleft"] = guielement:new("button", 0, 0, "_dir3", changenewmapsize, nil, {"left", "left"}, nil, 8, 0.02)
	guielements["mapleftright"] = guielement:new("button", 0, 0, "_dir5", changenewmapsize, nil, {"left", "right"}, nil, 8, 0.02)
	guielements["maprightleft"] = guielement:new("button", 0, 0, "_dir3", changenewmapsize, nil, {"right", "left"}, nil, 8, 0.02)
	guielements["maprightright"] = guielement:new("button", 0, 0, "_dir5", changenewmapsize, nil, {"right", "right"}, nil, 8, 0.02)
	guielements["mapbottomup"] = guielement:new("button", 0, 0, "_dir4", changenewmapsize, nil, {"bottom", "up"}, nil, 8, 0.02)
	guielements["mapbottomdown"] = guielement:new("button", 0, 0, "_dir6", changenewmapsize, nil, {"bottom", "down"}, nil, 8, 0.02)
	
	guielements["mapwidthapply"] = guielement:new("button", 0, 0, "apply", mapwidthapply, 3)
	guielements["mapwidthcancel"] = guielement:new("button", 0, 0, "cancel", mapwidthcancel, 3)
	
	local args = {unpack(custombackgrounds)}
	table.insert(args, 1, "default")
	
	local i = 1
	for j = 1, #custombackgrounds do
		if custombackground == custombackgrounds[j] then
			i = j+1
		end
	end
	
	guielements["backgrounddropdown"] = guielement:new("dropdown", 298, 125, 10, changebackground, i, unpack(args))
	
	args = {unpack(custombackgrounds)}
	table.insert(args, 1, "none")
	
	i = 1
	for j = 1, #custombackgrounds do
		if customforeground == custombackgrounds[j] then
			i = j+1
		end
	end
	
	guielements["foregrounddropdown"] = guielement:new("dropdown", 298, 155, 10, changeforeground, i, unpack(args))
	
	guielements["scrollfactorscrollbar"] = guielement:new("scrollbar", 298, 140, 93, 35, 11, reversescrollfactor(), "hor")
	guielements["fscrollfactorscrollbar"] = guielement:new("scrollbar", 298, 170, 93, 35, 11, reversefscrollfactor(), "hor")
	
	args = {unpack(levelscreens)}
	table.insert(args, 1, "none")
	
	i = 1
	for j = 1, #levelscreens do
		if levelscreenbackname == levelscreens[j] then
			i = j+1
		end
	end
	
	--get current description and shit
	local mappackname = ""
	local mappackauthor = ""
	local mappackdescription = ""
	if love.filesystem.getInfo(mappack_path(mappack) .. "/settings.txt") then
		local data = (love.filesystem.read(mappack_path(mappack) .. "/settings.txt") or "") as string
		local split1 = strsplit(data, "\n")
		for i = 1, #split1 do
			local split2 = strsplit(split1[i], "=") as {string}
			if split2[1] == "name" then
				mappackname = (split2[2] as string):lower()
			elseif split2[1] == "author" then
				mappackauthor = (split2[2] as string):lower()
			elseif split2[1] == "description" then
				mappackdescription = (split2[2] as string):lower()
			end
		end
	end
	
	guielements["levelscreendropdown"] = guielement:new("dropdown", 298, 185, 10, changelevelscreen, i, unpack(args))
	
	--TILES
	guielements["tilesall"] = guielement:new("button", 4, 20, "all", tilesall, 2) --72
	guielements["tilessmb"] = guielement:new("button", 37, 20, "smb", tilessmb, 2)
	guielements["tilesportal"] = guielement:new("button", 70, 20, "portal", tilesportal, 2)
	guielements["tilescustom"] = guielement:new("button", 127, 20, "custom", tilescustom, 2)
	guielements["tilesanimated"] = guielement:new("button", 184, 20, "animated", tilesanimated, 2)
	guielements["tilesentities"] = guielement:new("button", 257, 20, "entities", tilesentities, 2)
	guielements["tilesenemies"] = guielement:new("button", 330, 20, "enemies", tilesenemies, 2)
	
	guielements["tilesscrollbar"] = guielement:new("scrollbar", 381, 37, 167, 15, 40, 0, "ver", nil, nil, nil, nil, true)
	
	--TOOLS
	guielements["selectionbutton"] = guielement:new("button", 5, 22, "selection tool|click and drag to select entities|rightclick to configure all at once|hit del to delete.", selectionbutton, 2, false, 4, 383)
	guielements["selectionbutton"].bordercolor = {0, 1, 0}
	guielements["selectionbutton"].bordercolorhigh = {0.86, 1, 0.86}
	guielements["lightdrawbutton"] = guielement:new("button", 5, 71, "advanced draw tool|place tiles seamlessly using premade tools", powerlinestab, 2, false, 2, 383)
	guielements["lightdrawbutton"].bordercolor = {0, 0, 1}
	guielements["lightdrawbutton"].bordercolorhigh = {0.5, 0.5, 1}
	
	guielements["livesdecrease"] = guielement:new("button", 198, 104, "{", livesdecrease, 0)
	guielements["livesincrease"] = guielement:new("button", 194, 104, "}", livesincrease, 0)

	guielements["pastemodedropdown"] = guielement:new("checkbox", 149, 135, changepastemode, pastemode, "opaque paste")
	guielements["clipboardcheckbox"] = guielement:new("checkbox", 149, 145, toggleclipboardenabled, clipboardenabled, "copy to clipboard")
	guielements["linktoolkindabutnotreally"] = guielement:new("checkbox", 149, 155, toggledrawalllinks, drawalllinks, "draw all links")
	guielements["editordebugcheckbox"] = guielement:new("checkbox", 149, 165, toggleeditordebug, editordebug, "show hitboxes")
	guielements["levelscreencheckbox"] = guielement:new("checkbox", 149, 175, toggleskiplevelscreen, skiplevelscreen, "skip level screens")
	guielements["secretcheckbox"] = guielement:new("checkbox", 149, 185, editorexit, nil, secretcheckboxtext[math.random(1,#secretcheckboxtext)])
	
	guielements["edittitle"] = guielement:new("input", 5, 115, 17, nil, mappackname, 17)
	guielements["editauthor"] = guielement:new("input", 5, 140, 13, nil, mappackauthor, 13)
	guielements["editdescription"] = guielement:new("input", 5, 165, 17, nil, mappackdescription, 51, 3)
	guielements["savesettings"] = guielement:new("button", 5, 203, "save settings", savesettings, 2)
	guielements["savesettings"].bordercolor = {1, 0, 0}
	guielements["savesettings"].bordercolorhigh = {1, 0.5, 0.5}
	
  --[[MAPS
	guielements["savebutton2"] = guielement:new("button", 10, 140, "save", savelevel, 2)
	guielements["savebutton2"].bordercolor = {1, 0, 0}
	guielements["savebutton2"].bordercolorhigh = {1, 0.5, 0.5}]]
	guielements["mapscrollbar"] = guielement:new("scrollbar", 381, 21, 199, 15, 40, 0, "ver", nil, nil, nil, nil, true)
	guielements["mapsworldbox"] = guielement:new("input", 332, 21, 2, nil, nil, 2, 1, true, 0)
	guielements["mapslevelbox"] = guielement:new("input", 361, 21, 2, nil, nil, 2, 1, true, 0)
	guielements["mapsnewlevel"] = guielement:new("button", 320, 21, "+", newlevel, 0)
	
	--animationS
	guielements["animationsscrollbarver"] = guielement:new("scrollbar", animationguiarea[1]-10, animationguiarea[2], animationguiarea[4]-animationguiarea[2], 10, 40, 0, "ver", nil, nil, nil, nil, true)
	guielements["animationsscrollbarhor"] = guielement:new("scrollbar", animationguiarea[1], animationguiarea[4], animationguiarea[3]-animationguiarea[1], 40, 10, 0, "hor", nil, nil, nil, nil, false)
	
	addanimationtriggerbutton = guielement:new("button", 0, 0, "+", addanimationtrigger, nil, nil, nil, 8)
	addanimationtriggerbutton.textcolor = {0, 0.8, 0}
	
	addanimationconditionbutton = guielement:new("button", 0, 0, "+", addanimationcondition, nil, nil, nil, 8)
	addanimationconditionbutton.textcolor = {0, 0.8, 0}
	
	addanimationactionbutton = guielement:new("button", 0, 0, "+", addanimationaction, nil, nil, nil, 8)
	addanimationactionbutton.textcolor = {0, 0.8, 0}
	
	local args = {}
	for _, v in ipairs(animations) do
		table.insert(args, string.sub(v.name as string, 1, -6))
	end
	guielements["animationselectdrop"] = guielement:new("dropdown", 15, 20, 15, selectanimation, 1, unpack(args))
	guielements["animationnewbutton"] = guielement:new("button", 3, 20, "+", createnewanimation, nil)
	guielements["animationsavebutton"] = guielement:new("button", 150, 19, "save", saveanimation, 1)
		
	--OBJECTS fun fact: objects were originally in the tiles tab
	guielements["objectscrollbar"] = guielement:new("scrollbar", 381, 21, objectsguiarea[4]-objectsguiarea[2], 15, 40, 0, "ver", nil, nil, nil, nil, true)
	guielements["renamebar"] = guielement:new("input", 7, 0, 20, nil, nil, 20, 1, false, 0)
	guielements["renamebar"].active = false
	
	--POWERLINE "SUBTAB"
	drawtools = 2
	guielements["drawtool1"] = guielement:new("button", 5, 21, "power line draw", drawpowerlines, 2)
	guielements["drawtool1"].bordercolor = {0, 0, 1}
	guielements["drawtool1"].bordercolorhigh = {0.5, 0.5, 1}
	guielements["drawtool2"] = guielement:new("button", 5, 38, "mushroom platforms", drawmushrooms, 2)
	guielements["drawtool2"].bordercolor = {1, 0, 0}
	guielements["drawtool2"].bordercolorhigh = {1, 0.5, 0.5}
	
	multitileobjects = {}
	multitileobjectnames = {}
	loadmtobjects()
	loadmtgroups()
	
	helpui = {4, 4, width*16-4, height*16-4}

	hotkeys = {}
	loadHotKeys()
	
	tilesall()
	if editorloadopen then
		editoropen()
		editorloadopen = false
	else
		editorclose()
		editorstate = "main"
		editentities = false
	end
	
	savestate()
end

function editor_start()
	editormode = true
	players = 1
	playertype = "portal"
	playertypei = 1
	bullettime = false
	portalknockback = false
	bigmario = false
	goombaattack = false
	sonicrainboom = false
	playercollisions = false
	infinitetime = false
	infinitelives = false
	game_load()
end

function editor_update(dt: number)
	----------
	--EDITOR--
	----------
	
	if middlemode[1] == false and not love.mouse.isDown(3) then
		middlemode[2], middlemode[3] = getMouseTile(love.mouse.getX(), love.mouse.getY()-8*scale)
	end
	
	editor_update_rightclick(dt)
	
	if changemapwidthmenu then
		return
	end
	
	editor_update_keyscroll(dt)
	
	if regiondragging then
		local rd = regiondragging as RegionDragging
		if rd:update(dt) then
			regiondragging = nil
		end
		return
	end
	
	editor_update_modifiers()
	
	if editormenuopen == false then
		editor_update_closed(dt)
	elseif editorstate == "main" then
		editor_update_main(dt)
	elseif editorstate == "tiles" then
		editor_update_tiles(dt)
		-- Dock: paint map under cursor without closing palette
		if EDITOR_LAYOUT and EDITOR_LAYOUT.dock_mode and love.mouse.isDown(1) and allowdrag then
			local mx, my = mouse.getPosition()
			local ux, uy = mx / scale, my / scale
			if layout_over_canvas(ux, uy) then
				for t1 = 1, brush[1] do
					for t2 = 1, brush[2] do
						placetile(mx+(t1-1)*16*scale, my+(t2-1)*16*scale)
					end
				end
			end
		end
	elseif editorstate == "objects" then
		editor_update_objects(dt)
	end
	
	if animationguilines then
		for _, v in pairs(animationguilines) do
			for _, w in ipairs(v) do
				w:update(dt)
			end
		end
	end
end

function editor_update_rightclick(dt: number)
	if rightclickm then
		(rightclickm as rightclickmenu):update(dt)
		if rightclicka < 1 then
			rightclicka = math.min(1, rightclicka + dt/linktoolfadeouttime)
		end
	elseif not rightclickactive then
		if rightclicka > 0 then
			rightclicka = math.max(0, rightclicka - dt/linktoolfadeouttime)
		end
	end
end

function editor_update_keyscroll(_: number)
--key scroll
	if editormenuopen == false then
		if not sys_down("shift") then
			local xdir = sys_down("left") and -1 or (sys_down("right") and 1 or 0)
			local ydir = sys_down("up") and -1 or (sys_down("down") and 1 or 0)
			
			--xdir
			local oldxscroll = session.xscroll
			session.xscroll = math.max(0, math.min(session.mapwidth-width, session.xscroll + 30*gdt*xdir))
			splitxscroll[1] = math.max(0, math.min(session.mapwidth-width, splitxscroll[1]))
			
			--ydir
			local oldyscroll = session.yscroll
			session.yscroll = math.max(0, math.min(session.mapheight-1-height, session.yscroll + 30*gdt*ydir))
			
			if oldxscroll ~= session.xscroll or oldyscroll ~= session.yscroll then
				world_camera_sync()
				autoscroll = false
				guielements["autoscrollcheckbox"].var = autoscroll
				
				if regiondragging and (regiondragging as RegionDragging).movex and (regiondragging as RegionDragging).movey then
					(regiondragging as RegionDragging).movex = (regiondragging as RegionDragging).movex + (oldxscroll-session.xscroll)*16*scale
					(regiondragging as RegionDragging).movey = (regiondragging as RegionDragging).movey + (oldyscroll-session.yscroll)*16*scale
				end
			end
		end
	end
end

function editor_update_modifiers()
	ctrlpressed = sys_down("ctrl")
	tileswitcherpressed = ui_action_down(1, "use")

	if ctrlpressed then
		tileselection = true
	elseif tileselectionclick1 == true and tileselectionclick2 == true then
		-- both points selected: keep highlighting the area
	else
		tileselection = false
		tileselectionclick1 = false
		tileselectionclick1x = 0
		tileselectionclick1y = 0	
		tileselectionclick2 = false
		tileselectionclick2x = 0
		tileselectionclick2y = 0
	end
end

function editor_update_closed(_: number)
	if editorstate == "lightdraw" then
		if love.mouse.isDown(1) then
			mousex, mousey = mouse.getPosition()
			if not mousex or not mousey then
				return
			end
			local currentx, currenty = getMouseTile(mousex, mousey+8*scale)
			
			if lightdrawX and (currentx ~= lightdrawX or currenty ~= lightdrawY) then
				
				--fill in the gaps
				local x, y = lightdrawX, lightdrawY
				while x ~= currentx or y ~= currenty do
					if x ~= currentx then
						if x < currentx then
							x = x + 1
						else
							x = x - 1
						end
					else
						if y < currenty then
							y = y + 1
						else
							y = y - 1
						end
					end
					table.insert(lightdrawtable, {x=x,y=y})
				
					if #lightdrawtable >= 3 then
						local prev = lightdrawtable[#lightdrawtable-2] as {string:number}
						local curr = lightdrawtable[#lightdrawtable-1] as {string:number}
						local nextp = lightdrawtable[#lightdrawtable] as {string:number}
						local prevx, prevy = prev.x, prev.y
						local currx, curry = curr.x, curr.y
						local nextx, nexty = nextp.x, nextp.y
						
						local prev = "up"
						if prevx < currx then
							prev = "left"
							hprev = hprev - 2
							vprev = 0
						elseif prevx > currx then
							prev = "right"
							hprev = hprev + 2
							vprev = 0
						elseif prevy > curry then
							prev = "down"
							vprev = vprev + 2
							hprev = 0
						else
							vprev = vprev - 2
							hprev = 0
						end
						
						local next = "up"
						if nextx < currx then
							next = "left"
						elseif nextx > currx then
							next = "right"
						elseif nexty > curry then
							next = "down"
						end
						
						if advanceddrawtool == "mushroom" then
							powerlinedrawtable = { --mushroom platform
							{"down", "up", 65, false},
							{"left", "right", 22, false, hprev, 0, 20, false, (hprev/math.abs(hprev)), 0, 21, false, hprev-(hprev/math.abs(hprev)), 0, 21},
							{"right", "left", 20, false, hprev, 0, 22, false, (hprev/math.abs(hprev)), 0, 21, false, hprev-(hprev/math.abs(hprev)), 0, 21},
							{"down", "right", 21, false, 0, 1, 43},
							{"down", "left", 21, false, 0, 1, 43}}
						elseif advanceddrawtool == "powerlines" then
							powerlinedrawtable = { --powerlines
							{"up", "down", 43, true},
							{"down", "up", 43, true},
							{"left", "right", 44, true},
							{"right", "left", 44, true},
							{"up", "right", 45, true},
							{"right", "up", 45, true},
							{"right", "down", 46, true},
							{"down", "right", 46, true},
							{"down", "left", 47, true},
							{"left", "down", 47, true},
							{"left", "up", 48, true},
							{"up", "left", 48, true}}
						end
						
						local ii = 0
						for i = 1, #powerlinedrawtable do
							if prev == powerlinedrawtable[i][1] and next == powerlinedrawtable[i][2] then
								ii = i
							end
						end
						
						if ii > 0 and powerlinedrawtable[ii] then
							local row = powerlinedrawtable[ii]
							placetile((currx-session.xscroll-.5)*16*scale, (curry-session.yscroll-1)*16*scale, row[3], row[4] or false)
							for i = 5, #row, 4 do
								placetile((currx-session.xscroll-.5+(row[i] as number))*16*scale, (curry-session.yscroll-1+(row[i+1] as number))*16*scale, row[i+2] or row[3], row[4] or false)
							end
						end
					end
				end
				
				lightdrawX = currentx
				lightdrawY = currenty
			end
			
			return
		end
	end
	
	if rightclickactive or editorstate == "lightdraw" or editorstate == "selection" then
		return
	end

	if love.mouse.isDown(1) and allowdrag and editor_drag_move then
		local mx, my = mouse.getPosition()
		if editor_drag_active and editor_drag_active() then
			editor_drag_move(mx, my)
			return
		end
	end
	
	if love.mouse.isDown(1) and allowdrag then
		if not (pastingtiles or tileselection) then
			local x, y = mouse.getPosition()
			for t1 = 1, brush[1] do
				for t2 = 1, brush[2] do
					placetile(x+(t1-1)*16*scale, y+(t2-1)*16*scale)
				end
			end
		end
	elseif love.mouse.isDown(3) and not middlemode[1] then
		if (math.abs(love.mouse.getX() - middlemode[2] as number) as number) >= 8*scale or (math.abs(love.mouse.getY() - middlemode[3] as number) as number) >= 8*scale then
			middlemode[1] = true
			love.mouse.setVisible(false)
		end
	end
	
	if middlemode[1] then
		local xx, yy = love.mouse.getX() - (middlemode[2] as number), love.mouse.getY() - (middlemode[3] as number)
		
		if (math.abs(xx) as number) < 8*scale and (math.abs(yy) as number) < 8*scale then
			--ignore
		else
			if (math.abs(yy) as number) > (math.abs(xx) as number) then
				xx = 0
				if yy < 0 then yy = -1 else yy = 1 end
			else
				if xx < 0 then xx = -1 else xx = 1 end
				yy = 0
			end
			if editentities and editenemies then
				for i = 1, #enemies do
					if enemies[i] == currenttile then
						currenttile = i
						break
					end
				end
				local ct = currenttile as number
				if xx > 0 then
					ct = math.min(ct+1, math.ceil(ct/22)*22, #enemies)
				elseif xx < 0 then
					ct = math.max(ct-1, math.ceil(ct/22)*22-21, 1)
				elseif yy > 0 and ct+22 <= #enemies then
					ct = ct+22
				elseif yy < 0 and ct-22 >= 1 then
					ct = ct-22
				end
				currenttile = enemies[ct as integer]
			elseif editentities then
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
				if xx > 0 then
					id = math.min(id+1, #entitylistitems[list].entries)
				elseif xx < 0 then
					id = math.max(1, id-1)
				elseif yy > 0 then
					list = math.min(list+1, #entitylistitems)
					id = math.min(id, #entitylistitems[list].entries)
				elseif yy < 0 then
					list = math.max(list-1, 1)
					id = math.min(id, #entitylistitems[list].entries)
				end
				currenttile = entitylistitems[list].entries[id].i
			else
				local ct = currenttile as number
				if xx > 0 then
					ct = math.min(ct+1, math.ceil(ct/22)*22, tilelistcount+tileliststart)
				elseif xx < 0 then
					ct = math.max(ct-1, math.ceil(ct/22)*22-21, tileliststart)
				elseif yy > 0 and ct+22 <= tilelistcount+tileliststart then
					ct = ct+22
				elseif yy < 0 and ct-22 >= tileliststart then
					ct = ct-22
				end
				currenttile = math.max(1, ct)
				currenttile = math.min(currenttile, smbtilecount + portaltilecount + customtilecount + (modcustomtilecount[modcustomtiles as integer] or 0))
			end
			love.mouse.setPosition(middlemode[2] as number, middlemode[3] as number)
		end
	end
end

function editor_update_main(dt: number)
	-- Always refresh globals used by minimap/selection (never discard into `local _`).
	mousex, mousey = mouse.getPosition()
	if love.mouse.isDown(1) then
		if mousex and mousey and minimapx and minimapy and minimapheight
			and mousey >= minimapy*scale and mousey < (minimapy+minimapheight*2+4)*scale then
			if mousex >= minimapx*scale and mousex < (minimapx+394)*scale then
				--HORIZONTAL
				if mousex < (minimapx+width)*scale then
					if minimapscroll > 0 then
						minimapscroll = minimapscroll - minimapscrollspeed*dt
						if minimapscroll < 0 then
							minimapscroll = 0
						end
					end
				elseif mousex >= (minimapx+394-width)*scale then
					if minimapscroll < session.mapwidth-width-170 then
						minimapscroll = minimapscroll + minimapscrollspeed*dt
						if minimapscroll > session.mapwidth-width-170 then
							minimapscroll = session.mapwidth-width-170
						end
					end
				end
				
				splitxscroll[1] = editor_minimap_xscroll_from_mouse(mousex, scale, width, minimapscroll)
				if splitxscroll[1] > session.mapwidth-width then
					splitxscroll[1] = session.mapwidth-width
				end

				--SCROLL TRACK (full-map batches: no rebuild on pan)
				if math.floor(splitxscroll[1]) ~= spritebatchX[1] then
					spritebatchX[1] = math.floor(splitxscroll[1])
				end
				
				--VERTICAL
				if mousey < (minimapy+5)*scale then
					if session.yscroll > 0 then
						session.yscroll = session.yscroll - minimapscrollspeed*dt
						if session.yscroll < 0 then
							session.yscroll = 0
						end
					end
				elseif mousey >= (minimapy+minimapheight*2+4-5)*scale then
					if session.yscroll < session.mapheight-height then
						session.yscroll = session.yscroll + minimapscrollspeed*dt
						if session.yscroll > session.mapheight-height-1 then
							session.yscroll = session.mapheight-height-1
						end
					end
				end
			
				session.xscroll = editor_minimap_xscroll_from_mouse(mousex, scale, width, minimapscroll)
				if session.xscroll > session.mapwidth-width then
					session.xscroll = session.mapwidth-width
				end

				--SCROLL TRACK (full-map batches: no rebuild on pan)
				if math.floor(session.xscroll) ~= spritebatchX[1] then
					spritebatchX[1] = math.floor(session.xscroll)
				end
				if math.floor(session.yscroll) ~= spritebatchY[1] then
					spritebatchY[1] = math.floor(session.yscroll)
				end
			end
		end
		
		updatescrollfactor()
		updatefscrollfactor()
		updatebackground()
	end
end

function editor_update_tiles(dt: number)
	tilesoffset = (guielements["tilesscrollbar"].value as number) * tilescrollbarheight * scale
	if editentities and not editenemies then
		local x, y = mouse.getPosition()
		local tile = getentityhighlight(x, y)
		
		if tile ~= prevtile then
			if tile ~= nil and tooltipimages[(tile as entitylistitem).i] then
				entitytooltipobject = entitytooltip:new(tile)
			end
		end
		
		if tile ~= nil and tooltipimages[(tile as entitylistitem).i] then
			(entitytooltipobject as entitytooltip):update(dt)
			tooltipa = math.min(255, tooltipa + dt*4000)
		else
			tooltipa = math.max(-1000, tooltipa - dt*4000)
		end
		
		prevtile = tile
	end
end

function editor_update_objects(_: number)
	multitilesoffset = (guielements["objectscrollbar"].value as number) * objectscrollbarheight * scale
	if guielements["renamebar"].active then
		guielements["renamebar"].y = objectsguiarea[2]+1-multitilesoffset/scale + (guielements["renamebar"].tile*17)
		-- guielements["renamebar"]:update(dt)
	end
end

function editor_draw()
	love.graphics.setColor(1, 1, 1)

	local emx, emy = mouse.getPosition()

	if editormenuopen == false then
		editor_draw_live_preview()
		editor_draw_overlay(emx, emy)
		editor_draw_linking(emx, emy)
		editor_draw_status()
	else
		editor_draw_menu(emx, emy)
	end

	editor_draw_chrome()
end

function placetile(x: number, y: number, t: any, ent: any, preventMultiTile: any)
	local editentities = ent or editentities
	local currenttile = t or currenttile
	local cox, coy = getMouseTile(x, y+8*scale)
	
	if inmap(cox, coy) == false then
		return
	end

	-- Cell undo: snapshot before mutation
	editor_undo_record(cox, coy)
	if editor_recent_push and editentities == false and type(currenttile) == "number" then
		editor_recent_push(currenttile as integer)
	end

	-- Autotile brush (ALT = raw tile)
	local alt = sys_down("alt")
	if editentities == false and not preventMultiTile and not alt then
		if autotile_paint(cox, coy, currenttile as integer, false) then
			-- collision objects for resulting tile
			local nt = session.map[cox][coy][1] as number
			if tilequads[nt]:getproperty("collision") == true then
				physics_world_set_tile(tilekey(cox, coy), tile:new(cox-1, coy-1, 1, 1, true) as Entity)
			else
				physics_world_set_tile(tilekey(cox, coy), nil)
			end
			generatespritebatch(0, 0)
			return
		end
	end
	
	if editentities == false then
		if tilequads[currenttile as number]:getproperty("coin") then
			session.coinmap[cox][coy] = not editorcoinstart
			return
		end
	
		if tilequads[currenttile as number]:getproperty("collision") == true and tilequads[session.map[cox][coy][1] as number]:getproperty("collision") == false then
			physics_world_set_tile(tilekey(cox, coy), tile:new(cox-1, coy-1, 1, 1, true) as Entity)
		elseif tilequads[currenttile as number]:getproperty("collision") == false and tilequads[session.map[cox][coy][1] as number]:getproperty("collision") == true then
			physics_world_set_tile(tilekey(cox, coy), nil)
		end
		if session.map[cox][coy][1] ~= currenttile then
			session.map[cox][coy][1] = currenttile
			init_map_cell_gels(session.map[cox][coy])
			generatespritebatch(0, 0)
			if not preventMultiTile and not alt and AUTOTILE_BY_TILE[currenttile as integer] then
				autotile_around(cox, coy)
			end
		end
		
		--Tile grouping
		--Decided to remove the tile 136 as default. Figured if people cared, they could just set it up themselves
		if multitilegroups[tostring(currenttile)] and not preventMultiTile then
			for tx, v in ipairs(multitilegroups[tostring(currenttile)]) do
				for ty, w in ipairs(v) do
					if tx ~= 1 or ty ~= 1 then
						placetile(x + (tx-1)*16*scale, y + (ty-1)*16*scale, w, ent, true)
					end
				end
			end
		end
		
	else
		if editenemies == false and entitylist[currenttile].t == "remove" then --removing tile
			for i = 2, #session.map[cox][coy] do
				session.map[cox][coy][i] = nil
			end
		else
			for i = 3, #session.map[cox][coy] do
				session.map[cox][coy][i] = nil
			end
			
			session.map[cox][coy][2] = currenttile
			
			if editenemies == false then
				if rightclickmenues[(entitylist[currenttile as number] as EntityListEntry).t] then
					local rcm = rightclickmenues[(entitylist[currenttile as number] as EntityListEntry).t] as {RightClickVar}
					for i = 1, #rcm do
						local v = rcm[i]
						if tablecontains(rightclickelementslist, v.t) then
							if v.default then
								table.insert(session.map[cox][coy], v.default)
							else
								table.insert(session.map[cox][coy], "nil")
							end
						end
					end
				end
			else --Enemy rightclick menu?
				--no
			end
		end
	end
end

function editorclose()
	editormenuopen = false
	for _, v in pairs(guielements) do
		v.active = false
	end
	if mapbuttons then
		for _, v in pairs(mapbuttons) do
			v.active = false
		end
	end
	
	if editorstate == "animations" then
		saveanimation()
	end
end

function editoropen()
	for i = 1, players do
		session.objects["player"][i]:removeportals()
	end
	if editorstate == "lightdraw" or editorstate == "selection" then
		editorstate = "tools"
	end
	closerightclickmenu()
	finishregion()
	editormenuopen = true
	
	if mariolivecount == false then
		guielements["livesincrease"].x = 212 + 24
	else
		guielements["livesincrease"].x = 212 + string.len(tostring(mariolivecount))*8
	end
	guirepeattimer = 0
	getmaps()
	
	pastingtiles = false
	mtclipboard = {}
	selectionx, selectiony, selectionwidth, selectionheight = nil, nil, nil, nil
	
	if editorstate == "main" then
		maintab()
	elseif editorstate == "tiles" then
		tilestab()
	elseif editorstate == "tools" or editorstate == "lightdrawcustomize" then
		toolstab()
	elseif editorstate == "maps" then
		mapstab()
	elseif editorstate == "animations" then
		animationstab()
	elseif editorstate == "objects" then
		objectstab()
	end
end

function test_level()
	if editor_clear_cheats then editor_clear_cheats() end
	editor_capture_test_restore(nil)
	savelevel()
	editorclose()
	editormode = false
	testlevel = true
	testlevelworld = marioworld as number
	testlevellevel = mariolevel
	autoscroll = true
	if mariosublevel ~= 0 then
		loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel) .. "_" .. tostring(mariosublevel))
	else
		loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel))
	end
	startlevel()
end

global function editor_run_clearcheck_ui()
	local ok, msg = editor_clear_check()
	if ok then
		notice.new("CLEAR CHECK OK - ready to publish", notice.white, 3)
	else
		notice.new(msg or "clear check failed", notice.red, 3)
	end
end

-- Snapshot editor view so ESC can restore scroll/palette after playtest.
global function editor_capture_test_restore(extra: {string:any}|nil)
	local r: {string:any} = {
		xscroll = session.xscroll,
		yscroll = session.yscroll,
		editorstate = editorstate,
		currenttile = currenttile,
		editentities = editentities,
		editenemies = editenemies,
		palette_collapsed = EDITOR_LAYOUT.palette_collapsed,
		props_collapsed = EDITOR_LAYOUT.props_collapsed,
		death_x = nil,
		death_y = nil,
	}
	if extra ~= nil then
		local ex = extra as {string:any}
		for k, v in pairs(ex) do
			r[k] = v
		end
	end
	editor_test_restore = r
end

global function editor_apply_test_restore(shift_death: boolean|nil)
	if editor_test_restore == nil then
		return
	end
	local r = editor_test_restore as {string:any}
	if shift_death and r.death_x ~= nil then
		session.xscroll = math.max(0, (r.death_x as number) - width / 2)
		session.yscroll = math.max(0, (r.death_y as number) - height / 2)
	else
		if r.xscroll ~= nil then session.xscroll = r.xscroll as number end
		if r.yscroll ~= nil then session.yscroll = r.yscroll as number end
	end
	if splitxscroll then
		splitxscroll[1] = session.xscroll
	end
	if r.palette_collapsed ~= nil then EDITOR_LAYOUT.palette_collapsed = r.palette_collapsed as boolean end
	if r.props_collapsed ~= nil then EDITOR_LAYOUT.props_collapsed = r.props_collapsed as boolean end
	layout_recalc(nil, nil)
	if r.currenttile ~= nil then currenttile = r.currenttile end
	if r.editentities ~= nil then editentities = r.editentities as boolean end
	if r.editenemies ~= nil then editenemies = r.editenemies as boolean end
end


local function start_lightdraw(tool: string, entities: boolean)
	advanceddrawtool = tool
	editenemies = false
	editentities = entities
	editorstate = "lightdraw"
	lightdrawX = nil
	lightdrawY = nil
	editorclose()
end

function drawpowerlines()
	start_lightdraw("powerlines", true)
end

function drawmushrooms()
	start_lightdraw("mushroom", false)
end

function emptySelection()
	--print("del")
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
	
	local tile1x,tile1y = getMouseTile(slx1+8*scale, sly1+8*scale)
	local tile2x,tile2y = getMouseTile(slx2+8*scale, sly2+8*scale)
	local xnum = tile2x - tile1x
	local ynum = tile2y - tile1y
	
	for i = 1, xnum do
		for j = 1, ynum do
			session.map[tile1x + i - 1][tile1y + j - 1] = {1} as MapCell
			init_map_cell_gels(session.map[tile1x + i - 1][tile1y + j - 1])
		end
	end
	generatespritebatch(0, 0)
end

function getSelectedTiles(): {{any}}
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
	
	return getTiles({slx1+8*scale, sly1+8*scale},{slx2+8*scale, sly2+8*scale})
end

function getTiles(pos1: {number}, pos2: {number}): {{any}}
	local objecttable: {{any}} = {}
	local tx: {any} = {}
	local tile1x,tile1y = getMouseTile(pos1[1], pos1[2])
	local tile2x,tile2y = getMouseTile(pos2[1], pos2[2])
	local xnum = tile2x - tile1x
	local ynum = tile2y - tile1y
	for i = 1, xnum do
		tx = {}
		for j = 1, ynum do
			table.insert(tx, session.map[tile1x + i - 1][tile1y + j - 1][1])
			--print(map[tile1x + i - 1][tile1y + j - 1][1])
		end
		table.insert(objecttable, tx)
	end
	return objecttable
end

function closerightclickmenu()
	if rightclickm then
		local edittable = {{x=((rightclickm as rightclickmenu).tx as number), y=((rightclickm as rightclickmenu).ty as number)}}
		
		if selectionwidth then
			local selectionlist = selectiongettiles(selectionx, selectiony, selectionwidth, selectionheight)
			
			for i = 1, #selectionlist do
				local v = selectionlist[i]
				if (session.map[v.x as number][v.y as number][2] == session.map[((rightclickm as rightclickmenu).tx as number)][((rightclickm as rightclickmenu).ty as number)][2] or (tablecontains(groundlighttable, entitylist[session.map[((rightclickm as rightclickmenu).tx as number)][((rightclickm as rightclickmenu).ty as number)][2]].t) and tablecontains(groundlighttable, entitylist[session.map[v.x as number][v.y as number][2]].t))) and (v.x ~= (rightclickm as rightclickmenu).tx or v.y ~= (rightclickm as rightclickmenu).ty) then
					table.insert(edittable, {x=v.x, y=v.y})
				end
			end
		end
		
		for i = 1, #edittable do
			local x, y = edittable[i].x, edittable[i].y
			
			--remove all values until link or region
			while session.map[x][y][3] and session.map[x][y][3] ~= "link" and strsplit(tostring(session.map[x][y][3]), ":")[1] ~= "region" do
				table.remove(session.map[x][y], 3)
			end
			
			--add values to link
			for i = #(rightclickm as rightclickmenu).variables, 1, -1 do
				local v = (rightclickm as rightclickmenu).variables[i]
				local value: any = nil
				if v.t == "scrollbar" then
					value = ((rightclickm as rightclickmenu).t[i] as guielement).value
				elseif v.t == "checkbox" then
					value = tostring(((rightclickm as rightclickmenu).t[i] as guielement).var)
				elseif v.t == "directionbuttons" then
					value = v.value
				elseif v.t == "submenu" then
					local ge = (rightclickm as rightclickmenu).t[i] as guielement
					if ge.actualvalue then
						value = (ge.entries as {any:any})[ge.value]
					else
						value = ge.value
					end
				elseif v.t == "input" then
					value = ((rightclickm as rightclickmenu).t[i] as guielement).value
				end
				
				if value then
					table.insert(session.map[x][y], 3, value)
				end
			end
		end
		
		rightclickm = nil
	end
end

function startlinking(x: number, y: number, t: any)
	rightclickactive = true
	linktoolX = x
	linktoolY = y
	linktoolt = t as string
	rightclicka = 1
	
	closerightclickmenu()
end

function startregion(x: number, y: number, t: any)
	rightclickactive = true
	regiontoolX = x
	regiontoolY = y
	regiontoolt = t as string
	rightclicka = 1
	
	--get width n shit
	
	local j = 0
	for i = 3, #session.map[x][y] do
		local s = strsplit(tostring(session.map[x][y][i]), ":")
		if s[1] == t then
			j = i
			break
		end
	end
	
	if j then
		local s = strsplit(session.map[x][y][j] as string, ":")
		
		local rx: any = s[2]
		local ry: any = s[3]
		
		if string.sub(rx as string, 1, 1) == "m" then
			rx = -tonumber(string.sub(rx as string, 2))
		end
		if string.sub(ry as string, 1, 1) == "m" then
			ry = -tonumber(string.sub(ry as string, 2))
		end
		regiondragging = regiondrag:new(x+(rx as number), y+(ry as number), s[4], s[5])
	else
		print("Error! Unknown t :(")
	end
	
	closerightclickmenu()
end

function finishregion()
	if regiondragging then
		local t = regiontoolt
		local x, y = regiontoolX, regiontoolY
		
		local j = 0
		for i = 3, #session.map[x][y] do
			local s = strsplit(tostring(session.map[x][y][i]), ":")
			if s[1] == t then
				j = i
				break
			end
		end
		
		local rx: any = (regiondragging as RegionDragging).x-x+1
		local ry: any = (regiondragging as RegionDragging).y-y+1
		
		if (rx as number) < 0 then
			rx = "m" .. -(rx as number)
		end
		
		if (ry as number) < 0 then
			ry = "m" .. -(ry as number)
		end
		
		session.map[x][y][j] = (t as string) .. ":" .. tostring(rx) .. ":" .. tostring(ry) .. ":" .. (regiondragging as RegionDragging).width .. ":" .. (regiondragging as RegionDragging).height
		
		regiondragging = nil
		rightclickactive = false
	end
end

function removelink(x: number, y: number, t: any)
	local edittable = {{x=x, y=y}}
	
	if selectionwidth then
		local selectionlist = selectiongettiles(selectionx, selectiony, selectionwidth, selectionheight)
		
		for i = 1, #selectionlist do
			local v = selectionlist[i]
			if (session.map[v.x][v.y][2] == session.map[x][y][2] or (entitylist[session.map[v.x][v.y][2]] and tablecontains(groundlighttable, entitylist[session.map[v.x][v.y][2]].t) and tablecontains(groundlighttable, entitylist[session.map[x][y][2]].t))) and (v.x ~= x or v.y ~= y) then
				table.insert(edittable, {x=v.x, y=v.y})
			end
		end
	end
	
	for j = 1, #edittable do
		local cx, cy = edittable[j].x, edittable[j].y
		
		local r = session.map[cx][cy]
		local i = 1
		
		while (r[i] ~= "link" or tostring(r[i+1]) ~= tostring(t)) and i < #r do
			i = i + 1
		end
		
		if i < #r then --found a match
			table.remove(session.map[cx][cy], i)
			table.remove(session.map[cx][cy], i)
			table.remove(session.map[cx][cy], i)
			table.remove(session.map[cx][cy], i)
		end
	end
end

function finishlinking(x: number, y: number)
	if rightclickactive then
		local startx, starty = linktoolX, linktoolY
		local endx, endy = getMouseTile(x, y+8*scale)
		
		local edittable = {{x=startx, y=starty}}
		
		if selectionwidth then
			local selectionlist = selectiongettiles(selectionx, selectiony, selectionwidth, selectionheight)
			
			for i = 1, #selectionlist do
				local v = selectionlist[i]
				if (session.map[v.x][v.y][2] == session.map[startx][starty][2] or (entitylist[session.map[v.x][v.y][2]] and tablecontains(groundlighttable, entitylist[session.map[v.x][v.y][2]].t) and tablecontains(groundlighttable, entitylist[session.map[startx][starty][2]].t))) and (v.x ~= startx or v.y ~= starty) then
					table.insert(edittable, {x=v.x, y=v.y})
				end
			end
		end
		
		
		for i = 1, #edittable do
			local x, y = edittable[i].x, edittable[i].y
			if x ~= endx or y ~= endy then
				local r = session.map[endx][endy]
				
				--LIST OF NUMBERS THAT ARE ACCEPTED AS INPUTS (buttons, laserdetectors)
				if #r > 1 and tablecontains( outputsi, r[2] ) then
					r = session.map[x][y]
					
					local i = 1
					while (r[i] ~= "link" or r[i+1] ~= linktoolt) and i <= #r do
						i = i + 1
					end
					
					session.map[x][y][i] = "link"
					session.map[x][y][i+1] = linktoolt
					session.map[x][y][i+2] = endx
					session.map[x][y][i+3] = endy
					linktoolfadeouttime = linktoolfadeouttimeslow
				end
				
				rightclickactive = false
				
				allowdrag = false
			end
		end
		linktoolt = false
	end
end

function drawlinkline(x1: number, y1: number, x2: number, y2: number)
	love.graphics.rectangle("fill", x1, y1-math.ceil(scale/2), x2-x1, scale)
	love.graphics.rectangle("fill", x2-math.ceil(scale/2), y1, scale, y2-y1)
end

function drawlinkline2(x1: number, y1: number, x2: number, y2: number)
	love.graphics.rectangle("fill", x1-math.ceil(scale/2), y1, scale, y2-y1)
	love.graphics.rectangle("fill", x2, y2-math.ceil(scale/2), x1-x2, scale)
end

function selectionbutton()
	editorstate = "selection"
	editorclose()
end

function selectionstart()
	mousex, mousey = mouse.getPosition()
	if not mousex or not mousey then
		return
	end
	selectionx = mousex
	selectiony = mousey
	
	selectiondragging = true
end

function selectionend()
	mousex, mousey = mouse.getPosition()
	if not mousex or not mousey then
		return
	end
	selectionwidth = mousex - selectionx
	selectionheight = mousey - selectiony
	
	if selectionwidth < 0 then
		selectionx = selectionx + selectionwidth
		selectionwidth = -selectionwidth
	end
	if selectionheight < 0 then
		selectiony = selectiony + selectionheight
		selectionheight = -selectionheight
	end
	
	selectiondragging = false
end

function selectiongettiles(x: number, y: number, width: number, height: number): {SelectionTile}
	x, y = round(x), round(y)
	width, height = round(width), round(height)

	local out: {SelectionTile} = {}
	
	local xstart, ystart = getMouseTile(x, y+7*scale)
	local xend, yend = getMouseTile(x+width, y+height+7*scale)
	
	for cox = xstart, xend do
		for coy = ystart, yend do
			if inmap(cox, coy) and session.map[cox][coy][2] then
				table.insert(out, {x=cox, y=coy})
			end
		end
	end
	
	return out
end

function editorexit()
	toggleclipboardenabled(false)
	toggledrawalllinks(false)
	toggleeditordebug(false)
	toggleskiplevelscreen(false)
	
	menu_load()
end
