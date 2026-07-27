-- Gravity-direction speed / rotation helpers (from physics.lua).
-- Sim path uses core.dmath (deterministic); math.fmod kept for unrotate.

require("core.dmath")

local atan2 = datan2

global function converttostandard(obj: Entity, speedx: number, speedy: number): number, number
	--Convert speedx and speedy to horizontal values
	local speed = math.sqrt(speedx^2+speedy^2)
	local speeddir = atan2(speedy, speedx)

	local sx = dcos(speeddir-obj.gravitydirection+math.pi/2)*speed
	local sy = dsin(speeddir-obj.gravitydirection+math.pi/2)*speed

	if math.abs(sy) < 0.00001 then
		sy = 0
	end
	if math.abs(sx) < 0.00001 then
		sx = 0
	end

	return sx, sy
end

global function convertfromstandard(obj: Entity, speedx: number, speedy: number): number, number
	--reconvert speedx and speedy to actual directions
	local speed = math.sqrt(speedx^2+speedy^2)
	local speeddir = atan2(speedy, speedx)

	local sx = dcos(speeddir+obj.gravitydirection-math.pi/2)*speed
	local sy = dsin(speeddir+obj.gravitydirection-math.pi/2)*speed

	if math.abs(sy) < 0.00001 then
		sy = 0
	end
	if math.abs(sx) < 0.00001 then
		sx = 0
	end

	return sx, sy
end

global function unrotate(rotation: number, gravitydirection: number, dt: number): number
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
