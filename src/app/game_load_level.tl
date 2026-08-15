--[[ game_load level / map lifecycle ]]

require "world.level"
require "assets.spritebatch_util"
require "world.tile_spritebatch"

global function game_load(suspended?: any)
	
	checkpointx = {}
	checkpointy = {}
	checkpointsub = false
	
	scrollfactor = 0
	fscrollfactor = 0
	love.graphics.setBackgroundColor(backgroundcolor[1])

	
	--LINK STUFF
	mariocoincount = 0
	marioscore = 0
	globools = {}
	globints = {}
	firstunder100 = true
	--get mariolives
	mariolivecount = 3
	mappackendless = false
	endlessseed = 0
	local start_world: number|string|nil = nil
	local start_level: number|nil = nil
	local settings_path = mappack_path(mappack) .. "/settings.txt"
	if love.filesystem.getInfo(settings_path) then
		local s = love.filesystem.read(settings_path)
		local s1 = strsplit(s, "\n")
		for j = 1, #s1 do
			local s2 = strsplit(s1[j], "=")
			if s2[1] == "lives" then
				mariolivecount = tonumber(s2[2])
			elseif s2[1] == "endless" and (s2[2] == "true" or s2[2] == "1") then
				mappackendless = true
			elseif s2[1] == "seed" and tonumber(s2[2]) then
				endlessseed = tonumber(s2[2]) as number
			elseif s2[1] == "metroid" and (s2[2] == "true" or s2[2] == "1") then
				rawset(_G, "_metroid_settings_flag", true)
			elseif s2[1] == "maxhp" and tonumber(s2[2]) then
				globintSH("maxhp", "set", tonumber(s2[2]))
			elseif s2[1] == "start" and s2[2] then
				local sw, sl = string.match(s2[2], "^(%w+)%-(%d+)$")
				if sw and sl then
					start_world = tonumber(sw) or sw
					start_level = tonumber(sl)
				end
			end
		end
	end

	if metroid_try_load_mappack then
		metroid_try_load_mappack(mappack)
	end
	
	if mariolivecount == 0 then
		mariolivecount = false
	end
	
	mariolives = {}
	for i = 1, players do
		mariolives[i] = (mariolivecount or 0) as number
	end
	
	mariosizes = {}
	for i = 1, players do
		mariosizes[i] = 1
	end
	
	autoscroll = true
	autoscrollx = true
	autoscrolly = true
	minimapdragging = false
	
	jumpitems = { "mushroom", "oneup" }
	
	-- Online match: host already chose mappack/world/level via start packet.
	if not (Net and Net.is_online and Net.is_online()) then
		marioworld = start_world or 1
		mariolevel = start_level or 1
		mariosublevel = 0
		respawnsublevel = 0
	else
		marioworld = marioworld or 1
		mariolevel = mariolevel or 1
		mariosublevel = mariosublevel or 0
		respawnsublevel = mariosublevel or 0
	end
	
	session.objects = nil
	if suspended == true then
		continuegame()
	elseif suspended then
		marioworld = suspended as number|string
	end
	
	musicname = nil
	
	--FINALLY LOAD THE DAMN LEVEL
	levelscreen_load("initial")
end


-- Draw / update phases live in Teal (build/app/game_*.lua).
require "app.game_update"
require "app.game_draw"

-- Defensive: AE/mappack load paths have hit `mario` nil at player spawn (boot
-- require missed / global clobber). Re-require once; never index a nil class.
local function create_mario_player(x: number, y: number, i: any, animation: any, size: any, playertype: any): mario
	if not rawget(_G, "mario") or not (mario as Dyn).new then
		require "entities.mario"
	end
	if not rawget(_G, "mario") or not (mario as Dyn).new then
		error("mario class missing during loadlevel (entities.mario failed to register)")
	end
	return mario:new(x, y, i, animation, size, playertype)
end

