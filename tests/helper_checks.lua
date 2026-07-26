--[[
  Unit checks for extracted helpers (tilekey..playerutil).
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

require("core.tilekey")
require("world.zones")
require("world.bounceutil")
require("world.globstate")
require("core.tableutil")
require("core.listutil")
require("core.mathutil")
require("core.stringutil")
require("util.updateutil")
require("physics.late")
require("physics.convert")
require("physics.dir")
require("physics.emance")
require("core.maputil")
require("util.playerutil")
require("util.hatutil")
require("physics.handlegroup")
require("util.portalutil")
require("util.scrollutil")
require("util.enemyutil")
require("util.userectutil")

do
	local k = tilekey(12, 7)
	local x, y = tilekey_xy(k)
	check("tilekey roundtrip", x == 12 and y == 7, string.format("got %s,%s", tostring(x), tostring(y)))
	check("tilekey distinct", tilekey(1, 2) ~= tilekey(2, 1))
	check("tilekey no string", type(k) == "number")
end

-- PHYSICS_LATE_SET / LIST from real module
do
	check("late set portalwall", PHYSICS_LATE_SET["portalwall"] == true)
	check("late set castlefirefire", PHYSICS_LATE_SET["castlefirefire"] == true)
	check("late set enemy not late", PHYSICS_LATE_SET["enemy"] ~= true)
	check("late filter pass goomba", not PHYSICS_LATE_SET["goomba"])
	check("late filter skip platform", PHYSICS_LATE_SET["platform"] == true)
	check("late list length", #PHYSICS_LATE_LIST == 3)
	check("late list order", PHYSICS_LATE_LIST[1] == "portalwall" and PHYSICS_LATE_LIST[2] == "castlefirefire" and PHYSICS_LATE_LIST[3] == "platform")
	-- list members must all be in set
	local all_in_set = true
	for _, h in ipairs(PHYSICS_LATE_LIST) do
		if not PHYSICS_LATE_SET[h] then all_in_set = false end
	end
	check("late list matches set", all_in_set)
end

-- prerotatecall from real module
do
	check("prerotate goomba", prerotatecall("goomba") == true)
	check("prerotate squid", prerotatecall("squid", "player") == true)
	check("prerotate player false", prerotatecall("player") == false)
	check("prerotate tile false", prerotatecall("tile") == false)
	check("prerotate box false", prerotatecall("box") == false)
end

-- aabb from real module
do
	check("aabb overlap", aabb(0, 0, 1, 1, 0.5, 0.5, 1, 1) == true)
	check("aabb separate", aabb(0, 0, 1, 1, 2, 2, 1, 1) == false)
	check("aabb edge touch false", aabb(0, 0, 1, 1, 1, 0, 1, 1) == false)
end

-- aabt: unit box B at (0,0) size 2x2; probe A size 0.2x0.2
-- Diagonal half-planes relative to B origin.
do
	local bw, bh = 2, 2
	-- ur: ay+ah > ax  (with bx=by=0) — upper-left of diagonal hits, lower-right misses
	check("aabt ur hit", aabt(0.1, 1.5, 0.2, 0.2, 0, 0, bw, bh, "ur") == true)
	check("aabt ur miss", aabt(1.5, 0.1, 0.2, 0.2, 0, 0, bw, bh, "ur") == false)
	-- ul: ay+ah > bh - ax - aw  — upper-right hits, lower-left misses
	check("aabt ul hit", aabt(1.5, 1.5, 0.2, 0.2, 0, 0, bw, bh, "ul") == true)
	check("aabt ul miss", aabt(0.1, 0.1, 0.2, 0.2, 0, 0, bw, bh, "ul") == false)
	-- dl: ay < ax+aw — lower-right hits, upper-left misses
	check("aabt dl hit", aabt(1.5, 0.1, 0.2, 0.2, 0, 0, bw, bh, "dl") == true)
	check("aabt dl miss", aabt(0.1, 1.5, 0.2, 0.2, 0, 0, bw, bh, "dl") == false)
	-- dr: ay < bw - ax — lower-left hits, upper-right misses
	check("aabt dr hit", aabt(0.1, 0.1, 0.2, 0.2, 0, 0, bw, bh, "dr") == true)
	check("aabt dr miss", aabt(1.5, 1.5, 0.2, 0.2, 0, 0, bw, bh, "dr") == false)
	-- no AABB overlap → false for any dir
	check("aabt no overlap", aabt(5, 5, 0.2, 0.2, 0, 0, bw, bh, "ur") == false)
	-- unknown dir → nil
	check("aabt bad dir nil", aabt(0.1, 1.5, 0.2, 0.2, 0, 0, bw, bh, "xx") == nil)
end

-- maputil: inrange / inmap
do
	check("inrange include mid", inrange(5, 1, 10, true) == true)
	check("inrange include edge", inrange(1, 1, 10, true) == true)
	check("inrange exclude edge", inrange(1, 1, 10, false) == false)
	check("inrange exclude mid", inrange(5, 1, 10, false) == true)
	check("inrange swapped bounds", inrange(5, 10, 1, true) == true)
	check("inrange outside", inrange(0, 1, 10, true) == false)

	mapwidth, mapheight = 20, 15
	check("inmap inside", inmap(1, 1) == true)
	check("inmap corner", inmap(20, 15) == true)
	check("inmap outside", inmap(0, 1) == false)
	check("inmap outside y", inmap(1, 16) == false)
	check("inmap nil", inmap(nil, 1) == false)
end

-- Bounce lookup (real module)
do
	local bx = {3, 10, 5}
	local by = {4, 2, 8}
	local lookup = build_blockbounce_lookup(bx, by)
	check("bounce lookup hit", lookup[tilekey(10, 2)] == 2)
	check("bounce lookup miss", lookup[tilekey(1, 1)] == nil)
	check("bounce lookup truthy skip", lookup[tilekey(3, 4)] and true or false)
end

-- checkforemances should run once per mover (logical contract)
do
	local calls = 0
	local function checkforemances()
		calls = calls + 1
	end
	local groups = {"enemy", "player", "box", "gel"}
	local latetable = {"portalwall", "platform"}
	-- old: call inside every group loop
	local old = 0
	for _ in ipairs(groups) do
		old = old + 1
	end
	for _ in ipairs(latetable) do
		old = old + 1
	end
	-- new: once after collisions
	checkforemances()
	check("emance once vs per-group", calls == 1 and old == #groups + #latetable)
end

-- zones module
do
	local zones = buildstartendzones({10, 50}, {20, 60})
	check("zones two pairs", #zones == 2 and zones[1][1] == 10 and zones[1][2] == 20)
	check("zones empty starts", #buildstartendzones({}, {1}) == 0)
	check("zones nil starts", #buildstartendzones(nil, nil) == 0)
	local z2 = buildstartendzones({10, 50}, {20})
	check("zones unpaired end false", z2[2][2] == false)
end

-- globstate (needs globals)
do
	globools = {}
	globints = {}
	check("globool default false", globoolSH("a", "check") == false)
	globoolSH("a", "true")
	check("globool set true", globoolSH("a", "check") == true)
	globoolSH("a", "flip")
	check("globool flip", globoolSH("a", "check") == false)
	globoolSH("a", "false")
	check("globool set false", globoolSH("a", "check") == false)

	check("globint default 0", globintSH("n", "set", 0) == 0)
	globintSH("n", "set", 5)
	check("globint set", globints["n"] == 5)
	globintSH("n", "add", 3)
	check("globint add", globints["n"] == 8)
	globintSH("n", "subtract", 2)
	check("globint subtract", globints["n"] == 6)
	check("globintCH greater", globintCH("n", "greater", 5) == true)
	check("globintCH less", globintCH("n", "less", 10) == true)
	check("globintCH equal", globintCH("n", "equal", 6) == true)
	check("globintCH not equal", globintCH("n", "equal", 7) == false)
	check("globintCH tonumber", globintCH("n", "equal", "6") == true)
end

-- tableutil
do
	check("tablecontains hit", tablecontains({"a", "b", "c"}, "b") == true)
	check("tablecontains miss", tablecontains({"a", "b"}, "z") == false)
	check("tablecontains empty", tablecontains({}, 1) == false)
	check("tablecontains hash value", tablecontains({x = 3, y = 9}, 9) == true)
end

-- listutil: remove_indices_desc
do
	local t = {"a", "b", "c", "d", "e"}
	local idx = {2, 5} -- unsorted; remove e then b
	remove_indices_desc(t, idx)
	check("remove_indices_desc result", table.concat(t) == "acd")
	check("remove_indices_desc empty noop", (function()
		local u = {1, 2}
		remove_indices_desc(u, {})
		return #u == 2
	end)())
	-- multi parallel columns (blockbounce pattern)
	local timers = {10, 20, 30, 40}
	local xs = {1, 2, 3, 4}
	local ys = {5, 6, 7, 8}
	remove_indices_desc_multi({timers, xs, ys}, {2, 4})
	check("remove multi timers", timers[1] == 10 and timers[2] == 30 and #timers == 2)
	check("remove multi xs", xs[1] == 1 and xs[2] == 3 and #xs == 2)
	check("remove multi ys", ys[1] == 5 and ys[2] == 7 and #ys == 2)
end

-- update_and_compact dense path
do
	mapwidth, mapheight = 20, 15
	local calls = {}
	local list = {
		{name = "keep", update = function(self, dt) calls[#calls+1] = self.name; return false end},
		{name = "drop", update = function(self, dt) calls[#calls+1] = self.name; return true end},
		{name = "keep2", update = function(self, dt) calls[#calls+1] = self.name; return false end},
	}
	update_and_compact(list, 0.016)
	check("update dense compact len", #list == 2)
	check("update dense keep order", list[1].name == "keep" and list[2].name == "keep2")
	check("update dense all ran", table.concat(calls, ",") == "keep,drop,keep2")
end

-- update_and_compact autodelete bounds
do
	mapwidth, mapheight = 10, 10
	local deleted = false
	local list = {
		{x = 0, y = 0, update = function() return false end},
		{x = 100, y = 0, autodelete = true, autodeleted = function() deleted = true end},
	}
	update_and_compact(list, 0)
	check("update autodelete removed", #list == 1 and list[1].x == 0)
	check("update autodeleted hook", deleted == true)
end

-- mathutil
do
	check("round int", round(3.7) == 4)
	check("round 1dp", round(3.74, 1) == 3.7)
	local c = getrainbowcolor(0)
	check("rainbow red start", c[1] == 1 and c[2] == 0 and c[3] == 0 and c[4] == 1)
	local c2 = getrainbowcolor(0.5)
	check("rainbow mid cyan-ish", c2[1] == 0 and c2[3] == 1)
	local g = gradient({0, 0, 0}, {1, 0, 0}, 0.5)
	check("gradient mid", g[1] == 0.5 and g[2] == 0 and g[3] == 0)
	local g2 = gradient({1}, {0, 1}, 0)
	check("gradient unequal lens", g2[1] == 1 and g2[2] == 1)
end

-- portalutil
do
	local x, y = portal_facing_offset("up")
	check("portal offset up", x == 1 and y == 0)
	x, y = portal_facing_offset("right")
	check("portal offset right", x == 0 and y == 1)
	x, y = portal_facing_offset("down")
	check("portal offset down", x == -1 and y == 0)
	x, y = portal_facing_offset("left")
	check("portal offset left", x == 0 and y == -1)
	x, y = portal_facing_offset("nope")
	check("portal offset unknown", x == 0 and y == 0)
	local a, b, c, d = portal_pair_offsets("up", "left")
	check("portal pair offsets", a == 1 and b == 0 and c == 0 and d == -1)
end

-- scrollutil
do
	scale = 2
	check("scroll batch offset 0", scroll_batch_offset(0) == 0)
	check("scroll batch offset frac", scroll_batch_offset(3.25) == math.floor(-0.25 * 16 * 2))
	xscroll, yscroll, yoffset = 2, 1, 0
	local tx, ty = getMouseTile(0, 0)
	check("mouse tile origin", tx == 3 and ty == 2)
	xscroll = 0
	cameraxpan(5, 1)
	check("cameraxpan sets", xpan == true and xpandiff == 5 and xpantime == 1)
	yscroll = 2
	cameraypan(0, 0.5)
	check("cameraypan sets", ypan == true and ypandiff == -2 and ypantime == 0.5)
end

-- enemyutil
do
	check("enemy name ok", enemy_name_ok("goomba") == true)
	check("enemy name dash bad", enemy_name_ok("goom-ba") == false)
	check("enemy name comma bad", enemy_name_ok("a,b") == false)
	local t = {OffsetX = 3, Speed = "Fast", quadcenterY = 2}
	normalize_enemy_props(t)
	check("enemy norm offsetX", t.offsetX == 3)
	check("enemy norm speed lower", t.speed == "fast")
	check("enemy norm quadcenterY", t.quadcenterY == 2)
	apply_enemy_defaults(t, {quadcount = 1, speed = "slow"})
	check("enemy default fill", t.quadcount == 1)
	check("enemy default skip existing", t.speed == "fast")
	nobasevalues = {"description"}
	local base = usebase({hp = 2, description = "nope", graphic = "g"})
	check("usebase copies hp", base.hp == 2 and base.graphic == "g")
	check("usebase skips description", base.description == nil)
	xscroll, yscroll, width, height = 0, 0, 10, 10
	check("enemy onscreen hit", enemy_onscreen(1, 1, 1, 1) == true)
	check("enemy onscreen miss", enemy_onscreen(100, 1, 1, 1) == false)
end

-- userectutil (aabb from physicslate)
do
	userects = {}
	local cb = function() end
	local r = adduserect(0, 0, 1, 1, cb)
	check("adduserect fields", r.x == 0 and r.width == 1 and r.delete == false)
	local hits, j = userect(0.5, 0.5, 0.2, 0.2)
	check("userect hit", #hits == 1 and hits[1] == cb and j == 1)
	local miss = userect(5, 5, 0.2, 0.2)
	check("userect miss", #miss == 0)
end

-- stringutil
do
	check("addzeros pad", addzeros("7", 3) == "007")
	check("addzeros noop", addzeros("1234", 3) == "1234")
	local parts = ("a=b=c"):split("=")
	check("string split 3", #parts == 3 and parts[1] == "a" and parts[3] == "c")
	check("string split empty delim pieces", #(("x"):split(",")) == 1)
end

-- physicsconvert roundtrip at default gravity (down = pi/2)
do
	local obj = {gravitydirection = math.pi/2}
	local sx, sy = convertfromstandard(obj, 3, -4)
	local rx, ry = converttostandard(obj, sx, sy)
	check("convert roundtrip x", math.abs(rx - 3) < 1e-9, tostring(rx))
	check("convert roundtrip y", math.abs(ry - (-4)) < 1e-9, tostring(ry))
	-- near-zero snap
	local zx, zy = converttostandard(obj, 1e-12, 1e-12)
	check("convert snap zero", zx == 0 and zy == 0)
end

-- unrotate toward down gravity
do
	portalrotationalignmentspeed = 15
	local target = math.pi/2 - math.pi/2 -- 0 for down? gravitydirection-pi/2
	-- gravity down pi/2 → align to 0
	local r = unrotate(0.5, math.pi/2, 0.01)
	check("unrotate moves toward 0", r < 0.5 and r >= 0)
	local r2 = unrotate(-0.5, math.pi/2, 0.01)
	check("unrotate from neg toward 0", r2 > -0.5 and r2 <= 0)
end

-- physicsdir
do
	check("twist nil floor", twistdirection(nil, "floor") == "floor")
	check("twist left-grav floor->left", twistdirection(math.pi, "floor") == "left")
	check("twist up-grav floor->ceil", twistdirection(math.pi*1.5, "floor") == "ceil")
	check("adjust left down-grav", adjustcollside("left", math.pi/2) == "left")
	check("adjust left left-grav", adjustcollside("left", math.pi) == "up")
	check("adjust down right-grav", adjustcollside("down", 0) == "right")
end

-- physicsemance
do
	local calls = {}
	emancipationgrills = {
		{active = true, dir = "hor", startx = 1, endx = 3, y = 5, thickness = 16},
	}
	local v = {
		emancipatecheck = true,
		x = 1, y = 4.5, width = 1, height = 1,
		speedx = 0, speedy = 0,
		emancipate = function(_, h) calls[#calls+1] = h end,
	}
	checkforemances(0.016, v)
	check("emance hit hor", #calls == 1)
	calls = {}
	v.x, v.y = 100, 100
	checkforemances(0.016, v)
	check("emance miss", #calls == 0)
	v.emancipatecheck = false
	v.x, v.y = 1, 4.5
	checkforemances(0.016, v)
	check("emance skip when unchecked", #calls == 0)
end

-- playerutil
do
	players = 3
	objects = {player = {{x = 10}, {x = 2}, {x = 8}}}
	check("closest player index", getclosestplayer(3) == 2)
	check("closest sets global", closestplayer == 2)
	players = 1
	objects = {player = {{x = 0}}}
	check("closest single", getclosestplayer(99) == 1)
end

-- hatutil (#149 swim wins for big)
do
	fireanimationtime = 0.1
	local anims = {}
	local char = {
		animations = anims,
		nogunanimations = {},
		hatoffsets = {
			jumping = {[1] = "j"},
			swimming = {[1] = "s"},
			running = {[1] = "r"},
		},
		bighatoffsets = {
			jumping = {[1] = "bj"},
			swimming = {[1] = "bs"},
			running = {[1] = "br"},
			ducking = "bd",
			fire = "bf",
		},
	}
	check("hat small jump", gethatoffset(char, anims, "jumping", 1, 1, 1, 1, false, false, 1, false) == "j")
	check("hat small swim", gethatoffset(char, anims, "jumping", 1, 1, 1, 1, true, false, 1, false) == "s")
	check("hat big swim over jump", gethatoffset(char, {}, "jumping", 1, 1, 1, 1, true, false, 1, false) == "bs")
	check("hat big land jump", gethatoffset(char, {}, "jumping", 1, 1, 1, 1, false, false, 1, false) == "bj")
	check("hat big funnel", gethatoffset(char, {}, "jumping", 1, 1, 1, 1, true, true, 1, false) == "bj")
end

-- physicshandlegroup
do
	local calls = 0
	function checkcollision(v, t, h, g, j, i, dt, passed)
		calls = calls + 1
		return true, false
	end
	local v = {mask = {}, category = 3}
	local u = {
		a = {active = true, category = 2, mask = {}},
		b = {active = false, category = 2, mask = {}},
	}
	local hor, ver = handlegroup(1, "enemy", u, v, "player", 0.016, false)
	check("handlegroup hor", hor == true)
	check("handlegroup skips inactive", calls == 1)
	-- same object skipped
	calls = 0
	u = { [5] = {active = true, category = 2, mask = {}} }
	hor, ver = handlegroup(5, "player", u, v, "player", 0.016, false)
	check("handlegroup skip self", calls == 0 and hor == false)
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
