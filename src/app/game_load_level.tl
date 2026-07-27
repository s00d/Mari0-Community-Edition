--[[ game_load level / map lifecycle ]]

require "world.level"
require "assets.spritebatch_util"
require "world.paths"

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
	local settings_path = mappack_path(mappack) .. "/settings.txt"
	if love.filesystem.getInfo(settings_path) then
		local s = love.filesystem.read(settings_path)
		local s1 = strsplit(s, "\n")
		for j = 1, #s1 do
			local s2 = strsplit(s1[j], "=")
			if s2[1] == "lives" then
				mariolivecount = tonumber(s2[2])
			end
		end
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
	
	jumpitems = { "mushroom", "oneup" }
	
	marioworld = 1
	mariolevel = 1
	mariosublevel = 0
	respawnsublevel = 0
	
	objects = nil
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

global function loadlevel(level: string|number): boolean
	collectgarbage("collect")
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
	xscroll = 0
	repeatX = 0
	lastrepeat = 0
	ylookmodifier = 0
	displaywarpzonetext = false
	mazestarts = {}
	mazeends = {}
	mazesolved = {}
	mazesolved[0] = true
	mazeinprogress = false
	earthquake = 0
	sunrot = 0
	gelcannontimer = 0
	pausemenuselected = 1
	coinblocktimers = {}
	
	portaldelay = {}
	for i = 1, players do
		portaldelay[i] = 0
	end
	
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
	
	portals = {}
	
	level_reset_ctx()
	
	startx = {3, 3, 3, 3, 3}
	starty = {13, 13, 13, 13, 13}
	pipestartx = nil
	pipestarty = nil
	local animation: any = nil
	
	enemiesspawned = {}
	
	intermission = false
	haswarpzone = false
	underwater = false
	bonusstage = false
	custombackground = false
	customforeground = false
	mariotimelimit = 400
	spriteset = 1
	
	--LOAD THE MAP
	local needs_to_be_saved = false
	if loadmap(tostring(level), true) == false then --make one up
		needs_to_be_saved = true
		mapwidth = width
		background = {unpack(backgroundcolor[1] as {any})} as {any:number}
		mapheight = 15
		portalsavailable = {true, true}
		musicname = "overworld.ogg"
		map = {}
		coinmap = {}
		for x = 1, width do
			map[x] = {}
			coinmap[x] = {}
			for y = 1, mapheight do
				if y > 13 then
					map[x][y] = {2}
					objects["tile"][tilekey(x, y)] = tile:new(x-1, y-1)
					map[x][y]["gels"] = {}
					map[x][y]["portaloverride"] = {}
				else
					map[x][y] = {1}
					map[x][y]["gels"] = {}
					map[x][y]["portaloverride"] = {}
				end
			end
		end
		
		
		create_tile_spritebatches()
	end
	
	
	enemies_load()
	
	objects["screenboundary"] = {}
	objects["screenboundary"]["left"] = screenboundary:new(0)
	
	objects["screenboundary"]["right"] = screenboundary:new(mapwidth)
	
	if flagx then
		objects["screenboundary"]["flag"] = screenboundary:new((flagx as number)+6/16)
	end
	
	if axex then
		objects["screenboundary"]["axe"] = screenboundary:new(axex as number)
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
				for y = 1, mapheight do
					if map[x][y][2] and entitylist[map[x][y][2]] and entitylist[map[x][y][2]].t == "mazegate" then
						local gate = tonumber(map[x][y][3]) or 0
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
		if tilequads[map[startx[1] as number][starty[1] as number][1]]:getproperty("collision", startx[1] as number, starty[1] as number) then
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
	xscroll = (startx[1] as number)-scrollingleftcomplete-2
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
	
	spawnrestrictions = {}
	
	--Clear spawn area from enemies
	for i = 1, #startx do
		if startx[i] == checkpointx[i] and starty[i] == checkpointy[i] then
			table.insert(spawnrestrictions, {startx[i], starty[i]})
		end
	end
	
	--add the players
	local mul = 0.5
	if mariosublevel ~= 0 or prevsublevel ~= false then
		mul = 2/16
	end
	
	playerobjs = {}
	objects["player"] = playerobjs
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
			
			playerobjs[i] = mario:new((astartx as number)+add, (astarty as number)-1, i, animation, mariosizes[i], playertype)
		else
			playerobjs[i] = mario:new(1.5 + (i-1)*mul-6/16+1.5, 13, i, animation, mariosizes[i], playertype)
		end
	end
	
	--ADD ENEMIES ON START SCREEN
	if editormode == false then
		local xtodo = width+1
		if mapwidth < width+1 then
			xtodo = mapwidth
		end
		
		local ytodo = height+1
		if mapheight < height+1 then
			ytodo = mapheight
		end
			
		for x = math.floor(xscroll), math.floor(xscroll)+xtodo do
			for y = math.floor(yscroll), math.floor(yscroll)+ytodo do
				spawnenemy(x, y)
			end
		end
	end
	
	--load editor
	editor_load()
	
	updateranges()
	
	generatespritebatch()
	local Ctx = require("core.ctx")
	local lvl = Ctx.level
	if lvl ~= nil then
		local level = lvl as Level
		level:pull_globals()
		level:push_globals()
	end
	if session then session:sync_session_from_globals() end
	return needs_to_be_saved
