--[[ Golden-replay determinism (no LÖVE): fixed seed, scripted inputs, state hash. ]]

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

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	package.path,
}, ";")

local sha1 = require("sha1")
local ReplayHarness = require("core.replay_harness")

-- Fixed-seed RNG (MARI0_SEED infrastructure)
do
	local saved_love = love
	local saved_getenv = os.getenv
	love = {
		math = {
			setRandomSeed = function(seed)
				math.randomseed(seed)
			end,
			random = function(a, b)
				if a and b then
					return math.random(a, b)
				elseif a then
					return math.random(a)
				end
				return math.random()
			end,
		},
	}
	os.getenv = function(name)
		if name == "MARI0_SEED" then
			return "4242"
		end
		return saved_getenv(name)
	end
	local Rng = require("core.rng")
	local s = Rng.install(nil)
	check("golden MARI0_SEED", s == 4242, tostring(s))
	local a, b = love.math.random(), love.math.random()
	Rng.install(4242)
	check("golden RNG repeat", a == love.math.random() and b == love.math.random())
	love = saved_love
	os.getenv = saved_getenv
end

-- Replay index advancement (game_update hook)
do
	local replaydata = {
		{ data = {
			{ time = 0.0, x = 1 },
			{ time = 0.5, x = 2 },
			{ time = 1.0, x = 3 },
		} },
	}
	local replaytimer = { 0.0 }
	local replayi = { 1 }
	ReplayHarness.advance_replay_indices(replaydata, replaytimer, replayi, 0.25)
	check("replay idx after 0.25s", replayi[1] == 2, tostring(replayi[1]))
	ReplayHarness.advance_replay_indices(replaydata, replaytimer, replayi, 0.30)
	check("replay idx after 0.55s", replayi[1] == 3, tostring(replayi[1]))
	ReplayHarness.advance_replay_indices(replaydata, replaytimer, replayi, 0.50)
	check("replay idx after 1.05s", replayi[1] == 3, tostring(replayi[1]))
	local fp = ReplayHarness.fingerprint_replay_indices(replayi)
	check("replay fingerprint", fp == "3", fp)
end

-- Scripted 60-frame sim at 1/60 — golden hash locks integrator + input script
do
	local dt = 1 / 60
	local player = {
		x = 0, y = -1, speedx = 0, speedy = 0,
		jumping = false, grounded = true,
	}
	for frame = 1, 60 do
		ReplayHarness.step_scripted_player(player, {
			right = frame <= 40,
			left = false,
			jump = frame == 10 or frame == 35,
		}, dt)
	end
	local fp = ReplayHarness.fingerprint_players({ player })
	local hash = sha1(fp)
	check("golden player fingerprint", fp == "1:2.566667,0.000000,1.333333,0.000000", fp)
	check("golden player sha1", hash == "3213435650a7321caa5d68d6624ab491da1e1b01", hash)
end

return failed
