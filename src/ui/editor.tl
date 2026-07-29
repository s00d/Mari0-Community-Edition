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
	if objects and objects["player"] and objects["player"][1] and inmap(cox, coy) then
		objects["player"][1].x = cox - 1 + 2 / 16
		objects["player"][1].y = coy - 1 + 2 / 16
		xscroll = math.max(0, cox - width / 2)
		yscroll = math.max(0, coy - height / 2)
		if splitxscroll then splitxscroll[1] = xscroll end
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

	print("Better editor loaded!")
	
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
		if not (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
			local xdir = love.keyboard.isDown("left") and -1 or (love.keyboard.isDown("right") and 1 or 0)
			local ydir = love.keyboard.isDown("up") and -1 or (love.keyboard.isDown("down") and 1 or 0)
			
			--xdir
			local oldxscroll = xscroll
			xscroll = math.max(0, math.min(mapwidth-width, xscroll + 30*gdt*xdir))
			splitxscroll[1] = math.max(0, math.min(mapwidth-width, splitxscroll[1]))
			
			--ydir
			local oldyscroll = yscroll
			yscroll = math.max(0, math.min(mapheight-1-height, yscroll + 30*gdt*ydir))
			
			if oldxscroll ~= xscroll or oldyscroll ~= yscroll then
				editor_camera_sync()
				autoscroll = false
				guielements["autoscrollcheckbox"].var = autoscroll
				generatespritebatch(0, 0)
				
				if regiondragging and (regiondragging as RegionDragging).movex and (regiondragging as RegionDragging).movey then
					(regiondragging as RegionDragging).movex = (regiondragging as RegionDragging).movex + (oldxscroll-xscroll)*16*scale
					(regiondragging as RegionDragging).movey = (regiondragging as RegionDragging).movey + (oldyscroll-yscroll)*16*scale
				end
			end
		end
	end
end

function editor_update_modifiers()
	if love.keyboard.isDown("rctrl") or love.keyboard.isDown("lctrl") then
		ctrlpressed = true
	else
		ctrlpressed = false
	end

	if love.keyboard.isDown(tileswitcherkey) then
		tileswitcherpressed = true
	else
		tileswitcherpressed = false
	end

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
							placetile((currx-xscroll-.5)*16*scale, (curry-yscroll-1)*16*scale, row[3], row[4] or false)
							for i = 5, #row, 4 do
								placetile((currx-xscroll-.5+(row[i] as number))*16*scale, (curry-yscroll-1+(row[i+1] as number))*16*scale, row[i+2] or row[3], row[4] or false)
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
					if minimapscroll < mapwidth-width-170 then
						minimapscroll = minimapscroll + minimapscrollspeed*dt
						if minimapscroll > mapwidth-width-170 then
							minimapscroll = mapwidth-width-170
						end
					end
				end
				
				splitxscroll[1] = editor_minimap_xscroll_from_mouse(mousex, scale, width, minimapscroll)
				if splitxscroll[1] > mapwidth-width then
					splitxscroll[1] = mapwidth-width
				end

				--SPRITEBATCH UPDATE
				if math.floor(splitxscroll[1]) ~= spritebatchX[1] then
					spritebatchX[1] = math.floor(splitxscroll[1])
					generatespritebatch(0, 0)
				end
				
				--VERTICAL
				if mousey < (minimapy+5)*scale then
					if yscroll > 0 then
						yscroll = yscroll - minimapscrollspeed*dt
						if yscroll < 0 then
							yscroll = 0
						end
					end
				elseif mousey >= (minimapy+minimapheight*2+4-5)*scale then
					if yscroll < mapheight-height then
						yscroll = yscroll + minimapscrollspeed*dt
						if yscroll > mapheight-height-1 then
							yscroll = mapheight-height-1
						end
					end
				end
			
				xscroll = editor_minimap_xscroll_from_mouse(mousex, scale, width, minimapscroll)
				if xscroll > mapwidth-width then
					xscroll = mapwidth-width
				end

				--SPRITEBATCH UPDATE
				local batch_dirty = false
				if math.floor(xscroll) ~= spritebatchX[1] then
					spritebatchX[1] = math.floor(xscroll)
					batch_dirty = true
				elseif math.floor(yscroll) ~= spritebatchY[1] then
					spritebatchY[1] = math.floor(yscroll)
					batch_dirty = true
				end
				if batch_dirty then
					generatespritebatch(0, 0)
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
	editor_slab_draw()
end

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
				if map[v.x][v.y][2] and entitylist[map[v.x][v.y][2]] and rightclickmenues[entitylist[map[v.x][v.y][2]].t] then
					love.graphics.rectangle("fill", (v.x-xscroll-1)*16*scale, (v.y-yscroll-1.5)*16*scale, 16*scale, 16*scale)
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
								love.graphics.draw(tilequads[w].image, quad, math.floor((x-xscroll-1 + pastecenter[1])*16*scale+(i-1)*16*scale), ((y-yscroll-1 + pastecenter[2])*16+8)*scale+((j-1)*16*scale), 0, scale, scale)
							else
								love.graphics.setColor(1, 1, 1, 0.3)
								love.graphics.draw(tilequads[w].image, quad, math.floor((x-xscroll-1 + pastecenter[1])*16*scale+(i-1)*16*scale), ((y-yscroll-1 + pastecenter[2])*16+8)*scale+((j-1)*16*scale), 0, scale, scale)
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
				local mousetile = map[cox][coy][1]
				for i, v in ipairs(map as {{MapCell}}) do
					for j, w in ipairs(v) do
						local quad = tilequads[currenttile as number]:quad() --[[tilequads[w].quad]]
						if w[1] == mousetile then
							--print(i,j,w[1],"SWITCHED")
							love.graphics.draw(tilequads[currenttile as number].image, quad, (i-1)*16*scale-xscroll*16*scale, (((j-1)*16*scale)-8*scale)-yscroll*16*scale, 0, scale, scale)
						end
					end
				end
				
				
				
			elseif tileselection then
				if tileselectionclick1 == false then
					if pastingtiles == false then
						-- no clicks yet - draw layer on single block
						love.graphics.setColor(0.5, 1, 0.5, 0.3)
						love.graphics.rectangle("fill",math.floor((x-xscroll-1)*16*scale), (((y-1)*16+8)*scale)-yscroll*16*scale, 16*scale, 16*scale)
					end
				elseif tileselectionclick2 == false then
					-- first click done - draw area: click1xy->mousexy
					local lx1, ly1 = 0, 0
					lx1 = math.min(tileselectionclick1x as integer, x as integer)
					ly1 = math.min(tileselectionclick1y as integer, y as integer)
					
					love.graphics.setColor(0.44,0.44,1,0.44)
					love.graphics.rectangle("fill",math.floor((lx1-xscroll-1)*16*scale), (((ly1-1)*16+8)*scale)-yscroll*16*scale, (math.max(tileselectionclick1x, x)-lx1)*16*scale+16*scale, (math.max(tileselectionclick1y, y)-ly1)*16*scale+16*scale)
				else
					-- two clicks done
					local lx1, ly1, lx2, ly2 = 0, 0, 0, 0
					lx1 = math.min(tileselectionclick1x as integer, tileselectionclick2x as integer)
					ly1 = math.min(tileselectionclick1y as integer, tileselectionclick2y as integer)
					lx2 = math.max(tileselectionclick1x as integer, tileselectionclick2x as integer)
					ly2 = math.max(tileselectionclick1y as integer, tileselectionclick2y as integer)
					
					-- Laziness or cleverness?
					local px, py = math.floor((lx1-xscroll-1)*16*scale), ((ly1-yscroll-1)*16+8)*scale
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
				love.graphics.translate(-xscroll*16*scale, -yscroll*16*scale)
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
							love.graphics.draw(tilequads[ctile].image, tileq, math.floor((cox-xscroll-1+(t1-1))*16*scale), math.floor(((coy-yscroll-1+(t2-1))*16+8)*scale), 0, scale, scale)
						end
					end
				elseif editenemies == false then
					local ctile = currenttile as number
					for t1 = 1, brush[1] as number do
						for t2 = 1, brush[2] as number do
							love.graphics.draw(entityquads[ctile].image, entityquads[ctile].quad, math.floor((cox-xscroll-1+(t1-1))*16*scale), math.floor(((coy-yscroll-1+(t2-1))*16+8)*scale), 0, scale, scale)
						end
					end
				else
					local v = enemiesdata[currenttile as string]
					local xoff, yoff = (((v.spawnoffsetx or 0)+v.width/2-.5)*16 - v.offsetX + v.quadcenterX)*scale, (((v.spawnoffsety or 0)-v.height+1)*16-v.offsetY - v.quadcenterY)*scale
					for t1 = 1, brush[1] as number do
						for t2 = 1, brush[2] as number do
							love.graphics.draw(v.graphic, v.quad, math.floor((cox-xscroll-1+(t1-1))*16*scale+xoff), math.floor(((coy-yscroll+(t2-1))*16)*scale+yoff), 0, scale, scale)
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
		
		for x = math.floor(xscroll), math.floor(xscroll)+width+1 do
			for y = math.floor(yscroll), math.floor(yscroll)+height+1 do
				for _, v in ipairs(table1) do
					if inmap(x, y) and #map[x][y] > 1 and map[x][y][2] == v then
						if cox == x and coy == y and tablecontains(outputsi, map[x][y][2]) then
							love.graphics.setColor(1, 1, 0.6, 1)
						elseif tablecontains(outputsi, map[x][y][2]) then
							love.graphics.setColor(1, 1, 0.6, 0.6)
						end
						love.graphics.rectangle("fill", math.floor((x-1-xscroll)*16*scale), ((y-1-yscroll)*16-8)*scale, 16*scale, 16*scale)
					end
				end
			end
		end
	end
	
	if drawalllinks then
		local added: number = 0
		for x = 1, mapwidth do
			for y = 1, mapheight do
				local ltx, lty = x, y
				local lx1, ly1 = editor_link_screen_pos(ltx, lty)
				local lx2, ly2 = 0.0, 0.0
				
				local drawtable: {{any}} = {}
				
				for i = 1, #map[ltx][lty] do
					if map[ltx][lty][i] == "link" and tonumber(map[ltx][lty][i+2]) and tonumber(map[ltx][lty][i+3]) then
						lx2, ly2 = math.floor(((map[ltx][lty][i+2] as number)-xscroll-.5)*16*scale), math.floor(((map[ltx][lty][i+3] as number)-yscroll-1)*16*scale)
						
						local t = map[ltx][lty][i+1]
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
		
		if map[ltx] and map[ltx][lty] then
			for i = 1, #map[ltx][lty] do
				if map[ltx][lty][i] == "link" and tonumber(map[ltx][lty][i+2]) and tonumber(map[ltx][lty][i+3]) then
					lx2, ly2 = math.floor(((map[ltx][lty][i+2] as number)-xscroll-.5)*16*scale), math.floor(((map[ltx][lty][i+3] as number)-yscroll-1)*16*scale)
					
					local t = map[ltx][lty][i+1]
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
		if entitylist[map[ltx][lty][2] as number].t == "faithplate" then
			local yoff = -8/16
			local x = ltx
			local y = lty-1
			local pointstable: {{string:number}} = {{x=x, y=y+yoff}}
			
			local speedx, speedy = 0.0, 0.0
			if rightclickm then
				speedx = (((rightclickm as rightclickmenu).t[2] as guielement).value) as number
				speedy = -((((rightclickm as rightclickmenu).t[4] as guielement).value) as number)
			else
				speedx = tonumber(map[ltx][lty][3]) or 0
				speedy = -(tonumber(map[ltx][lty][4]) or 0)
			end
			
			local step = 1/60
			
			repeat
				x, y = x+speedx*step, y+speedy*step
				speedy = speedy + yacceleration*step
				table.insert(pointstable, {x=x, y=y+yoff})
			until y > yscroll+height+.5
			
			love.graphics.setColor(62 / 255, 213 / 255, 244 / 255, 0.6*rightclicka)
			for i = 1, #pointstable-1 do
				local v = pointstable[i]
				local w = pointstable[i+1]
				love.graphics.line((v.x-xscroll)*16*scale, (v.y-yscroll-.5)*16*scale, (w.x-xscroll)*16*scale, (w.y-yscroll-.5)*16*scale)
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
	
	if love.keyboard.isDown("f1") and not rightclickm then
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
	for x = 1, mapwidth do
		for y = 1, mapheight do
			if x > -newmapoffsetx and x <= newmapwidth-newmapoffsetx and y > -newmapoffsety and y <= newmapheight-newmapoffsety then
				local id = map[x][y][1]
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
	properprintbackground("old width: " .. mapwidth, 26*scale, (mapy-21)*scale, true)
	properprintbackground("old height: " .. mapheight, 26*scale, (mapy-11)*scale, true)
	
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
	
	local lmap = map
	
	love.graphics.setScissor((minimapx+2)*scale, (minimapy+2)*scale, 390*scale, minimapheight*2*scale)
	
	for x = 1, mapwidth do --blocks
		for y = math.floor(yscroll)+1, math.min(mapheight, math.ceil(yscroll)+16) do
			if x-minimapscroll > 0 and x-minimapscroll < 196 then
				local id = lmap[x][y][1]
				if id ~= nil and id ~= 0 and tilequads[id]:getproperty("invisible", x, y) == false then
					if rgblist[id] then
						love.graphics.setColor(unpack(rgblist[id as number] as {any}))
						love.graphics.rectangle("fill", (minimapx+x*2-minimapscroll*2)*scale, (minimapy+(y+1)*2-(math.floor(yscroll)+1)*2-math.fmod(yscroll, 1)*2)*scale, 2*scale, 2*scale)
					end
				end
			end
		end
	end
	
	love.graphics.setScissor()
	
	love.graphics.setColor(1, 0, 0)
	drawrectangle(xscroll*2+minimapx-minimapscroll*2, minimapy, (width+2)*2, minimapheight*2+4)
	drawrectangle(xscroll*2+minimapx-minimapscroll*2+1, minimapy+1, (width+1)*2, minimapheight*2+2)
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

function maintab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "main"
	for _, v in pairs(guielements) do
		v.active = false
	end
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0, 0, 0}
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	guielements["colorsliderr"].active = true
	guielements["colorsliderg"].active = true
	guielements["colorsliderb"].active = true
	for i = 1, #backgroundcolor do
		guielements["defaultcolor" .. i].active = true
	end
	
	guielements["autoscrollcheckbox"].active = true
	guielements["musicdropdown"].active = true
	guielements["spritesetdropdown"].active = true
	guielements["timelimitdecrease"].active = true
	guielements["timelimitincrease"].active = true
	guielements["portalgundropdown"].active = true
	guielements["savebutton"].active = true
	guielements["menubutton"].active = true
	guielements["testbutton"].active = true
	if guielements["testcursorbutton"] then
		guielements["testcursorbutton"].active = true
	end
	if guielements["clearcheckbutton"] then
		guielements["clearcheckbutton"].active = true
	end
	guielements["widthbutton"].active = true
	guielements["intermissioncheckbox"].active = true
	guielements["warpzonecheckbox"].active = true
	guielements["underwatercheckbox"].active = true
	guielements["bonusstagecheckbox"].active = true
	guielements["custombackgroundcheckbox"].active = true
	guielements["customforegroundcheckbox"].active = true
	guielements["scrollfactorscrollbar"].active = true
	guielements["fscrollfactorscrollbar"].active = true
	guielements["backgrounddropdown"].active = true
	guielements["foregrounddropdown"].active = true
	guielements["levelscreendropdown"].active = true