end

global function startlevel(levelstart?: any)
	
	if session then
		session:set_gamestate("game")
	else
		gamestate = "game"
		if Gamestate then Gamestate.set("game") end
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
	
	if width > (mapwidth as number) then
		for x = (mapwidth as number)+1, width do
			map[x] = {}
			for y = 1, (mapheight as number)-2 do
				map[x][y] = {1}
				map[x][y].gels = {}
				map[x][y].portaloverride = {}
				objects["tile"][tilekey(x, y)] = nil
			end
		
			for y = (mapheight as number)-1, mapheight as number do
				map[x][y] = {2}
				objects["tile"][tilekey(x, y)] = tile:new(x-1, y-1)
				map[x][y].gels = {}
				map[x][y].portaloverride = {}
			end
		end
	end

	mapwidth = width
	objects["screenboundary"]["right"].x = mapwidth as number
	
	if playerobjs[1].x > (mapwidth as number) then
		playerobjs[1].x = (mapwidth as number)-1
	end
	
	generatespritebatch()
end

global function changemapheight(height: number)
	
	if height > (mapheight as number) then
		for x = 1, mapwidth as number do
			for y = (mapheight as number)+1, height do
				map[x][y] = {currenttile}
				map[x][y].gels = {}
				map[x][y].portaloverride = {}
				
				if tilequads[currenttile]:getproperty("collision", x, y) then
					objects["tile"][tilekey(x, y)] = tile:new(x-1, y-1, 1, 1, true)
				else
					objects["tile"][tilekey(x, y)] = nil
				end			
			end
		end
	end
	
	mapheight = height
	
	for _, v in pairs(objects["screenboundary"] as {any:any}) do
		(v as Entity).height = 1000+(mapheight as number)
	end
	
	if playerobjs[1].y > (mapheight as number) then
		playerobjs[1].y = (mapheight as number)-1
	end
	
	generatespritebatch()
end

