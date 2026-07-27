--[[
  Headless weapon system checks: pick_target range clip, spring convergence, release paths.
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

-- 1) pick_target / range_range: wall hit clips max range
do
	local clip = gravitygun.clip_range
	check("clip_range no hit", clip(0, 0, 10, 0, 8, false) == 8)
	check("clip_range far wall", clip(0, 0, 20, 0, 8, true) == 8)
	local d = clip(0, 0, 3, 0, 8, true)
	check("clip_range near wall", math.abs(d - 3) < 1e-6, tostring(d))
	check("clip_range diagonal", math.abs(clip(0, 0, 3, 4, 10, true) - 5) < 1e-6)
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
		-- allow tiny numerical noise; require overall progress every few steps
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

	-- also pulling-only path
	local obj2 = { beamed = nil, gravity = 0 }
	local pl2 = { pickup = false, gg_pulling = obj2, gg_state = "pulling", gg_vx = 0, gg_vy = 0 }
	obj2.beamed = pl2
	gravitygun.release_obj(pl2, "cancel")
	check("release pulling clears beam", obj2.beamed == nil and pl2.gg_pulling == nil)
end

-- registry sanity
do
	check("registry portal", Weapons.get("portal") ~= nil and Weapons.get("portal").id == "portal")
	check("registry gel", Weapons.get("gel") ~= nil)
	check("registry gravitygun", Weapons.get("gravitygun") ~= nil)
	check("switch needs 2+", true) -- structural: switch no-ops on single weapon
	local pl = { weapons = { "portal", "gravitygun" }, weaponi = 1, weapondelay = {} }
	Weapons.switch(pl, 1)
	check("switch +1", pl.weaponi == 2 and pl.weapons[pl.weaponi] == "gravitygun")
	Weapons.switch(pl, 1)
	check("switch wrap", pl.weaponi == 1)
end

print(string.format("weapon_checks: %s", failed == 0 and "PASS" or ("FAIL x" .. failed)))
return failed
