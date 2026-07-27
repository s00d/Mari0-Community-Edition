--[[
  Physics hot-path performance checks (no LÖVE).
  Run: lua tests/perf_checks.lua

  Stubs: portal audio, portals, emancipation grills, tilequads (minimal).
  Missing from fixture: full tile collision slants, portal teleport, gel, shaders.
]]

local M = {}

local function setup_path(root)
	package.path = table.concat({
		root .. "/build/?.lua",
		root .. "/build/?/init.lua",
		root .. "/lib/?.lua",
		root .. "/lib/?/init.lua",
		root .. "/tests/?.lua",
		package.path,
	}, ";")
end

local function stub_globals()
	yacceleration = 40
	maxyspeed = 8
	portals = {}
	emancipationgrills = {}
	checkportalVER = function()
		return false
	end
	checkportalHOR = function()
		return false
	end
	playsound = function()
	end
	inportal = function()
		return false
	end
end

local function stub_tilequads()
	tilequads = {
		[1] = {
			getproperty = function(_, prop)
				if prop == "invisible" then
					return false
				end
				return false
			end,
		},
	}
end

local function stub_map(w, h)
	mapwidth = w
	mapheight = h
	map = {}
	for x = 1, w do
		map[x] = {}
		for y = 1, h do
			map[x][y] = { 1 }
		end
	end
end

local function make_body(id, x, y, is_mover)
	return {
		static = not is_mover,
		active = true,
		x = x,
		y = y,
		width = 0.8,
		height = 0.8,
		speedx = is_mover and (0.3 + (id % 5) * 0.02) or 0,
		speedy = 0,
		category = 4,
		mask = {},
		gravitydirection = math.pi / 2,
		portalable = false,
	}
end

function M.setup_fixture(object_count)
	stub_globals()
	stub_tilequads()
	stub_map(64, 32)

	require("world.level")
	require("physics.late")
	require("core.maputil")
	require("core.tilekey")
	require("physics.convert")
	require("physics.dir")
	require("physics.collision")
	require("physics.handlegroup")
	require("physics.emance")
	require("physics.order")
	require("physics.update")

	objects = fresh_objects()
	objects["tile"] = {}

	local enemies = objects["enemy"]
	for i = 1, object_count do
		local x = 2 + (i % 20) * 1.2
		local y = 2 + math.floor(i / 20) * 1.2
		-- One mover + static targets: linear scaling, isolates per-target cost.
		enemies[i] = make_body(i, x, y, i == 1)
	end

	return objects
end

function M.bench_physics(object_count, opts)
	opts = opts or {}
	local work = opts.work or 100
	local rounds = opts.rounds or 5

	M.setup_fixture(object_count)

	local bench = require("tests.bench")
	local dt = 1 / 60
	return bench.run("physics_" .. object_count, function()
		for _ = 1, work do
			physicsupdate(dt)
		end
	end, {
		rounds = rounds,
		work = work,
		warmup = function()
			local nwarm = 500 + object_count * 10
			for _ = 1, nwarm do
				physicsupdate(dt)
			end
		end,
	})
end

function M.run_all(root)
	setup_path(root)
	local results = {}
	results["physics_10"] = M.bench_physics(10)
	results["physics_50"] = M.bench_physics(50)
	results["physics_200"] = M.bench_physics(200)
	return results
end

function M.run_checks(root, opts)
	opts = opts or {}
	local check_alloc = opts.check_alloc ~= false
	local failed = 0
	local function check(name, cond, detail)
		if cond then
			print("OK  " .. name)
		else
			failed = failed + 1
			print("FAIL " .. name .. (detail and (": " .. detail) or ""))
		end
	end

	local results = M.run_all(root)

	for _, key in ipairs({ "physics_10", "physics_50", "physics_200" }) do
		local r = results[key]
		print(string.format(
			"  %s: median=%.3f ms  alloc=%.1f KB  work=%d",
			r.name,
			r.median_ms,
			r.alloc_kb,
			r.work or 0
		))
		-- Sub-KB jitter from collectgarbage("count") resolution; steady-state hot path is zero-alloc.
		if check_alloc then
			check(r.name .. " zero alloc", r.alloc_kb < 1, string.format("%.1f KB", r.alloc_kb))
		end
	end

	local t10 = results["physics_10"].median_s
	local t50 = results["physics_50"].median_s
	local ratio = t50 / t10
	check(
		"scaling 10→50 not >5×",
		ratio <= 5.0,
		string.format("ratio=%.2f (10=%.4fs 50=%.4fs)", ratio, t10, t50)
	)

	return failed, results
end

-- Invoked from tests/run.lua with repo root (path contains / or is ".")
local root_arg = (...)
if type(root_arg) == "string" and (root_arg:find("/") or root_arg == ".") then
	local failed = M.run_checks(root_arg)
	return failed
end

-- Standalone: lua tests/perf_checks.lua
if arg and arg[0] and tostring(arg[0]):match("perf_checks%.lua$") then
	local info = debug.getinfo(1, "S").source
	local root = "."
	if info:sub(1, 1) == "@" then
		local path = info:sub(2)
		root = path:match("^(.*)/tests/perf_checks%.lua$") or "."
	end
	local failed, _ = M.run_checks(root)
	os.exit(failed > 0 and 1 or 0)
end

return M