end

function tilestab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "tiles"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"].fillcolor = {0, 0, 0}
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	guielements["tilesscrollbar"].active = true
	
	guielements["tilesall"].active = true
	guielements["tilessmb"].active = true
	guielements["tilesportal"].active = true
	guielements["tilescustom"].active = true
	guielements["tilesanimated"].active = true
	guielements["tilesentities"].active = true
	guielements["tilesenemies"].active = true
	
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function toolstab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "tools"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"].fillcolor = {0, 0, 0}
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	guielements["selectionbutton"].active = true
	guielements["lightdrawbutton"].active = true
	guielements["edittitle"].active = true
	guielements["editauthor"].active = true
	guielements["editdescription"].active = true
	guielements["savesettings"].active = true
	
	guielements["livesdecrease"].active = true
	guielements["livesincrease"].active = true
	
	guielements["pastemodedropdown"].active = true
	guielements["clipboardcheckbox"].active = true
	guielements["linktoolkindabutnotreally"].active = true
	guielements["editordebugcheckbox"].active = true
	guielements["levelscreencheckbox"].active = true
	
	if guielements["editauthor"].value == "willware" or guielements["editauthor"].value == "turretbot" then
		guielements["secretcheckbox"].active = true
	end
	
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function mapstab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "maps"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"].fillcolor = {0, 0, 0}
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	guielements["mapsnewlevel"].active = true
	guielements["mapsnewlevel"].textcolor = {0, 1, 0}
	guielements["mapsworldbox"].active = true
	guielements["mapslevelbox"].active = true
	
	guielements["mapscrollbar"].active = true
	
	for _, v in pairs(mapbuttons) do
		v.active = true
	end
