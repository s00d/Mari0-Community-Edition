--[[
  ENGINE FAULT checks (no LÖVE):
  - quest compile produces valid animation JSON with giveweapon
  - memleak respects enemy cap 60
  - nullptr drawable toggles with fake pointingangle
]]

local root = ...
if not root or root == "" then
	local info = debug.getinfo(1, "S").source
	if info:sub(1, 1) == "@" then
		root = info:sub(2):match("^(.*)/tests/enginefault_checks%.lua$") or "."
	else
		root = "."
	end
end

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	package.path,
}, ";")

local failed = 0
local function check(name, cond, detail)
	if cond then
		print("OK   " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (" — " .. tostring(detail)) or ""))
	end
end

local JSON = require("dkjson")

-- --- quest compile ---
do
	local cmd = string.format('lua "%s/scripts/compile_enginefault_quests.lua" "%s"', root, root)
	local ok = os.execute(cmd)
	-- lua 5.1 returns exit status differently than 5.2+
	local exit_ok = (ok == true or ok == 0)
	check("quest compile exit", exit_ok, tostring(ok))

	local reward = root .. "/mappacks/enginefault/animations/q_ticket_4471_reward.json"
	local f = io.open(reward, "r")
	check("reward json exists", f ~= nil, reward)
	if f then
		local body = f:read("*a")
		f:close()
		local data, _, err = JSON.decode(body)
		check("reward json parse", data ~= nil, err)
		if data then
			check("reward has triggers", type(data.triggers) == "table" and #data.triggers > 0)
			check("reward has actions", type(data.actions) == "table" and #data.actions > 0)
			local has_give = false
			for _, a in ipairs(data.actions) do
				if a[1] == "giveweapon" and a[2] == "freezeray" then
					has_give = true
				end
			end
			check("reward giveweapon freezeray", has_give)
		end
	end

	local intro = root .. "/mappacks/enginefault/animations/intro_1_1.json"
	local fi = io.open(intro, "r")
	check("intro_1_1 exists", fi ~= nil)
	if fi then fi:close() end
end

-- --- mappack files ---
do
	local function exists(rel)
		local f = io.open(root .. "/" .. rel, "r")
		if f then f:close() return true end
		return false
	end
	check("settings.txt", exists("mappacks/enginefault/settings.txt"))
	check("tiles.png", exists("mappacks/enginefault/tiles.png"))
	check("icon.png", exists("mappacks/enginefault/icon.png"))
	check("1-1.txt", exists("mappacks/enginefault/1-1.txt"))
	check("1-2.txt", exists("mappacks/enginefault/1-2.txt"))
	check("1-3.txt", exists("mappacks/enginefault/1-3.txt"))
	check("nullptr.json", exists("mappacks/enginefault/enemies/nullptr.json"))
	check("offbyone.json", exists("mappacks/enginefault/enemies/offbyone.json"))
	check("memleak.json", exists("mappacks/enginefault/enemies/memleak.json"))
	check("quests.lua", exists("mappacks/enginefault/quests.lua"))
end

-- --- enemy moves ---
players = 1
playerobjs = {
	{
		x = 5, y = 5, width = 0.75, height = 0.75,
		speedx = 0, speedy = 0, pointingangle = 0, dead = false,
	},
}
inmap = function() return false end
map = {}
tilequads = {}
objects = { enemy = {} }
earthquake = 0
playsound = function() end
enemy = {
	new = function(_, x, y, t)
		return {
			x = x, y = y, t = t, width = 0.75, height = 0.75,
			speedx = 0, speedy = 0, customscale = 1,
			mlgrow = 0.08, mlsplit = 0.01, mlmax = 3, mltimer = 0,
			truffleshufflespeed = 2, truffleshuffleacceleration = 8,
			animationdirection = "left", falling = false,
		}
	end,
}

local ok, err = pcall(require, "entities.enemymoves")
check("load enemymoves", ok, err)
if ok then
	check("nullptr registered", type(ENEMY_MOVES.nullptr) == "function")
	check("offbyone registered", type(ENEMY_MOVES.offbyone) == "function")
	check("memleak registered", type(ENEMY_MOVES.memleak) == "function")

	-- nullptr drawable toggle
	local e = {
		x = 8, y = 5, width = 0.75, height = 0.75,
		speedx = 0, speedy = 0, npspeed = 3.2, npcone = 0.55,
		drawable = true, gravity = 0,
	}
	-- aim away (pointingangle 0 → aim up-ish via -sin/-cos); enemy to the right
	playerobjs[1].x = 5
	playerobjs[1].y = 5
	playerobjs[1].pointingangle = 0 -- aim vector (-0,-1) = up; enemy at +x → not aimed
	ENEMY_MOVES.nullptr(e, 1 / 60)
	check("nullptr hidden when not aimed", e.drawable == false, tostring(e.drawable))

	-- aim right toward enemy: pointingangle = -pi/2 → ax=1, ay=0
	playerobjs[1].pointingangle = -math.pi / 2
	ENEMY_MOVES.nullptr(e, 1 / 60)
	check("nullptr visible when aimed", e.drawable == true, tostring(e.drawable))

	-- memleak cap
	objects.enemy = {}
	for i = 1, 59 do
		objects.enemy[i] = { t = "memleak" }
	end
	local leak = {
		x = 3, y = 3, width = 0.75, height = 0.75, t = "memleak",
		speedx = -1, speedy = 0, mlgrow = 0, mlsplit = 0.001, mlmax = 3,
		mltimer = 1, truffleshufflespeed = 2, truffleshuffleacceleration = 8,
		animationdirection = "left", falling = false, customscale = 1,
	}
	objects.enemy[60] = leak
	local before = #objects.enemy
	for _ = 1, 30 do
		ENEMY_MOVES.memleak(leak, 1 / 60)
	end
	check("memleak respects cap 60", #objects.enemy <= 60, tostring(#objects.enemy))
	check("memleak did not grow past cap", #objects.enemy == before, tostring(#objects.enemy))

	-- under cap can spawn
	objects.enemy = { leak }
	leak.mltimer = 1
	leak.mlsplit = 0.001
	ENEMY_MOVES.memleak(leak, 1 / 60)
	check("memleak spawns under cap", #objects.enemy >= 2, tostring(#objects.enemy))

	-- offbyone offset
	local ob = {
		x = 3, y = 3, width = 0.75, height = 0.75,
		speedx = -2, speedy = 0, offsetX = 6,
		truffleshufflespeed = 2, truffleshuffleacceleration = 8,
		animationdirection = "right", falling = false,
	}
	ENEMY_MOVES.offbyone(ob, 1 / 60)
	check("offbyone shifts draw +16", ob.offsetX == 22, tostring(ob.offsetX))
	ob.animationdirection = "left"
	ENEMY_MOVES.offbyone(ob, 1 / 60)
	check("offbyone shifts draw -16", ob.offsetX == -10, tostring(ob.offsetX))
end

-- giveweapon branch present in animation source
do
	local f = io.open(root .. "/src/world/animation.tl", "r")
	check("animation.tl readable", f ~= nil)
	if f then
		local s = f:read("*a")
		f:close()
		check("giveweapon action branch", s:find('v%[1%] == "giveweapon"', 1, false) ~= nil
			or s:find('== "giveweapon"', 1, true) ~= nil)
	end
end

return failed
