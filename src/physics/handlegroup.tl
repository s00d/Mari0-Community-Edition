-- Object-group collision pass (depends on checkcollision).

global function handlegroup(i: any, h: any, u: {any:Body}, v: Body, j: any, dt: number, passed: any): boolean, boolean
	local horcollision = false
	local vercollision = false
	local group = u
	local mover = v
	local sx = mover.speedx or 0
	local sy = mover.speedy or 0

	-- Large-group cull only. Do NOT gate on current-position AABB:
	-- checkcollision uses swept/next-frame AABB (needed for height=0 portalwalls
	-- that form the floor on top of down-portal tiles after modifyportaltiles).
	local use_cells = false
	local group_count = 0
	for _ in pairs(group) do
		group_count = group_count + 1
		if group_count >= 12 then
			use_cells = true
			break
		end
	end

	local mx0, my0, mx1, my1 = 0, 0, 0, 0
	if use_cells then
		mx0 = math.floor(mover.x + math.min(0, sx * dt) - 1)
		my0 = math.floor(mover.y + math.min(0, sy * dt) - 1)
		mx1 = math.floor(mover.x + mover.width + math.max(0, sx * dt) + 1)
		my1 = math.floor(mover.y + mover.height + math.max(0, sy * dt) + 1)
	end

	for g, t in pairs(group) do
		if (i ~= g or j ~= h) and t.active then
			if not use_cells
				or (math.floor(t.x + t.width) >= mx0 and math.floor(t.x) <= mx1
					and math.floor(t.y + t.height) >= my0 and math.floor(t.y) <= my1) then
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

	return horcollision, vercollision
end
