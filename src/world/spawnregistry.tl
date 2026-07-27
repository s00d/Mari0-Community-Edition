-- Entity / item spawn dispatch tables (extracted from game.lua loadmap + spawnenemy + item).
-- Type strings must match entitylist / mappack / editor names exactly.
-- Handlers close over runtime globals (objects, constructors, map markers); safe to require early.

local unpack = rawget(_G, "unpack") or table.unpack

-- Early loadmap types (run before createobjects gate).
MAP_SPAWN_EARLY_HANDLERS = {}

MAP_SPAWN_EARLY_HANDLERS["spawn"] = function(x: number, y: number, r: {any})
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

MAP_SPAWN_EARLY_HANDLERS["textentity"] = function(x: number, y: number, r: {any})
	if not editormode then
		table.insert(textentities, textentity:new(x-1, y-1, r) as Entity)
	end
end

-- loadmap createobjects entity types (legacy elseif chain).
MAP_SPAWN_HANDLERS = {}

MAP_SPAWN_HANDLERS["warppipe"] = function(x: number, y: number, r: {any})
	table.insert(warpzonenumbers, {x, y, r[3]})
end

MAP_SPAWN_HANDLERS["manycoins"] = function(x: number, y: number, _: {any})
	map[x][y][3] = 7
end

MAP_SPAWN_HANDLERS["flag"] = function(x: number, y: number, _: {any})
	flagx = x-1
	flagy = y
end

MAP_SPAWN_HANDLERS["firestart"] = function(x: number, _: number, _: {any})
	firestartx = x
end

MAP_SPAWN_HANDLERS["flyingfishstart"] = function(x: number, _: number, _: {any})
	flyingfishstartx = x -- keep legacy single-zone vars for compatibility
	table.insert(flyingfishstarts, x)
end

MAP_SPAWN_HANDLERS["flyingfishend"] = function(x: number, _: number, _: {any})
	flyingfishendx = x
	table.insert(flyingfishends, x)
end

MAP_SPAWN_HANDLERS["bulletbillstart"] = function(x: number, _: number, _: {any})
	bulletbillstartx = x
	table.insert(bulletbillstarts, x)
end

MAP_SPAWN_HANDLERS["bulletbillend"] = function(x: number, _: number, _: {any})
	bulletbillendx = x
	table.insert(bulletbillends, x)
end

MAP_SPAWN_HANDLERS["axe"] = function(x: number, y: number, _: {any})
	axex = x
	axey = y
end

MAP_SPAWN_HANDLERS["lakitoend"] = function(x: number, _: number, _: {any})
	lakitoendx = x
end

MAP_SPAWN_HANDLERS["pipespawn"] = function(x: number, y: number, r: {any})
	if prevsublevel == (r[3] as number)-1 or (mariosublevel == (r[3] as number)-1 and blacktime == sublevelscreentime) then
		pipestartx = x
		pipestarty = y
	end
end

MAP_SPAWN_HANDLERS["gel"] = function(x: number, y: number, r: {any})
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

