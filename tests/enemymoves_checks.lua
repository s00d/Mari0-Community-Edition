--[[
  Enemy movement table checks (no LÖVE).
  Finite speeds / no NaN over 600 frames; splitter base case; drybones freeze;
  latcher shake-off; populate determinism.
]]

local root = ...
if not root or root == "" then
	local info = debug.getinfo(1, "S").source
	if info:sub(1, 1) == "@" then
		root = info:sub(2):match("^(.*)/tests/enemymoves_checks%.lua$") or "."
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

-- stubs
players = 1
playerobjs = {
	{
		x = 5, y = 5, width = 0.75, height = 0.75,
		speedx = 0, speedy = 0, pointingangle = 0, dead = false,
	},
}
inmap = function() return false end
inrange = function() return false end
map = {}
tilequads = {}
objects = { enemy = {}, fireball = {}, lightbridgebody = {} }
screenshake = function() end
screenshake_amp = function() return 0 end
playsound = function() end
fireball = {
	new = function(_, x, y, dir, owner)
		return { x = x, y = y, speedx = 0, speedy = 0, gravity = 0, owner = owner }
	end,
}
enemy = {
	new = function(_, x, y, t)
		return {
			x = x, y = y, t = t, width = 1, height = 1, splitlevel = 0,
			hopforce = 9, customscale = 1, speedx = 0, speedy = 0,
		}
	end,
}

local ok, err = pcall(require, "entities.enemymoves")
check("load enemymoves", ok, err)
if not ok then
	return failed
end

check("ENEMY_MOVES table", type(ENEMY_MOVES) == "table")

local needed = {
	"truffleshuffle", "shell", "follow", "piston", "wiggle", "verticalwiggle",
	"rocket", "squid", "targety", "flyvertical", "flyhorizontal",
	"turret", "sine", "shy", "bones", "slam", "charge", "hop", "trap", "hover", "latch",
	"nullptr", "offbyone", "memleak",
}
for _, name in ipairs(needed) do
	check("move registered " .. name, type(ENEMY_MOVES[name]) == "function")
end

local function stub_enemy(extra)
	local e = {
		x = 3, y = 3, width = 0.75, height = 0.75,
		speedx = -2, speedy = 0, startx = 3, starty = 3,
		truffleshufflespeed = 2, truffleshuffleacceleration = 8,
		falling = false, animationdirection = "left",
		gravity = 0, active = true, stompable = true, killsonsides = true,
		turretrange = 9, turretcone = 0.5, turretwindup = 0.1,
		turretburst = 2, turretburstdelay = 0.05, turretcooldown = 0.2,
		sineamp = 1, sinefreq = 2, sinespeed = 2,
		shyspeed = 3, shyaccel = 6, shycone = 0.6,
		bonesrevive = 4, bonesdown = false, bonestimer = 0,
		slamtrigger = 3.5, slamaccel = 90, slammax = 22, slamrest = 0.7, slamrise = 2,
		chargeaggro = 8, chargewindup = 0.1, chargespeed = 13, chargestun = 0.2,
		hopforce = 9, hopdelay = 0.05, hopdrift = 2,
		trapreach = 12, trapcooldown = 1, trapspeed = 10,
		hoverspeed = 2, hoveraccel = 3, hoverkeep = 3, hoverfire = 99, hoverlead = 0.3, shotspeed = 9,
		latchspeed = 4, latchdrain = 9, latchshake = 6, latchwindow = 1,
		splitlevel = 2, splitcount = 2, splitscale = 0.6,
		wiggledistance = 2, wigglespeed = 1,
		verticalwiggledistance = 2, verticalwigglespeed = 1,
		rocketdistance = 5,
		squidfallspeed = 1, squidacceleration = 5, squidxspeed = 3, squidupspeed = 3,
		squiddowndistance = 1, squidstate = "idle",
		targety = 3, targetyspeed = 2,
		flyingtimer = 0, flyingtime = 7, flyingdistance = 2,
		func = function(_, t) return math.sin(t * math.pi * 2) end,
		pistonspeedx = 0, pistonspeedy = 1, pistondistx = 0, pistondisty = -1,
		pistonextendtime = 1, pistonretracttime = 1, pistontimer = 0, pistonstate = "retracting",
		followspeed = 2, distancetime = 0, followspace = 2,
		small = false,
	}
	if extra then
		for k, v in pairs(extra) do e[k] = v end
	end
	return e
