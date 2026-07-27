--[[ Shared gel reactions for gelreactive bodies (not Mario). ]]

-- Bounce / speed on floor contact. Returns true if collision absorbed (bounce).
global function gel_react_floor(obj: {string:any}, gid: number|nil): boolean
	if gel_has(gid, "bounce") then
		local grav = (obj.gravity as number) or yacceleration
		if grav == 0 then
			grav = yacceleration
		end
		local mul = (obj.gelbouncemul as number) or 1
		obj.speedy = -math.sqrt(2 * grav * bounceheight) * mul
		return true
	end
	if gel_has(gid, "speed") then
		local sx = (obj.speedx as number) or 0
		if sx ~= 0 then
			obj.speedx = sx * gelspeedmul
		end
	end
	return false
end

-- Horizontal bounce off a gelled wall side. Returns true if bounced.
global function gel_react_side(obj: {string:any}, gid: number|nil, side: integer): boolean
	if not gel_has(gid, "bounce") then
		return false
	end
	local sx = (obj.speedx as number) or 0
	if math.abs(sx) < horbounceminspeedx then
		return false
	end
	local dir = (side == GEL_SIDE_LEFT) and 1 or -1
	obj.speedx = dir * math.min(horbouncemaxspeedx, math.abs(sx) * horbouncemul)
	obj.speedy = math.min((obj.speedy as number) or 0, -horbouncespeedy)
	return true
end

return {
	gel_react_floor = gel_react_floor,
	gel_react_side = gel_react_side,
}
