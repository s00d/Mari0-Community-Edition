-- Object-group collision pass via bump broadphase → checkcollision.

require("physics.world")

global function handlegroup(i: any, h: any, u: {any:Body}, v: Body, j: any, dt: number, passed: any): boolean, boolean
	local horcollision = false
	local vercollision = false
	local group = u
	local mover = v
	local sx = mover.speedx or 0
	local sy = mover.speedy or 0

	local smx = mover.x + math.min(0, sx * dt)
	local smy = mover.y + math.min(0, sy * dt)
	local smw = mover.width + math.abs(sx * dt)
	local smh = mover.height + math.abs(sy * dt)

	local group_name = h as string

	local function group_filter(item: any): boolean
		local g = physics_world_meta(item)
		return g == group_name
	end

	local items: {integer: any}
	local len: number
	items, len = physics_world_query(smx, smy, smw, smh, group_filter)

	for ii = 1, len do
		local t = items[ii as integer] as Body
		if t and t.active then
			local meta_group: string|nil
			local g: any
			meta_group, g = physics_world_meta(t)
			if meta_group == group_name and g ~= nil and (i ~= g or j ~= h) then
				if group[g] == t then
					local mmask = mover.mask
					local tmask = t.mask
					if (mmask == nil or (mmask as {number:boolean})[t.category] ~= true) and (tmask == nil or (tmask as {number:boolean})[mover.category] ~= true) then
						local collision1, collision2 = checkcollision(mover as Entity, t as Entity, h, g, j, i, dt, passed)
						if collision1 then
							horcollision = true
						elseif collision2 then
							vercollision = true
						end
					end
				end
			end
		end
	end

	return horcollision, vercollision
end
