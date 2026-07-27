-- Endless enemy registry (docs + optional runtime load).
-- Canonical Teal: src/world/endless_enemies.tl

ENDLESS_ENEMIES = {
	turret   = { tag="guard",           weight=8,  min_room="corridor", cost=2 },
	medusa   = { tag="hazard_flying",   weight=10, min_room="shaft",    cost=1 },
	boo      = { tag="stalker",         weight=5,  min_room="corridor", cost=3 },
	drybones = { tag="respawner",       weight=7,  min_room="arena",    cost=2 },
	thwomp   = { tag="vertical_hazard", weight=6,  min_room="shaft",    cost=2 },
	charger  = { tag="bruiser",         weight=6,  min_room="wide",     cost=3 },
	splitter = { tag="swarm",           weight=8,  min_room="arena",    cost=2 },
	arrowtrap= { tag="trap",            weight=12, min_room="corridor", cost=1 },
	floater  = { tag="ranged_air",      weight=7,  min_room="open",     cost=3 },
	latcher  = { tag="coop_threat",     weight=4,  min_room="any",      cost=2, minplayers=2 },
}

local function populate(room, depth, rng, players)
	players = players or 1
	local budget = 2 + math.floor(depth / 3)
	local pool = {}
	for id, d in pairs(ENDLESS_ENEMIES) do
		if (d.min_room == "any" or d.min_room == room.kind)
			and (d.minplayers == nil or players >= d.minplayers)
			and d.cost <= budget then
			for _ = 1, d.weight do pool[#pool + 1] = id end
		end
	end
	local placed = {}
	while budget > 0 and #pool > 0 do
		local id = pool[rng:random(#pool)]
		local d = ENDLESS_ENEMIES[id]
		if d.cost > budget then break end
		placed[#placed + 1] = id
		budget = budget - d.cost
	end
	return placed
end

return { ENDLESS_ENEMIES = ENDLESS_ENEMIES, populate = populate }
