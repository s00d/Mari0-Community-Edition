--[[ Shared lethality: box crush, gravity ball, legacy punt timer. ]]

global function punt_tick(obj: {string:any}, dt: number)
	local t = obj.punttimer as number|nil
	if t ~= nil and t > 0 then
		obj.punttimer = math.max(0, t - dt)
	end
end

-- Mario calls enemy:stomp(mario.x, mario); shell kick needs that x.
local function call_stomp(target: {string:any}, from_x: number|nil, from: {string:any}|nil): any
	local x = from_x
	if x == nil then
		-- Kick right when no stomper (blast / direct kill).
		x = ((target.x as number) or 0) - 1
	end
	return (target.stomp as function({string:any}, number, {string:any}|nil): any)(target, x as number, from)
end

-- true = collision absorbed (target killed)
global function punt_hit(self: {string:any}, othertype: string, other: {string:any}): boolean
	local t = self.punttimer as number|nil
	if t == nil or t <= 0 or othertype ~= "enemy" then
		return false
	end
	if other.stompable and other.stomp then
		call_stomp(other, self.x as number, self)
	elseif other.shotted then
		(other.shotted as function({string:any}, string, boolean, boolean, boolean))(other, "right", false, false, false)
	else
		return false
	end
	if addpoints then
		addpoints(200, self.x as number, self.y as number)
	end
	if playsound then
		playsound("stomp")
	end
	return true
end

-- Direct kill from blast (no flight). Prefer punt_kill_entity for new call sites.
global function punt_kill(obj: {string:any}): boolean
	if obj.stompable and obj.stomp then
		call_stomp(obj, nil, nil)
	elseif obj.shotted then
		(obj.shotted as function({string:any}, string, boolean, boolean, boolean))(obj, "right", false, false, false)
	else
		return false
	end
	if playsound then
		playsound("stomp")
	end
	return true
end

-- Shared kill for box crush + gravity ball (health-aware, no points here).
global function punt_kill_entity(target: {string:any}): boolean
	if target.destroying or target.dead or target.kill then
		return false
	end
	if target.stompable then
		if call_stomp(target, nil, nil) == false then
			return false
		end
	elseif target.shotted then
		local r = (target.shotted as function({string:any}, string, boolean, boolean, boolean): any)(
			target, "right", false, false, false)
		if r == false then
			return false
		end
		if r == nil and (target.health or target.shothealth) then
			return false
		end
	else
		return false
	end
	playsound("stomp")
	return true
end

return {
	punt_tick = punt_tick,
	punt_hit = punt_hit,
	punt_kill = punt_kill,
	punt_kill_entity = punt_kill_entity,
}