MAP_SPAWN_HANDLERS["checkpoint"] = function(x: number, y: number, r: {any})
	table.insert(objects["checkpoints"], checkpoint:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["mazestart"] = function(x: number, _: number, _: {any})
	if not tablecontains(mazestarts, x) then
		table.insert(mazestarts, x)
	end
end

MAP_SPAWN_HANDLERS["mazeend"] = function(x: number, _: number, _: {any})
	if not tablecontains(mazeends, x) then
		table.insert(mazeends, x)
	end
end

MAP_SPAWN_HANDLERS["emance"] = function(x: number, y: number, r: {any})
	table.insert(emancipationgrills, emancipationgrill:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["door"] = function(x: number, y: number, r: {any})
	table.insert(objects["door"], door:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["button"] = function(x: number, y: number, r: {any})
	table.insert(objects["button"], button:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["pushbutton"] = function(x: number, y: number, r: {any})
	table.insert(objects["pushbutton"], pushbutton:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["wallindicator"] = function(x: number, y: number, r: {any})
	table.insert(objects["wallindicator"], wallindicator:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["groundlightver"] = function(x: number, y: number, r: {any})
	table.insert(objects["groundlight"], groundlight:new(x, y, 1, r) as Entity)
end

MAP_SPAWN_HANDLERS["groundlighthor"] = function(x: number, y: number, r: {any})
	table.insert(objects["groundlight"], groundlight:new(x, y, 2, r) as Entity)
end

MAP_SPAWN_HANDLERS["groundlightupright"] = function(x: number, y: number, r: {any})
	table.insert(objects["groundlight"], groundlight:new(x, y, 3, r) as Entity)
end

MAP_SPAWN_HANDLERS["groundlightrightdown"] = function(x: number, y: number, r: {any})
	table.insert(objects["groundlight"], groundlight:new(x, y, 4, r) as Entity)
end

MAP_SPAWN_HANDLERS["groundlightdownleft"] = function(x: number, y: number, r: {any})
	table.insert(objects["groundlight"], groundlight:new(x, y, 5, r) as Entity)
end

MAP_SPAWN_HANDLERS["groundlightleftup"] = function(x: number, y: number, r: {any})
	table.insert(objects["groundlight"], groundlight:new(x, y, 6, r) as Entity)
end

MAP_SPAWN_HANDLERS["faithplate"] = function(x: number, y: number, r: {any})
	table.insert(objects["faithplate"], faithplate:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["laser"] = function(x: number, y: number, r: {any})
	table.insert(objects["laser"], laser:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["lightbridge"] = function(x: number, y: number, r: {any})
	table.insert(objects["lightbridge"], lightbridge:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["laserdetector"] = function(x: number, y: number, r: {any})
	table.insert(objects["laserdetector"], laserdetector:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["boxtube"] = function(x: number, y: number, r: {any})
	table.insert(objects["cubedispenser"], cubedispenser:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["walltimer"] = function(x: number, y: number, r: {any})
	table.insert(objects["walltimer"], walltimer:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["notgate"] = function(x: number, y: number, r: {any})
	table.insert(objects["notgate"], notgate:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["rsflipflop"] = function(x: number, y: number, r: {any})
	table.insert(objects["rsflipflop"], rsflipflop:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["orgate"] = function(x: number, y: number, r: {any})
	table.insert(objects["orgate"], orgate:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["andgate"] = function(x: number, y: number, r: {any})
	table.insert(objects["andgate"], andgate:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["musicentity"] = function(x: number, y: number, r: {any})
	table.insert(objects["musicentity"], musicentity:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["enemyspawner"] = function(x: number, y: number, r: {any})
	table.insert(objects["enemyspawner"], enemyspawner:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["squarewave"] = function(x: number, y: number, r: {any})
	table.insert(objects["squarewave"], squarewave:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["platformspawner"] = function(x: number, y: number, r: {any})
	table.insert(platformspawners, platformspawner:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["scaffold"] = function(x: number, y: number, r: {any})
	table.insert(objects["scaffold"], scaffold:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["box"] = function(x: number, y: number, _: {any})
	table.insert(objects["box"], box:new(x, y) as Entity)
end

MAP_SPAWN_HANDLERS["portal1"] = function(x: number, y: number, r: {any})
	table.insert(objects["portalent"], portalent:new(x, y, 1, r) as Entity)
end

MAP_SPAWN_HANDLERS["portal2"] = function(x: number, y: number, r: {any})
	table.insert(objects["portalent"], portalent:new(x, y, 2, r) as Entity)
end

MAP_SPAWN_HANDLERS["spring"] = function(x: number, y: number, _: {any})
	table.insert(objects["spring"], spring:new(x, y) as Entity)
end

MAP_SPAWN_HANDLERS["seesaw"] = function(x: number, y: number, r: {any})
	table.insert(seesaws, seesaw:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["ceilblocker"] = function(x: number, _: number, _: {any})
	table.insert(objects["ceilblocker"], ceilblocker:new(x) as Entity)
end

MAP_SPAWN_HANDLERS["funnel"] = function(x: number, y: number, r: {any})
	table.insert(objects["funnel"], funnel:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["regiontrigger"] = function(x: number, y: number, r: {any})
	table.insert(objects["regiontrigger"], regiontrigger:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["zgbooltrigger"] = function(x: number, y: number, r: {any})
	table.insert(objects["zgbooltrigger"], zgbooltrigger:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["zginttrigger"] = function(x: number, y: number, r: {any})
	table.insert(objects["zginttrigger"], zginttrigger:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["animationtrigger"] = function(x: number, y: number, r: {any})
	table.insert(objects["animationtrigger"], animationtrigger:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["pedestal"] = function(x: number, y: number, r: {any})
	table.insert(pedestals, pedestal:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["actionblock"] = function(x: number, y: number, _: {any})
	table.insert(objects["actionblock"], actionblock:new(x, y) as Entity)
end

MAP_SPAWN_HANDLERS["animatedtiletrigger"] = function(x: number, y: number, r: {any})
	table.insert(objects["animatedtiletrigger"], animatedtiletrigger:new(x, y, r) as Entity)
end

MAP_SPAWN_HANDLERS["delayer"] = function(x: number, y: number, r: {any})
	table.insert(objects["delayer"], delayer:new(x, y, r) as Entity)
end

-- Deferred spawnenemy entitylist types (not the enemies[] JSON path).
-- Return true only when this spawn should trigger the 5x1 neighbor enemy cascade.
ENEMY_SPAWN_HANDLERS = {}

ENEMY_SPAWN_HANDLERS["cheepcheep"] = function(x: number, y: number, r: {any}, allowenemy?: boolean): boolean
	if not allowenemy then
		return false
	end
	if math.random(2) == 1 then
		table.insert(objects["enemy"], enemy:new(x, y, "cheepcheepwhite", r) as Entity)
	else
		table.insert(objects["enemy"], enemy:new(x, y, "cheepcheepred", r) as Entity)
	end
	return true
end

ENEMY_SPAWN_HANDLERS["bowser"] = function(x: number, y: number, _: {any}, _?: boolean): boolean
	objects["bowser"][1] = bowser:new(x, y-1/16)
	return false
end

ENEMY_SPAWN_HANDLERS["castlefire"] = function(x: number, y: number, r: {any}, _?: boolean): boolean
	table.insert(objects["castlefire"], castlefire:new(x, y, r) as Entity)
	return false
end

ENEMY_SPAWN_HANDLERS["platform"] = function(x: number, y: number, r: {any}, _?: boolean): boolean
	table.insert(objects["platform"], platform:new(x, y, r) as Entity) --Platform
	return false
end

ENEMY_SPAWN_HANDLERS["platformfall"] = function(x: number, y: number, r: {any}, _?: boolean): boolean
	table.insert(objects["platform"], platform:new(x, y, {0, 0, r[3]}, "fall") as Entity) --Platform fall
	return false
end

ENEMY_SPAWN_HANDLERS["platformbonus"] = function(x: number, y: number, _: {any}, _?: boolean): boolean
	table.insert(objects["platform"], platform:new(x, y, {0, 0, 3}, "justright") as Entity)
	return false
end

ENEMY_SPAWN_HANDLERS["bulletbill"] = function(x: number, y: number, _: {any}, _?: boolean): boolean
	table.insert(rocketlaunchers, rocketlauncher:new(x, y) as Entity)
	return false
end

ENEMY_SPAWN_HANDLERS["geldispenser"] = function(x: number, y: number, r: {any}, _?: boolean): boolean
	table.insert(objects["geldispenser"], geldispenser:new(x, y, r) as Entity)
	return false
end

ENEMY_SPAWN_HANDLERS["upfire"] = function(x: number, y: number, r: {any}, _?: boolean): boolean
	table.insert(objects["upfire"], upfire:new(x, y, r) as Entity)
	return false
end

ENEMY_SPAWN_HANDLERS["panel"] = function(x: number, y: number, r: {any}, _?: boolean): boolean
	table.insert(objects["panel"], panel:new(x-1, y-1, r) as Entity)
	return false
end

-- Block-content item() types (enemiesdata[i] remains dynamic fallback).
ITEM_SPAWN_HANDLERS = {}

ITEM_SPAWN_HANDLERS["powerup"] = function(x: number, y: number, size: any)
	if size == 1 then
		table.insert(itemanimations, itemanimation:new(x, y, "mushroom") as Entity)
	else
		table.insert(itemanimations, itemanimation:new(x, y, "flower") as Entity)
	end
end

ITEM_SPAWN_HANDLERS["vine"] = function(x: number, y: number, _: any)
	table.insert(objects["vine"], vine:new(x, y) as Entity)
end

global function dispatch_map_entity_spawn(t: string, x: number, y: number, r: {any}, createobjects?: boolean, editormode?: boolean)
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

global function dispatch_enemy_entity_spawn(t: string, x: number, y: number, r: {any}, allowenemy?: boolean): boolean
	local h = ENEMY_SPAWN_HANDLERS[t]
	if h then
		return h(x, y, r, allowenemy) and true or false
	end
	return false
end

global function item(i: any, x: number, y: number, size?: any)
	local h = ITEM_SPAWN_HANDLERS[i as string]
	if h then
		h(x, y, size)
	elseif enemiesdata[i] then
		table.insert(itemanimations, itemanimation:new(x, y, i) as Entity)
	end
end

global function count_spawn_handlers(t: {any:any}): number
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end
