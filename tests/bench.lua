--[[
  Reusable micro-benchmark harness (no LÖVE).
  Measures fixed work → median time over N rounds, plus allocation delta.
]]

local bench = {}

local function median(values)
	if #values == 0 then
		return 0
	end
	local sorted = {}
	for i = 1, #values do
		sorted[i] = values[i]
	end
	table.sort(sorted)
	local n = #sorted
	if n % 2 == 1 then
		return sorted[(n + 1) / 2]
	end
	return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
end

--- Run a benchmark.
-- @param name string label for logging
-- @param fn function body to time (should perform fixed `work` internally)
-- @param opts table optional: rounds (default 5), work (iteration count hint), warmup (function run after GC, before measure)
-- @return table { name, median_s, median_ms, alloc_kb, rounds, work }
function bench.run(name, fn, opts)
	opts = opts or {}
	local rounds = opts.rounds or 5
	local work = opts.work
	local warmup = opts.warmup

	local times = {}
	local allocs = {}

	for _ = 1, rounds do
		collectgarbage("collect")
		if warmup then
			warmup()
		end
		local mem_before = collectgarbage("count")
		local t0 = os.clock()
		fn()
		local t1 = os.clock()
		local mem_after = collectgarbage("count")

		times[#times + 1] = t1 - t0
		allocs[#allocs + 1] = mem_after - mem_before
	end

	local med_s = median(times)
	return {
		name = name,
		median_s = med_s,
		median_ms = med_s * 1000,
		alloc_kb = median(allocs),
		rounds = rounds,
		work = work,
	}
end

return bench
