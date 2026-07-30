--[[ Enemy map-arg modifiers (Mario Maker style). Args in map[x][y][3..]. ]]

global ENEMY_MODIFIERS: {string:{string:any}} = {
	winged = { icon = "W", label = "winged" },
	big = { icon = "B", label = "big" },
	fast = { icon = "F", label = "fast" },
	frozen = { icon = "I", label = "frozen" },
	stack = { icon = "S", label = "stack" },
	left = { icon = "L", label = "face left" },
	right = { icon = "R", label = "face right" },
	upsidedown = { icon = "U", label = "upsidedown" },
}

global ENEMY_MODIFIER_ORDER: {string} = { "winged", "big", "fast", "frozen", "stack", "left", "right", "upsidedown" }

global function enemy_modifier_ids_from_args(a: {any}|nil): {string}
	local out: {string} = {}
	local args = (a or {}) as {any}
	for i = 3, #args do
		local v = args[i]
		local s = tostring(v or "")
		if ENEMY_MODIFIERS[s] then
			out[#out + 1] = s
		end
	end
	return out
end

global function apply_enemy_modifiers(e_any: any, a: {any}|nil)
	if not e_any or not a then return end
	local e = e_any as {string:any}
	local mods = enemy_modifier_ids_from_args(a)
	if #mods == 0 then return end
	e.mods = table.concat(mods, ",")
	for i = 1, #mods do
		local id = mods[i]
		if id == "winged" then
			e.movement = "sine"
			e.gravity = 0
			e.sineamp = (e.sineamp as number) or 2
			e.static = false
		elseif id == "big" then
			local w = (e.width as number) or 0.75
			local h = (e.height as number) or 0.75
			e.width = w * 2
			e.height = h * 2
			e.customscale = ((e.customscale as number) or 1) * 2
			e.health = ((e.health as number) or 1) + 2
			e.y = (e.y as number) - h
		elseif id == "fast" then
			e.speedmul = 2
			if e.speedx then e.speedx = (e.speedx as number) * 2 end
			if e.maxspeed then e.maxspeed = (e.maxspeed as number) * 2 end
		elseif id == "frozen" then
			e.startfrozen = true
			e.frozen = true
			e.speedx = 0
			e.speedy = 0
			e.movement = nil
		elseif id == "stack" then
			e.carries = e.t
		elseif id == "left" then
			e.animationdirection = "left"
			e.turretlockedfacing = true
		elseif id == "right" then
			e.animationdirection = "right"
			e.turretlockedfacing = true
		elseif id == "upsidedown" then
			e.upsidedown = true
			local g = (e.gravity as number) or 40
			e.gravity = -math.abs(g)
			e.startgravity = e.gravity
		end
	end
end

-- Drop modifier string onto map cell (editor). Returns true if applied.
global function enemy_drop_modifier(mod: string, cox: number, coy: number): boolean
	if not ENEMY_MODIFIERS[mod] or not inmap(cox, coy) then return false end
	local c = map[cox][coy]
	if not c or #c < 2 then return false end
	local name = c[2]
	local is_enemy = false
	if enemies then
		for i = 1, #enemies do
			if enemies[i] == name then is_enemy = true; break end
		end
	end
	if not is_enemy and type(name) == "string" then
		-- still allow string enemy names
		is_enemy = true
	end
	if not is_enemy then return false end
	for i = 3, #c do
		if c[i] == mod then return false end
	end
	editor_undo_begin()
	editor_undo_record(cox, coy)
	c[#c + 1] = mod
	editor_undo_commit()
	return true
end