end

function animationstab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "animations"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"].fillcolor = {0, 0, 0}
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	guielements["animationsscrollbarver"].active = true
	guielements["animationsscrollbarhor"].active = true
	guielements["animationsavebutton"].active = true
	guielements["animationselectdrop"].active = true
	guielements["animationnewbutton"].active = true
	
	generateanimationgui()
	
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function objectstab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "objects"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"].fillcolor = {0, 0, 0}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	guielements["objectscrollbar"].active = true	
	objectscrollbarheight = math.max(0, math.ceil((#multitileobjects-1))*17 - 1 - (17*9) - 12)
	
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function powerlinestab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "lightdrawcustomize"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	-- guielements["tabtools"].text = "party"
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	for i = 1, drawtools do
		guielements["drawtool" .. i].active = true
	end
	
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function fromanimationstab()
	saveanimation()
end

function frommapstab()
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function fromlightdrawcustomizetab() --the name for this tab is all over the place
	guielements["tabtools"].text = "tools"
	guielements["tabtools"].textcolor = {1, 1, 1}
	guielements["tabtools"].bordercolor = {0.5, 0.5, 0.5}
	for i = 1, drawtools do
		guielements["drawtool" .. i].active = false
	end
end

function generateentitylist()
	entitylistitems = {}
	for i, v in ipairs(entitylist as {EntityListEntry}) do
		if v.t ~= "" and not v.hidden then
			local cat = v.category or "misc"
			
			local cati = 0
			for j = 1, #entitylistitems do
				if entitylistitems[j].t == cat then
					cati = j
					break
				end
			end
			
			if cati == 0 then
				table.insert(entitylistitems, {t=cat, entries={}}) --cat??
				cati = #entitylistitems
			end
			
			table.insert(entitylistitems[cati].entries, entitylistitem:new(v.t, i))
		end
	end
	
	--sort categories
	table.sort(entitylistitems, function(a: entitylistcategory, b: entitylistcategory): boolean return a.t > b.t end)
	
	--calculate X and Y positions..
	local yadd = -3
	for _, v in ipairs(entitylistitems) do
		table.sort(v.entries, function(a: entitylistitem, b: entitylistitem): boolean return a.t < b.t end)
		
		--Category name space
		yadd = yadd + 14
		
		for j, k in ipairs(v.entries) do
			local x, y = math.fmod(j-1, 22)+1, math.ceil(j/22)
			k.x = (x-1)*17
			k.y = (y-1)*17+yadd
		end
		
		yadd = yadd + math.ceil(#v.entries/22)*17
	end
	
	yadd = yadd + 2
	
	tilescrollbarheight = math.max(0, yadd - 1 - (17*9) - 12)
end

function generateanimationgui()
	if not animations[currentanimation] then
		createnewanimation()
	end

	animationguilines = {}
	animationguilines.triggers = {}
	for _, v in pairs(animations[currentanimation].triggers as {any:any}) do
		table.insert(animationguilines.triggers, animationguiline:new(v, "trigger"))
	end
	animationguilines.conditions = {}
	for _, v in pairs(animations[currentanimation].conditions as {any:any}) do
		table.insert(animationguilines.conditions, animationguiline:new(v, "condition"))
	end
	animationguilines.actions = {}
	for _, v in pairs(animations[currentanimation].actions as {any:any}) do
		table.insert(animationguilines.actions, animationguiline:new(v, "action"))
	end
end

function createnewanimation()
	local s = {}
	s.triggers = {}
	s.conditions = {}
	s.actions = {}
	
	local i = 1
	while love.filesystem.getInfo(mappack_path(mappack) .. "/animations/animation" .. i .. ".json") do
		i = i + 1
	end
	love.filesystem.createDirectory(mappack_path(mappack) .. "/animations/")
	love.filesystem.write(mappack_path(mappack) .. "/animations/animation" .. i .. ".json", JSON.encode(s, { indent = true }))
	
	table.insert(animations as {any}, animation:new(mappack_path(mappack) .. "/animations/animation" .. i .. ".json", "animation" .. i .. ".json"))
	
	currentanimation = #animations
	
	updateanimationdropdown()
end

function updateanimationdropdown()	
	local args = {}
	for _, v in ipairs(animations) do
		table.insert(args, string.sub(v.name as string, 1, -6))
	end
	
	guielements["animationselectdrop"] = guielement:new("dropdown", 15, 20, 15, selectanimation, currentanimation, unpack(args))
end
	
function deleteanimationguiline(t: string, tabl: animationguiline)
	for i, v in ipairs((animationguilines[t .. "s"]) as {animationguiline}) do
		if v == tabl then
			table.remove(animationguilines[t .. "s"], i)
		end
	end
end

function movedownanimationguiline(t: string, tabl: animationguiline)
	for i, v in ipairs((animationguilines[t .. "s"]) as {animationguiline}) do
		if v == tabl then
			if i ~= #animationguilines[t .. "s"] then
				animationguilines[t .. "s"][i], animationguilines[t .. "s"][i+1] = animationguilines[t .. "s"][i+1], animationguilines[t .. "s"][i]
				break
			end
		end
	end
end

function moveupanimationguiline(t: string, tabl: animationguiline)
	for i, v in ipairs((animationguilines[t .. "s"]) as {animationguiline}) do
		if v == tabl then
			if i ~= 1 then
				animationguilines[t .. "s"][i], animationguilines[t .. "s"][i-1] = animationguilines[t .. "s"][i-1], animationguilines[t .. "s"][i]
				break
			end
		end
	end
end

function selectanimation(i: number)
	guielements["animationselectdrop"].var = i
	saveanimation()
	currentanimation = i as integer
	generateanimationgui()
end

function saveanimation()
	local out: {string:{{any}}} = {}
	
	local typelist = {"triggers", "conditions", "actions"}
	for _, w in ipairs(typelist) do
		out[w] = {}
		for i, v in ipairs((animationguilines[w]) as {animationguiline}) do
			out[w][i] = {}
			for j, k in ipairs(v.elements as {animationguielement}) do
				if k.gui then
					local val: any = ""
					if k.gui.type == "dropdown" then
						if j == 1 then
							--find normal name
							for l, m in pairs(animationlist as {any:any}) do
								if (m as guielement).nicename == (k.gui.entries as {any:any})[k.gui.var] then
									val = l
									break
								end
							end
						else
							val = (k.gui.entries as {any:any})[k.gui.var]
						end
					elseif k.gui.type == "input" then
						val = k.gui.value
					end
					
					table.insert(out[w][i], val)
				end
			end
		end
	end
	
	animations[currentanimation].triggers = out.triggers as {{any}}
	animations[currentanimation].conditions = out.conditions as {{any}}
	animations[currentanimation].actions = out.actions as {{any}}
	
	local json = JSON.encode(out, { indent = true })
	
	local ok, err = pcall(love.filesystem.write, animations[currentanimation].filepath as string, json as string)
	if not ok then
		print(tostring(err) .. " - File: " .. (animations[currentanimation].filepath as string))
	end
end

function addanimationtrigger()
	table.insert(animationguilines.triggers, animationguiline:new({}, "trigger"))
end

function addanimationcondition()
	table.insert(animationguilines.conditions, animationguiline:new({}, "condition"))
end

function addanimationaction()
	table.insert(animationguilines.actions, animationguiline:new({}, "action"))
end

function loadmtobjects()
	-- get multitile objects!
	multitileobjects = nil
	multitileobjects = {}
	multitileobjectnames = nil
	multitileobjectnames = {}
	if love.filesystem.getInfo(mappack_path(mappack) .. "/objects.txt") then
		local data = ((love.filesystem.read(mappack_path(mappack) .. "/objects.txt")) or "") as string
		if #data > 0 then
			data = string.sub(data, 1, -2)
			--print(data)
			local split1 = strsplit(data, "\n")
			local split2: {string} = {}
			local split3: {string} = {}
			for i = 1, #split1 do
				-- objects
				split2 = strsplit(split1[i], "=") as {string}
				table.insert(multitileobjectnames, split2[1])
				-- rows
				if string.find(split1[i] as string,":") then
					split3 = strsplit(split2[2], ":") as {string}
				else
					split3 = {split2[2]}
				end
				local ox = {}
				local oo = {}
				for j = 1, #split3 do
					ox = {}
					local split4 = strsplit(split3[j], ",")
					for u = 1, #split4 do
						table.insert(ox, tonumber(split4[u]))
						--print(split4[u]..",")
					end
					table.insert(oo, ox)
					--print(":")
				end
				table.insert(multitileobjects, oo)
			end
		end
	end
end

function loadmtgroups()
	multitilegroups = nil
	multitilegroups = {}
	if love.filesystem.getInfo(mappack_path(mappack) .. "/groups.txt") then
		local data = ((love.filesystem.read(mappack_path(mappack) .. "/groups.txt")) or "") as string
		if #data > 0 then
			data = string.sub(data, 1, -2)
			local split1 = strsplit(data, "\n")
			local split2: {string} = {}
			local split3: {string} = {}
			for i = 1, #split1 do
				-- groups
				split2 = strsplit(split1[i], "=") as {string}
				-- rows
				if string.find(split1[i] as string,":") then
					split3 = strsplit(split2[2], ":") as {string}
				else
					split3 = {split2[2]}
				end
				local ox = {}
				local oo = {}
				for j = 1, #split3 do
					ox = {}
					local split4 = strsplit(split3[j], ",")
					for u = 1, #split4 do
						table.insert(ox, tonumber(split4[u]))
					end
					table.insert(oo, ox)
				end
				multitilegroups[split2[1]] = oo
			end
		end
	end
end

function openchangewidth()
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["maptopup"].active = true
	guielements["maptopdown"].active = true
	guielements["mapbottomup"].active = true
	guielements["mapbottomdown"].active = true
	guielements["mapleftleft"].active = true
	guielements["mapleftright"].active = true
	guielements["maprightleft"].active = true
	guielements["maprightright"].active = true
	guielements["mapwidthapply"].active = true
	guielements["mapwidthcancel"].active = true

	changemapwidthmenu = true
	newmapwidth = mapwidth
	newmapheight = mapheight
	newmapoffsetx = 0
	newmapoffsety = 0
end

function mapwidthapply()
	changemapwidthmenu = false
	objects["tile"] = {}
	
	local newmap = {}
	local newcoinmap = {}
	for x = 1, newmapwidth do
		newmap[x] = {}
		newcoinmap[x] = {}
		for y = 1, newmapheight do
			local oldx, oldy = x-newmapoffsetx, y-newmapoffsety
			if inmap(oldx, oldy) then
				newmap[x][y] = map[oldx][oldy]
				newcoinmap[x][y] = coinmap[oldx][oldy]
			else
				newmap[x][y] = {1, portaloverride={0, 0}}
				init_map_cell_gels(newmap[x][y] as MapCell)
			end
			
			if tilequads[newmap[x][y][1]]:getproperty("collision", x, y) then
				physics_world_set_tile(tilekey(x, y), tile:new(x-1, y-1, 1, 1, true) as Entity)
			end
		end
	end
	
	objects["player"][1].x = objects["player"][1].x + newmapoffsetx
	objects["player"][1].y = objects["player"][1].y + newmapoffsety
	
	xscroll = xscroll + newmapoffsetx
	yscroll = yscroll + newmapoffsety
	
	if xscroll < 0 then
		xscroll = 0
	end
	
	if xscroll > mapwidth-width then
		xscroll = math.max(0, mapwidth-width)
		hitrightside()
	end
	
	map = newmap
	coinmap = newcoinmap
	mapwidth = newmapwidth
	mapheight = newmapheight
	
	--Update animatedtimers
	animatedtimers = {}
	animatedbooltimers = {}
	for x = 1, mapwidth do
		if not animatedtimers[x] then
			animatedtimers[x] = {}
		end
	end
	for x = 1, mapwidth do
		if not animatedbooltimers[x] then
			animatedbooltimers[x] = {}
		end
	end
	
	--move all them links!
	for x = 1, mapwidth do
		for y = 1, mapheight do
			for i, v in pairs(map[x][y] as {any:any}) do
				if v == "link" then
					local ii = (i as number)
					map[x][y][(ii+2) as integer] = (map[x][y][(ii+2) as integer] as number) + newmapoffsetx
					map[x][y][(ii+3) as integer] = (map[x][y][(ii+3) as integer] as number) + newmapoffsety
				end
			end
		end
	end
	
	objects["screenboundary"]["right"].x = mapwidth
	physics_world_refresh()
	generatespritebatch(0, 0)
	
	--editorclose()
	
	maintab()
end

function mapwidthcancel()
	changemapwidthmenu = false
	--editorclose()
	maintab()
end

function changenewmapsize(side: any, dir: any)
	if side == "top" then
		if dir == "up" then
			newmapheight = newmapheight + 1
			newmapoffsety = newmapoffsety + 1
		else
			if newmapheight > 15 then
				newmapheight = newmapheight - 1
				newmapoffsety = newmapoffsety - 1
			end
		end
	elseif side == "bottom" then
		if dir == "up" then
			if newmapheight > 15 then
				newmapheight = newmapheight - 1
			end
		else
			newmapheight = newmapheight + 1
		end
	elseif side == "left" then
		if dir == "left" then
			newmapwidth = newmapwidth + 1
			newmapoffsetx = newmapoffsetx + 1
		else
			if newmapwidth > 1 then
				newmapwidth = newmapwidth - 1
				newmapoffsetx = newmapoffsetx - 1
			end
		end
	elseif side == "right" then
		if dir == "left" then
			if newmapwidth > 1 then
				newmapwidth = newmapwidth - 1
			end
		else
			newmapwidth = newmapwidth + 1
		end
	end
end

function tilesall()
	guielements["tilesall"].textcolor = {1, 1, 1}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = false
	tileliststart = 1
	tilelistcount = smbtilecount + portaltilecount + customtilecount + (modcustomtilecount[modcustomtiles as integer] or 0)  -1
	
	if editentities or editenemies then
		currenttile = 1
	end
	
	tilescrollbarheight = math.max(0, math.ceil((smbtilecount + portaltilecount + customtilecount + (modcustomtilecount[modcustomtiles as integer] or 0))/22)*17 - 1 - (17*9) - 12)
	editentities = false
	editenemies = false
end

function tilessmb()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {1, 1, 1}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = false
	tileliststart = 1
	tilelistcount = smbtilecount-1
	
	if editentities or editenemies then
		currenttile = 1
	end
	
	tilescrollbarheight = math.max(0, math.ceil((smbtilecount)/22)*17 - 1 - (17*9) - 12)
	editentities = false
	editenemies = false
end

function tilesportal()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {1, 1, 1}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = false
	tileliststart = smbtilecount + 1
	tilelistcount = portaltilecount - 1
	
	if editentities or editenemies then
		currenttile = 1
	end
	
	tilescrollbarheight = math.max(0, math.ceil((portaltilecount)/22)*17 - 1 - (17*9) - 12)
	editentities = false
	editenemies = false
end

function tilescustom()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {1, 1, 1}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = false
	tileliststart = smbtilecount + portaltilecount + 1
	tilelistcount = customtilecount + (modcustomtilecount[modcustomtiles as integer] or 0) - 1
	
	if editentities or editenemies then
		currenttile = 1
	end
	
	tilescrollbarheight = math.max(0,  math.ceil((customtilecount + (modcustomtilecount[modcustomtiles as integer] or 0))/22)*17 - 1 - (17*9) - 12)
	editentities = false
	editenemies = false
end

function tilesanimated()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {1, 1, 1}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = true
	tileliststart = 1
	tilelistcount = animatedtilecount - 1
	
	if editentities or editenemies then
		currenttile = 1
	end
	
	tilescrollbarheight = math.max(0, math.ceil((customtilecount)/22)*17 - 1 - (17*9) - 12)
	editentities = false
	editenemies = false
end

function tilesentities()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {1, 1, 1}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = false
	editentities = true
	editenemies = false
	
	currenttile = 1
	
	generateentitylist()
end

function tilesenemies()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {1, 1, 1}
	
	animatedtilelist = false
	tilescrollbarheight = math.max(0, math.ceil((#enemies)/22)*17 - 1 - (17*9) - 12)
	editentities = true
	editenemies = true
	
	currenttile = enemies[1]
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
	local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
	if editentities == false and not preventMultiTile and not alt then
		if autotile_paint(cox, coy, currenttile as integer, false) then
			-- collision objects for resulting tile
			local nt = map[cox][coy][1] as number
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
			coinmap[cox][coy] = not editorcoinstart
			return
		end
	
		if tilequads[currenttile as number]:getproperty("collision") == true and tilequads[map[cox][coy][1] as number]:getproperty("collision") == false then
			physics_world_set_tile(tilekey(cox, coy), tile:new(cox-1, coy-1, 1, 1, true) as Entity)
		elseif tilequads[currenttile as number]:getproperty("collision") == false and tilequads[map[cox][coy][1] as number]:getproperty("collision") == true then
			physics_world_set_tile(tilekey(cox, coy), nil)
		end
		if map[cox][coy][1] ~= currenttile then
			map[cox][coy][1] = currenttile
			init_map_cell_gels(map[cox][coy])
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
			for i = 2, #map[cox][coy] do
				map[cox][coy][i] = nil
			end
		else
			for i = 3, #map[cox][coy] do
				map[cox][coy][i] = nil
			end
			
			map[cox][coy][2] = currenttile
			
			if editenemies == false then
				if rightclickmenues[(entitylist[currenttile as number] as EntityListEntry).t] then
					local rcm = rightclickmenues[(entitylist[currenttile as number] as EntityListEntry).t] as {RightClickVar}
					for i = 1, #rcm do
						local v = rcm[i]
						if tablecontains(rightclickelementslist, v.t) then
							if v.default then
								table.insert(map[cox][coy], v.default)
							else
								table.insert(map[cox][coy], "nil")
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
		objects["player"][i]:removeportals()
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

function mapnumberclick(i: number, j: number, k: any)
	if editormode then
		marioworld = tonumber(i) as number
		mariolevel = tonumber(j) as number
		editorloadopen = true
		local needs_to_be_saved = false
		if k then
			k = tonumber(k)
			needs_to_be_saved = loadlevel(i .. "-" .. j .. "_" .. (k as number))
		else
			needs_to_be_saved = loadlevel(i .. "-" .. j)
		end
		startlevel()
		if needs_to_be_saved then
			savelevel()
			getmaps()
		end
	end
end

function getmaps()
	existingmaps = {}
	largestworld = 0
	mapbuttons = {}
	local yadd: number = 2
	local worlds: number = 0
	local levels: number = 0
	local sublevels: number = 0
	local files = love.filesystem.getDirectoryItems(mappack_path(mappack))
	editor_filter_map_files(files)
	table.sort(files, mapsort)
	for i = 1, #files do
		if string.match(files[i], "(%d+)-(%d+).txt") then
			local ws, ls = string.match(files[i], "(%d+)-(%d+).txt")
			worlds = (tonumber(ws) or 0) as number
			levels = (tonumber(ls) or 0) as number
			sublevels = 0
			mapbuttons["text" .. worlds .. "-" .. levels] = guielement:new("text", 4, yadd+21, "world " .. worlds .. "-" .. levels)
			mapbuttons["text" .. worlds .. "-" .. levels].starty = yadd+21
			mapbuttons["plus" .. worlds .. "-" .. levels] = guielement:new("button", 62+(string.len(tostring(worlds))+string.len(tostring(levels)))*8, yadd+19, "+", mapnumberclick, 0, {worlds, levels, 1})
			mapbuttons["plus" .. worlds .. "-" .. levels].starty = yadd+19
			yadd = yadd + 10
			local mapkey = worlds .. "-" .. levels .. "_" .. (sublevels or 0)
			if love.filesystem.getInfo(mappack_path(mappack) .. "/" .. level_name(worlds, levels) .. ".png") then
				mapbuttons[mapkey] = guielement:new("button", 4, yadd+21, AssetStore.load_image(mappack_path(mappack) .. "/" .. level_name(worlds, levels) .. ".png"), mapnumberclick, 0, {worlds, levels})
			else
				mapbuttons[mapkey] = guielement:new("button", 4, yadd+21, "no preview", mapnumberclick, 0, {worlds, levels})
			end
			mapbuttons[mapkey].starty = yadd+21
			yadd = yadd + 20
			if largestworld < worlds then
				largestworld = worlds
			end
			if existingmaps[worlds] == nil or (existingmaps[worlds] as number) < levels then
				existingmaps[worlds] = levels
			end
		elseif string.match(files[i], "(%d+)-(%d+)_(%d+).txt") then
			local ws, ls, ss = string.match(files[i], "(%d+)-(%d+)_(%d+).txt")
			worlds = (tonumber(ws) or 0) as number
			levels = (tonumber(ls) or 0) as number
			sublevels = (tonumber(ss) or 0) as number
			if not mapbuttons["text" .. worlds .. "-" .. levels] then
				mapbuttons["text" .. worlds .. "-" .. levels] = guielement:new("text", 4, yadd+21, "world " .. worlds .. "-" .. levels, {0.5, 0.5, 0.5})
				mapbuttons["text" .. worlds .. "-" .. levels].starty = yadd+21
				mapbuttons["plus" .. worlds .. "-" .. levels] = guielement:new("button", 62+(string.len(tostring(worlds))+string.len(tostring(levels)))*8, yadd+19, "+", mapnumberclick, 0, {worlds, levels, (sublevels as number) + 1})
				mapbuttons["plus" .. worlds .. "-" .. levels].starty = yadd+19
				yadd = yadd + 10
			end
			mapbuttons["text" .. worlds .. "-" .. levels .. "_" .. sublevels] = guielement:new("text", 4, yadd+26, "sub " .. sublevels, {0.5, 0.5, 0.5})
			mapbuttons["text" .. worlds .. "-" .. levels .. "_" .. sublevels].starty = yadd+26
			if love.filesystem.getInfo(mappack_path(mappack) .. "/" .. worlds .. "-" .. levels .. "_" .. sublevels ..".png") then
				mapbuttons[worlds .. "-" .. levels .. "_" .. sublevels] = guielement:new("button", 54, yadd+21, AssetStore.load_image(mappack_path(mappack) .. "/" .. level_name(worlds, levels, sublevels) .. ".png"), mapnumberclick, 0, {worlds, levels, sublevels})
				mapbuttons[worlds .. "-" .. levels .. "_" .. sublevels].starty = yadd+21
			else
				mapbuttons[worlds .. "-" .. levels .. "_" .. sublevels] = guielement:new("button", 54, yadd+21, "no preview", mapnumberclick, 0, {worlds, levels, sublevels})
				mapbuttons[worlds .. "-" .. levels .. "_" .. sublevels].starty = yadd+24
			end
			yadd = yadd + 20
			
			if mapbuttons["plus" .. worlds .. "-" .. levels] and (mapbuttons["plus" .. worlds .. "-" .. levels].arguments[3] as number) < (sublevels as number) + 1 then
				mapbuttons["plus" .. worlds .. "-" .. levels].arguments[3] = (sublevels as number) + 1
			end
		end
	end

	mapsymissing = math.max(0, yadd-200)
end

function newlevel()	
	local i = tonumber(guielements["mapsworldbox"].value)
	local j = tonumber(guielements["mapslevelbox"].value)
	
	if i ~= nil and j ~= nil then
		mapnumberclick(i, j)
	elseif i == nil and j ~= nil then
		mapnumberclick(marioworld, j)
	elseif i ~= nil and j == nil then
		mapnumberclick(i, ((existingmaps[i] as number) or 0)+1)
	elseif marioworld ~= nil and existingmaps[marioworld as number] ~= nil then
		mapnumberclick(marioworld, (existingmaps[marioworld as number] as number)+1)
	else
		mapnumberclick(1, 1)
	end
end

function savestate()
	while #(savestates as {any}) >= maxstates do
		table.remove(savestates, 1)
	end
	local t: {any:any} = {}
	t.coinmap = {} as {any}
	for x = 1, #map do
		t[x] = {}
		;(t.coinmap as {any})[x] = {}
		for y = 1, #map[x] do
			(t[x] as {any})[y] = {}
			;((t.coinmap as {any})[x] as {any})[y] = coinmap[x][y]
			for i, v in pairs(map[x][y] as {any:any}) do
				((t[x] as Dyn)[y] as Dyn)[i] = v as Dyn
			end
		end
	end
	table.insert(savestates, t)
end

function loadstate(s: any)
	local si = (s or currentstate) as number
	currentstate = si
	
	local v = savestates[si as integer] as Dyn
	map = {}
	coinmap = {}
	for x = 1, #(v as {any}) do
		map[x] = {}
		coinmap[x] = {}
		local col = v[x] as {any}
		for y = 1, #col do
			map[x][y] = {} as MapCell
			coinmap[x][y] = ((v["coinmap"] as {any})[x] as {any})[y] as boolean
			for i, w in pairs(col[y] as {any:any}) do
				map[x][y][i as integer] = w
			end
		end
	end
	
	generatespritebatch(0, 0)
end

--[[function getmaps() VANILLA GETMAPS
	existingmaps = {}
	mapbuttons = {}
	local yadd = 0
	for i = 1, 8 do --world
		existingmaps[i] = {}
		for j = 1, 4 do --level
			mapbuttons["text" .. i .. "-" .. j] = guielement:new("text", 4, yadd+21, "world " .. i .. "-" .. j)
			mapbuttons["text" .. i .. "-" .. j].starty = yadd+21
			
			yadd = yadd + 10
			existingmaps[i][j] = {}
			for k = 0, 5 do --sublevel
				local s = i .. "-" .. j
				
				local xadd = 0
				
				if k ~= 0 then
					s = s .. "_" .. k
				end
				
				if love.filesystem.getInfo(mappack_level_path(mappack, i, j, k), "file") then
					if k ~= 0 then
						mapbuttons["text" .. i .. "-" .. j .. "_" .. k] = guielement:new("text", 4, yadd+26, "sub " .. k, {0.5, 0.5, 0.5})
						mapbuttons["text" .. i .. "-" .. j .. "_" .. k].starty = yadd+26
						xadd = 50
					end
					
					if love.filesystem.getInfo(mappack_path(mappack) .. "/" .. level_name(i, j, k) .. ".png", "file") then
						mapbuttons[i .. "-" .. j .. "_" .. k] = guielement:new("button", 4+xadd, yadd+21, AssetStore.load_image(mappack_path(mappack) .. "/" .. level_name(i, j, k) .. ".png"), mapnumberclick, 0, {i, j, k})
					else
						mapbuttons[i .. "-" .. j .. "_" .. k] = guielement:new("button", 4+xadd, yadd+21, "no preview", mapnumberclick, 0, {i, j, k})
					end
					mapbuttons[i .. "-" .. j .. "_" .. k].starty = yadd+21
					yadd = yadd + 20
				end
			end
		end
	end
	
	mapsymissing = math.max(0, yadd-200)
end]]

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
				
				slx1 = math.floor((lx1-xscroll-1)*16*scale)
				sly1 = ((ly1-yscroll-1)*16+8)*scale
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
							local mousetile = map[cox][coy][1]
							for i, v in ipairs(map as {{MapCell}}) do
								for j, w in ipairs(v) do
									if w[1] == mousetile then
										map[i][j][1] = currenttile
									end
								end
							end
							generatespritebatch(0, 0)
							--local x, y = love.mouse.getPosition()
							--placetile(x, y)
						end
					else
						if coinmap[cox][coy] then
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
		if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
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
		if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
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
			local r = map[tileX][tileY]
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
				
				if objects["player"][1] and not objects["player"][1].vine and not objects["player"][1].grapple then
					objects["player"][1].x = cox-1+2/16
					objects["player"][1].y = coy-objects["player"][1].height
					objects["player"][1].vine = false
				end
			end
		end
	else
		if editorstate == "main" then
			if y >= (minimapy+2)*scale and y < (minimapy+32)*scale then
				if x >= (minimapx+2)*scale and x < (minimapx+392)*scale then
					local x, y = editor_minimap_tile_from_click(x, y, scale, minimapx, minimapy, minimapscroll, yscroll)
					
					if objects["player"][1] then
						objects["player"][1].x = x-1+2/16
						objects["player"][1].y = y-1+2/16
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
				currenttile = map[cox][coy][1]
				
				if currenttile == 1 and coinmap[cox][coy] then
					currenttile = 116 -- Let's be nice to the map maker, alright?
				end
			elseif not editenemies then
				tilesentities()
				generateentitylist()
				currenttile = map[cox][coy][2]
				if type(currenttile) ~= "number" then currenttile = 1 end
			else
				tilesenemies()
				currenttile = map[cox][coy][2]
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
				for j = 2, #map[selectionlist[i].x][selectionlist[i].y] do
					map[selectionlist[i].x][selectionlist[i].y][j] = nil
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
			tileselectionclick2x = mapwidth
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
	elseif (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) and not editormenuopen and ENEMY_MODIFIER_ORDER then
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
		local shiftpressed = ((love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) and true) or false
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

function toggleautoscroll(var: any)
	if var ~= nil then
		autoscroll = var
	else
		autoscroll = not autoscroll
	end
	guielements["autoscrollcheckbox"].var = autoscroll
end

function toggleintermission(var: any)
	if var ~= nil then
		intermission = var
	else
		intermission = not intermission
	end
	guielements["intermissioncheckbox"].var = intermission
end

function togglewarpzone(var: any)
	if var ~= nil then
		haswarpzone = var
	else
		haswarpzone = not haswarpzone
	end
	guielements["warpzonecheckbox"].var = haswarpzone
end

function toggleunderwater(var: any)
	if var ~= nil then
		underwater = var
	else
		underwater = not underwater
	end
	guielements["underwatercheckbox"].var = underwater
end

function togglebonusstage(var: any)
	if var ~= nil then
		bonusstage = var
	else
		bonusstage = not bonusstage
	end
	guielements["bonusstagecheckbox"].var = bonusstage
end

function toggleclipboardenabled(var: any)
	if var ~= nil then
		clipboardenabled = var
	else
		clipboardenabled = not clipboardenabled
	end
	guielements["clipboardcheckbox"].var = clipboardenabled
end

function toggledrawalllinks(var: any)
	if var ~= nil then
		drawalllinks = var
	else
		drawalllinks = not drawalllinks
	end
	guielements["linktoolkindabutnotreally"].var = drawalllinks
end

function togglecustombackground(_: any)
	if custombackground then
		custombackground = false
	else
		custombackground = custombackgrounds[(((guielements["backgrounddropdown"].var as number)-1) as integer)]
		if custombackground == nil then
			custombackground = true
		end
	end
	
	guielements["custombackgroundcheckbox"].var = custombackground ~= false
end

function toggleeditordebug(var: any)
	if var ~= nil then
		editordebug = var
	else
		editordebug = not editordebug
	end
	
	physicsdebug = editordebug
	portalwalldebug = editordebug
	
	guielements["editordebugcheckbox"].var = editordebug
end

function toggleskiplevelscreen(var: any)
	if var ~= nil then
		skiplevelscreen = var
	else
		skiplevelscreen = not skiplevelscreen
	end
	
	guielements["levelscreencheckbox"].var = skiplevelscreen
end

function changepastemode(var: any)
	--	pastemode = var
	--	guielements["pastemodedropdown"].var = var
	if var ~= nil then
		pastemode = var
	else
		pastemode = not pastemode
	end
	guielements["pastemodedropdown"].var = pastemode
end

function togglecustomforeground(_: any)
	if customforeground then
		customforeground = false
	else
		customforeground = custombackgrounds[(((guielements["foregrounddropdown"].var as number)-1) as integer)]
		if customforeground == nil then
			customforeground = true
		end
	end
	
	guielements["customforegroundcheckbox"].var = customforeground ~= false
end

function changebackground(var: any)
	guielements["backgrounddropdown"].var = var
	if custombackground then
		custombackground = custombackgrounds[(((guielements["backgrounddropdown"].var as number)-1) as integer)]
		if custombackground == nil then
			custombackground = true
		end
	end	
end

function changeforeground(var: any)
	guielements["foregrounddropdown"].var = var
	if customforeground then
		customforeground = custombackgrounds[(((var as number)-1) as integer)]
		if customforeground == nil then
			customforeground = true
		end
	end	
end

function changelevelscreen(var: any)
	guielements["levelscreendropdown"].var = var
	levelscreenbackname = levelscreens[(((var as number)-1) as integer)]
end

function changeportalgun(var: any)
	if var == 1 then
		portalsavailable = {true, true}
	elseif var == 2 then
		portalsavailable = {true, false}
	elseif var == 3 then
		portalsavailable = {false, true}
	elseif var == 4 then
		portalsavailable = {false, false}
	end
	guielements["portalgundropdown"].var = var
end

function changemusic(var: any)
	stopmusic()
	musicname = musiclist[var as integer] as string
	
	if var == 1 then
		musicname = nil
	end
	
	playmusic()
	guielements["musicdropdown"].var = var
end

function changespriteset(var: any)
	spriteset = var as integer
	guielements["spritesetdropdown"].var = var
end

function decreasetimelimit()
	mariotimelimit = mariotimelimit - 10
	if mariotimelimit < 0 then
		mariotimelimit = 0
	end
	mariotime = mariotimelimit
	guielements["timelimitincrease"].x = 31 + string.len(tostring(mariotimelimit))*8
end

function increasetimelimit()
	mariotimelimit = mariotimelimit + 10
	mariotime = mariotimelimit
	guielements["timelimitincrease"].x = 31 + string.len(tostring(mariotimelimit))*8
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
		xscroll = xscroll,
		yscroll = yscroll,
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
		xscroll = math.max(0, (r.death_x as number) - width / 2)
		yscroll = math.max(0, (r.death_y as number) - height / 2)
	else
		if r.xscroll ~= nil then xscroll = r.xscroll as number end
		if r.yscroll ~= nil then yscroll = r.yscroll as number end
	end
	if splitxscroll then
		splitxscroll[1] = xscroll
	end
	if r.palette_collapsed ~= nil then EDITOR_LAYOUT.palette_collapsed = r.palette_collapsed as boolean end
	if r.props_collapsed ~= nil then EDITOR_LAYOUT.props_collapsed = r.props_collapsed as boolean end
	layout_recalc(nil, nil)
	if r.currenttile ~= nil then currenttile = r.currenttile end
	if r.editentities ~= nil then editentities = r.editentities as boolean end
	if r.editenemies ~= nil then editenemies = r.editenemies as boolean end
end


function drawpowerlines()
	advanceddrawtool = "powerlines"
	
	editenemies = false
	editentities = true
	editorstate = "lightdraw"
	lightdrawX = nil
	lightdrawY = nil
	editorclose()
end

function drawmushrooms()
	advanceddrawtool = "mushroom"

	editenemies = false
	editentities = false
	editorstate = "lightdraw"
	lightdrawX = nil
	lightdrawY = nil
	editorclose()
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
	
	slx1 = math.floor((lx1-xscroll-1)*16*scale)
	sly1 = ((ly1-yscroll-1)*16+8)*scale
	slx2 = slx1 + ((lx2-lx1)*16*scale+16*scale)
	sly2 = sly1 + (ly2-ly1)*16*scale+16*scale
	
	local tile1x,tile1y = getMouseTile(slx1+8*scale, sly1+8*scale)
	local tile2x,tile2y = getMouseTile(slx2+8*scale, sly2+8*scale)
	local xnum = tile2x - tile1x
	local ynum = tile2y - tile1y
	
	for i = 1, xnum do
		for j = 1, ynum do
			map[tile1x + i - 1][tile1y + j - 1] = {1} as MapCell
			init_map_cell_gels(map[tile1x + i - 1][tile1y + j - 1])
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
	
	slx1 = math.floor((lx1-xscroll-1)*16*scale)
	sly1 = ((ly1-yscroll-1)*16+8)*scale
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
			table.insert(tx, map[tile1x + i - 1][tile1y + j - 1][1])
			--print(map[tile1x + i - 1][tile1y + j - 1][1])
		end
		table.insert(objecttable, tx)
	end
	return objecttable
end

function loadHotKeys()
	hotkeys = {}
	if love.filesystem.getInfo(mappack_path(mappack) .. "/hotkeys.txt") then
		local data = (love.filesystem.read(mappack_path(mappack) .. "/hotkeys.txt") or "") as string
		hotkeys = editor_hotkeys_parse(data)
	end
end

function saveHotKeys()
	love.filesystem.write(mappack_path(mappack) .. "/hotkeys.txt", editor_hotkeys_serialize(hotkeys) as string)
end

function savesettings()
	local s = ""
	s = s .. "name=" .. (guielements["edittitle"].value as string) .. "\n"
	s = s .. "author=" .. (guielements["editauthor"].value as string) .. "\n"
	s = s .. "description=" .. (guielements["editdescription"].value as string) .. "\n"
	if mariolivecount == false then
		s = s .. "lives=0\n"
	else
		s = s .. "lives=" .. (mariolivecount as integer) .. "\n"
	end
	
	love.filesystem.createDirectory("mappacks")
	love.filesystem.createDirectory( mappack_path(mappack) )
	
	love.filesystem.write(mappack_path(mappack) .. "/settings.txt", s)
	notice.new("Saved settings!", notice.white, 2)
end

--DELIMITERS old: ,-;*=   new: ¤×¸·¨
--BLOCKDELIMITER = "¤"
--LAYERDELIMITER = "×"
--CATEGORYDELIMITER = "¸"
--MULTIPLYDELIMITER = "·"
--EQUALSIGN = "¨"
function savemtobject(objecttable: {{any}}, name: string|nil, file: string|nil)
	-- 1 read objects file
	file = file or "objects"
	
	local data: string = ""
	local datalines: {string} = {}
	if love.filesystem.getInfo(mappack_path(mappack) .. "/" .. file .. ".txt") then
		data = (love.filesystem.read(mappack_path(mappack) .. "/" .. file .. ".txt") or "") as string
	else
		data = ""
	end
	if name then
		data = data .. name .. "="
	else
		datalines = strsplit(data, "\n") as {string}
		data = data .. "object " .. tostring(#datalines) .. " } mtobjsize="
	end
	-- 2 append new object (with \n at the end!)
	local s: {any} = {}
	local m: number = 0
	local n: number = 0
	for i = 1, #objecttable do
		s = objecttable[i] -- x's
		for j = 1, #s do
			data = data .. tostring(s[j]) .. ","
			n = j
		end
		data = string.sub(data, 1, -2)
		data = data .. ":"
		m = i
	end
	data = string.sub(data, 1, -2)
	data = string.gsub(data, "mtobjsize", m .. " * " .. n)
	data = data .. "\n"
	love.filesystem.write(mappack_path(mappack) .. "/" .. file .. ".txt", data)
	mtjustsaved = 1
end

function objectclipboardcopy(objecttable: {{any}})
	local data: string = ""
	-- 2 append new object (with \n at the end!)
	local s: {any} = {}
	local m: number = 0
	local n: number = 0
	for i = 1, #objecttable do
		s = objecttable[i] -- x's
		for j = 1, #s do
			data = data .. tostring(s[j]) .. ","
			n = j
		end
		data = string.sub(data, 1, -2)
		data = data .. ":"
		m = i
	end
	data = string.sub(data, 1, -2)
	love.system.setClipboardText(data)
end

function moveline(file: string, line: any, direction: string): boolean|nil
	if not love.filesystem.getInfo(file) then
		return false
	end
	if direction ~= "up" then
		direction = "down"
	end
	
	-- cant move first one up
	if line == 1 and direction == "up" then
		return false
	end
	
	local linenum = tonumber(line) or 0
	
	local data: string = (love.filesystem.read(file) or "") as string
	data = string.sub(data, 1, -2)
	local newdata = ""
	local split1 = strsplit(data, "\n")
	
	-- cant move last one down
	if linenum == #split1 and direction == "down" then
		return false
	end
	
	local linetmp1 = split1[linenum as integer]
	local changeto: number = 0
	local linetmp2 = ""
	if direction == "up" then
		changeto = linenum-1
		linetmp2 = split1[changeto as integer] as string
	else
		changeto = linenum+1
		linetmp2 = split1[changeto as integer] as string
	end
	
	for i, _ in ipairs(split1) do
		if i == linenum then
			newdata = newdata .. linetmp2 .. "\n"
		elseif i == changeto then
			newdata = newdata .. (linetmp1 as string) .. "\n"
		else
			newdata = newdata .. (split1[i] as string) .. "\n"
		end
	end
	love.filesystem.write(file, newdata)
	return nil
end

function deleteline(file: string, line: any): boolean|nil
	if not love.filesystem.getInfo(file) then
		return false
	end
	local linenum = tonumber(line) or 0
	local data: string = (love.filesystem.read(file) or "") as string
	data = string.sub(data, 1, -2)
	local newdata = ""
	local split1 = strsplit(data, "\n")
	for i, _ in ipairs(split1) do
		if i ~= linenum then
			newdata = newdata .. (split1[i] as string) .. "\n"
		end
	end
	love.filesystem.write(file, newdata)
	return nil
end

function renameline(file: string, line: any, newName: string): boolean|nil
	if not love.filesystem.getInfo(file) then
		return false
	end
	local linenum = tonumber(line) or 0
	local data: string = (love.filesystem.read(file) or "") as string
	data = string.sub(data, 1, -2)
	local newdata = ""
	local split1 = strsplit(data, "\n")
	for i, _ in ipairs(split1) do
		if i == linenum then
			local split2 = strsplit(split1[i], "=") as {string}
			newdata = newdata .. (newName as string) .. "=" .. (split2[#split2] as string) .. "\n"
		else
			newdata = newdata .. (split1[i] as string) .. "\n"
		end
	end
	love.filesystem.write(file, newdata)
	return nil
end

function changeline(file: string, linenumber: any, newstring: string): boolean|nil
	if not love.filesystem.getInfo(file) then
		return false
	end
	local linenum = tonumber(linenumber) or 0
	local data: string = (love.filesystem.read(file) or "") as string
	data = string.sub(data, 1, -2)
	local newdata = ""
	local split1 = strsplit(data, "\n")
	for i, _ in ipairs(split1) do
		if i ~= linenum then
			newdata = newdata .. (split1[i] as string) .. "\n"
		else
			newdata = newdata .. newstring .. "\n"
		end
	end
	love.filesystem.write(file, newdata)
	return nil
end

function livesdecrease()
	if mariolivecount == false then
		return
	end
	
	mariolivecount = (mariolivecount as integer) - 1
	if mariolivecount == 0 then
		mariolivecount = false
		guielements["livesincrease"].x = 212 + 24
	else
		guielements["livesincrease"].x = 212 + string.len(tostring(mariolivecount))*8
	end
end

function livesincrease()
	if mariolivecount == false then
		mariolivecount = 1
	else
		mariolivecount = (mariolivecount as number) + 1
	end
	guielements["livesincrease"].x = 212 + string.len(tostring(mariolivecount))*8
end

function defaultbackground(i: number)
	background = {unpack(backgroundcolor[i as integer] as {any})} as {number}
	love.graphics.setBackgroundColor(unpack(background))
	
	guielements["colorsliderr"].internvalue = background[1] as number
	guielements["colorsliderg"].internvalue = background[2] as number
	guielements["colorsliderb"].internvalue = background[3] as number
end

function updatebackground()
	background[1] = guielements["colorsliderr"].internvalue
	background[2] = guielements["colorsliderg"].internvalue
	background[3] = guielements["colorsliderb"].internvalue
	love.graphics.setBackgroundColor(unpack(background))
end

function updatescrollfactor()
	scrollfactor = round(((guielements["scrollfactorscrollbar"].value as number)*3)^2, 2)
end

function updatefscrollfactor()
	fscrollfactor = round(((guielements["fscrollfactorscrollbar"].value as number)*3)^2, 2)
end

function reversescrollfactor(): number
	return math.sqrt(scrollfactor)/3
end

function reversefscrollfactor(): number
	return math.sqrt(fscrollfactor)/3
end

function closerightclickmenu()
	if rightclickm then
		local edittable = {{x=((rightclickm as rightclickmenu).tx as number), y=((rightclickm as rightclickmenu).ty as number)}}
		
		if selectionwidth then
			local selectionlist = selectiongettiles(selectionx, selectiony, selectionwidth, selectionheight)
			
			for i = 1, #selectionlist do
				local v = selectionlist[i]
				if (map[v.x as number][v.y as number][2] == map[((rightclickm as rightclickmenu).tx as number)][((rightclickm as rightclickmenu).ty as number)][2] or (tablecontains(groundlighttable, entitylist[map[((rightclickm as rightclickmenu).tx as number)][((rightclickm as rightclickmenu).ty as number)][2]].t) and tablecontains(groundlighttable, entitylist[map[v.x as number][v.y as number][2]].t))) and (v.x ~= (rightclickm as rightclickmenu).tx or v.y ~= (rightclickm as rightclickmenu).ty) then
					table.insert(edittable, {x=v.x, y=v.y})
				end
			end
		end
		
		for i = 1, #edittable do
			local x, y = edittable[i].x, edittable[i].y
			
			--remove all values until link or region
			while map[x][y][3] and map[x][y][3] ~= "link" and strsplit(tostring(map[x][y][3]), ":")[1] ~= "region" do
				table.remove(map[x][y], 3)
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
					table.insert(map[x][y], 3, value)
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
	for i = 3, #map[x][y] do
		local s = strsplit(tostring(map[x][y][i]), ":")
		if s[1] == t then
			j = i
			break
		end
	end
	
	if j then
		local s = strsplit(map[x][y][j] as string, ":")
		
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
		for i = 3, #map[x][y] do
			local s = strsplit(tostring(map[x][y][i]), ":")
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
		
		map[x][y][j] = (t as string) .. ":" .. tostring(rx) .. ":" .. tostring(ry) .. ":" .. (regiondragging as RegionDragging).width .. ":" .. (regiondragging as RegionDragging).height
		
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
			if (map[v.x][v.y][2] == map[x][y][2] or (entitylist[map[v.x][v.y][2]] and tablecontains(groundlighttable, entitylist[map[v.x][v.y][2]].t) and tablecontains(groundlighttable, entitylist[map[x][y][2]].t))) and (v.x ~= x or v.y ~= y) then
				table.insert(edittable, {x=v.x, y=v.y})
			end
		end
	end
	
	for j = 1, #edittable do
		local cx, cy = edittable[j].x, edittable[j].y
		
		local r = map[cx][cy]
		local i = 1
		
		while (r[i] ~= "link" or tostring(r[i+1]) ~= tostring(t)) and i < #r do
			i = i + 1
		end
		
		if i < #r then --found a match
			table.remove(map[cx][cy], i)
			table.remove(map[cx][cy], i)
			table.remove(map[cx][cy], i)
			table.remove(map[cx][cy], i)
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
				if (map[v.x][v.y][2] == map[startx][starty][2] or (entitylist[map[v.x][v.y][2]] and tablecontains(groundlighttable, entitylist[map[v.x][v.y][2]].t) and tablecontains(groundlighttable, entitylist[map[startx][starty][2]].t))) and (v.x ~= startx or v.y ~= starty) then
					table.insert(edittable, {x=v.x, y=v.y})
				end
			end
		end
		
		
		for i = 1, #edittable do
			local x, y = edittable[i].x, edittable[i].y
			if x ~= endx or y ~= endy then
				local r = map[endx][endy]
				
				--LIST OF NUMBERS THAT ARE ACCEPTED AS INPUTS (buttons, laserdetectors)
				if #r > 1 and tablecontains( outputsi, r[2] ) then
					r = map[x][y]
					
					local i = 1
					while (r[i] ~= "link" or r[i+1] ~= linktoolt) and i <= #r do
						i = i + 1
					end
					
					map[x][y][i] = "link"
					map[x][y][i+1] = linktoolt
					map[x][y][i+2] = endx
					map[x][y][i+3] = endy
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
			if inmap(cox, coy) and map[cox][coy][2] then
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

return { ported = true }
