-- Physics collision ordering + tiny pure helpers (safe extractions from physics.lua).

-- Object types collided after tiles (hash for O(1) skip in early pass)
PHYSICS_LATE_SET = {
	portalwall = true,
	castlefirefire = true,
	platform = true,
}
PHYSICS_LATE_LIST = {"portalwall", "castlefirefire", "platform"}

-- Entity types that need collision callback before position update
local PREROTATE_SET: {string:boolean} = {
	goomba = true,
	koopa = true,
	hammerbros = true,
	lakito = true,
	cheep = true,
	flyingfish = true,
	squid = true,
}

global function prerotatecall(a: any, b: any): boolean
	return PREROTATE_SET[a as string] == true
end

global function aabb(ax: number, ay: number, awidth: number, aheight: number, bx: number, by: number, bwidth: number, bheight: number): boolean
	return ax+awidth > bx and ax < bx+bwidth and ay+aheight > by and ay < by+bheight
end

global function aabt(ax: number, ay: number, awidth: number, aheight: number, bx: number, by: number, bwidth: number, bheight: number, bdir: any): boolean|nil
	if bdir == "ur" then
		return ax+awidth > bx and ax < bx+bwidth and ay+aheight > by and ay < by+bheight and ay + aheight - by > ax - bx
	elseif bdir == "ul" then
		return ax+awidth > bx and ax < bx+bwidth and ay+aheight > by and ay < by+bheight and ay + aheight - by > bheight - ax - awidth + bx
	elseif bdir == "dl" then
		return ax+awidth > bx and ax < bx+bwidth and ay+aheight > by and ay < by+bheight and ay - by < ax+awidth - bx
	elseif bdir == "dr" then
		return ax+awidth > bx and ax < bx+bwidth and ay+aheight > by and ay < by+bheight and ay - by < bwidth- ax + bx
	end
	return nil
end
