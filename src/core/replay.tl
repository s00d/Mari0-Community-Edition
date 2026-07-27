--[[ Golden replay harness skeleton: per-frame input + optional physics snapshot.

Minimal viable: record/replay tables for regression tests. Not a full demo recorder.
]]

local record ReplayFrame
	input: {string:boolean}
	snapshot: {string:number}|nil
end

local record Replay
	seed: number|nil
	frames: {ReplayFrame}
end

local function new_replay(seed: number|nil): Replay
	return {
		seed = seed,
		frames = {},
	}
end

local function record_frame(r: Replay, input: {string:boolean}, snapshot: {string:number}|nil)
	table.insert(r.frames, {
		input = input,
		snapshot = snapshot,
	})
end

local function frame_count(r: Replay): integer
	return #r.frames
end

local function get_frame(r: Replay, i: integer): ReplayFrame|nil
	return r.frames[i]
end

-- Compare two snapshots; returns true if all keys in expected match within eps.
local function snapshots_match(a: {string:number}|nil, b: {string:number}|nil, eps: number|nil): boolean
	if a == nil and b == nil then
		return true
	end
	if a == nil or b == nil then
		return false
	end
	local left = a as {string:number}
	local right = b as {string:number}
	local e = eps or 1e-6
	for k, v in pairs(left) do
		local other = right[k]
		if other == nil or math.abs((other as number) - v) > e then
			return false
		end
	end
	for k in pairs(right) do
		if left[k] == nil then
			return false
		end
	end
	return true
end

-- Serialize to a plain table (JSON-friendly).
local function export_replay(r: Replay): {string:any}
	return {
		seed = r.seed,
		frames = r.frames,
	}
end

local function load_replay(data: {string:any}): Replay
	local frames = (data.frames as {ReplayFrame}) or {}
	return {
		seed = data.seed as number|nil,
		frames = frames,
	}
end

-- Run recorded frames through a step callback; callback(input, i) -> snapshot.
-- Returns first mismatch frame index, or 0 if all match.
local function replay_verify(
	r: Replay,
	step: function({string:boolean}, integer): {string:number}|nil,
	eps: number|nil
): integer
	for i = 1, #r.frames do
		local f = r.frames[i]
		local got = step(f.input, i)
		if f.snapshot ~= nil and not snapshots_match(f.snapshot, got, eps) then
			return i
		end
	end
	return 0
end

_G.Replay_new = new_replay
_G.Replay_record = record_frame
_G.Replay_frame_count = frame_count
_G.Replay_get_frame = get_frame
_G.Replay_snapshots_match = snapshots_match
_G.Replay_export = export_replay
_G.Replay_load = load_replay
_G.Replay_verify = replay_verify

return {
	new = new_replay,
	record = record_frame,
	frame_count = frame_count,
	get_frame = get_frame,
	snapshots_match = snapshots_match,
	export = export_replay,
	load = load_replay,
	verify = replay_verify,
}
