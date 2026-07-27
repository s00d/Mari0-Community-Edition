--[[ Endless enemy registry + budget populate (deterministic). ]]

-- Also mirrored for mappack docs; generator requires world.endless_enemies.

global ENDLESS_ENEMIES: {string:{string:any}} = {
	turret = { tag = "guard", weight = 8, min_room = "corridor", cost = 2 },
	medusa = { tag = "hazard_flying", weight = 10, min_room = "shaft", cost = 1 },
	boo = { tag = "stalker", weight = 5, min_room = "corridor", cost = 3 },
	drybones = { tag = "respawner", weight = 7, min_room = "arena", cost = 2 },
	thwomp = { tag = "vertical_hazard", weight = 6, min_room = "shaft", cost = 2 },
	charger = { tag = "bruiser", weight = 6, min_room = "wide", cost = 3 },
	splitter = { tag = "swarm", weight = 8, min_room = "arena", cost = 2 },
	arrowtrap = { tag = "trap", weight = 12, min_room = "corridor", cost = 1 },
	floater = { tag = "ranged_air", weight = 7, min_room = "open", cost = 3 },
	latcher = { tag = "coop_threat", weight = 4, min_room = "any", cost = 2, minplayers = 2 },
}

local ROOM_KIND_FROM_NAME: {string:string} = {
	hall = "corridor",
	corner = "corridor",
	shaft = "shaft",
	room = "arena",
	filler = "open",
	start = "wide",
	["end"] = "wide",
}

global function endless_room_kind_from_name(name: string): string
	local base = name:match("^([^_]+)") or name
	return ROOM_KIND_FROM_NAME[base] or "arena"
end

local function rng_random(rng: {any:any}, a: number|nil, b: number|nil): number
	local fn = rng["random"] as function({any:any}, number|nil, number|nil): number
	return fn(rng, a, b)
end

local function is_air(map: {number:{number:MapCell}}, x: number, y: number): boolean
	if not map[x] or not map[x][y] then
		return false
	end
	local tid = map[x][y][1]
	return tid == 1 or tid == nil
end

local function is_solid(map: {number:{number:MapCell}}, x: number, y: number): boolean
	if not map[x] or not map[x][y] then
		return true
	end
	local tid = map[x][y][1]
	return tid ~= nil and tid ~= 1
end

local function free_slots(map: {number:{number:MapCell}}, ox: number, oy: number, rw: number, rh: number): {{number}}
	local slots: {{number}} = {}
	for ly = 2, rh - 1 do
		for lx = 2, rw - 1 do
			local x, y = ox + lx, oy + ly
			if is_air(map, x, y) and is_solid(map, x, y + 1) then
				slots[#slots + 1] = {x, y}
			end
		end
	end
	return slots
end

global function endless_populate(
	map: {number:{number:MapCell}},
	room_ox: number,
	room_oy: number,
	room_w: number,
	room_h: number,
	room_kind: string,
	depth: number,
	rng: {any:any},
	player_count: number|nil
): {string}
	local pc = player_count or 1
	local budget: number = 2 + math.floor(depth / 3)
	local pool: {string} = {}
	for id, d in pairs(ENDLESS_ENEMIES) do
		local min_room = d.min_room as string
		local minp = d.minplayers as number|nil
		if (min_room == "any" or min_room == room_kind)
			and (minp == nil or pc >= minp)
			and (d.cost as number) <= budget then
			local w = d.weight as number
			for _ = 1, w do
				pool[#pool + 1] = id
			end
		end
	end
	local placed: {string} = {}
	local slots = free_slots(map, room_ox, room_oy, room_w, room_h)
	while budget > 0 and #pool > 0 and #slots > 0 do
		local pi = math.floor(rng_random(rng, 1, #pool))
		local id = pool[pi]
		local d = ENDLESS_ENEMIES[id]
		local cost = d.cost as number
		if cost > budget then
			break
		end
		local si = math.floor(rng_random(rng, 1, #slots))
		local slot = slots[si]
		table.remove(slots, si)
		local cell = map[slot[1]][slot[2]]
		-- cell[1]=tile, append enemy name like endless rooms do
		if #cell < 2 then
			cell[2] = id
		else
			-- already has entity; skip or overwrite goomba-style
			cell[2] = id
		end
		placed[#placed + 1] = id
		budget = budget - cost
		-- rebuild pool for remaining budget
		local np: {string} = {}
		for i = 1, #pool do
			local oid = pool[i]
			if (ENDLESS_ENEMIES[oid].cost as number) <= budget then
				np[#np + 1] = oid
			end
		end
		pool = np
	end
	return placed
end

return {
	ENDLESS_ENEMIES = ENDLESS_ENEMIES,
	endless_populate = endless_populate,
	endless_room_kind_from_name = endless_room_kind_from_name,
}
