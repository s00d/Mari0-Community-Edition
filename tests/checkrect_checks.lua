--[[
  checkrect AABB list-filter fixtures (no LÖVE).
]]

local root = ... or "."
local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

local function out_has(out, typ, key)
	for i = 1, #out, 2 do
		if out[i] == typ and out[i + 1] == key then
			return true
		end
	end
	return false
end

require("physics.late") -- aabb
require("physics.world")
require("physics.checkrect")

local function sync_physics()
	if physics_world_refresh then
		physics_world_refresh()
	end
end

-- empty world
do
	objects = {}
	sync_physics()
	local out = checkrect(0, 0, 1, 1, "all")
	check("empty all", #out == 0)
end

-- hit active dynamic; miss inactive / non-overlap
do
	objects = {
		player = {
			[1] = {x = 0, y = 0, width = 1, height = 1, active = true, static = false},
			[2] = {x = 10, y = 10, width = 1, height = 1, active = true, static = false},
			[3] = {x = 0.2, y = 0.2, width = 1, height = 1, active = false, static = false},
		},
	}
	sync_physics()
	local out = checkrect(0, 0, 1, 1, "all")
	check("hit player 1", out_has(out, "player", 1))
	check("miss far player 2", not out_has(out, "player", 2))
	check("miss inactive", not out_has(out, "player", 3))
	check("pair count", #out == 2)
end

-- type list filter
do
	objects = {
		player = {
			[1] = {x = 0, y = 0, width = 1, height = 1, active = true, static = false},
		},
		box = {
			[1] = {x = 0.2, y = 0.2, width = 1, height = 1, active = true, static = false},
		},
	}
	sync_physics()
	local out = checkrect(0, 0, 1, 1, {"box"})
	check("list only box", #out == 2 and out[1] == "box" and out[2] == 1)
	out = checkrect(0, 0, 1, 1, {"player", "box"})
	check("list both types", out_has(out, "player", 1) and out_has(out, "box", 1))
end

-- statics skipped on list=="all" unless statics flag
do
	objects = {
		tile = {
			[1] = {x = 0, y = 0, width = 1, height = 1, active = true, static = true},
		},
		box = {
			[1] = {x = 0, y = 0, width = 1, height = 1, active = true, static = false},
		},
	}
	sync_physics()
	local out = checkrect(0, 0, 1, 1, "all")
	check("all skips static", not out_has(out, "tile", 1) and out_has(out, "box", 1))
	out = checkrect(0, 0, 1, 1, "all", true)
	check("statics flag includes tile", out_has(out, "tile", 1))
	-- named list still includes statics even without flag
	out = checkrect(0, 0, 1, 1, {"tile"})
	check("named list keeps static", out_has(out, "tile", 1))
end

-- exclude self + mask mutual skip
do
	local a = {x = 0, y = 0, width = 1, height = 1, active = true, static = false, category = 3, mask = {}}
	local b = {x = 0.2, y = 0.2, width = 1, height = 1, active = true, static = false, category = 9, mask = {}}
	local c = {x = 0.2, y = 0.2, width = 1, height = 1, active = true, static = false, category = 4, mask = {[3] = true}}
	objects = {
		player = {[1] = a},
		box = {[1] = b},
		goomba = {[1] = c},
	}
	sync_physics()
	local out = checkrect(0, 0, 1, 1, {"exclude", a})
	check("exclude self", not out_has(out, "player", 1))
	check("exclude keeps box", out_has(out, "box", 1))
	-- c.mask[a.category] => skip goomba when excluding a
	check("exclude mask skip", not out_has(out, "goomba", 1))
end

-- enemy category filter via numeric list entry
do
	objects = {
		enemy = {
			[1] = {x = 0, y = 0, width = 1, height = 1, active = true, static = false, category = 4},
			[2] = {x = 0, y = 0, width = 1, height = 1, active = true, static = false, category = 5},
		},
		player = {
			[1] = {x = 0, y = 0, width = 1, height = 1, active = true, static = false},
		},
	}
	sync_physics()
	local out = checkrect(0, 0, 1, 1, {4})
	check("enemy cat 4 only", out_has(out, "enemy", 1) and not out_has(out, "enemy", 2))
	check("enemy list no player", not out_has(out, "player", 1))
end

return failed
