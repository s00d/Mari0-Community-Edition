--[[
  SMB3 dump source helpers (JSON → naming + IR scaffolding).

  Full tiles.png rebuild + prop writing lives in scripts/mapsdk/build_smb3.py
  (Pillow). This module handles Mari0 N-M_S naming and IR height fit.
]]

local irmod = dofile((function()
	local src = debug.getinfo(1, "S").source
	local dir = src:sub(1, 1) == "@" and (src:sub(2):match("^(.*)/") or ".") or "."
	return dir .. "/../ir.lua"
end)())

local M = {}

local CUSTOM_TILE_BASE = 221 -- smbtilecount(132)+portaltilecount(88)+1

M.CUSTOM_TILE_BASE = CUSTOM_TILE_BASE
M.ENEMY_MAP = {
	["goomba"] = "goomba",
	["red koopa troopa"] = "koopa",
	["green koopa troopa"] = "koopa",
	["para-goomba"] = "paragoomba",
	["red para-goomba"] = "paragoomba",
	["red para-troopa"] = "parakoopa",
	["green para-troopa"] = "parakoopa",
	["buzzy beetle"] = "beetle",
	["spiny"] = "spiny",
	["piranha plant"] = "plant",
	["venus fire trap"] = "plant",
	["cheep-cheep"] = "cheep",
	["blooper"] = "squid",
	["hammer bro"] = "hammerbro",
	["lakitu"] = "lakitu",
	["bullet bill"] = "bulletbill",
}

function M.mari0_entity(name)
	local key = string.lower(tostring(name or ""))
	if M.ENEMY_MAP[key] then
		return M.ENEMY_MAP[key]
	end
	for prefix, ent in pairs(M.ENEMY_MAP) do
		if key:find(prefix, 1, true) then
			return ent
		end
	end
	return nil
end

--- Map dump id / name → Mari0 `N-M` or `N-M_S`.
-- Bonus/ending rooms become sublevels of the referenced main level.
function M.level_filename(data)
	local world = tonumber(data.world) or 1
	local name = tostring(data.name or "")
	local id = tostring(data.id or "")

	local main = name:match("^[Ll]evel%s+(%d+)$")
	if main then
		return string.format("%d-%s", world, main)
	end

	local lvl, kind = id:match("level_(%d+)_(%w+)")
	if not lvl then
		lvl, kind = id:match("level_(%d+)_(.+)$")
	end
	-- id forms: 1-9_level_1_bonus_area, 1-18_level_4_ending
	local lvl2, rest = id:match("^%d+%-%d+_level_(%d+)_(.+)$")
	if lvl2 then
		lvl, kind = lvl2, rest
	end

	if lvl then
		local sub = 1
		if kind and kind:find("ending", 1, true) then
			sub = 2
		elseif kind and kind:find("bonus", 1, true) then
			sub = 1
		elseif kind and kind:find("beginning", 1, true) then
			sub = 1
		else
			sub = 1
		end
		return string.format("%d-%s_%d", world, lvl, sub)
	end

	-- Main-ish named rooms kept as W-N (dungeon/ship/pyramid/…)
	local w, n, suffix = id:match("^(%d+)%-(%d+)_(.+)$")
	if w and n and suffix then
		local main_suffixes = {
			dungeon = true, ship = true, quicksand = true, pyramid = true,
			tank = true, battleship = true,
		}
		local base = suffix:match("^([^_]+)")
		if main_suffixes[base] and not suffix:find("boss", 1, true)
			and not suffix:find("spike", 1, true)
			and not suffix:find("water", 1, true)
			and not suffix:find("pipe", 1, true)
			and not suffix:find("bonus", 1, true)
		then
			return string.format("%s-%s", w, n)
		end
		-- Other rooms → sublevel index from dump N (clamped)
		local sub = tonumber(n)
		if sub and sub > 9 then
			-- Foundry uses high ids for subrooms; attach to nearest main via name hints
			local parent = 1
			if suffix:find("dungeon", 1, true) then
				parent = 7
			elseif suffix:find("ship", 1, true) then
				parent = 8
			elseif suffix:find("hammer", 1, true) then
				parent = 1
			end
			local s = (sub % 5) + 1
			return string.format("%s-%d_%d", w, parent, s)
		end
		return string.format("%s-%s_1", w, n)
	end

	-- Lost levels etc.
	local w2, n2 = id:match("^(%d+)%-(%d+)")
	if w2 and n2 then
		return string.format("%s-%s", w2, n2)
	end
	return id:gsub("[^%w%-_]", "_")
end

--- Build IR from dump level (tilemap already mapped to Mari0 tile ids).
-- mapped_rows: [y][x] 1-based rows of mari0 tile ids
function M.to_ir(data, mapped_rows, y_offset)
	y_offset = y_offset or 0
	local h = #mapped_rows
	local w = mapped_rows[1] and #mapped_rows[1] or 0
	local ir = irmod.new({
		source = "smb3dump",
		id = data.id,
		object_set = data.object_set,
	})
	irmod.set_size(ir, w, h, CUSTOM_TILE_BASE)
	for y = 1, h do
		for x = 1, w do
			ir.tiles[x][y] = mapped_rows[y][x]
		end
	end
	for _, enemy in ipairs(data.enemies or {}) do
		local ent = M.mari0_entity(enemy.name)
		if ent then
			local x, y = enemy.x + 1, enemy.y - y_offset + 1
			if x >= 1 and y >= 1 and x <= w and y <= h then
				ir.entities[#ir.entities + 1] = { x = x, y = y, name = ent }
			end
		end
	end
	-- crude spawn: first empty-ish cell near left on bottom third
	ir.spawn = { x = 3, y = math.max(1, h - 2) }
	ir.finish = { x = math.max(1, w - 5), y = math.max(1, h - 2) }
	return ir
end

return M