global function generatespritebatch()
	smbspritebatch:clear()
	smbspritebatchfront:clear()
	
	portalspritebatch:clear()
	portalspritebatchfront:clear()
	
	if customtiles then
		customspritebatch:clear()
		customspritebatchfront:clear()
	end
	
	if modcustomtiles then
		for i = 1, modcustomtiles as number do
			(modcustomspritebatch[i as number] as SpriteBatch):clear()
			(modcustomspritebatchfront[i as number] as SpriteBatch):clear()
		end
	end
	
	local xtodraw: number = 0
	if (mapwidth as number) < width+1 then
		xtodraw = math.ceil(mapwidth as number)
	else
		if (mapwidth as number) > width and xscroll < (mapwidth as number)-width then
			xtodraw = math.ceil(width+1)
		else
			xtodraw = math.ceil(width)
		end
	end
	
	local ytodraw: number = 0
	if (mapheight as number) < height+1 then
		ytodraw = math.ceil(mapheight as number)
	else
		if (mapheight as number) > height and yscroll < (mapheight as number)-height then
			ytodraw = height+1
		else
			ytodraw = height
		end
	end
	
	local lmap = map
	
	local flooredxscroll: number = 0
	if xscroll >= 0 then
		flooredxscroll = math.floor(xscroll)
	else
		flooredxscroll = math.ceil(xscroll)
	end
	
	local flooredyscroll: number = 0
	if yscroll >= 0 then
		flooredyscroll = math.floor(yscroll)
	else
		flooredyscroll = math.ceil(yscroll)
	end

	local bounce_batch_skip = build_blockbounce_lookup(blockbouncex, blockbouncey) as {any:any}
	
	for y = 0, ytodraw+1 do
		for x = 1, xtodraw do
			if inmap(flooredxscroll+x, math.min(flooredyscroll+y+1, mapheight as number)) then
				local _ = 0
				
				local draw = true
				local coy = math.min(flooredyscroll+y+1, mapheight as number)
				if bounce_batch_skip[tilekey(flooredxscroll+x, coy)] then
					draw = false
				end	
				if draw == true then
					local cox = flooredxscroll+x
					local t = lmap[cox][coy]
					
					local tilenumber = t[1] as number
					
					if not tilequads[tilenumber]:getproperty("foreground", cox, coy) then
						if tilenumber ~= 0 and tilequads[tilenumber]:getproperty("invisible", cox, coy) == false and tilequads[tilenumber]:getproperty("coinblock", cox, coy) == false then
							if tilenumber <= smbtilecount then
								smbspritebatch:add( tilequads[tilenumber]:quad(), (x-1)*16*scale, ((y)*16-8)*scale, 0, scale, scale )
							elseif tilenumber <= smbtilecount+portaltilecount then
								portalspritebatch:add( tilequads[tilenumber]:quad(), (x-1)*16*scale, ((y)*16-8)*scale, 0, scale, scale )
							elseif tilenumber <= smbtilecount+portaltilecount+customtilecount then
								customspritebatch:add( tilequads[tilenumber]:quad(), (x-1)*16*scale, ((y)*16-8)*scale, 0, scale, scale )
							elseif tilenumber <= smbtilecount+portaltilecount+customtilecount+(modcustomtilecount[modcustomtiles as integer] or 0) then
								for i = 1, modcustomtiles as integer do
									if tilenumber <= smbtilecount+portaltilecount+customtilecount+modcustomtilecount[i] then
										(modcustomspritebatch[i as number] as SpriteBatch):add( tilequads[tilenumber]:quad(), (x-1)*16*scale, ((y)*16-8)*scale, 0, scale, scale )
										break
									end
								end
							end								
						end
					else
						if tilenumber ~= 0 and tilequads[tilenumber]:getproperty("invisible", cox, coy) == false and tilequads[tilenumber]:getproperty("coinblock", cox, coy) == false then
							if tilenumber <= smbtilecount then
								smbspritebatchfront:add( tilequads[tilenumber]:quad(), (x-1)*16*scale, ((y)*16-8)*scale, 0, scale, scale )
							elseif tilenumber <= smbtilecount+portaltilecount then
								portalspritebatchfront:add( tilequads[tilenumber]:quad(), (x-1)*16*scale, ((y)*16-8)*scale, 0, scale, scale )
							elseif tilenumber <= smbtilecount+portaltilecount+customtilecount then
								customspritebatchfront:add( tilequads[tilenumber]:quad(), (x-1)*16*scale, ((y)*16-8)*scale, 0, scale, scale )
							elseif tilenumber <= smbtilecount+portaltilecount+customtilecount+(modcustomtilecount[modcustomtiles as integer] or 0) then
								for i = 1, modcustomtiles as integer do
									if tilenumber <= smbtilecount+portaltilecount+customtilecount+modcustomtilecount[i] then
										(modcustomspritebatch[i as number] as SpriteBatch):add( tilequads[tilenumber]:quad(), (x-1)*16*scale, ((y)*16-8)*scale, 0, scale, scale )
										break
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	--Unbind spritebatches
end

global function nextlevel()
	if not levelfinished then
		return
	end
	
	if testlevel then
		editormode = true
		testlevel = false
		loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel) .. ((mariosublevel as number) > 0 and ("_" .. tostring(mariosublevel)) or ""))
		startlevel()
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

global function warpzone(w: any, l: any)
	
	love.audio.stop()
	mariolevel = l as number
	marioworld = w as number|string
	mariosublevel = 0
	prevsublevel = false
	
	-- minus 1 world glitch just because I can.
	if not displaywarpzonetext and w == 4 and l == 1 then
		marioworld = "M"
	end
	
	levelscreen_load("next")
end

global function hitrightside()
	if haswarpzone then
		for _, v in pairs(objects["enemy"] as {any:any}) do
			if (v as Entity).t == "plant" then	
				(v as Entity).kill = true
			end
		end
		displaywarpzonetext = true
	end
end

global function endgame()
	if testlevel then
		marioworld = testlevelworld
		mariolevel = testlevellevel
		testlevel = false
		editormode = true
		loadlevel(tostring(marioworld) .. "-" .. tostring(mariolevel))
		startlevel()
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
		if mariolives[i] == 1 and playerobjs.dead then
			playerobjs[i]:respawn()
		end
	end
end

