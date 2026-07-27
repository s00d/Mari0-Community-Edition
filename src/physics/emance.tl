-- Emancipation grill check (once per mover). Depends on aabb + emancipationgrills global.

global function checkforemances(_: number, v: Body, speedx?: number, speedy?: number)
	-- Body doesn't include emancipate callbacks; they live on full Entity types.
	local ent = v as Entity
	if ent.emancipatecheck then
		for h, u in pairs(emancipationgrills) do
			local grill = u as emancipationgrill
			if grill.active then
				local _ = speedx or ent.speedx
				local _ = speedy or ent.speedy

				-- Honestly, why were fizzlers originally done with "inrange" instead of "aabb"?
				if grill.dir == "hor" then
					-- if inrange(v.x+6/16, u.startx-1, u.endx, true) and inrange(u.y-14/16, v.y, v.y+spy*dt, true) then
					if aabb(v.x, v.y, v.width, v.height, grill.startx - 1, grill.y - .5 - grill.thickness/16/2, (grill.endx - grill.startx + 1), grill.thickness/16) then
						if ent.emancipate then (ent.emancipate as function(Entity, any))(ent, h) end
					end
				else
					-- if inrange(v.y+6/16, u.starty-1, u.endy, true) and inrange(u.x-14/16, v.x, v.x+spx*dt, true) then
					if aabb(v.x, v.y, v.width, v.height, grill.x - .5 - grill.thickness/16/2, grill.starty - 1, grill.thickness/16, (grill.endy - grill.starty + 1)) then
						if ent.emancipate then (ent.emancipate as function(Entity, any))(ent, h) end
					end
				end
			end
		end
	end
end
