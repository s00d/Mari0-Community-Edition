--[[
  Spawn registry structural + mock dispatch checks (no LÖVE).
]]

local root = ... or "."
local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

dofile(root .. "/spawnregistry.lua")

local map_keys = {
	"warppipe", "manycoins", "flag", "firestart", "flyingfishstart", "flyingfishend",
	"bulletbillstart", "bulletbillend", "axe", "lakitoend", "pipespawn", "gel",
	"checkpoint", "mazestart", "mazeend", "emance", "door", "button", "pushbutton",
	"wallindicator", "groundlightver", "groundlighthor", "groundlightupright",
	"groundlightrightdown", "groundlightdownleft", "groundlightleftup", "faithplate",
	"laser", "lightbridge", "laserdetector", "boxtube", "walltimer", "notgate",
	"rsflipflop", "orgate", "andgate", "musicentity", "enemyspawner", "squarewave",
	"platformspawner", "scaffold", "box", "portal1", "portal2", "spring", "seesaw",
	"ceilblocker", "funnel", "regiontrigger", "zgbooltrigger", "zginttrigger",
	"animationtrigger", "pedestal", "actionblock", "animatedtiletrigger", "delayer",
}

local enemy_keys = {
	"cheepcheep", "bowser", "castlefire", "platform", "platformfall", "platformbonus",
	"bulletbill", "geldispenser", "upfire", "panel",
}

local item_keys = { "powerup", "vine" }

check("map spawn handler count", count_spawn_handlers(MAP_SPAWN_HANDLERS) == #map_keys,
	tostring(count_spawn_handlers(MAP_SPAWN_HANDLERS)) .. " vs " .. #map_keys)
check("early spawn handler count", count_spawn_handlers(MAP_SPAWN_EARLY_HANDLERS) == 2)
check("enemy spawn handler count", count_spawn_handlers(ENEMY_SPAWN_HANDLERS) == #enemy_keys)
check("item spawn handler count", count_spawn_handlers(ITEM_SPAWN_HANDLERS) == #item_keys)

for _, k in ipairs(map_keys) do
	check("map handler " .. k, type(MAP_SPAWN_HANDLERS[k]) == "function")
end
for _, k in ipairs({"spawn", "textentity"}) do
	check("early handler " .. k, type(MAP_SPAWN_EARLY_HANDLERS[k]) == "function")
end
for _, k in ipairs(enemy_keys) do
	check("enemy handler " .. k, type(ENEMY_SPAWN_HANDLERS[k]) == "function")
end
for _, k in ipairs(item_keys) do
	check("item handler " .. k, type(ITEM_SPAWN_HANDLERS[k]) == "function")
end

-- Unknown type: no-op (same as legacy elseif fallthrough)
do
	local ok, err = pcall(function()
		dispatch_map_entity_spawn("nosuch_entity_type", 1, 1, {1, 99}, true, false)
	end)
	check("unknown map type no-op", ok, err)
	ok, err = pcall(function()
		local w = dispatch_enemy_entity_spawn("nosuch_enemy_type", 1, 1, {1, 99}, true)
		assert(w == false)
	end)
	check("unknown enemy type returns false", ok, err)
end

-- item() unknown without enemiesdata: no-op
do
	enemiesdata = {}
	itemanimations = {}
	objects = { vine = {} }
	local ok, err = pcall(function()
		item("star_not_registered", 3, 4, 1)
	end)
	check("unknown item no-op", ok and #itemanimations == 0, err)
end

-- item powerup / enemiesdata fallback with mocks
do
	local anims = {}
	itemanimations = anims
	itemanimation = {
		new = function(_, x, y, name)
			return {x = x, y = y, name = name}
		end,
	}
	item("powerup", 2, 5, 1)
	check("powerup size1 mushroom", #anims == 1 and anims[1].name == "mushroom")
	item("powerup", 2, 5, 2)
	check("powerup size2 flower", #anims == 2 and anims[2].name == "flower")

	enemiesdata = { goomba = {}, flower = {}, star = {}, ["1up"] = {} }
	item("goomba", 1, 1, 1)
	item("star", 1, 1, 1)
	item("1up", 1, 1, 1)
	check("enemiesdata item fallback", anims[3].name == "goomba" and anims[4].name == "star" and anims[5].name == "1up")
end

-- map spawn early: spawn marker sets startx/starty
do
	startx, starty = {0,0,0,0,0}, {0,0,0,0,0}
	MAP_SPAWN_EARLY_HANDLERS["spawn"](8, 9, {1, 2})
	check("spawn empty r2 all starts", startx[1] == 8 and starty[3] == 9)

	flagx, flagy = nil, nil
	objects = { box = {} }
	box = { new = function(_, x, y) return {x = x, y = y} end }
	dispatch_map_entity_spawn("box", 4, 6, {1, 2}, true, false)
	check("map box spawn", #objects["box"] == 1 and objects["box"][1].x == 4)
	dispatch_map_entity_spawn("box", 4, 6, {1, 2}, true, true)
	check("map box skipped in editor", #objects["box"] == 1)
	dispatch_map_entity_spawn("flag", 10, 3, {1, 2}, true, false)
	check("map flag spawn", flagx == 9 and flagy == 3)
	dispatch_map_entity_spawn("door", 1, 1, {1, 2}, false, false)
	check("map skipped without createobjects", true) -- no error; door ctor absent
end

-- enemy cheepcheep respects allowenemy; bowser does not (legacy)
do
	local enemies_spawned = {}
	objects = { enemy = enemies_spawned, bowser = {} }
	enemy = {
		new = function(_, x, y, name, r)
			return {x = x, y = y, name = name}
		end,
	}
	bowser = {
		new = function(_, x, y)
			return {x = x, y = y}
		end,
	}
	math.random = function() return 1 end
	check("cheep blocked without allow", dispatch_enemy_entity_spawn("cheepcheep", 1, 1, {}, false) == false)
	check("cheep none spawned", #enemies_spawned == 0)
	check("cheep allowed", dispatch_enemy_entity_spawn("cheepcheep", 2, 3, {}, true) == true)
	check("cheep white when random1", enemies_spawned[1].name == "cheepcheepwhite")
	check("bowser without allow still spawns", dispatch_enemy_entity_spawn("bowser", 5, 5, {}, false) == false)
	check("bowser object set", objects["bowser"][1] ~= nil)
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
