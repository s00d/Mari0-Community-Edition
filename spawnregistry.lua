-- Entity / item spawn dispatch tables (extracted from game.lua loadmap + spawnenemy + item).
-- Type strings must match entitylist / mappack / editor names exactly.
-- Handlers close over runtime globals (objects, constructors, map markers); safe to require early.

local unpack = rawget(_G, "unpack") or table.unpack

-- Early loadmap types (run before createobjects gate).
MAP_SPAWN_EARLY_HANDLERS = {}

MAP_SPAWN_EARLY_HANDLERS["spawn"] = function(x, y, r)
	local r2 = {unpack(r)}
	table.remove(r2, 1)
	table.remove(r2, 1)

	--compatibility for Mari0
	if #r2 == 0 then
		startx = {x, x, x, x, x}
		starty = {y, y, y, y, y}
	else
		if r2[1] == "true" then --all
			startx = {x, x, x, x, x}
			starty = {y, y, y, y, y}
		else
			for i = 1, 5 do
				if r2[i+1] == "true" then
					startx[i] = x
					starty[i] = y
				end
			end
		end
	end
end

MAP_SPAWN_EARLY_HANDLERS["textentity"] = function(x, y, r)
	if not editormode then
		table.insert(textentities, textentity:new(x-1, y-1, r))
	end
end

-- loadmap createobjects entity types (legacy elseif chain).
MAP_SPAWN_HANDLERS = {}

MAP_SPAWN_HANDLERS["warppipe"] = function(x, y, r)
	table.insert(warpzonenumbers, {x, y, r[3]})
end

MAP_SPAWN_HANDLERS["manycoins"] = function(x, y, r)
	map[x][y][3] = 7
end

MAP_SPAWN_HANDLERS["flag"] = function(x, y, r)
	flagx = x-1
	flagy = y
end

MAP_SPAWN_HANDLERS["firestart"] = function(x, y, r)
	firestartx = x
end

MAP_SPAWN_HANDLERS["flyingfishstart"] = function(x, y, r)
	flyingfishstartx = x -- keep legacy single-zone vars for compatibility
	table.insert(flyingfishstarts, x)
end

MAP_SPAWN_HANDLERS["flyingfishend"] = function(x, y, r)
	flyingfishendx = x
	table.insert(flyingfishends, x)
end

MAP_SPAWN_HANDLERS["bulletbillstart"] = function(x, y, r)
	bulletbillstartx = x
	table.insert(bulletbillstarts, x)
end

MAP_SPAWN_HANDLERS["bulletbillend"] = function(x, y, r)
	bulletbillendx = x
	table.insert(bulletbillends, x)
end

MAP_SPAWN_HANDLERS["axe"] = function(x, y, r)
	axex = x
	axey = y
end

MAP_SPAWN_HANDLERS["lakitoend"] = function(x, y, r)
	lakitoendx = x
end

MAP_SPAWN_HANDLERS["pipespawn"] = function(x, y, r)
	if prevsublevel == r[3]-1 or (mariosublevel == r[3]-1 and blacktime == sublevelscreentime) then
		pipestartx = x
		pipestarty = y
	end
end

MAP_SPAWN_HANDLERS["gel"] = function(x, y, r)
	if tilequads[map[x][y][1]]:getproperty("collision", x, y) then
		if r[4] == "true" then
			map[x][y]["gels"]["left"] = r[3]
		end
		if r[5] == "true" then
			map[x][y]["gels"]["top"] = r[3]
		end
		if r[6] == "true" then
			map[x][y]["gels"]["right"] = r[3]
		end
		if r[7] == "true" then
			map[x][y]["gels"]["bottom"] = r[3]
		end
	end
end

MAP_SPAWN_HANDLERS["checkpoint"] = function(x, y, r)
	table.insert(objects["checkpoints"], checkpoint:new(x, y, r))
end

MAP_SPAWN_HANDLERS["mazestart"] = function(x, y, r)
	if not tablecontains(mazestarts, x) then
		table.insert(mazestarts, x)
	end
end

MAP_SPAWN_HANDLERS["mazeend"] = function(x, y, r)
	if not tablecontains(mazeends, x) then
		table.insert(mazeends, x)
	end
end

MAP_SPAWN_HANDLERS["emance"] = function(x, y, r)
	table.insert(emancipationgrills, emancipationgrill:new(x, y, r))
end

MAP_SPAWN_HANDLERS["door"] = function(x, y, r)
	table.insert(objects["door"], door:new(x, y, r))
end

MAP_SPAWN_HANDLERS["button"] = function(x, y, r)
	table.insert(objects["button"], button:new(x, y, r))
end

MAP_SPAWN_HANDLERS["pushbutton"] = function(x, y, r)
	table.insert(objects["pushbutton"], pushbutton:new(x, y, r))
end

MAP_SPAWN_HANDLERS["wallindicator"] = function(x, y, r)
	table.insert(objects["wallindicator"], wallindicator:new(x, y, r))
