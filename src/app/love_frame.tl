--[[ Per-frame timing state for love.update (module-local; global_freeze safe). ]]

local LoveFrame = {}

local steptimer: number = 0
local skip_update = false

function LoveFrame.request_skip_update()
	skip_update = true
end

function LoveFrame.begin_update(): boolean
	if skip_update then
		skip_update = false
		steptimer = 0
		return false
	end
	return true
end

function LoveFrame.add_time(delta: number)
	steptimer = steptimer + delta
end

function LoveFrame.try_step(cost: number): boolean
	if steptimer >= cost then
		steptimer = steptimer - cost
		return true
	end
	return false
end

function LoveFrame.has_pending_step(cost: number): boolean
	return steptimer >= cost
end

function LoveFrame.clear_debt()
	steptimer = 0
end

return LoveFrame
