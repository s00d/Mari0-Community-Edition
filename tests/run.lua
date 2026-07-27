--[[
  Test aggregator for Mari0 CE (no LÖVE required for default suite).
  Run: lua tests/run.lua   or   make test
]]

local root = ...
if not root or root == "" then
	-- When run as `lua tests/run.lua`, find repo root relative to this file.
	local info = debug.getinfo(1, "S").source
	if info:sub(1, 1) == "@" then
		local path = info:sub(2)
		root = path:match("^(.*)/tests/run%.lua$") or "."
	else
		root = "."
	end
end

-- Teal build/ + LuaRocks vendors in lib/ (dkjson, sha1)
package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	root .. "/?.lua",
	package.path,
}, ";")

local failed = 0
local ran = 0

local function run_file(rel)
	local path = root .. "/" .. rel
	print("=== " .. rel .. " ===")
	local chunk, err = loadfile(path)
	if not chunk then
		print("FAIL load " .. rel .. ": " .. tostring(err))
		failed = failed + 1
		ran = ran + 1
		return
	end
	local ok, result = pcall(chunk, root)
	ran = ran + 1
	if not ok then
		print("FAIL " .. rel .. ": " .. tostring(result))
		failed = failed + 1
	elseif type(result) == "number" then
		failed = failed + result
	end
	print("")
end

run_file("tests/issue_regression_checks.lua")
run_file("tests/static_api_lint.lua")
run_file("tests/global_freeze_checks.lua")
run_file("tests/steptimer_checks.lua")
run_file("tests/rng_checks.lua")
run_file("tests/level_roundtrip_checks.lua")
run_file("tests/level_leak_checks.lua")
run_file("tests/physics_order_checks.lua")
run_file("tests/session_checks.lua")
run_file("tests/net_checks.lua")
run_file("tests/gc_checks.lua")
run_file("tests/transition_checks.lua")
run_file("tests/camera_follow_checks.lua")
run_file("tests/helper_checks.lua")
run_file("tests/teal_checks.lua")
run_file("tests/collision_checks.lua")
run_file("tests/perf_gate.lua")
run_file("tests/portal_checks.lua")
run_file("tests/portal_platform_checks.lua")
run_file("tests/spritebatch_portal_checks.lua")
run_file("tests/fork_ideas_checks.lua")
run_file("tests/checkrect_checks.lua")
run_file("tests/spawn_checks.lua")
run_file("tests/levelio_checks.lua")
run_file("tests/vglc_import_checks.lua")
run_file("tests/tileset_props_checks.lua")
run_file("tests/mapsdk_checks.lua")
run_file("tests/mappack_convert_checks.lua")
run_file("tests/editor_checks.lua")
run_file("tests/menu_checks.lua")
run_file("tests/weapon_checks.lua")
run_file("tests/weapon_interact_checks.lua")
run_file("tests/gel_checks.lua")

print(string.format("Suites: %d  Failures: %d", ran, failed))
if failed > 0 then
	os.exit(1)
end
print("All tests passed.")
os.exit(0)
