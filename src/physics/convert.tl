-- Gravity-direction speed / rotation helpers (from physics.lua).
-- Uses math.fmod and portalrotationalignmentspeed for unrotate.

local atan2 = math.atan2 or math.atan -- LuaJIT/5.1: atan2; Lua 5.3+: atan(y, x)

global function converttostandard(...: any): any
	local obj, speedx, speedy = ...
	--Convert speedx and speedy to horizontal values
	local speed = math.sqrt(speedx^2+speedy^2)
	local speeddir = atan2(speedy, speedx)

	local speedx, speedy = math.cos(speeddir-obj.gravitydirection+math.pi/2)*speed, math.sin(speeddir-obj.gravitydirection+math.pi/2)*speed

	if math.abs(speedy) < 0.00001 then
		speedy = 0
	end
	if math.abs(speedx) < 0.00001 then
		speedx = 0
	end

	return speedx, speedy
end

global function convertfromstandard(...: any): any
	local obj, speedx, speedy = ...
	--reconvert speedx and speedy to actual directions
	local speed = math.sqrt(speedx^2+speedy^2)
	local speeddir = atan2(speedy, speedx)

	local speedx, speedy = math.cos(speeddir+obj.gravitydirection-math.pi/2)*speed, math.sin(speeddir+obj.gravitydirection-math.pi/2)*speed

	if math.abs(speedy) < 0.00001 then
		speedy = 0
	end
	if math.abs(speedx) < 0.00001 then
		speedx = 0
	end

	return speedx, speedy
end

global function unrotate(...: any): any
	local rotation, gravitydirection, dt = ...
	--rotate back to gravitydirection (portals)
	local mod = math.fmod
	rotation = mod(rotation, math.pi*2)

	if rotation < -math.pi then
		rotation = rotation + math.pi*2
	elseif rotation > math.pi then
		rotation = rotation - math.pi*2
	end

	if rotation == math.pi and gravitydirection == 0 then
		rotation = rotation + portalrotationalignmentspeed*dt
	elseif rotation <= -math.pi/2 and gravitydirection == math.pi*1.5 then
		rotation = rotation - portalrotationalignmentspeed*dt
	elseif rotation > (gravitydirection-math.pi/2) then
		rotation = rotation - portalrotationalignmentspeed*dt
		if rotation < (gravitydirection-math.pi/2) then
			rotation = (gravitydirection-math.pi/2)
		end
	elseif rotation < (gravitydirection-math.pi/2) then
		rotation = rotation + portalrotationalignmentspeed*dt
		if rotation > (gravitydirection-math.pi/2) then
			rotation = (gravitydirection-math.pi/2)
		end
	end

	return rotation
end
