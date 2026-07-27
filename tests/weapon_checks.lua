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

-- 4) registry + default loadout includes all weapons
do
	check("registry portal", Weapons.get("portal") ~= nil and Weapons.get("portal").id == "portal")
	check("registry gelcannon", Weapons.get("gelcannon") ~= nil and Weapons.get("gelcannon").id == "gelcannon")
	check("registry gel alias", Weapons.get("gel") == Weapons.get("gelcannon"))
	check("registry gravitygun", Weapons.get("gravitygun") ~= nil)
	check("registry hookshot", Weapons.get("hookshot") ~= nil and Weapons.get("hookshot").id == "hookshot")
	check("registry lightgun", Weapons.get("lightgun") ~= nil and Weapons.get("lightgun").id == "lightgun")
	check("registry freezeray", Weapons.get("freezeray") ~= nil and Weapons.get("freezeray").id == "freezeray")
	check("portal icon path", tostring(Weapons.get("portal").icon):find("portalgun%.png") ~= nil)
	check("gel icon path", tostring(Weapons.get("gelcannon").icon):find("gelcannon%.png") ~= nil)
	check("hookshot icon path", tostring(Weapons.get("hookshot").icon):find("hookshot%.png") ~= nil)
	check("lightgun icon path", tostring(Weapons.get("lightgun").icon):find("lightgun%.png") ~= nil)
	check("freezeray icon path", tostring(Weapons.get("freezeray").icon):find("freezeray%.png") ~= nil)

	levelweapons = nil
	playertype = "portal"
	portalsavailable = { true, true }
	local loadout = Weapons.default_loadout()
	check("default has portal", loadout[1] == "portal")
	check("default has gravitygun", loadout[2] == "gravitygun")
	check("default has gelcannon", loadout[3] == "gelcannon")
	check("default has hookshot", loadout[4] == "hookshot")
	check("default has lightgun", loadout[5] == "lightgun")
	check("default has freezeray", loadout[6] == "freezeray")
	check("default len 6", #loadout == 6)

	local pl = { weapons = { "portal", "gravitygun", "gelcannon", "hookshot", "lightgun", "freezeray" }, weaponi = 1, weapondelay = {} }
	Weapons.switch(pl, 1)
	check("switch +1", pl.weaponi == 2 and pl.weapons[pl.weaponi] == "gravitygun")
	Weapons.switch(pl, 1)
	check("switch to gel", pl.weaponi == 3 and pl.weapons[pl.weaponi] == "gelcannon")
	Weapons.switch(pl, 1)
	check("switch to hookshot", pl.weaponi == 4 and pl.weapons[pl.weaponi] == "hookshot")
	Weapons.switch(pl, 1)
	check("switch to lightgun", pl.weaponi == 5 and pl.weapons[pl.weaponi] == "lightgun")
	Weapons.switch(pl, 1)
	check("switch to freezeray", pl.weaponi == 6 and pl.weapons[pl.weaponi] == "freezeray")
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
	objects = { box = { [1] = box }, enemy = {} }
	traceline = function(sx, sy, ang)
		return 1, 2, "up", 0, sx + 1.0, sy + 0.2
	end
	checkrect = function()
		return {}
	end
	-- Cursor world ≈ box center so spring converges to hold
	xscroll, yscroll, scale = 0, 0, 1
	love = {
		mouse = {
			getPosition = function()
				return 2.375 * 16, (1.375 - 0.5) * 16 -- world (2.375, 1.375)
			end,
			isDown = function(b)
				return b == 1
			end,
		},
	}
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
	check("pull no parent snap", box.parent == nil)

	for _ = 1, 180 do
		gravitygun.update(pl, 1 / 60)
		if pl.weapondelay.gravitygun then
			pl.weapondelay.gravitygun = math.max(0, pl.weapondelay.gravitygun - 1 / 60)
		end
	end
	check("pull becomes held", pl.gg_state == "held" and pl.pickup == box, tostring(pl.gg_state))
	check("held no parent snap", box.parent == nil)

	-- LMB while held must NOT shoot
	pl.weapondelay.gravitygun = 0
	gravitygun.fire(pl, "l")
	check("lmb while held keeps hold", pl.gg_state == "held" and pl.pickup == box)

	-- RMB fires ball but keeps hold (no punt / no drop)
	objects.gravityball = {}
	gravityball = {
		new = function(_, x, y, dx, dy, owner)
			return { x = x, y = y, dx = dx, dy = dy, owner = owner, state = "flying", speedx = dx * 22, speedy = dy * 22 }
		end,
	}
	pl.weapondelay.gravitygun = 0
	local hold_before = pl.pickup
	gravitygun.fire(pl, "r")
	check("rmb keeps hold", pl.gg_state == "held" and pl.pickup == hold_before)
	check("rmb shoots ball", #objects.gravityball == 1)
	check("rmb sets ball cooldown", (pl.weapondelay.gravitygun or 0) > 0)
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

-- 8) mouse_world / hold_point follow cursor, not character aim
do
	local mw = gravitygun.mouse_world
	local wx, wy = mw(160, 80, 2, 1, 2) -- mx,my,xscroll,yscroll,scale
	-- wx = 2 + 160/(16*2) = 2 + 5 = 7
	-- wy = 1 + 0.5 + 80/(16*2) = 1.5 + 2.5 = 4
	check("mouse_world x", math.abs(wx - 7) < 1e-9, tostring(wx))
	check("mouse_world y", math.abs(wy - 4) < 1e-9, tostring(wy))

	xscroll, yscroll, scale = 2, 1, 2
	love = {
		mouse = {
			getPosition = function()
				return 160, 80
			end,
			isDown = function()
				return true
			end,
		},
	}
	local pl = { x = 0, y = 0, pointingangle = 0 }
	local obj = { width = 1, height = 1 }
	local tx, ty = gravitygun.hold_point(pl, obj)
	-- center on cursor: 7-0.5, 4-0.5
	check("hold_point tracks cursor x", math.abs(tx - 6.5) < 1e-9, tostring(tx))
	check("hold_point tracks cursor y", math.abs(ty - 3.5) < 1e-9, tostring(ty))
	check("hold_point not character front", math.abs(tx) > 1 or math.abs(ty) > 1)
end

-- 9) enemy grab eligibility + pick_target finds enemy
do
	local eu = gravitygun.enemy_usable
	local pl = { x = 0, y = 0 }
	check("enemy_usable alive", eu({ dead = false, shot = false }, pl) == true)
	check("enemy_usable dead", eu({ dead = true }, pl) == false)
	check("enemy_usable shot", eu({ shot = true }, pl) == false)
	check("enemy_usable other beam", eu({ beamed = {} }, pl) == false)

	local enemy = {
		x = 2.0,
		y = 1.0,
		width = 0.75,
		height = 0.75,
		t = "goomba",
		movement = "truffleshuffle",
		gravity = 40,
		destroying = false,
		dead = false,
		speedx = 2,
		speedy = 0,
		active = true,
	}
	objects = { box = {}, enemy = { [1] = enemy } }
	traceline = function(sx, sy)
		return false, false, nil, 0, sx + 8, sy
	end
	checkrect = function()
		return {}
	end
	love = {
		mouse = {
			getPosition = function()
				return 100, 50
			end,
			isDown = function(b)
				return b == 1
			end,
		},
	}
	xscroll, yscroll, scale = 0, 0, 1
	mouseowner = 1

	local p2 = {
		x = 0,
		y = 0.5,
		pointingangle = -math.pi / 2,
		playernumber = 1,
		weapondelay = {},
		gg_state = "idle",
		pickup = false,
	}
	local t = gravitygun.pick_target(p2)
	check("pick_target finds enemy", t == enemy)

	gravitygun.fire(p2, "l")
	check("fire grabs enemy", p2.gg_state == "pulling" and p2.gg_pulling == enemy)
	check("enemy AI frozen", enemy.movement == nil and enemy.gravity == 0 and enemy.gg_saved ~= nil)
	check("enemy no parent snap", enemy.parent == nil)

	-- spring toward cursor (not character)
	for _ = 1, 180 do
		gravitygun.update(p2, 1 / 60)
		if p2.weapondelay.gravitygun then
			p2.weapondelay.gravitygun = math.max(0, p2.weapondelay.gravitygun - 1 / 60)
		end
	end
	check("enemy becomes held", p2.gg_state == "held" and p2.pickup == enemy, tostring(p2.gg_state))

	-- RMB while on cooldown does nothing; hold remains
	p2.weapondelay.gravitygun = 0.5
	objects.gravityball = {}
	gravityball = {
		new = function()
			return { state = "flying" }
		end,
	}
	gravitygun.fire(p2, "r")
	check("rmb cooldown keeps hold", p2.gg_state == "held" and p2.pickup == enemy)
	check("rmb cooldown no ball", #objects.gravityball == 0)
end

-- 10) shoot_ball: one gravityball + cooldown + sound + recoil
do
	objects = { box = {}, enemy = {}, gravityball = {} }
	local spawned = nil
	gravityball = {
		new = function(_, x, y, dx, dy, owner)
			spawned = {
				x = x,
				y = y,
				dx = dx,
				dy = dy,
				owner = owner,
				speedx = dx * 22,
				speedy = dy * 22,
				state = "flying",
			}
			return spawned
		end,
	}
	traceline = function(sx, sy)
		return false, false, nil, 0, sx + 8, sy
	end
	checkrect = function()
		return {}
	end
	love = {
		mouse = {
			getPosition = function()
				return 200, 100
			end,
			isDown = function()
				return false
			end,
		},
	}
	xscroll, yscroll, scale = 0, 0, 1
	mouseowner = 1
	local sounds = {}
	playsound = function(name)
		sounds[#sounds + 1] = name
	end

	local pl = {
		x = 0,
		y = 0.5,
		speedx = 0,
		speedy = 0,
		pointingangle = -math.pi / 2,
		playernumber = 1,
		weapondelay = {},
		gg_state = "idle",
		pickup = false,
	}
	gravitygun.shoot_ball(pl)
	check("shoot_ball one object", #objects.gravityball == 1 and objects.gravityball[1] == spawned)
	check("shoot_ball sets cooldown", (pl.weapondelay.gravitygun or 0) > 0)
	check("shoot_ball plays sound", sounds[1] == "portalgun")
	check("shoot_ball recoil", (pl.speedx or 0) ~= 0 or (pl.speedy or 0) ~= 0)
	check("shoot_ball velocity", spawned and ((spawned.speedx or 0) ~= 0 or (spawned.speedy or 0) ~= 0))
end

-- 11) gravityball hitstuff/explode lifetime + punt_kill_entity + box crush
do
	local FRAME_TIME = 0.05
	local ok_punt, punt = pcall(require, "weapons.punt")
	check("load weapons.punt", ok_punt)

	-- Stub fireball graphics for gravityball module
	fireballimg = "fbimg"
	fireballquad = {}
	for i = 1, 7 do
		fireballquad[i] = "q" .. i
	end
	earthquake = 0
	local sounds = {}
	playsound = function(name)
		sounds[#sounds + 1] = name
	end
	local points = {}
	addpoints = function(n, x, y)
		points[#points + 1] = { n = n, x = x, y = y }
	end

	package.loaded["entities.gravityball"] = nil
	local ok_gb, _ = pcall(require, "entities.gravityball")
	check("load entities.gravityball", ok_gb)

	-- hitstuff enemy → shotted once, exploding
	local shot_n = 0
	local enemy = {
		shotted = function(self)
			shot_n = shot_n + 1
			self.dead = true
			return true
		end,
	}
	local ball = gravityball:new(1, 1, 1, 0, nil)
	check("ball starts flying", ball.state == "flying" and ball.gravity == 0)
	ball:hitstuff("enemy", enemy)
	check("hitstuff enemy shotted once", shot_n == 1)
	check("hitstuff enemy exploding", ball.state == "exploding" and ball.active == false)

	-- hitstuff tile → explode, no kill call
	shot_n = 0
	local ball2 = gravityball:new(1, 1, 1, 0, nil)
	ball2:hitstuff("tile", {})
	check("hitstuff tile exploding", ball2.state == "exploding")
	check("hitstuff tile no shotted", shot_n == 0)

	-- explode animation finishes after 3 frame steps
	local ball3 = gravityball:new(1, 1, 1, 0, nil)
	ball3:explode()
	local done = false
	for _ = 1, 3 do
		done = ball3:update(FRAME_TIME + 0.001)
	end
	check("explode update returns true", done == true)

	if ok_punt then
		-- health edge: first hit returns nil → no kill credit
		local healthy = { health = 2 }
		healthy.shotted = function(self)
			self.health = self.health - 1
			return nil
		end
		check("punt_kill_entity health no credit", punt.punt_kill_entity(healthy) == false)

		local deadish = {}
		deadish.shotted = function()
			return true
		end
		check("punt_kill_entity kill credit", punt.punt_kill_entity(deadish) == true)

		local attacker = { x = 1, y = 1, punttimer = 0 }
		local target = { stompable = true, stomped = false }
		target.stomp = function()
			target.stomped = true
		end
		check("punt_hit false when punttimer==0", punt.punt_hit(attacker, "enemy", target) == false)
	end

	-- box crush speed gate
	package.loaded["entities.box"] = nil
	-- Minimal stubs so box init can be skipped; call floorcollide on prototype
	adduserect = function(x, y, w, h, self)
		return { x = x, y = y }
	end
	boximg = "boximg"
	boxquad = { [1] = "bq" }
	local ok_box = pcall(require, "entities.box")
	check("load entities.box", ok_box)
	if ok_box then
		local crate = {
			speedy = 2,
			falling = true,
			x = 1,
			y = 1,
			globalcollide = function()
				return false
			end,
		}
		local stomped = false
		local foe = {
			stompable = true,
			stomp = function()
				stomped = true
			end,
		}
		points = {}
		box.floorcollide(crate, "enemy", foe, nil, nil)
		check("box crush slow no kill", stomped == false and crate.speedy == 2)

		crate.speedy = 12
		crate.falling = true
		stomped = false
		points = {}
		box.floorcollide(crate, "enemy", foe, nil, nil)
		check("box crush fast kills", stomped == true and crate.speedy == -6)
		check("box crush awards points", #points == 1 and points[1].n == 200)

		local immune = {
			immunetoboxes = true,
			stompable = true,
			stomp = function()
				stomped = true
			end,
		}
		stomped = false
		crate.speedy = 12
		box.floorcollide(crate, "enemy", immune, nil, nil)
		check("box crush immune", stomped == false)
	end
end

-- 12) hookshot rope_step + detach funnel
do
	local ok_hs, hookshot = pcall(require, "weapons.hookshot")
	check("load weapons.hookshot", ok_hs)
	if ok_hs then
		-- 1) d < rest: no move
		local pl = {
			x = 0, y = 0, width = 1, height = 1,
			speedx = 0, speedy = 0,
			grapple = true, grapple_x = 2, grapple_y = 0.5,
			grapple_len = 5, grapple_reel = false,
		}
		local x0, y0 = pl.x, pl.y
		hookshot.rope_step(pl, 1 / 60)
		check("rope d<rest no move", pl.x == x0 and pl.y == y0)

		-- 2) d > rest → distance == rest
		pl.x, pl.y = 0, 0
		pl.width, pl.height = 0, 0 -- center == top-left for easy math
		pl.grapple_x, pl.grapple_y = 10, 0
		pl.grapple_len = 4
		pl.grapple_reel = false
		pl.speedx, pl.speedy = 0, 0
		hookshot.rope_step(pl, 1 / 60)
		local px = pl.x + pl.width / 2
		local py = pl.y + pl.height / 2
		local d = math.sqrt((pl.grapple_x - px) ^ 2 + (pl.grapple_y - py) ^ 2)
		check("rope d>rest equals rest", math.abs(d - 4) < 1e-6, "d=" .. tostring(d))

		-- 3) tangential kept, radial away zeroed
		-- anchor at (0,0), player at (5,0), rest=5 so already on circle; give outward + tangential vel
		-- Wait: need d > rest to apply velocity kill. rest=4, d=5.
		pl.x, pl.y = 5, 0
		pl.width, pl.height = 0, 0
		pl.grapple_x, pl.grapple_y = 0, 0
		pl.grapple_len = 4
		pl.grapple_reel = false
		-- velocity: away from anchor (-radial in their convention: nx points to anchor)
		-- nx = (0-5)/5 = -1, radial = vx*nx + vy*ny; away means moving further = opposite to nx = positive x
		pl.speedx, pl.speedy = 3, 4 -- radial away = speedx*(-nx?); nx=-1, radial = 3*(-1)+4*0 = -3 < 0 → kill
		hookshot.rope_step(pl, 1 / 60)
		-- after step: on circle at rest=4; radial away removed
		px = pl.x + pl.width / 2
		py = pl.y + pl.height / 2
		d = math.sqrt((0 - px) ^ 2 + (0 - py) ^ 2)
		check("rope after step on circle", math.abs(d - 4) < 1e-5, "d=" .. tostring(d))
		local nx, ny = (0 - px) / d, (0 - py) / d
		local radial = pl.speedx * nx + pl.speedy * ny
		check("rope radial away zeroed", radial >= -1e-6, "radial=" .. tostring(radial))
		-- tangential component of (3,4) should remain roughly: original tangential was (0,4) if on x-axis
		-- after position correction player is at (4,0), nx=-1; speed was (3,4), radial=-3, remove → (0,4)
		check("rope tangential kept", math.abs(pl.speedy - 4) < 1e-5 and math.abs(pl.speedx) < 1e-5,
			"vx=" .. tostring(pl.speedx) .. " vy=" .. tostring(pl.speedy))

		-- 4) detach clears all grapple_* for all reasons
		local reasons = {
			"release", "jump", "death", "levelend", "broken_anchor", "grill", "outofreach", "portal", "switch",
		}
		local all_ok = true
		for _, reason in ipairs(reasons) do
			local p = {
				grapple = true,
				grapple_x = 1, grapple_y = 2,
				grapple_cox = 3, grapple_coy = 4,
				grapple_len = 5, grapple_reel = true,
				speedy = 0,
			}
			local boost = reason == "jump"
			hookshot.detach(p, reason, boost)
			if p.grapple or p.grapple_x or p.grapple_y or p.grapple_cox or p.grapple_coy
				or p.grapple_len or p.grapple_reel then
				all_ok = false
				print("  leftover after " .. reason)
			end
			if boost and not (p.speedy <= -9) then
				all_ok = false
				print("  boost missing after jump: " .. tostring(p.speedy))
			end
		end
		check("detach clears all reasons", all_ok)

		-- 5) broken anchor → detach same frame
		local p2 = {
			x = 1, y = 1, width = 0.75, height = 0.75,
			speedx = 0, speedy = 0,
			grapple = true,
			grapple_x = 5, grapple_y = 1,
			grapple_cox = 6, grapple_coy = 2,
			grapple_len = 4, grapple_reel = true,
			playernumber = 99, -- != mouseowner → mouse treated as held
		}
		mouseowner = 1
		inmap = function() return true end
		map = { [6] = { [2] = { 1 } } } -- tid 1 = empty
		tilequads = {}
		love = { mouse = { isDown = function() return true end } }
		hookshot.update(p2, 1 / 60)
		check("broken anchor detaches same frame", p2.grapple == false and p2.grapple_x == nil)

		-- Weapons.release detaches grapple
		local p3 = {
			grapple = true, grapple_x = 1, grapple_y = 1,
			grapple_len = 2, grapple_reel = true,
			gg_state = "idle", pickup = false,
		}
		Weapons.release(p3, "death")
		check("Weapons.release detaches grapple", p3.grapple == false)
	end