end

for name, fn in pairs(ENEMY_MOVES) do
	local e = stub_enemy({ movement = name })
	local okrun = true
	for _ = 1, 600 do
		local okf, errf = pcall(fn, e, 1 / 60)
		if not okf then
			okrun = false
			check(name .. " runs", false, errf)
			break
		end
	end
	if okrun then
		check(name .. " speedx finite", e.speedx == e.speedx and math.abs(e.speedx) < 200, tostring(e.speedx))
		check(name .. " speedy finite", e.speedy == e.speedy and math.abs(e.speedy) < 200, tostring(e.speedy))
		check(name .. " no nan y", e.y == e.y)
	end
end

-- splitter level 0: no spawn storm
do
	objects.enemy = {}
	local e = stub_enemy({ t = "splitter", splitlevel = 0, splitcount = 2 })
	local before = #objects.enemy
	enemymove_splitter_die(e)
	check("splitter lvl0 no spawn", #objects.enemy == before, tostring(#objects.enemy))
	e.splitlevel = 2
	enemymove_splitter_die(e)
	check("splitter lvl2 spawns", #objects.enemy == before + 2, tostring(#objects.enemy))
end

-- drybones frozen does not revive
do
	local e = stub_enemy({ bonesdown = true, bonestimer = 0, bonesrevive = 1, frozen = true })
	for _ = 1, 120 do
		ENEMY_MOVES.bones(e, 1 / 60)
	end
	check("drybones frozen no revive", e.bonesdown == true and e.bonestimer == 0)
	e.frozen = false
	for _ = 1, 120 do
		ENEMY_MOVES.bones(e, 1 / 60)
	end
	check("drybones unfrozen revives", e.bonesdown == false)
end

-- latcher shake count
do
	local pl = playerobjs[1]
	pl.speedx = 0
	local e = stub_enemy({ latchedto = pl, latchshake = 4, latchwindow = 2, latchdrain = 99 })
	local dirs = { 5, -5, 5, -5 }
	for _, sx in ipairs(dirs) do
		pl.speedx = sx
		ENEMY_MOVES.latch(e, 1 / 60)
	end
	check("latcher shake unlatch", e.latchedto == nil, tostring(e.shakes))
end

-- populate same seed
do
	local okp, errp = pcall(require, "world.endless_enemies")
	check("load endless_enemies", okp, errp)
	if okp then
		local function make_rng(seed)
			local state = seed % 2147483647
			if state <= 0 then state = 1 end
			return {
				random = function(_, a, b)
					state = (1103515245 * state + 12345) % 2147483648
					local u = state / 2147483648
					if not a then return u end
					if not b then return 1 + math.floor(u * a) end
					return a + math.floor(u * (b - a + 1))
				end,
			}
		end
		local function blank_map(w, h)
			local m = {}
			for x = 1, w do
				m[x] = {}
				for y = 1, h do
					-- floor on bottom
					m[x][y] = { (y == h) and 78 or 1 }
				end
			end
			return m
		end
		local function snapshot(m)
			local t = {}
			for x = 1, #m do
				for y = 1, #m[1] do
					if m[x][y][2] then
						t[#t + 1] = string.format("%d,%d=%s", x, y, tostring(m[x][y][2]))
					end
				end
			end
			table.sort(t)
			return table.concat(t, ";")
		end
		local m1 = blank_map(16, 15)
		local m2 = blank_map(16, 15)
		endless_populate(m1, 0, 0, 16, 15, "corridor", 3, make_rng(42), 1)
		endless_populate(m2, 0, 0, 16, 15, "corridor", 3, make_rng(42), 1)
		check("populate same seed", snapshot(m1) == snapshot(m2), snapshot(m1))
		local m3 = blank_map(16, 15)
		endless_populate(m3, 0, 0, 16, 15, "corridor", 3, make_rng(99), 1)
		check("populate different seed", snapshot(m1) ~= snapshot(m3) or snapshot(m1) == "")
	end
end

return failed
