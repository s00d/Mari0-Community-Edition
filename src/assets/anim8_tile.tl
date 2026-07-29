--[[ anim8 tile helpers (animatedquad compat). ]]

local Core = require("assets.anim8_core")

local M = {}

function M.build_loop(quadlist: {any}, delays: {number}, on_frame: function({any:any})|nil): {any:any}
	return {
		anim = Core.build_sequence(quadlist, delays, nil),
		quadi = 1,
		on_frame = on_frame,
	} as {any:any}
end

function M.update(state: {any:any}, dt: number): integer
	local anim_n = state.anim
	if not anim_n then
		return state.quadi as integer
	end
	local anim = anim_n as Anim8Animation
	local prev = anim.position
	Core.step(anim, dt, 1)
	if anim.position ~= prev then
		state.quadi = anim.position
		local cb = state.on_frame
		if cb then
			(cb as function({any:any}))(state)
		end
	end
	return state.quadi as integer
end

function M.goto_frame(state: {any:any}, frame: integer)
	state.quadi = frame
	if state.anim then
		Core.reset(state.anim as Anim8Animation, frame)
	end
	local cb = state.on_frame
	if cb then
		(cb as function({any:any}))(state)
	end
end

return M

