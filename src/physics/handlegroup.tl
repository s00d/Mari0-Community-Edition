-- Object-group collision pass (depends on checkcollision).
-- Note: no per-call prof zones here — handlegroup is too hot; profile via
-- physicsupdate zone or temporarily wrap locally when investigating.

global function handlegroup(i: any, h: any, u: {any:Body}, v: Body, j: any, dt: number, passed: any): boolean, boolean
	local horcollision = false
	local vercollision = false
	local group = u
	local mover = v
	local sx = mover.speedx or 0
	local sy = mover.speedy or 0

	-- Swept mover AABB for this frame (union of current + next-frame boxes).
	-- Current-only AABB wrongly culled height=0 portalwall floors that Mario
	-- approaches from above after modifyportaltiles removes the solid tile.
	local smx = mover.x + math.min(0, sx * dt)
	local smy = mover.y + math.min(0, sy * dt)
	local smw = mover.width + math.abs(sx * dt)
	local smh = mover.height + math.abs(sy * dt)

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
		mx0 = math.floor(smx - 1)
		my0 = math.floor(smy - 1)
		mx1 = math.floor(smx + smw + 1)
		my1 = math.floor(smy + smh + 1)
	end

	for g, t in pairs(group) do
		if (i ~= g or j ~= h) and t.active then
			if not use_cells
				or (math.floor(t.x + t.width) >= mx0 and math.floor(t.x) <= mx1
					and math.floor(t.y + t.height) >= my0 and math.floor(t.y) <= my1) then
				-- Zero-size targets (portalwall lines) get epsilon thickness for
				-- the broadphase test only; checkcollision still sees real sizes.
				local tx, ty, tw, th = t.x, t.y, t.width, t.height
				if tw == 0 then
					tx = tx - 1 / 32
					tw = 1 / 16
				end
				if th == 0 then
					ty = ty - 1 / 32
					th = 1 / 16
				end
				if aabb(smx, smy, smw, smh, tx, ty, tw, th) then
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
