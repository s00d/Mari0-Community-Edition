--[[
  Headless weapon system checks: pick_target range clip, spring convergence, release paths,
  tile extract → prop, LMB grab / RMB punt-as-ball.
  Run via: lua tests/run.lua  (or make test)
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

-- Load compiled Teal modules (after make teal / cyan build)
local ok_gg, gravitygun = pcall(require, "weapons.gravitygun")
if not ok_gg then
	print("FAIL load weapons.gravitygun: " .. tostring(gravitygun))
	return 1
end

local ok_w, Weapons = pcall(require, "weapons")
if not ok_w then
	print("FAIL load weapons: " .. tostring(Weapons))
	return 1
end

-- 1) pick_target / clip_range: wall hit clips max range (with floor fudge)
do
	local clip = gravitygun.clip_range
	check("clip_range no hit", clip(0, 0, 10, 0, 8, false) == 8)
	check("clip_range far wall", clip(0, 0, 20, 0, 8, true) == 8)
	local d = clip(0, 0, 3, 0, 8, true)
	check("clip_range near wall fudge", math.abs(d - 3.75) < 1e-6, tostring(d))
	check("clip_range diagonal", math.abs(clip(0, 0, 3, 4, 10, true) - 5.75) < 1e-6)
end

-- 2) spring converges monotonically toward target (critically damped)
do
	local spring_step = gravitygun.spring_step
	local pos, vel = 0.0, 0.0
	local target = 5.0
	local omega = 14
	local dt = 1 / 60
	local prev_err = math.abs(pos - target)
	local mono = true
	for _ = 1, 180 do
		pos, vel = spring_step(pos, vel, target, omega, dt)
		local err = math.abs(pos - target)
		if err > prev_err + 1e-4 then
			mono = false
			break
		end
		prev_err = err
	end
	check("spring mono converge", mono and prev_err < 0.05, "err=" .. tostring(prev_err))
end

-- 3) all 8 release reasons clear pickup + beamed
do
	local reasons = {
		"switch",
		"death",
		"levelend",
		"emancipate",
		"destroying",
		"outofreach",
		"objportal",
		"cancel",
	}
	local all_ok = true
	for _, reason in ipairs(reasons) do
		local obj = { beamed = true, gravity = 0, active = false, parent = nil }
		local pl = {
			pickup = obj,
			gg_pulling = nil,
			gg_state = "held",
			gg_vx = 1,
			gg_vy = 1,
		}
		obj.beamed = pl
		gravitygun.release_obj(pl, reason)
		if pl.pickup ~= false and pl.pickup ~= nil then
			all_ok = false
			print("  leftover pickup after " .. reason)
		end
		if obj.beamed ~= nil then
			all_ok = false
			print("  leftover beamed after " .. reason)
		end
		if pl.gg_state ~= "idle" then
			all_ok = false
			print("  leftover state after " .. reason .. ": " .. tostring(pl.gg_state))
		end
	end
	check("release 8 reasons clear", all_ok)

	local obj2 = { beamed = nil, gravity = 0 }
	local pl2 = { pickup = false, gg_pulling = obj2, gg_state = "pulling", gg_vx = 0, gg_vy = 0 }
	obj2.beamed = pl2
	gravitygun.release_obj(pl2, "cancel")
	check("release pulling clears beam", obj2.beamed == nil and pl2.gg_pulling == nil)
end

-- 4) registry + default loadout includes all three weapons
do
	check("registry portal", Weapons.get("portal") ~= nil and Weapons.get("portal").id == "portal")
	check("registry gelcannon", Weapons.get("gelcannon") ~= nil and Weapons.get("gelcannon").id == "gelcannon")
	check("registry gel alias", Weapons.get("gel") == Weapons.get("gelcannon"))
	check("registry gravitygun", Weapons.get("gravitygun") ~= nil)
	check("portal icon path", tostring(Weapons.get("portal").icon):find("portalgun%.png") ~= nil)
	check("gel icon path", tostring(Weapons.get("gelcannon").icon):find("gelcannon%.png") ~= nil)

	levelweapons = nil
	playertype = "portal"
	portalsavailable = { true, true }
	local loadout = Weapons.default_loadout()
	check("default has portal", loadout[1] == "portal")
	check("default has gravitygun", loadout[2] == "gravitygun")
	check("default has gelcannon", loadout[3] == "gelcannon")
	check("default len 3", #loadout == 3)

	local pl = { weapons = { "portal", "gravitygun", "gelcannon" }, weaponi = 1, weapondelay = {} }
	Weapons.switch(pl, 1)
	check("switch +1", pl.weaponi == 2 and pl.weapons[pl.weaponi] == "gravitygun")
	Weapons.switch(pl, 1)
	check("switch to gel", pl.weaponi == 3 and pl.weapons[pl.weaponi] == "gelcannon")
	Weapons.switch(pl, 1)
	check("switch wrap", pl.weaponi == 1)
end

-- 5) pick_target cone finds floor box; LMB pulls; RMB punts as ball
do
	local box = {
		x = 2.0,
		y = 1.0,
		width = 0.75,
		height = 0.75,
		grabbable = true,
		destroying = false,
		beamed = nil,
		active = true,
		speedx = 0,
		speedy = 0,
	}
	objects = { box = { [1] = box } }
	traceline = function(sx, sy, ang)
		return 1, 2, "up", 0, sx + 1.0, sy + 0.2
	end
	checkrect = function()
		return {}
	end
	love = { mouse = { isDown = function() return true end } }
	mouseowner = 1

	local pl = {
		x = 0,
		y = 0.5,
		pointingangle = -math.pi / 2, -- aim right
		playernumber = 1,
		weapondelay = {},
		gg_state = "idle",
		pickup = false,
	}
	local t = gravitygun.pick_target(pl)
	check("pick_target cone finds box", t == box)

	gravitygun.fire(pl, "l")
	check("fire starts pull", pl.gg_state == "pulling" and pl.gg_pulling == box)

	for _ = 1, 180 do
		gravitygun.update(pl, 1 / 60)
		if pl.weapondelay.gravitygun then
			pl.weapondelay.gravitygun = math.max(0, pl.weapondelay.gravitygun - 1 / 60)
		end
	end
	check("pull becomes held", pl.gg_state == "held" and pl.pickup == box, tostring(pl.gg_state))

	-- LMB while held must NOT punt
	pl.weapondelay.gravitygun = 0
	gravitygun.fire(pl, "l")
	check("lmb while held keeps hold", pl.gg_state == "held" and pl.pickup == box)

	-- RMB punts as ball
	pl.weapondelay.gravitygun = 0
	gravitygun.fire(pl, "r")
	check("rmb punt releases", pl.gg_state == "idle" and pl.pickup == false)
	check("rmb punt impulse", (box.speedx or 0) > 5, tostring(box.speedx))
	check("rmb punt ball look", box.gg_ball == true)