global function loadlevel(level: string|number): boolean
	-- Do NOT full-collect here: that sets a low GC threshold, then map/entity
	-- alloc balloons debt → multi-second pause ~5s into gameplay. Collect after load.
	-- Pump events between heavy chunks so Love 12 + Metal cannot stall the window.
	if keepalive_pump then
		keepalive_pump()
	end
	love.audio.stop()
	animationsystem_load()
	
	if replaysystem then
		for i = 1, #replaydata do
			replaytimer[i] = 0
			replayi[i] = 1
			replaychar[i] = characters.mario
		end
	end

	local sublevel = false
	if type(level) == "number" then
		sublevel = true
	end
	
	if sublevel then
		prevsublevel = mariosublevel as number|boolean
		mariosublevel = level as number
		if level ~= 0 then
			level = tostring(marioworld) .. "-" .. tostring(mariolevel) .. "_" .. tostring(level)
		else
			level = tostring(marioworld) .. "-" .. tostring(mariolevel)
		end
	else
		local s = strsplit(level as string, "_")
		if s[2] then
			mariosublevel = (tonumber(s[2] as string) or 0) as number
		else
			mariosublevel = 0
		end
		prevsublevel = false
		mariotime = 400
		
		--check for checkpoint!
		if checkpointsub then
			mariosublevel = checkpointsub as number
			
			if checkpointsub ~= 0 then
				level = tostring(marioworld) .. "-" .. tostring(mariolevel) .. "_" .. tostring(checkpointsub)
			else
				level = tostring(marioworld) .. "-" .. tostring(mariolevel)
			end
		end
	end
	
	--MISC VARS
	everyonedead = false
	levelfinished = false
	coinanimation = 1
	flagx = false
	levelfinishtype = nil
	firestartx = false
	firestarted = false
	firedelay = math.random(4)
	flyingfishdelay = 1
	flyingfishstarted = false
	flyingfishstartx = false
	flyingfishendx = false
	flyingfishstarts = {}
	flyingfishends = {}
	flyingfishzones = {}
	bulletbilldelay = 1
	bulletbillstarted = false
	bulletbillstartx = false
	bulletbillendx = false
	bulletbillstarts = {}
	bulletbillends = {}
	bulletbillzones = {}
	firetimer = firedelay
	flyingfishtimer = flyingfishdelay
	bulletbilltimer = bulletbilldelay
	axex = false
	axey = false
	lakitoendx = false
	lakitoend = false
	noupdate = false
	minimapdragging = false
	autoscroll = true
	autoscrollx = true
	autoscrolly = true
	session.xscroll = 0
	repeatX = 0
	lastrepeat = 0
	session.ylookmodifier = 0
	displaywarpzonetext = false
	mazestarts = {}
	mazeends = {}
	mazesolved = {}
	mazesolved[0] = true
	mazeinprogress = false
	screenshake(0)
	sunrot = 0
	gelcannontimer = 0
	pausemenuselected = 1
	coinblocktimers = {}
	
	portaldelay = {}
	for i = 1, players do
		portaldelay[i] = 0
	end
	levelweapons = {} as {string}
	
	--class tables
	coinblockanimations = {}
	scrollingscores = {}
	scrollingtexts = {}
	portalparticles = {}
	portalprojectiles = {}
	emancipationgrills = {}
	platformspawners = {}
	rocketlaunchers = {}
	userects = {}
	blockdebristable = {}
	fireworks = {}
	seesaws = {}
	bubbles = {}
	rainbooms = {}
	emancipateanimations = {}
	emancipationfizzles = {}
	textentities = {}
	pedestals = {}
	dialogboxes = {}
	miniblocks = {}
	inventory = {}
	for i = 1, 9 do
		inventory[i] = {}
	end
	mccurrentblock = 1
	itemanimations = {}
	
	blockbouncetimer = {}
	blockbouncex = {}
	blockbouncey = {}
	blockbouncecontent = {}
	blockbouncecontent2 = {}
	warpzonenumbers = {}
	textentities = {}
	
	session.portals = {}
	
	reset_level_state()
	
	startx = {3, 3, 3, 3, 3}
	starty = {13, 13, 13, 13, 13}
	pipestartx = nil
	pipestarty = nil
	local animation: any = nil
	
	session.enemiesspawned = {}
	
	intermission = false
	haswarpzone = false
	underwater = false
	level_mapmode = false
	mapmode_zoom = 1
	mapmode_pad_x = 0
	mapmode_pad_y = 0
	bonusstage = false
	custombackground = false
	customforeground = false
	mariotimelimit = 400
	spriteset = 1
	
	-- Metroid: load rooms for this level (rooms/<level>.json) before map spawn/bootstrap
	if metroid_try_load_level then
		metroid_try_load_level(mappack as string, tostring(level))
	elseif metroid_try_load_mappack then
		metroid_try_load_mappack(mappack as string)
	end

	--LOAD THE MAP
	local needs_to_be_saved = false
	if loadmap(tostring(level), true) == false then --make one up
		needs_to_be_saved = true
		session.mapwidth = width
		background = {unpack(backgroundcolor[1] as {any})} as {any:number}
		session.mapheight = 15
		portalsavailable = {true, true}
		musicname = "overworld.ogg"
		session.map = {}
		session.coinmap = {}
		for x = 1, width do
			session.map[x] = {}
			session.coinmap[x] = {}
			for y = 1, session.mapheight do
				if y > 13 then
					session.map[x][y] = {2}
					session.objects["tile"][tilekey(x, y)] = tile:new(x-1, y-1)
					init_map_cell_gels(session.map[x][y])
					session.map[x][y]["portaloverride"] = {}
				else
					session.map[x][y] = {1}
					init_map_cell_gels(session.map[x][y])
					session.map[x][y]["portaloverride"] = {}
				end
			end
		end
		
		
		create_tile_spritebatches(nil)
	end

	if keepalive_pump then
		keepalive_pump()
	end
	
	enemies_load()

	if keepalive_pump then
		keepalive_pump()
	end
	
	session.objects["screenboundary"] = {}
	session.objects["screenboundary"]["left"] = screenboundary:new(0)
	
	session.objects["screenboundary"]["right"] = screenboundary:new(session.mapwidth)
	
	if flagx then
		session.objects["screenboundary"]["flag"] = screenboundary:new((flagx as number)+6/16)
	end
	
	if axex then
		session.objects["screenboundary"]["axe"] = screenboundary:new(axex as number)
	end
	
	if intermission then
		animation = "intermission"
	end
	
	if not sublevel then
		mariotime = mariotimelimit
	end
	
	--Maze setup
	--check every block between every start/end pair to see how many gates it contains
	if #mazestarts == #mazeends then
		mazegates = {}
		for i = 1, #mazestarts do
			local maxgate: number = 1
			for x = mazestarts[i], mazeends[i] do
				for y = 1, session.mapheight do
					if session.map[x][y][2] and entitylist[session.map[x][y][2]] and entitylist[session.map[x][y][2]].t == "mazegate" then
						local gate = tonumber(session.map[x][y][3]) or 0
						if gate > maxgate then
							maxgate = gate
						end
					end
				end
			end
			mazegates[i] = maxgate
		end
	else
		print("Mazenumber doesn't fit!")
	end
	
	--check if it's a bonusstage (boooooooonus!)
	if bonusstage then
		animation = "vinestart"
	end
		
	--set startx to pipestart
	if pipestartx then
		local psx = (pipestartx as number) - 1
		local psy = pipestarty as number
		startx = {psx, psx, psx, psx, psx}
		starty = {psy, psy, psy, psy, psy}
		--check if startpos is a colliding block
		if tilequads[session.map[startx[1] as number][starty[1] as number][1]]:getproperty("collision", startx[1] as number, starty[1] as number) then
			animation = "pipeup"
		end
	end
	
	--set starts to checkpoint
	if not sublevel and checkpointsub then
		for i = 1, 5 do
			if checkpointx[i] then
				startx[i] = checkpointx[i]
			end
			if checkpointy[i] then
				starty[i] = checkpointy[i]
			end
		end
	end
	
	--Adjust start X scroll
	session.xscroll = (startx[1] as number)-scrollingleftcomplete-2
	if session.xscroll > session.mapwidth - width then
		session.xscroll = session.mapwidth - width
	end
	
	if session.xscroll < 0 then
		session.xscroll = 0
	end
	
	--and Y too
	session.yscroll = (starty[1] as number)-height+downscrollborder
	if session.yscroll > session.mapheight - height - 1 then
		session.yscroll = session.mapheight - height - 1
	end
	
	if session.yscroll < 0 then
		session.yscroll = 0
	end
	
	spawnrestrictions = {}

	--Clear spawn area from enemies
	for i = 1, #startx do
		if startx[i] == checkpointx[i] and starty[i] == checkpointy[i] then
			add_spawn_restriction(startx[i] as number, starty[i] as number)
		end
	end
	
	--add the players
	local mul = 0.5
	if mariosublevel ~= 0 or prevsublevel ~= false then
		mul = 2/16
	end

	if Weapons and session.playerobjs then
		for i = 1, (players or 0) do
			if session.playerobjs[i] then
				Weapons.release(session.playerobjs[i], "levelend")
			end
		end
	end
	
	session.playerobjs = {}
	session.objects["player"] = session.playerobjs
	local spawns = {}
	for i = 1, players do
		local animation = animation
		
		local astartx: any = nil
		local astarty: any = nil
		if i > 4 then
			astartx = startx[5]
			astarty = starty[5]
		else
			astartx = startx[i]
			astarty = starty[i]
		end
		
		if astartx then
			local add = -6/16
			for _, v in ipairs(spawns as {any}) do
				local sv = v as {string:any}
				if sv.x == astartx and sv.y == astarty then
					add = add + mul
				end
			end
			
			table.insert(spawns, {x=astartx, y=astarty})
			
			local spawn_y_off = level_mapmode and 0 or -1
			session.playerobjs[i] = create_mario_player((astartx as number)+add, (astarty as number)+spawn_y_off, i, animation, mariosizes[i], playertype)
			physics_world_upsert(session.playerobjs[i], "player", i)
		else
			session.playerobjs[i] = create_mario_player(1.5 + (i-1)*mul-6/16+1.5, 13, i, animation, mariosizes[i], playertype)
			physics_world_upsert(session.playerobjs[i], "player", i)
		end
	end
	
	if level_mapmode and session.playerobjs[1] then
		mapmode_update_view(session.playerobjs[1])
		mapmode_snap_to_start(session.playerobjs[1])
	else
		mapmode_zoom = 1
		mapmode_pad_x = 0
		mapmode_pad_y = 0
	end
	
	--ADD ENEMIES ON START SCREEN
	if editormode == false and not level_mapmode then
		if metroidmode and metroid_bootstrap_from_player then
			metroid_bootstrap_from_player()
		else
			local xtodo = width+1
			if session.mapwidth < width+1 then
				xtodo = session.mapwidth
			end
			local ytodo = height+1
			if session.mapheight < height+1 then
				ytodo = session.mapheight
			end
			for x = math.floor(session.xscroll), math.floor(session.xscroll)+xtodo do
				for y = math.floor(session.yscroll), math.floor(session.yscroll)+ytodo do
					spawnenemy(x, y)
				end
			end
		end
	end
	if metroidmode and session.playerobjs then
		for i = 1, players do
			if session.playerobjs[i] then
				if metroid_reapply_abilities then metroid_reapply_abilities(session.playerobjs[i]) end
				if metroid_apply_hp_to_player then metroid_apply_hp_to_player(session.playerobjs[i]) end
			end
		end
	end
	
	--load editor (play mode: skip heavy rightclick menu rebuild)
	editor_load()

	if keepalive_pump then
		keepalive_pump()
	end
	
	updateranges()
	
	spritebatch_portal_catchup = false
	generatespritebatch(0, 0)
	updatespritebatch()
	-- Incremental reclaim after load (full collect freezes transition on Metal).
	if gcpace_after_load then
		gcpace_after_load()
	end
	if keepalive_pump then
		keepalive_pump()
	end
	if physics_world_refresh then
		physics_world_refresh()
	end
	return needs_to_be_saved
