-- Gravity-relative direction remapping (pure).

global function twistdirection(gravitydir: any, dir: any): any
	if not gravitydir or ((gravitydir as number) > math.pi/4*1 and (gravitydir as number) <= math.pi/4*3) then
		if dir == "floor" then
			return "floor"
		elseif dir == "left" then
			return "left"
		elseif dir == "ceil" then
			return "ceil"
		elseif dir == "right" then
			return "right"
		end
	elseif (gravitydir as number) > math.pi/4*3 and (gravitydir as number) <= math.pi/4*5 then
		if dir == "floor" then
			return "left"
		elseif dir == "left" then
			return "ceil"
		elseif dir == "ceil" then
			return "right"
		elseif dir == "right" then
			return "floor"
		end
	elseif (gravitydir as number) > math.pi/4*5 and (gravitydir as number) <= math.pi/4*7 then
		if dir == "floor" then
			return "ceil"
		elseif dir == "left" then
			return "right"
		elseif dir == "ceil" then
			return "floor"
		elseif dir == "right" then
			return "left"
		end
	else
		if dir == "floor" then
			return "right"
		elseif dir == "left" then
			return "floor"
		elseif dir == "ceil" then
			return "left"
		elseif dir == "right" then
			return "ceil"
		end
	end
end

global function adjustcollside(side: any, gravitydirection: any): any
	local gd = gravitydirection as number
	if side == "left" then
		if gd > math.pi/4*1 and gd <= math.pi/4*3 then --down
			return "left"
		elseif gd > math.pi/4*3 and gd <= math.pi/4*5 then --left
			return "up"
		elseif gd > math.pi/4*5 and gd <= math.pi/4*7 then --up
			return "right"
		else --right
			return "down"
		end
	elseif side == "up" then
		if gd > math.pi/4*1 and gd <= math.pi/4*3 then --down
			return "up"
		elseif gd > math.pi/4*3 and gd <= math.pi/4*5 then --left
			return "right"
		elseif gd > math.pi/4*5 and gd <= math.pi/4*7 then --up
			return "down"
		else --right
			return "left"
		end
	elseif side == "right" then
		if gd > math.pi/4*1 and gd <= math.pi/4*3 then --down
			return "right"
		elseif gd > math.pi/4*3 and gd <= math.pi/4*5 then --left
			return "down"
		elseif gd > math.pi/4*5 and gd <= math.pi/4*7 then --up
			return "left"
		else --right
			return "up"
		end
	elseif side == "down" then
		if gd > math.pi/4*1 and gd <= math.pi/4*3 then --down
			return "down"
		elseif gd > math.pi/4*3 and gd <= math.pi/4*5 then --left
			return "left"
		elseif gd > math.pi/4*5 and gd <= math.pi/4*7 then --up
			return "up"
		else --right
			return "right"
		end
	end
end
