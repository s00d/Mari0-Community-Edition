--[[ Shared anim8 helpers + non-sprite timers (hold, blink, lerp, flip, counter). ]]

local anim8 = require("anim8")

local M = {}

function M.build_loop(frames: {any}, frame_delay: number): Anim8Animation
	return (anim8.newAnimation as function({any}, number))(frames, frame_delay)
end

function M.build_sequence(frames: {any}, delays: {number}, onLoop: (function|nil)): Anim8Animation
	return (anim8.newAnimation as function({any}, {number}, (function|nil)))(frames, delays, onLoop)
end

function M.clone(anim: Anim8Animation): Anim8Animation
	return (anim as Anim8Animation):clone()
end

function M.step(anim: Anim8Animation|nil, dt: number, scale: number): integer
	if not anim then
		return 1
	end
	local a = anim as Anim8Animation
	a:update(dt * scale)
	return a.position
end

function M.step_delay(anim: Anim8Animation|nil, dt: number, frame_delay: number): integer
	if frame_delay <= 0 then
		frame_delay = 0.1
	end
	return M.step(anim, dt, 1 / frame_delay)
end

function M.quad_at(anim: Anim8Animation|nil, quads: {integer: any}): any
	if not anim then
		return quads[1]
	end
	return quads[(anim as Anim8Animation).position]
end

function M.reset(anim: Anim8Animation|nil, frame: integer)
	if not anim then
		return
	end
	(anim as Anim8Animation):gotoFrame(frame)
end

-- Hold timer: returns elapsed time after tick (cap at duration).
function M.hold_tick(t: number, dt: number, duration: number): number
	local next_t = t + dt
	if next_t > duration then
		return duration
	end
	return next_t
end

function M.hold_active(t: number, duration: number): boolean
	return t < duration
end

function M.hold_reset(): number
	return 0
end

function M.hold_expired(_t: number, duration: number): number
	return duration
end

-- Blink: true on first half of each period.
function M.blink_visible(t: number, half_period: number): boolean
	if half_period <= 0 then
		return true
	end
	return math.ceil(math.fmod(t, half_period * 2) / half_period) == 1
end

-- Lerp segment: advance t toward duration, return interpolated value.
function M.lerp_tick(t: number, dt: number, duration: number, from: number, to: number): number, number
	local next_t = t + dt
	if next_t >= duration then
		return duration, to
	end
	local alpha = next_t / duration
	return next_t, from + (to - from) * alpha
end

function M.lerp_value(t: number, duration: number, from: number, to: number): number
	if duration <= 0 then
		return to
	end
	local alpha = math.min(1, t / duration)
	return from + (to - from) * alpha
end

-- Mirror flip: toggle direction each interval. Returns new direction string.
function M.flip_on_interval(timer: number, dt: number, delay: number, direction: string): number, string
	local t = timer + dt
	while t > delay do
		t = t - delay
		if direction == "left" then
			direction = "right"
		else
			direction = "left"
		end
	end
	return t, direction
end

-- Frame counter 1..max (wraps). Returns timer, frame.
function M.advance_counter(timer: number, dt: number, delay: number, max_frame: integer): number, integer
	local t = timer + dt
	local frame = 1
	while t > delay do
		frame = frame + 1
		t = t - delay
		if frame > max_frame then
			frame = 1
		end
	end
	return t, frame
end

-- One-shot counter 1..max (no wrap). Returns timer, frame, done.
function M.advance_counter_once(timer: number, dt: number, delay: number, max_frame: integer): number, integer, boolean
	local t = timer + dt
	local frame = 1
	while t > delay do
		frame = frame + 1
		t = t - delay
		if frame >= max_frame then
			return t, max_frame, true
		end
	end
	return t, frame, false
end

-- Spawn ticks: call spawn_fn each interval while timer < limit.
function M.interval_spawns(timer: number, dt: number, delay: number, limit: number, spawn_fn: function()): number
	local t = timer + dt
	if t >= limit then
		return t
	end
	while t > delay do
		spawn_fn()
		t = t - delay
	end
	return t
end

-- Returns updated timer and whether interval elapsed (at least once).
function M.tick_interval(timer: number, dt: number, delay: number): number, boolean
	local t = timer + dt
	local fired = false
	while t > delay do
		t = t - delay
		fired = true
	end
	return t, fired
end

function M.slice_quads(row: {any:any}, start_idx: integer, count: integer): {any}
	local frames: {any} = {} as {any}
	for i = 1, count do
		frames[i] = row[start_idx + i - 1]
	end
	return frames
end

return M