end

global function startlevel(levelstart?: any)
	
	if Gamestate then
		Gamestate.set("game")
	else
		gamestate = "game"
	end
	(require("app.love_frame") as LoveFrameModule).request_skip_update()
	
	--background
	love.graphics.setBackgroundColor(unpack(background as {any}))
	
	--PLAY BGM
	if intermission == false then
		playmusic()
	else
		playsound("intermission")
	end
	
	if replaysystem and levelstart then
		livereplaydata = {{}}
		livereplaydelay = {0}
		livereplaystored = {{}}
	end
end

global function changemapwidth(width: number)
	
	if width > (session.mapwidth as number) then
		for x = (session.mapwidth as number)+1, width do
			session.map[x] = {}
			for y = 1, (session.mapheight as number)-2 do
				session.map[x][y] = {1}
				init_map_cell_gels(session.map[x][y])
				session.map[x][y].portaloverride = {}
				physics_world_set_tile(tilekey(x, y), nil)
			end
		
			for y = (session.mapheight as number)-1, session.mapheight as number do
				session.map[x][y] = {2}
				physics_world_set_tile(tilekey(x, y), tile:new(x-1, y-1))
				init_map_cell_gels(session.map[x][y])
				session.map[x][y].portaloverride = {}
			end
		end
	end

	session.mapwidth = width
	session.objects["screenboundary"]["right"].x = session.mapwidth as number
	physics_world_upsert_slot("screenboundary", "right", session.objects["screenboundary"]["right"])
	if session.playerobjs[1].x > (session.mapwidth as number) then
		session.playerobjs[1].x = (session.mapwidth as number)-1
	end
	
	generatespritebatch(0, 0)
	updatespritebatch()