end

-- 13) lightgun: one bridge, replace, RMB clear, unequip clear
do
	local ok_lg, lightgun = pcall(require, "weapons.lightgun")
	check("load weapons.lightgun", ok_lg)
	if ok_lg then
		local bodies = {}
		local bridges = {}
		local function make_bridge(cox, coy, r)
			local dir = "right"
			if r and r[3] then dir = r[3] end
			local self = {
				cox = cox, coy = coy, dir = dir, power = true,
				childtable = {}, destroy = false, handheld = nil,
			}
			function self:updaterange()
				for _, c in ipairs(self.childtable) do
					c.destroy = true
				end
				self.childtable = {}
				if not self.power then
					return
				end
				local body = { destroy = false, parent = self }
				table.insert(bodies, body)
				table.insert(self.childtable, body)
			end
			self:updaterange()
			return self
		end
		lightbridge = {
			new = function(_, x, y, r)
				return make_bridge(x, y, r)
			end,
		}
		objects = { lightbridge = bridges, lightbridgebody = bodies }
		traceline = function()
			return 5, 3, "left", 0, 5, 3
		end
		xscroll, yscroll, scale = 0, 0, 1
		love = { mouse = { getPosition = function() return 80, 40 end } }
		playsound = function() end

		local pl = {
			x = 1, y = 2, pointingangle = -math.pi / 2,
			weapondelay = {}, weapons = { "lightgun" }, weaponi = 1,
		}
		lightgun.fire(pl, "l")
		check("lightgun one bridge", #bridges == 1 and pl.lb_bridge ~= nil)
		check("lightgun dir from face", pl.lb_bridge.dir == "left", tostring(pl.lb_bridge and pl.lb_bridge.dir))
		local first = pl.lb_bridge
		local body_count_1 = #bodies

		pl.weapondelay.lightgun = 0
		traceline = function()
			return 8, 4, "up", 0, 8, 4
		end
		lightgun.fire(pl, "l")
		local alive = 0
		for _, b in ipairs(bridges) do
			if not b.destroy then alive = alive + 1 end
		end
		check("lightgun second fire still one", alive == 1 and pl.lb_bridge ~= first)
		check("lightgun old bodies destroyed", first.destroy == true)

		pl.weapondelay.lightgun = 0
		lightgun.fire(pl, "r")
		check("lightgun RMB clears", pl.lb_bridge == nil)
		local alive2 = 0
		for _, b in ipairs(bridges) do
			if not b.destroy then alive2 = alive2 + 1 end
		end
		check("lightgun RMB no live bridges", alive2 == 0)

		pl.weapondelay.lightgun = 0
		traceline = function()
			return 5, 3, "right", 0, 5, 3
		end
		lightgun.fire(pl, "l")
		check("lightgun placed again", pl.lb_bridge ~= nil)
		lightgun.unequip(pl)
		check("lightgun unequip clears", pl.lb_bridge == nil)

		-- Weapons.release clears bridge
		pl.weapondelay.lightgun = 0
		lightgun.fire(pl, "l")
		Weapons.release(pl, "death")
		check("Weapons.release clears bridge", pl.lb_bridge == nil)

		local _ = body_count_1 -- silence unused
	end
end

-- 14) freezeray: 6 cases from design plan
do
	local ok_fz, freezeray = pcall(require, "weapons.freezeray")
	check("load weapons.freezeray", ok_fz)
	local ok_ib = pcall(require, "entities.iceblock")
	check("load entities.iceblock", ok_ib)
	if ok_fz and ok_ib then
		-- stub box for iceblock metatable
		if not box then
			box = {
				init = function(self, x, y)
					self.cox, self.coy = x, y
					self.x, self.y = x - 14 / 16, y - 12 / 16
					self.width, self.height = 0.75, 0.75
					self.speedx, self.speedy = 0, 0
					self.grabbable = true
					self.drawable = true
					self.active = true
					self.destroying = false
				end,
				update = function() return false end,
			}
			setmetatable(iceblock, { __index = box })
		end
		adduserect = function() return {} end
		blockdebristable = {}
		blockdebris = {
			new = function(_, x, y, sx, sy)
				return { x = x, y = y, speedx = sx, speedy = sy }
			end,
		}
		playsound = function() end
		enemiesdata = { goomba = { width = 0.75, height = 0.75 } }
		enemy = {
			new = function(_, x, y, t)
				return {
					t = t, x = x, y = y, width = 0.75, height = 0.75,
					animationdirection = "left", drawable = true, kill = false,
				}
			end,
		}

		local function reset_world()
			objects = { enemy = {}, iceblock = {}, box = {} }
			blockdebristable = {}
		end

		-- 1) fire on enemy → kill + one iceblock
		reset_world()
		local victim = {
			t = "goomba", x = 2, y = 1, cox = 3, coy = 2,
			width = 0.75, height = 0.75, animationdirection = "right",
			graphic = "g", quad = "q", offsetX = 1, offsetY = 2,
			quadcenterX = 3, quadcenterY = 4,
			freezeimmune = false, dead = false, shot = false, kill = false, drawable = true,
		}
		objects.enemy[1] = victim
		traceline = function(sx, sy)
			return false, false, false, false, sx + 10, sy
		end
		checkrect = function()
			return { "enemy", 1 }
		end
		xscroll, yscroll, scale = 0, 0, 1
		love = { mouse = { getPosition = function() return 40, 20 end } }
		local pl = { x = 0, y = 0.5, pointingangle = -math.pi / 2, weapondelay = {} }
		freezeray.fire(pl, "l")
		check("fz freeze marks kill", victim.kill == true and victim.drawable == false)
		check("fz one iceblock", #objects.iceblock == 1)
		check("fz beam always", (pl.fz_beam or 0) > 0)
		check("fz cooldown set", (pl.weapondelay.freezeray or 0) > 0)

		-- 2) fire miss → beam + cooldown, no block
		reset_world()
		pl = { x = 0, y = 0.5, pointingangle = -math.pi / 2, weapondelay = {} }
		checkrect = function() return {} end
		freezeray.fire(pl, "l")
		check("fz miss beam set", (pl.fz_beam or 0) > 0)
		check("fz miss cooldown", (pl.weapondelay.freezeray or 0) > 0)
		check("fz miss no block", #objects.iceblock == 0)

		-- 3) thaw restores enemy with same t
		reset_world()
		local ib = iceblock:new({
			t = "goomba", x = 2, y = 1, cox = 3, coy = 2,
			width = 0.75, height = 0.75, animationdirection = "left",
			graphic = "g", quad = "q",
		})
		table.insert(objects.iceblock, ib)
		ib.thaw = 0.001
		local removed = ib:update(0.01)
		check("fz thaw returns true", removed == true)
		check("fz thaw restores enemy", #objects.enemy == 1 and objects.enemy[1].t == "goomba")

		-- 4) shatter does not restore
		reset_world()
		ib = iceblock:new({
			t = "goomba", x = 2, y = 1, cox = 3, coy = 2,
			width = 0.75, height = 0.75, animationdirection = "left",
			graphic = "g", quad = "q",
		})
		table.insert(objects.iceblock, ib)
		ib.speedy = 20
		removed = ib:update(0.01)
		check("fz shatter returns true", removed == true)
		check("fz shatter no enemy", #objects.enemy == 0)

		-- 5) beamed thaw → Weapons.release
		reset_world()
		local release_called = false
		local old_release = Weapons.release
		Weapons.release = function(p, reason)
			release_called = (reason == "thaw")
			if old_release then old_release(p, reason) end
		end
		ib = iceblock:new({
			t = "goomba", x = 2, y = 1, cox = 3, coy = 2,
			width = 0.75, height = 0.75, animationdirection = "left",
			graphic = "g", quad = "q",
		})
		local holder = { pickup = ib, gg_state = "held", gg_pulling = nil }
		ib.beamed = holder
		ib.thaw = 0
		ib:melt()
		check("fz beamed thaw releases", release_called == true)
		Weapons.release = old_release

		-- 6) freezeimmune not frozen
		reset_world()
		victim = {
			t = "goomba", x = 2, y = 1, cox = 3, coy = 2,
			width = 0.75, height = 0.75,
			freezeimmune = true, dead = false, shot = false, kill = false, drawable = true,
			gg_group = "enemy",
		}
		objects.enemy[1] = victim
		checkrect = function() return { "enemy", 1 } end
		pl = { x = 0, y = 0.5, pointingangle = -math.pi / 2, weapondelay = {} }
		freezeray.fire(pl, "l")
		check("fz immune not killed", victim.kill ~= true)
		check("fz immune no block", #objects.iceblock == 0)
		check("fz immune still beams", (pl.fz_beam or 0) > 0)
	end
end

print(string.format("weapon_checks: %s", failed == 0 and "PASS" or ("FAIL x" .. failed)))
return failed