end

MAP_SPAWN_HANDLERS["groundlightver"] = function(x, y, r)
	table.insert(objects["groundlight"], groundlight:new(x, y, 1, r))
end

MAP_SPAWN_HANDLERS["groundlighthor"] = function(x, y, r)
	table.insert(objects["groundlight"], groundlight:new(x, y, 2, r))
end

MAP_SPAWN_HANDLERS["groundlightupright"] = function(x, y, r)
	table.insert(objects["groundlight"], groundlight:new(x, y, 3, r))
end

MAP_SPAWN_HANDLERS["groundlightrightdown"] = function(x, y, r)
	table.insert(objects["groundlight"], groundlight:new(x, y, 4, r))
end

MAP_SPAWN_HANDLERS["groundlightdownleft"] = function(x, y, r)
	table.insert(objects["groundlight"], groundlight:new(x, y, 5, r))
end

MAP_SPAWN_HANDLERS["groundlightleftup"] = function(x, y, r)
	table.insert(objects["groundlight"], groundlight:new(x, y, 6, r))
end

MAP_SPAWN_HANDLERS["faithplate"] = function(x, y, r)
	table.insert(objects["faithplate"], faithplate:new(x, y, r))
end

MAP_SPAWN_HANDLERS["laser"] = function(x, y, r)
	table.insert(objects["laser"], laser:new(x, y, r))
end

MAP_SPAWN_HANDLERS["lightbridge"] = function(x, y, r)
	table.insert(objects["lightbridge"], lightbridge:new(x, y, r))
end

MAP_SPAWN_HANDLERS["laserdetector"] = function(x, y, r)
	table.insert(objects["laserdetector"], laserdetector:new(x, y, r))
end

MAP_SPAWN_HANDLERS["boxtube"] = function(x, y, r)
	table.insert(objects["cubedispenser"], cubedispenser:new(x, y, r))
end

MAP_SPAWN_HANDLERS["walltimer"] = function(x, y, r)
	table.insert(objects["walltimer"], walltimer:new(x, y, r))
end

MAP_SPAWN_HANDLERS["notgate"] = function(x, y, r)
	table.insert(objects["notgate"], notgate:new(x, y, r))
end

MAP_SPAWN_HANDLERS["rsflipflop"] = function(x, y, r)
	table.insert(objects["rsflipflop"], rsflipflop:new(x, y, r))
end

MAP_SPAWN_HANDLERS["orgate"] = function(x, y, r)
	table.insert(objects["orgate"], orgate:new(x, y, r))
end

MAP_SPAWN_HANDLERS["andgate"] = function(x, y, r)
	table.insert(objects["andgate"], andgate:new(x, y, r))
end

MAP_SPAWN_HANDLERS["musicentity"] = function(x, y, r)
	table.insert(objects["musicentity"], musicentity:new(x, y, r))
end

MAP_SPAWN_HANDLERS["enemyspawner"] = function(x, y, r)
	table.insert(objects["enemyspawner"], enemyspawner:new(x, y, r))
end

MAP_SPAWN_HANDLERS["squarewave"] = function(x, y, r)
	table.insert(objects["squarewave"], squarewave:new(x, y, r))
end

MAP_SPAWN_HANDLERS["platformspawner"] = function(x, y, r)
	table.insert(platformspawners, platformspawner:new(x, y, r))
end

MAP_SPAWN_HANDLERS["scaffold"] = function(x, y, r)
	table.insert(objects["scaffold"], scaffold:new(x, y, r))
end

MAP_SPAWN_HANDLERS["box"] = function(x, y, r)
	table.insert(objects["box"], box:new(x, y))
end

MAP_SPAWN_HANDLERS["portal1"] = function(x, y, r)
	table.insert(objects["portalent"], portalent:new(x, y, 1, r))
end

MAP_SPAWN_HANDLERS["portal2"] = function(x, y, r)
	table.insert(objects["portalent"], portalent:new(x, y, 2, r))
end

MAP_SPAWN_HANDLERS["spring"] = function(x, y, r)
	table.insert(objects["spring"], spring:new(x, y))
end

MAP_SPAWN_HANDLERS["seesaw"] = function(x, y, r)
	table.insert(seesaws, seesaw:new(x, y, r))
end

MAP_SPAWN_HANDLERS["ceilblocker"] = function(x, y, r)
	table.insert(objects["ceilblocker"], ceilblocker:new(x))
end

MAP_SPAWN_HANDLERS["funnel"] = function(x, y, r)
	table.insert(objects["funnel"], funnel:new(x, y, r))
end

MAP_SPAWN_HANDLERS["regiontrigger"] = function(x, y, r)
	table.insert(objects["regiontrigger"], regiontrigger:new(x, y, r))
end

MAP_SPAWN_HANDLERS["zgbooltrigger"] = function(x, y, r)
	table.insert(objects["zgbooltrigger"], zgbooltrigger:new(x, y, r))
