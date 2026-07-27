--[[ Headless golden-replay helpers (no LÖVE).
     Replay index advancement mirrors game_update.tl; scripted sim uses fixed dt. ]]

local ReplayHarness = {}

local record ScriptedPlayer
	x: number
	y: number
	speedx: number
	speedy: number
	jumping: boolean
	grounded: boolean
end

local record ScriptedInput
	right: boolean
	left: boolean
	jump: boolean
end

local function round6(n: number): number
	return math.floor(n * 1000000 + 0.5) / 1000000
end

-- Advance replaydata indices (same loop as game_update when replaysystem is on).
function ReplayHarness.advance_replay_indices(
	replaydata: {any},
	replaytimer: {number},
	replayi: {number},
	dt: number
)
	for j = 1, #replaydata do
		local rep = replaydata[j] as {string: any}
		local rdata = rep.data as {integer: any}
		if rdata then
			replaytimer[j] = replaytimer[j] + dt
			local idx = replayi[j] as integer
			while idx < #rdata and ((rdata[idx] as {string: any}).time as number) < replaytimer[j] do
				idx = idx + 1
				replayi[j] = idx
			end
		end
	end
end

-- Minimal integrator for golden hashes (not full Mario physics).
function ReplayHarness.step_scripted_player(p: ScriptedPlayer, input: ScriptedInput, dt: number)
	local accel = 8.0
	local maxrun = 4.0
	local gravity = 30.0
	local jumpv = -9.0

	if input.right then
		p.speedx = math.min(maxrun, p.speedx + accel * dt)
	elseif input.left then
		p.speedx = math.max(-maxrun, p.speedx - accel * dt)
	else
		if p.speedx > 0 then
			p.speedx = math.max(0, p.speedx - accel * dt)
		elseif p.speedx < 0 then
			p.speedx = math.min(0, p.speedx + accel * dt)
		end
	end

	if input.jump and p.grounded then
		p.speedy = jumpv
		p.jumping = true
		p.grounded = false
	end

	p.speedy = p.speedy + gravity * dt
	p.x = p.x + p.speedx * dt
	p.y = p.y + p.speedy * dt

	if p.y >= 0 then
		p.y = 0
		p.speedy = 0
		p.grounded = true
		p.jumping = false
	end
end

function ReplayHarness.fingerprint_players(players: {ScriptedPlayer}): string
	local parts: {string} = {}
	for i = 1, #players do
		local p = players[i]
		parts[#parts + 1] = string.format(
			"%d:%.6f,%.6f,%.6f,%.6f",
			i,
			round6(p.x),
			round6(p.y),
			round6(p.speedx),
			round6(p.speedy)
		)
	end
	return table.concat(parts, ";")
end

function ReplayHarness.fingerprint_replay_indices(replayi: {number}): string
	local parts: {string} = {}
	for i = 1, #replayi do
		parts[#parts + 1] = tostring(replayi[i])
	end
	return table.concat(parts, ",")
end

return ReplayHarness
