--[[ Camera shake amplitude via Flux (replaces manual earthquake decay). ]]

local state: {string:number} = { amp = 0 }
local active: FluxTween|nil = nil

global function screenshake(power: number)
	local t = active
	if t ~= nil then
		(t as FluxTween):stop()
		active = nil
	end
	if power <= 0 then
		state.amp = 0
		return
	end
	state.amp = math.max(state.amp, power)
	-- expo-out ≈ old exponential falloff; duration scales with amplitude
	local duration = 0.45 + math.min(2, state.amp * 0.015)
	active = Flux.to(state, duration, { amp = 0 }):ease("expoout")
end

global function screenshake_amp(): number
	return state.amp
end
