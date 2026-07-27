-- Object-group collision pass (depends on checkcollision).

global function handlegroup(i: any, h: any, u: {any:Entity}, v: Entity, j: any, dt: number, passed: any): boolean, boolean
	local horcollision = false
	local vercollision = false
	local group = u
	local mover = v
	for g, t in pairs(group) do
		--    Same object?          Active                 Not masked
		if (i ~= g or j ~= h) and t.active and (mover.mask == nil or mover.mask[t.category] ~= true) and (t.mask == nil or t.mask[mover.category] ~= true) then
			local collision1, collision2 = checkcollision(mover, t, h, g, j, i, dt, passed)
			if collision1 then
				horcollision = true
			elseif collision2 then
				vercollision = true
			end
		end
	end

	return horcollision, vercollision
end
