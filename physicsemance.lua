-- Emancipation grill check (once per mover). Depends on aabb + emancipationgrills global.

function checkforemances(dt, v, speedx, speedy)
	if v.emancipatecheck then
		for h, u in pairs(emancipationgrills) do
			if u.active then
				local spx = speedx or v.speedx
				local spy = speedy or v.speedy

				-- Honestly, why were fizzlers originally done with "inrange" instead of "aabb"?
				if u.dir == "hor" then
					-- if inrange(v.x+6/16, u.startx-1, u.endx, true) and inrange(u.y-14/16, v.y, v.y+spy*dt, true) then
					if aabb(v.x, v.y, v.width, v.height, u.startx - 1, u.y - .5 - u.thickness/16/2, (u.endx - u.startx + 1), u.thickness/16) then
						if v.emancipate then v:emancipate(h) end
					end
				else
					-- if inrange(v.y+6/16, u.starty-1, u.endy, true) and inrange(u.x-14/16, v.x, v.x+spx*dt, true) then
					if aabb(v.x, v.y, v.width, v.height, u.x - .5 - u.thickness/16/2, u.starty - 1, u.thickness/16, (u.endy - u.starty + 1)) then
						if v.emancipate then v:emancipate(h) end
					end
				end
			end
		end
	end
end
