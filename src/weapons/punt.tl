--[[ Shared punt blast lethality: timer tick + collide kill + direct blast kill. ]]

global function punt_tick(obj: {string:any}, dt: number)
	local t = obj.punttimer as number|nil
	if t ~= nil and t > 0 then
		obj.punttimer = math.max(0, t - dt)
	end
end

-- true = collision absorbed (target killed)
global function punt_hit(self: {string:any}, othertype: string, other: {string:any}): boolean
	local t = self.punttimer as number|nil
	if t == nil or t <= 0 or othertype ~= "enemy" then
		return false
	end
	if other.stompable and other.stomp then
		(other.stomp as function({string:any}))(other)
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

-- Direct kill from blast (no flight)
global function punt_kill(obj: {string:any}): boolean
	if obj.stompable and obj.stomp then
		(obj.stomp as function({string:any}))(obj)
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

return {
	punt_tick = punt_tick,
	punt_hit = punt_hit,
	punt_kill = punt_kill,
}
