--[[ UI run preview — cloned anim8 run cycle for lobby/online player cards. ]]

local Core = require("assets.anim8_core")

local M = {}

local preview: Anim8Animation|nil = nil
local preview_rundelay: number = 10

local function pick_run_template(char: Character): Anim8Animation|nil
	local raw = (char as {string:any})["anim8_template"]
	if not raw then
		return nil
	end
	local bag = raw as {string: {integer: {string: Anim8Animation}}}
	local angle = 3
	if char.nopointing then
		angle = 1
	end
	local size_bag = bag.small
	if not size_bag then
		return nil
	end
	local angle_bag = size_bag[angle]
	if not angle_bag then
		return nil
	end
	return angle_bag.run
end

function M.attach_char(char: Character)
	local run = pick_run_template(char)
	if run then
		preview = Core.clone(run as Anim8Animation)
	else
		preview = nil
	end
	preview_rundelay = (char.rundelay or runanimationspeed) as number
end

function M.update(dt: number)
	local scale = (4 / 5) * preview_rundelay
	Core.step(preview, dt, scale)
end

function M.frame(): integer
	if preview then
		return (preview as Anim8Animation).position
	end
	return 1
end

return M
