--[[ Global sprite cycle templates (portal, fire, fireball) from boot quads. ]]

local Core = require("assets.anim8_core")

local M = {}

local portal_template: Anim8Animation|nil = nil
local fire_template: Anim8Animation|nil = nil
local fireball_loop_template: Anim8Animation|nil = nil
local fireball_die_template: Anim8Animation|nil = nil
local bowser_walk_template: Anim8Animation|nil = nil

function M.init()
	if portalquad then
		local pq = portalquad as {integer: any}
		local frames = {} as {integer: any}
		local count = portalanimationcount as integer
		for i = 1, count do
			frames[i] = pq[i]
		end
		portal_template = Core.build_loop(frames as {any}, portalanimationdelay)
	end

	if firequad then
		local fq = firequad as {integer: any}
		if fq[1] and fq[2] then
			fire_template = Core.build_loop({fq[1], fq[2]}, fireanimationdelay)
		end
	end

	if fireballquad then
		local fbq = fireballquad as {integer: any}
		if fbq[7] then
			fireball_loop_template = Core.build_loop({
				fbq[1], fbq[2], fbq[3], fbq[4],
			}, staranimationdelay)
			fireball_die_template = Core.build_sequence({
				fbq[5], fbq[6], fbq[7],
			}, {staranimationdelay, staranimationdelay, staranimationdelay}, nil)
		end
	end

	bowser_walk_template = Core.build_loop({1, 2} as {any}, bowseranimationspeed)
end

function M.new_portal(): Anim8Animation|nil
	if portal_template then
		return Core.clone(portal_template)
	end
	return nil
end

function M.step_portal(anim: Anim8Animation|nil, dt: number): integer
	return Core.step_delay(anim, dt, portalanimationdelay)
end

function M.portal_quad(anim: Anim8Animation|nil): any
	return Core.quad_at(anim, portalquad as {integer: any})
end

function M.portal_glow_alpha(frame: integer): number
	return 1 - math.abs(frame - 3) / 3
end

function M.new_fire(): Anim8Animation|nil
	if fire_template then
		return Core.clone(fire_template)
	end
	return nil
end

function M.step_fire(anim: Anim8Animation|nil, dt: number): any
	Core.step_delay(anim, dt, fireanimationdelay)
	return Core.quad_at(anim, firequad as {integer: any})
end

function M.new_fireball_loop(): Anim8Animation|nil
	if fireball_loop_template then
		return Core.clone(fireball_loop_template)
	end
	return nil
end

function M.new_fireball_die(): Anim8Animation|nil
	if fireball_die_template then
		return Core.clone(fireball_die_template)
	end
	return nil
end

function M.step_fireball_loop(anim: Anim8Animation|nil, dt: number): any
	Core.step_delay(anim, dt, staranimationdelay)
	return Core.quad_at(anim, fireballquad as {integer: any})
end

function M.step_fireball_die(anim: Anim8Animation|nil, dt: number): any, boolean
	if not anim then
		return fireballquad[7], true
	end
	local a = anim as Anim8Animation
	if a.status == "paused" then
		return fireballquad[7], true
	end
	Core.step_delay(anim, dt, staranimationdelay)
	local quad = fireballquad[4 + a.position]
	if a.position >= 3 then
		a:pauseAtEnd()
		return quad, true
	end
	return quad, false
end

function M.fireball_loop_quad_at(anim: Anim8Animation|nil, index: integer): any
	if anim then
		Core.reset(anim, index)
	end
	return fireballquad[index]
end

function M.new_bowser_walk(): Anim8Animation|nil
	if bowser_walk_template then
		return Core.clone(bowser_walk_template)
	end
	return nil
end

function M.step_bowser_walk(anim: Anim8Animation|nil, dt: number): integer
	return Core.step_delay(anim, dt, bowseranimationspeed)
end

local menu_portal: Anim8Animation|nil = nil

function M.menu_portal_reset()
	menu_portal = M.new_portal()
end

function M.menu_portal_step(dt: number): integer
	return M.step_portal(menu_portal, dt)
end

return M
