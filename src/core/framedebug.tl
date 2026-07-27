--[[ Frame step / pause / fast-forward (mari0-2 FrameDebug3, MIT-inspired, minimal). ]]

local FrameDebug = {}

local ADVANCE_DT: number = 1 / 60
local playing: boolean = true
local advance_frame: boolean = false
local ff_mul: number = 1

function FrameDebug.is_playing(): boolean
	return playing
end

function FrameDebug.set_playing(v: boolean)
	playing = v
end

function FrameDebug.pause_play()
	playing = not playing
end

function FrameDebug.frame_advance()
	playing = false
	advance_frame = true
end

-- Hold-key multipliers (checked each update). Right-shift = 4x, right-ctrl = 0.25x.
function FrameDebug.poll_ff_keys()
	ff_mul = 1
	if not love or not love.keyboard or not love.keyboard.isDown then
		return
	end
	if love.keyboard.isDown("rshift") then
		ff_mul = ff_mul * 4
	end
	if love.keyboard.isDown("rctrl") then
		ff_mul = ff_mul * 0.25
	end
end

-- Returns scaled dt, or false when paused with no frame-advance pending.
function FrameDebug.apply(dt: number): number|boolean
	FrameDebug.poll_ff_keys()
	if not playing then
		if advance_frame then
			advance_frame = false
			return ADVANCE_DT * ff_mul
		end
		return false
	end
	return dt * ff_mul
end

return FrameDebug
