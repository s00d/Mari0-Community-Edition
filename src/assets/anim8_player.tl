--[[ anim8 player compat layer (v1) ]]

local Core = require("assets.anim8_core")

local M = {}

local DEFAULT_GROW_DELAY = 0.08
local DEFAULT_TAIL_DELAY = 0.08
local DEFAULT_SPIN_DELAY = 0.1

local function delay_or(value: number|nil, fallback: number): number
	if value and value > 0 then
		return value
	end
	return fallback
end

local function build_angle_set(
	char: Character,
	size_key: string,
	angle: integer,
	frame_duration: number,
	delays: {string: number}|nil
): {string: Anim8Animation}
	local run_row = (size_key == "small") and char.run[angle] or char.bigrun[angle]
	local jump_row = (size_key == "small") and char.jump[angle] or char.bigjump[angle]
	local swim_row = (size_key == "small") and char.swim[angle] or char.bigswim[angle]
	local climb_row = (size_key == "small") and char.climb[angle] or char.bigclimb[angle]

	local d = delays
	local grow_delay = delay_or(d and (d as {string: number})["grow"], DEFAULT_GROW_DELAY)
	local set = {
		run = Core.build_loop(Core.slice_quads(run_row as {any:any}, 1, char.runframes as integer), frame_duration),
		jump = Core.build_loop(Core.slice_quads(jump_row as {any:any}, 1, char.jumpframes as integer), frame_duration),
		swim = Core.build_loop(Core.slice_quads(swim_row as {any:any}, 1, 2), frame_duration),
		climb = Core.build_loop(Core.slice_quads(climb_row as {any:any}, 1, 2), frame_duration),
		grow = Core.build_loop({1, 2, 3} as {any}, grow_delay),
	} as {string: Anim8Animation}

	if size_key == "big" and (char.customframes or 0) >= 12 then
		local cf = char.bigcustomframe[angle] as {any:any}
		local tail_delay = delay_or(d and (d as {string: number})["tail"], DEFAULT_TAIL_DELAY)
		local spin_delay = delay_or(d and (d as {string: number})["spin"], DEFAULT_SPIN_DELAY)
		set.tailwag_glide = Core.build_loop(Core.slice_quads(cf, 4, 3), tail_delay)
		set.tailwag_fall = Core.build_loop(Core.slice_quads(cf, 10, 3), tail_delay)
		set.spin_ground = Core.build_loop(Core.slice_quads(cf, 1, 3), spin_delay)
		set.spin_air = Core.build_loop(Core.slice_quads(cf, 13, 3), spin_delay)
	end

	return set
end

local function clone_angle_set(set: {string: Anim8Animation}): {string: Anim8Animation}
	local out = {} as {string: Anim8Animation}
	for k, v in pairs(set) do
		out[k as string] = Core.clone(v as Anim8Animation)
	end
	return out
end

local function clone_bag(template: {string: {integer: {string: Anim8Animation}}}): {string: {integer: {string: Anim8Animation}}}
	local bag = {
		small = {} as {integer: {string: Anim8Animation}},
		big = {} as {integer: {string: Anim8Animation}},
	} as {string: {integer: {string: Anim8Animation}}}

	for sk, sizes in pairs(template) do
		local out_sizes = {} as {integer: {string: Anim8Animation}}
		for angle, set in pairs(sizes as {integer: {string: Anim8Animation}}) do
			out_sizes[angle] = clone_angle_set(set)
		end
		bag[sk] = out_sizes
	end

	return bag
end

function M.attach(char: Character, delays: {string: number}|nil)
	local quadnum = 5
	if char.nopointing then
		quadnum = 1
	end

	local frame_duration = 1
	local bag = {
		small = {} as {integer: {string: Anim8Animation}},
		big = {} as {integer: {string: Anim8Animation}},
	} as {string: {integer: {string: Anim8Animation}}}

	for i = 1, quadnum do
		bag.small[i] = build_angle_set(char, "small", i, frame_duration, delays)
		bag.big[i] = build_angle_set(char, "big", i, frame_duration, delays)
	end

	(char as {string:any})["anim8_template"] = bag
end

function M.init_instance(pl: mario)
	local raw = (pl.char as {string:any})["anim8_template"]
	if not raw then
		return
	end
	(pl as {string:any})["anim8"] = clone_bag(raw as {string: {integer: {string: Anim8Animation}}})
end

function M.angleframe(pl: mario): integer
	if pl.char.nopointing then
		return 1
	elseif not pl.portalsavailable[1] and not pl.portalsavailable[2] and not pl.char.nogunanimations then
		return 3
	else
		return (getAngleFrame(pl.pointingangle, pl.rotation) or 1) as integer
	end
end

local function size_key(size: number): string
	if size == 1 then
		return "small"
	end
	return "big"
end

function M.get(pl: mario, state: string): Anim8Animation|nil
	local raw = (pl as {string:any})["anim8"]
	if not raw then
		return nil
	end
	local bag = raw as {string: {integer: {string: Anim8Animation}}}
	local sk = size_key(pl.size)
	local af = M.angleframe(pl)
	local size_bag = bag[sk]
	if not size_bag then
		return nil
	end
	local angle_bag = size_bag[af]
	if not angle_bag then
		return nil
	end
	return angle_bag[state]
end

function M.step(anim: Anim8Animation|nil, dt: number, scale: number): integer
	return Core.step(anim, dt, scale)
end

function M.step_climb(pl: mario, dt: number, frame_delay: number): integer
	return Core.step_delay(M.get(pl, "climb"), dt, frame_delay)
end

function M.step_grow(pl: mario, dt: number): integer
	return Core.step_delay(M.get(pl, "grow"), dt, growframedelay)
end

function M.reset_grow(pl: mario)
	Core.reset(M.get(pl, "grow"), 1)
end

function M.reset(anim: Anim8Animation|nil, frame: integer)
	Core.reset(anim, frame)
end

function M.set_climb_frame(pl: mario, frame: integer)
	pl.climbframe = frame
	Core.reset(M.get(pl, "climb"), frame)
end

function M.reset_run(pl: mario)
	pl.runframe = 1
	Core.reset(M.get(pl, "run"), 1)
end

function M.reset_raccoon_spin(pl: mario)
	Core.reset(M.get(pl, "spin_ground"), 1)
	Core.reset(M.get(pl, "spin_air"), 1)
	pl.raccoonspinframe = 1
end

return M
