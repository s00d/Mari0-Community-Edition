-- Gravity-relative direction remapping (pure).

global function twistdirection(...: any): any
	local gravitydir, dir = ...
	if not gravitydir or (gravitydir > math.pi/4*1 and gravitydir <= math.pi/4*3) then
		if dir == "floor" then
			return "floor"
		elseif dir == "left" then
			return "left"
		elseif dir == "ceil" then
			return "ceil"
		elseif dir == "right" then
			return "right"
		end
	elseif gravitydir > math.pi/4*3 and gravitydir <= math.pi/4*5 then
		if dir == "floor" then
			return "left"
		elseif dir == "left" then
			return "ceil"
		elseif dir == "ceil" then
			return "right"
		elseif dir == "right" then
			return "floor"
		end
	elseif gravitydir > math.pi/4*5 and gravitydir <= math.pi/4*7 then
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

global function adjustcollside(...: any): any
	local side, gravitydirection = ...
	if side == "left" then
		if gravitydirection > math.pi/4*1 and gravitydirection <= math.pi/4*3 then --down
			return "left"
		elseif gravitydirection > math.pi/4*3 and gravitydirection <= math.pi/4*5 then --left
			return "up"
		elseif gravitydirection > math.pi/4*5 and gravitydirection <= math.pi/4*7 then --up
			return "right"
		else --right
			return "down"
		end
	elseif side == "up" then
		if gravitydirection > math.pi/4*1 and gravitydirection <= math.pi/4*3 then --down
			return "up"
		elseif gravitydirection > math.pi/4*3 and gravitydirection <= math.pi/4*5 then --left
			return "right"
		elseif gravitydirection > math.pi/4*5 and gravitydirection <= math.pi/4*7 then --up
			return "down"
		else --right
			return "left"
		end
	elseif side == "right" then
		if gravitydirection > math.pi/4*1 and gravitydirection <= math.pi/4*3 then --down
			return "right"
		elseif gravitydirection > math.pi/4*3 and gravitydirection <= math.pi/4*5 then --left
			return "down"
		elseif gravitydirection > math.pi/4*5 and gravitydirection <= math.pi/4*7 then --up
			return "left"
		else --right
			return "up"
		end
	elseif side == "down" then
		if gravitydirection > math.pi/4*1 and gravitydirection <= math.pi/4*3 then --down
			return "down"
		elseif gravitydirection > math.pi/4*3 and gravitydirection <= math.pi/4*5 then --left
			return "left"
		elseif gravitydirection > math.pi/4*5 and gravitydirection <= math.pi/4*7 then --up
			return "up"
		else --right
			return "right"
		end
	end
end