end

-- 6) extract_tile clears map cell and spawns prop box
do
	local spawned = nil
	box = {
		new = function(_, x, y)
			spawned = {
				x = x - 14 / 16,
				y = y - 12 / 16,
				width = 12 / 16,
				height = 12 / 16,
				grabbable = true,
				destroying = false,
				speedx = 0,
				speedy = 0,
				cox = x,
				coy = y,
			}
			return spawned
		end,
	}
	map = {
		[5] = {
			[3] = { 42 },
		},
	}
	mapwidth, mapheight = 20, 15
	inmap = function(x, y)
		return x >= 1 and x <= mapwidth and y >= 1 and y <= mapheight
	end
	tilekey = function(x, y)
		return x * 1000 + y
	end
	objects = { tile = { [tilekey(5, 3)] = { x = 4, y = 2 } }, box = {} }
	tilequads = {
		[42] = {
			image = "fakeimg",
			quadobj = "fakequad",
			getproperty = function(_, s)
				if s == "collision" then
					return true
				end
				if s == "invisible" then
					return false
				end
				return false
			end,
			quad = function(self)
				return self.quadobj
			end,
		},
		[1] = {
			getproperty = function()
				return false
			end,
		},
	}
	init_map_cell_gels = function() end
	generatespritebatch = function() end
	checkportalremove = function() end
	playerobjs = {}
	players = 0

	check("tile_can_grab solid", gravitygun.tile_can_grab(5, 3) == true)
	check("tile_can_grab air", gravitygun.tile_can_grab(1, 1) == false)

	local prop = gravitygun.extract_tile(5, 3)
	check("extract_tile returns prop", prop == spawned)
	check("extract_tile clears map", map[5][3][1] == 1)
	check("extract_tile removes tile obj", objects.tile[tilekey(5, 3)] == nil)
	check("extract_tile inserts box", objects.box[1] == spawned)
	check("extract_tile marks from_tile", spawned.gg_from_tile == true and spawned.gg_tileid == 42)
	check("extract_tile uses tile graphic", spawned.graphic == "fakeimg" and spawned.quad == "fakequad")
end

-- 7) pick_target extracts tile when no box in ray
do
	local spawned = nil
	box = {
		new = function(_, x, y)
			spawned = {
				x = x - 14 / 16,
				y = y - 12 / 16,
				width = 12 / 16,
				height = 12 / 16,
				grabbable = true,
				destroying = false,
				speedx = 0,
				speedy = 0,
			}
			return spawned
		end,
	}
	map = { [4] = { [2] = { 7 } } }
	mapwidth, mapheight = 20, 15
	inmap = function(x, y)
		return x >= 1 and x <= mapwidth and y >= 1 and y <= mapheight
	end
	tilekey = function(x, y)
		return x * 1000 + y
	end
	objects = { tile = { [tilekey(4, 2)] = {} }, box = {} }
	tilequads = {
		[7] = {
			image = "brick",
			quadobj = "bq",
			getproperty = function(_, s)
				return s == "collision"
			end,
			quad = function(self)
				return self.quadobj
			end,
		},
	}
	init_map_cell_gels = function() end
	generatespritebatch = function() end
	checkportalremove = function() end
	playerobjs = {}
	players = 0
	traceline = function(sx, sy)
		return 4, 2, "left", 0, sx + 2, sy
	end
	checkrect = function()
		return {}
	end

	local pl = {
		x = 0,
		y = 1,
		pointingangle = -math.pi / 2,
		playernumber = 1,
		weapondelay = {},
		gg_state = "idle",
		pickup = false,
	}
	love = { mouse = { isDown = function() return true end } }
	mouseowner = 1

	local t = gravitygun.pick_target(pl)
	check("pick_target extracts tile", t == spawned)
	check("pick tile cleared cell", map[4][2][1] == 1)

	gravitygun.fire(pl, "l")
	-- already extracted by pick_target above; fire picks again on empty — re-seed
	map[4][2][1] = 7
	objects.tile[tilekey(4, 2)] = {}
	pl.gg_state = "idle"
	pl.gg_pulling = nil
	pl.weapondelay.gravitygun = 0
	spawned = nil
	gravitygun.fire(pl, "l")
	check("fire lmb grabs tile prop", pl.gg_state == "pulling" and pl.gg_pulling ~= nil, tostring(pl.gg_state))
end

print(string.format("weapon_checks: %s", failed == 0 and "PASS" or ("FAIL x" .. failed)))
return failed
