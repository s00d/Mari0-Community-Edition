--[[
  Performance gate: compare current benchmarks against tests/baseline.json.
  Regenerate baseline: UPDATE_BASELINE=1 make test
]]

local root = ... or "."

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	root .. "/tests/?.lua",
	package.path,
}, ";")

local json = require("dkjson")
local perf_checks = require("tests.perf_checks")

local TIME_FACTOR = 1.5
-- GC timing noise: alloc_kb can jitter by fractions of a KB across runs.
local ALLOC_EPS_KB = 1.0
local BASELINE_PATH = root .. "/tests/baseline.json"

local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

local function load_baseline()
	local f = io.open(BASELINE_PATH, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return json.decode(content)
end

local function save_baseline(data)
	local f = io.open(BASELINE_PATH, "w")
	if not f then
		error("cannot write " .. BASELINE_PATH)
	end
	f:write(json.encode(data, { indent = true }))
	f:write("\n")
	f:close()
end

local function results_to_baseline(results)
	local baseline = {}
	for name, r in pairs(results) do
		baseline[name] = {
			median_s = r.median_s,
			median_ms = r.median_ms,
			alloc_kb = r.alloc_kb,
			work = r.work,
		}
	end
	return baseline
end

print("Running performance benchmarks...")

if os.getenv("UPDATE_BASELINE") == "1" then
	local results = perf_checks.run_all(root)
	for _, key in ipairs({ "physics_10", "physics_50", "physics_200" }) do
		local r = results[key]
		print(string.format(
			"  %s: median=%.3f ms  alloc=%.1f KB  work=%d",
			r.name,
			r.median_ms,
			r.alloc_kb,
			r.work or 0
		))
	end
	local baseline = results_to_baseline(results)
	save_baseline(baseline)
	print("Wrote baseline to " .. BASELINE_PATH)
	if select("#", ...) > 0 then
		return 0
	end
	os.exit(0)
end

local check_failed, results = perf_checks.run_checks(root, { check_alloc = false })
failed = failed + check_failed

local baseline = load_baseline()
if not baseline then
	check("baseline.json exists", false, "run UPDATE_BASELINE=1 make test first")
	if select("#", ...) > 0 then
		return failed + 1
	end
	os.exit(1)
end

print("")
print("Comparing against baseline (time >" .. TIME_FACTOR .. "× fails, alloc strict):")

for name, current in pairs(results) do
	local base = baseline[name]
	if not base then
		check(name .. " in baseline", false, "missing entry")
	else
		local time_limit = base.median_s * TIME_FACTOR
		check(
			name .. " time",
			current.median_s <= time_limit,
			string.format(
				"current=%.4fs baseline=%.4fs limit=%.4fs",
				current.median_s,
				base.median_s,
				time_limit
			)
		)
		check(
			name .. " alloc",
			current.alloc_kb <= base.alloc_kb + ALLOC_EPS_KB,
			string.format(
				"current=%.1f KB baseline=%.1f KB",
				current.alloc_kb,
				base.alloc_kb
			)
		)
	end
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
