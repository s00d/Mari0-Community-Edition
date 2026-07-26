--[[
  Collision pipeline fixtures (no LÖVE). Tests physicscollision.lua pure branches.
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

-- Deps used by collision module
dofile(root .. "/physicslate.lua")
dofile(root .. "/maputil.lua")
dofile(root .. "/physicsconvert.lua")
dofile(root .. "/physicscollision.lua")

-- collisionexists: gravity remaps which callback is checked
do
	local obj = {
		floorcollide = "F",
		leftcollide = "L",
		ceilcollide = "C",
		rightcollide = "R",
	}
	check("exists down floor", collisionexists("floor", obj) == "F")
	check("exists down left", collisionexists("left", obj) == "L")
	obj.gravitydirection = math.pi/2
	check("exists pi/2 floor", collisionexists("floor", obj) == "F")
	obj.gravitydirection = math.pi -- left
	check("exists left-grav floor->right", collisionexists("floor", obj) == "R")
	check("exists left-grav left->floor", collisionexists("left", obj) == "F")
	obj.gravitydirection = math.pi*1.5 -- up
	check("exists up-grav floor->ceil", collisionexists("floor", obj) == "C")
	obj.gravitydirection = 0 -- right
	check("exists right-grav floor->left", collisionexists("floor", obj) == "L")
	check("exists right-grav right->floor", collisionexists("right", obj) == "F")
end

-- collisionscalls with down gravity
do
	local called = {}
	local obj = {
		gravitydirection = math.pi/2,
		floorcollide = function(self, a, b, c, d)
			called[#called+1] = {"floor", a, b}
			return "ok"
		end,
		leftcollide = function(self, a, b, c, d)
			called[#called+1] = {"left", a, b}
			return false
		end,
	}
	local r = collisionscalls("floor", obj, "tile", {}, 1, 2)
	check("calls floor", r == "ok" and called[1][1] == "floor")
	called = {}
	obj.gravitydirection = math.pi -- left: floor maps to rightcollide (nil)
	r = collisionscalls("floor", obj, "tile", {}, 1, 2)
	check("calls remapped missing nil", r == nil)
	obj.rightcollide = function(self) called[#called+1] = "right"; return true end
	r = collisionscalls("floor", obj, "t", {}, 1, 2)
	check("calls remapped right", r == true and called[1] == "right")
end

-- callcollision simple path (no gravitydirection)
do
	local saw = nil
	local obj = {
		floorcollide = function(self, a, b, c, d)
			saw = {a, b, c, d}
			return "hit"
		end,
	}
	local r = callcollision("floor", obj, "enemy", {x=1}, 3, 4)
	check("callcollision plain", r == "hit" and saw[1] == "enemy" and saw[3] == 3)
end

-- horcollision: mover left into wall, no callbacks → snap + stop
do
	local v = {x = 5, y = 0, width = 1, height = 1, speedx = -2, speedy = 0}
	local t = {x = 3, y = 0, width = 1, height = 1}
	local blocked = horcollision(v, t, "tile", 1, "player", 1, 0.016)
	check("hor left blocked", blocked == true)
	check("hor left snap x", v.x == t.x + t.width)
	check("hor left stop", v.speedx == 0)
end

-- horcollision: mover right
do
	local v = {x = 1, y = 0, width = 1, height = 1, speedx = 3, speedy = 0}
	local t = {x = 3, y = 0, width = 1, height = 1}
	local blocked = horcollision(v, t, "tile", 1, "player", 1, 0.016)
	check("hor right blocked", blocked == true)
	check("hor right snap x", v.x == t.x - v.width)
	check("hor right stop", v.speedx == 0)
end

-- vercollision: falling onto floor
do
	local v = {x = 0, y = 1, width = 1, height = 1, speedx = 0, speedy = 4}
	local t = {x = 0, y = 3, width = 1, height = 1}
	local blocked = vercollision(v, t, "tile", 1, "player", 1, 0.016)
	check("ver floor blocked", blocked == true)
	check("ver floor snap y", v.y == t.y - v.height)
	check("ver floor stop", v.speedy == 0)
end

-- vercollision: rising into ceiling
do
	local v = {x = 0, y = 3, width = 1, height = 1, speedx = 0, speedy = -4}
	local t = {x = 0, y = 1, width = 1, height = 1}
	local blocked = vercollision(v, t, "tile", 1, "player", 1, 0.016)
	check("ver ceil blocked", blocked == true)
	check("ver ceil snap y", v.y == t.y + t.height)
	check("ver ceil stop", v.speedy == 0)
end

-- passivecollision: snap to top when no passivecollide
do
	local v = {x = 0, y = 2.5, width = 1, height = 1, speedy = 2}
	local t = {x = 0, y = 3, width = 1, height = 1}
	local r = passivecollision(v, t, "tile", 1, "player", 1, 0.016)
	check("passive snaps", r == true and v.y == 2 and v.speedy == 0)
end

-- passivecollision: custom callback path
do
	local saw = false
	local v = {
		passivecollide = function(self, h, t, i, g)
			saw = true
		end,
	}
	local t = {x = 0, y = 0, width = 1, height = 1}
	local r = passivecollision(v, t, "box", 1, "player", 1, 0.016)
	check("passive custom", saw == true and r == false)
end

-- trianglevercollision ur slant (no floorcollide → else branch)
do
	local v = {x = 0.25, y = 0, width = 0.5, height = 0.5, speedx = 0, speedy = 1}
	local t = {x = 0, y = 1, width = 1, height = 1, slant = "ur"}
	local r = trianglevercollision(v, t, "tile", 1, "player", 1, 0)
	check("triangle ur", r == true and v.speedy == 0)
	-- y = t.y - v.height + (t.x - v.x) + 2/16 = 1 - 0.5 + (0 - 0.25) + 0.125 = 0.375
	check("triangle ur y", math.abs(v.y - 0.375) < 1e-9, tostring(v.y))
end

-- checkcollision: clear miss (far apart)
do
	yacceleration = 40
	local v = {x = 0, y = 0, width = 1, height = 1, speedx = 0, speedy = 0}
	local t = {x = 50, y = 50, width = 1, height = 1, cox = 1, coy = 1}
	-- non-tile path (h ~= "tile")
	local hor, ver = checkcollision(v, t, "box", 1, "player", 1, 0.016, false)
	check("check miss far", hor == false and ver == false)
end

-- checkcollision: horizontal approach into AABB
do
	yacceleration = 40
	local v = {x = 0, y = 0, width = 1, height = 1, speedx = 2, speedy = 0}
	local t = {x = 1.5, y = 0, width = 1, height = 1}
	local hor, ver = checkcollision(v, t, "box", 1, "player", 1, 1, false)
	-- at dt=1: v moves to x=2, overlaps t; horizontal-only aabb
	check("check hor hit", hor == true and ver == false)
	check("check hor resolved x", v.x == t.x - v.width and v.speedx == 0)
end

-- checkcollision: vertical fall
do
	yacceleration = 40
	local v = {x = 0, y = 0, width = 1, height = 1, speedx = 0, speedy = 2}
	local t = {x = 0, y = 1.5, width = 1, height = 1}
	local hor, ver = checkcollision(v, t, "box", 1, "player", 1, 1, false)
	check("check ver hit", hor == false and ver == true)
	check("check ver resolved y", v.y == t.y - v.height and v.speedy == 0)
end

-- checkcollision: already overlapping → passive
do
	yacceleration = 40
	local v = {x = 0, y = 2.2, width = 1, height = 1, speedx = 0, speedy = 1}
	local t = {x = 0, y = 3, width = 1, height = 1}
	local hor, ver = checkcollision(v, t, "box", 1, "player", 1, 0.016, false)
	check("check passive", hor == false and ver == true)
	check("check passive y", v.y == t.y - v.height)
end

-- checkcollision: passed=true skips passive; moving out so next AABB misses
do
	yacceleration = 40
	local v = {x = 0, y = 2.5, width = 1, height = 1, speedx = 0, speedy = -1}
	local t = {x = 0, y = 3, width = 1, height = 1}
	-- overlapping now; dt=1 → y=1.5, no longer overlaps
	local hor, ver = checkcollision(v, t, "box", 1, "player", 1, 1, true)
	check("check passed skips passive", hor == false and ver == false and v.y == 2.5 and v.speedy == -1)
	-- same setup without passed → passive snap
	v = {x = 0, y = 2.5, width = 1, height = 1, speedx = 0, speedy = -1}
	hor, ver = checkcollision(v, t, "box", 1, "player", 1, 1, false)
	check("check without passed does passive", ver == true and v.y == t.y - v.height)
end

-- floorcollide returning false cancels block
do
	local v = {
		x = 1, y = 0, width = 1, height = 1, speedx = 2, speedy = 0,
		rightcollide = function() return false end,
	}
	local t = {x = 3, y = 0, width = 1, height = 1}
	local blocked = horcollision(v, t, "tile", 1, "player", 1, 0.016)
	check("hor cancel by callback", blocked == false)
	check("hor cancel keeps speed", v.speedx == 2)
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
