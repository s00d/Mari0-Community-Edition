-- Object-group collision pass (depends on checkcollision).

global function handlegroup(i: any, h: any, u: {any:Body}, v: Body, j: any, dt: number, passed: any): boolean, boolean
	local horcollision = false
	local vercollision = false
	local group = u
	local mover = v
	for g, t in pairs(group) do
		--    Same object?          Active                 Not masked
		if (i ~= g or j ~= h) and t.active then
			-- Broadphase: skip pairs that cannot overlap this frame
			if not aabb(mover.x, mover.y, mover.width, mover.height, t.x, t.y, t.width, t.height) then
				-- continue
			else
			local mmask = mover.mask
			local tmask = t.mask
			if (mmask == nil or (mmask as {number:boolean})[t.category] ~= true) and (tmask == nil or (tmask as {number:boolean})[mover.category] ~= true) then
				-- checkcollision needs full Entity (collision callbacks, etc).
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

	return horcollision, vercollision
end
