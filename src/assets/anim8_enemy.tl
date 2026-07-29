--[[ anim8 enemy compat layer (v1) ]]

local Core = require("assets.anim8_core")

local M = {}

function M.build_cycle(ed: {string:any}): Anim8Animation|nil
	if (ed["animationtype"] as string) ~= "frames" then
		return nil
	end
	if not ed["quadgroup"] then
		return nil
	end

	local qg = ed["quadgroup"] as {integer: any}
	local start = ed["animationstart"] as integer
	local count = ed["animationframes"] as integer
	local frames = Core.slice_quads(qg, start, count)
	local speed = ed["animationspeed"] as number|nil
	if not speed or speed <= 0 then
		speed = 0.15
	end

	return Core.build_loop(frames, speed)
end

local SQUID_QUAD = {
	idle = 1,
	upward = 2,
	downward = 1,
} as {string: integer}

function M.apply_squid_quad(self: enemy, state: string)
	if (self.animationtype as string) ~= "squid" then
		return
	end
	local idx = SQUID_QUAD[state]
	if idx and self.quadgroup then
		self.quad = (self.quadgroup as {integer: any})[idx]
	end
end

return M