end

MAP_SPAWN_HANDLERS["zginttrigger"] = function(x, y, r)
	table.insert(objects["zginttrigger"], zginttrigger:new(x, y, r))
end

MAP_SPAWN_HANDLERS["animationtrigger"] = function(x, y, r)
	table.insert(objects["animationtrigger"], animationtrigger:new(x, y, r))
end

MAP_SPAWN_HANDLERS["pedestal"] = function(x, y, r)
	table.insert(pedestals, pedestal:new(x, y, r))
end

MAP_SPAWN_HANDLERS["actionblock"] = function(x, y, r)
	table.insert(objects["actionblock"], actionblock:new(x, y, r))
end

MAP_SPAWN_HANDLERS["animatedtiletrigger"] = function(x, y, r)
	table.insert(objects["animatedtiletrigger"], animatedtiletrigger:new(x, y, r))
end

MAP_SPAWN_HANDLERS["delayer"] = function(x, y, r)
	table.insert(objects["delayer"], delayer:new(x, y, r))
end

-- Deferred spawnenemy entitylist types (not the enemies[] JSON path).
-- Return true only when this spawn should trigger the 5x1 neighbor enemy cascade.
ENEMY_SPAWN_HANDLERS = {}

ENEMY_SPAWN_HANDLERS["cheepcheep"] = function(x, y, r, allowenemy)
	if not allowenemy then
		return false
	end
	if math.random(2) == 1 then
		table.insert(objects["enemy"], enemy:new(x, y, "cheepcheepwhite", r))
	else
		table.insert(objects["enemy"], enemy:new(x, y, "cheepcheepred", r))
	end
	return true
end

ENEMY_SPAWN_HANDLERS["bowser"] = function(x, y, r, allowenemy)
	objects["bowser"][1] = bowser:new(x, y-1/16)
	return false
end

ENEMY_SPAWN_HANDLERS["castlefire"] = function(x, y, r, allowenemy)
	table.insert(objects["castlefire"], castlefire:new(x, y, r))
	return false
end

ENEMY_SPAWN_HANDLERS["platform"] = function(x, y, r, allowenemy)
	table.insert(objects["platform"], platform:new(x, y, r)) --Platform
	return false
end

ENEMY_SPAWN_HANDLERS["platformfall"] = function(x, y, r, allowenemy)
	table.insert(objects["platform"], platform:new(x, y, {0, 0, r[3]}, "fall")) --Platform fall
	return false
end

ENEMY_SPAWN_HANDLERS["platformbonus"] = function(x, y, r, allowenemy)
	table.insert(objects["platform"], platform:new(x, y, {0, 0, 3}, "justright"))
	return false
end

ENEMY_SPAWN_HANDLERS["bulletbill"] = function(x, y, r, allowenemy)
	table.insert(rocketlaunchers, rocketlauncher:new(x, y))
	return false
end

ENEMY_SPAWN_HANDLERS["geldispenser"] = function(x, y, r, allowenemy)
	table.insert(objects["geldispenser"], geldispenser:new(x, y, r))
	return false
end

ENEMY_SPAWN_HANDLERS["upfire"] = function(x, y, r, allowenemy)
	table.insert(objects["upfire"], upfire:new(x, y, r))
	return false
end

ENEMY_SPAWN_HANDLERS["panel"] = function(x, y, r, allowenemy)
	table.insert(objects["panel"], panel:new(x-1, y-1, r))
	return false
end

-- Block-content item() types (enemiesdata[i] remains dynamic fallback).
ITEM_SPAWN_HANDLERS = {}

ITEM_SPAWN_HANDLERS["powerup"] = function(x, y, size)
	if size == 1 then
		table.insert(itemanimations, itemanimation:new(x, y, "mushroom"))
	else
		table.insert(itemanimations, itemanimation:new(x, y, "flower"))
	end
end

ITEM_SPAWN_HANDLERS["vine"] = function(x, y, size)
	table.insert(objects["vine"], vine:new(x, y))
end

function dispatch_map_entity_spawn(t, x, y, r, createobjects, editormode)
	local early = MAP_SPAWN_EARLY_HANDLERS[t]
	if early then
		early(x, y, r)
		return
	end
	if createobjects and not editormode then
		local h = MAP_SPAWN_HANDLERS[t]
		if h then
			h(x, y, r)
		end
	end
end

function dispatch_enemy_entity_spawn(t, x, y, r, allowenemy)
	local h = ENEMY_SPAWN_HANDLERS[t]
	if h then
		return h(x, y, r, allowenemy) and true or false
	end
	return false
end

function item(i, x, y, size)
	local h = ITEM_SPAWN_HANDLERS[i]
	if h then
		h(x, y, size)
	elseif enemiesdata[i] then
		table.insert(itemanimations, itemanimation:new(x, y, i))
	end
end

function count_spawn_handlers(t)
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end