end

global function changemapheight(height: number)
	
	if height > (session.mapheight as number) then
		for x = 1, session.mapwidth as number do
			for y = (session.mapheight as number)+1, height do
				session.map[x][y] = {currenttile}
				init_map_cell_gels(session.map[x][y])
				session.map[x][y].portaloverride = {}
				
				if tilequads[currenttile]:getproperty("collision", x, y) then
					physics_world_set_tile(tilekey(x, y), tile:new(x-1, y-1, 1, 1, true))
				else
					physics_world_set_tile(tilekey(x, y), nil)
				end
			end
		end
	end
	
	session.mapheight = height
	
	for key, v in pairs(session.objects["screenboundary"] as {any:any}) do
		(v as Entity).height = 1000+(session.mapheight as number)
		physics_world_upsert_slot("screenboundary", key, v)
	end
	
	if session.playerobjs[1].y > (session.mapheight as number) then
		session.playerobjs[1].y = (session.mapheight as number)-1
	end
	
	generatespritebatch(0, 0)
	updatespritebatch()
end

global function invalidate_spritebatch_after_portal_teleport()
	-- Full-map batches: scroll offset only — no rebuild on portal camera catch-up.
	spritebatch_portal_catchup = true
end

-- Mark dirty; flush once via updatespritebatch (end of game_update / after load).
global function generatespritebatch(_scroll_dx: integer, _scroll_dy: integer)
	spritebatch_dirty = true
