-- In-game frame time ring buffer (p50/p95/p99 percentiles).

local CAPACITY: integer = 300
local times: {number} = {}
local head: integer = 0
local count: integer = 0

local function percentile(sorted: {number}, p: number): number
	if #sorted == 0 then
		return 0
	end
	local rank = math.ceil((p / 100) * #sorted)
	if rank < 1 then
		rank = 1
	end
	if rank > #sorted then
		rank = #sorted
	end
	return sorted[rank]
end

global function frametime_record(dt: number)
	head = head + 1
	if head > CAPACITY then
		head = 1
	end
	times[head] = dt
	if count < CAPACITY then
		count = count + 1
	end
end

global function frametime_percentiles(): number, number, number
	local sorted: {number} = {}
	for i = 1, count do
		sorted[i] = times[i]
	end
	table.sort(sorted)
	return percentile(sorted, 50), percentile(sorted, 95), percentile(sorted, 99)
end

global function frametime_reset()
	head = 0
	count = 0
	for i = 1, CAPACITY do
		times[i] = nil as number
	end
end

return {
	frametime_record = frametime_record,
	frametime_percentiles = frametime_percentiles,
	frametime_reset = frametime_reset,
	CAPACITY = CAPACITY,
}
