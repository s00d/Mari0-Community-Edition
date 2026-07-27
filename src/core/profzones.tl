--[[ Thin named-zone profiler (jprof-style push/pop, no MessagePack dependency). ]]

local ENABLED: boolean = false
local stack: {string} = {}
local stack_t0: {number} = {}
local totals: {string:number} = {}
local counts: {string:integer} = {}
local frame_totals: {string:number} = {}

local function now(): number
	if love and love.timer and love.timer.getTime then
		return love.timer.getTime()
	end
	return os.clock()
end

global function profzones_set_enabled(v: boolean)
	ENABLED = v
end

global function profzones_enabled(): boolean
	return ENABLED
end

global function profzones_toggle(): boolean
	ENABLED = not ENABLED
	if not ENABLED then
		for i = #stack, 1, -1 do
			stack[i] = nil as string
			stack_t0[i] = nil as number
		end
	end
	return ENABLED
end

global function prof_push(name: string)
	if not ENABLED then
		return
	end
	local n = #stack + 1
	stack[n] = name
	stack_t0[n] = now()
end

global function prof_pop(name: string|nil)
	if not ENABLED then
		return
	end
	local n = #stack
	if n < 1 then
		return
	end
	local zone = stack[n]
	if name ~= nil and name ~= zone then
		-- mismatched pop: still close top
	end
	local dt = now() - (stack_t0[n] or now())
	stack[n] = nil as string
	stack_t0[n] = nil as number
	totals[zone] = (totals[zone] or 0) + dt
	counts[zone] = (counts[zone] or 0) + 1
	frame_totals[zone] = (frame_totals[zone] or 0) + dt
end

global function profzones_frame_begin()
	if not ENABLED then
		return
	end
	for k in pairs(frame_totals) do
		frame_totals[k] = 0
	end
end

global function profzones_report(limit: integer|nil): string
	local lim = limit or 12
	local rows: {{string|number}} = {}
	for name, t in pairs(totals) do
		table.insert(rows, {name, t, counts[name] or 0})
	end
	table.sort(rows, function(a: {string|number}, b: {string|number}): boolean
		return (a[2] as number) > (b[2] as number)
	end)
	local lines: {string} = {"=== profzones top " .. tostring(lim) .. " ==="}
	for i = 1, math.min(lim, #rows) do
		local r = rows[i]
		table.insert(lines, string.format(
			"%2d  %-28s  %.3f ms  n=%d",
			i,
			r[1] as string,
			(r[2] as number) * 1000,
			r[3] as integer
		))
	end
	return table.concat(lines, "\n")
end

global function profzones_reset()
	for k in pairs(totals) do
		totals[k] = nil as number
	end
	for k in pairs(counts) do
		counts[k] = nil as integer
	end
	for k in pairs(frame_totals) do
		frame_totals[k] = nil as number
	end
	for i = #stack, 1, -1 do
		stack[i] = nil as string
		stack_t0[i] = nil as number
	end
end

return {
	prof_push = prof_push,
	prof_pop = prof_pop,
	profzones_set_enabled = profzones_set_enabled,
	profzones_enabled = profzones_enabled,
	profzones_toggle = profzones_toggle,
	profzones_frame_begin = profzones_frame_begin,
	profzones_report = profzones_report,
	profzones_reset = profzones_reset,
}