end

global function updatespritebatch()
	if not spritebatch_dirty then
		return
	end
	spritebatch_dirty = false
	tile_spritebatch_rebuild()
end


global function nextlevel()
	if not levelfinished then
		return
	end
	
	if testlevel then
		if editor_pass_clearcheck then editor_pass_clearcheck() end
		editormode = true
		testlevel = false
		loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel) .. ((mariosublevel as number) > 0 and ("_" .. tostring(mariosublevel)) or ""))
		startlevel()
		editor_apply_test_restore(false)
		return
	end
	
	love.audio.stop()

	mariolevel = (mariolevel as number) + 1
	if not love.filesystem.getInfo(mappack_level_path(mappack as string, marioworld, mariolevel)) then
		mariolevel = 1
		marioworld = (marioworld as number) + 1
	end
	mariosublevel = 0
	levelscreen_load("next")
end

global function warpzone(w: any, l: any, sub?: any)
	
	love.audio.stop()
	mariolevel = l as number
	marioworld = w as number|string
	mariosublevel = tonumber(sub) or 0
	prevsublevel = false
	
	-- minus 1 world glitch just because I can.
	if not displaywarpzonetext and w == 4 and l == 1 then
		marioworld = "M"
	end

	levelscreen_load("next")
end

global function hitrightside()
	if haswarpzone then
		for _, v in pairs(session.objects["enemy"] as {any:any}) do
			if (v as Entity).t == "plant" then	
				(v as Entity).kill = true
			end
		end
		displaywarpzonetext = true
	end
end

global function endgame()
	if testlevel then
		if editor_pass_clearcheck then editor_pass_clearcheck() end
		marioworld = testlevelworld
		mariolevel = testlevellevel
		testlevel = false
		editormode = true
		loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel))
		startlevel()
		editor_apply_test_restore(false)
	else
		love.audio.stop()
		gamefinished = true
		saveconfig()
		menu_load()
	end
end

global function respawnplayers()
	if mariolivecount == false then
		return
	end
	for i = 1, players do
		if mariolives[i] == 1 and session.playerobjs.dead then
			session.playerobjs[i]:respawn()
		end
	end
end

