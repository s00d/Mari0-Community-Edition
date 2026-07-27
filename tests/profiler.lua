--[[
  Optional sampling profiler (not run in CI by default).
  Use when perf_gate fails to locate hot lines / alloc sources.

  Usage:
    local profiler = require("tests.profiler")
    profiler.start("time")   -- or "alloc"
    ... code ...
    local report = profiler.stop()
    profiler.print_report(report, 20)
]]

local profiler = {}

local hook_mode = nil
local hook_counts = {}
local hook_allocs = {}
local last_mem = 0
local running = false

local function line_key(info)
	return (info.short_src or "?") .. ":" .. tostring(info.currentline or 0)
end

local function time_hook(_)
	local key = line_key(debug.getinfo(2, "Sl"))
	hook_counts[key] = (hook_counts[key] or 0) + 1
end

local function alloc_hook(_)
	local key = line_key(debug.getinfo(2, "Sl"))
	local mem = collectgarbage("count")
	local delta = mem - last_mem
	last_mem = mem
	hook_allocs[key] = (hook_allocs[key] or 0) + delta
	hook_counts[key] = (hook_counts[key] or 0) + 1
end

function profiler.start(mode)
	if running then
		error("profiler already running")
	end
	mode = mode or "time"
	hook_mode = mode
	hook_counts = {}
	hook_allocs = {}
	last_mem = collectgarbage("count")
	running = true
	if mode == "alloc" then
		debug.sethook(alloc_hook, "l")
	else
		debug.sethook(time_hook, "l")
	end
end

function profiler.stop()
	if not running then
		error("profiler not running")
	end
	debug.sethook()
	running = false
	return {
		mode = hook_mode,
		counts = hook_counts,
		allocs = hook_allocs,
	}
end

local function sorted_entries(t, limit)
	local entries = {}
	for k, v in pairs(t) do
		entries[#entries + 1] = { key = k, value = v }
	end
	table.sort(entries, function(a, b)
		return a.value > b.value
	end)
	if limit and #entries > limit then
		local trimmed = {}
		for i = 1, limit do
			trimmed[i] = entries[i]
		end
		return trimmed
	end
	return entries
end

function profiler.print_report(report, limit)
	limit = limit or 20
	print("=== profiler (" .. report.mode .. ") top " .. limit .. " ===")
	local metric = report.mode == "alloc" and report.allocs or report.counts
	for _, e in ipairs(sorted_entries(metric, limit)) do
		local unit = report.mode == "alloc" and " KB" or ""
		print(string.format("  %8.1f%s  %s", e.value, unit, e.key))
	end
end

return profiler
