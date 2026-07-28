--[[ Ported from doukutsu-rs (https://github.com/doukutsu-rs/doukutsu-rs)
     Copyright 2020 doukutsu-rs contributors. MIT License — see licenses/doukutsu-rs.MIT

  Cave Story → mapsdk IR source (Level-1 geometry + NPC remaps).
  Does not crop map height — Mari0 CE supports mapheight > 15 (endless arenas).
]]

local function script_dir()
	local src = debug.getinfo(1, "S").source
	if src:sub(1, 1) == "@" then
		return src:sub(2):match("^(.*)/") or "."
	end
	return "."
end

local DIR = script_dir()
local irmod = dofile(DIR .. "/../ir.lua")
local fmt = dofile(DIR .. "/../cs_formats.lua")

local M = {}

-- SMB + portal tiles occupy 1..(CUSTOM_TILE_BASE-1); CS tileset starts here.
M.CUSTOM_TILE_BASE = 221

-- PXE flag bits (doukutsu-rs / freeware)
local FLAG_APPEAR_WHEN = 0x0800
local FLAG_HIDE_WHEN = 0x8000
local FLAG_FACE_RIGHT = 0x2000

--- Top NPC types by frequency across freeware Stage/*.pxe (histogram).
-- Level-1: remap to existing Mari0 enemies / markers. Unmapped → log only.
M.NPC_MAP = {
	[0] = { kind = "none" },
	[1] = { kind = "none" }, -- experience orb
	[5] = { kind = "enemy", name = "goomba" }, -- green critter
	[15] = { kind = "none" }, -- closed chest
	[16] = { kind = "none" }, -- save point
	[18] = { kind = "door" }, -- door
	[26] = { kind = "enemy", name = "koopaflying" }, -- bat flying
	[27] = { kind = "enemy", name = "fire" }, -- death trap
	[28] = { kind = "enemy", name = "koopaflying" }, -- flying critter
	[31] = { kind = "enemy", name = "koopaflying" }, -- bat hanging
	[32] = { kind = "enemy", name = "mushroom" }, -- life capsule
	[34] = { kind = "none" }, -- bed
	[37] = { kind = "none" }, -- sign
	[39] = { kind = "none" }, -- save sign
	[46] = { kind = "none" }, -- hv trigger
	[57] = { kind = "enemy", name = "koopaflying" }, -- crow
	[59] = { kind = "door" }, -- eye door
	[60] = { kind = "none" }, -- toroko (story)
	[64] = { kind = "enemy", name = "goomba" }, -- first cave critter
	[65] = { kind = "enemy", name = "koopaflying" }, -- first cave bat
	[76] = { kind = "none" }, -- flowers
	[78] = { kind = "none" }, -- pot
	[85] = { kind = "none" }, -- terminal
	[86] = { kind = "enemy", name = "flower" }, -- missile pickup
	[87] = { kind = "enemy", name = "mushroom" }, -- heart
	[95] = { kind = "enemy", name = "cheepcheepred" }, -- jelly
	[97] = { kind = "none" }, -- fan
	[125] = { kind = "none" }, -- hidden item
	[147] = { kind = "enemy", name = "goomba" }, -- purple critter
	[153] = { kind = "enemy", name = "beetle" }, -- gaudi
	[173] = { kind = "enemy", name = "beetle" }, -- gaudi armored
	[175] = { kind = "enemy", name = "goomba" }, -- gaudi egg
	[196] = { kind = "enemy", name = "koopa" }, -- ironhead wall
	[204] = { kind = "enemy", name = "fire" }, -- falling spike
	[210] = { kind = "enemy", name = "beetle" }, -- beetle
	[211] = { kind = "enemy", name = "fire" }, -- small spikes
	[238] = { kind = "enemy", name = "plant" }, -- press sideways
	[241] = { kind = "enemy", name = "goomba" }, -- red critter
	[245] = { kind = "enemy", name = "fire" }, -- lava drop gen
	[246] = { kind = "enemy", name = "plant" }, -- press proximity
	[253] = { kind = "enemy", name = "mushroom" }, -- exp capsule
	[292] = { kind = "none" }, -- quake
	[308] = { kind = "enemy", name = "goomba" }, -- stumpy
	[309] = { kind = "enemy", name = "goomba" }, -- bute
	[311] = { kind = "enemy", name = "koopaflying" }, -- bute archer
	[347] = { kind = "enemy", name = "goomba" }, -- hoppy
	[359] = { kind = "none" }, -- water droplet gen
}

local function place_flag(ir)
	-- Rightmost solid-ish column, near bottom
	local x = ir.width
	local y = math.max(1, ir.height - 2)
	for yy = ir.height, 1, -1 do
		local t = ir.tiles[x] and ir.tiles[x][yy]
		if t and t > M.CUSTOM_TILE_BASE then
			y = math.max(1, yy - 1)
			break
		end
	end
	return { x = x, y = y }
end

local function place_spawn(ir)
	-- Left side: air above solid floor, headroom, and side clearance (avoid wall pockets).
	local base = M.CUSTOM_TILE_BASE
	local function solid(x, y)
		if x < 1 or y < 1 or x > ir.width or y > ir.height then
			return true
		end
		local t = ir.tiles[x] and ir.tiles[x][y]
		return t ~= nil and t > base
	end
	local function air(x, y)
		return not solid(x, y)
	end
	local xmax = math.min(ir.width - 1, math.max(16, math.floor(ir.width / 3)))
	local function search(need_both)
		for x = 2, xmax do
			for y = ir.height - 1, 2, -1 do
				if air(x, y) and solid(x, y + 1) and air(x, y - 1) then
					local left_ok = air(x - 1, y) and air(x - 1, y - 1)
					local right_ok = air(x + 1, y) and air(x + 1, y - 1)
					if need_both and left_ok and right_ok then
						return { x = x, y = y }
					end
					if not need_both and (left_ok or right_ok) then
						return { x = x, y = y }
					end
				end
			end
		end
		return nil
	end
	local hit = search(true) or search(false)
	if hit then
		return hit
	end
	for x = 2, ir.width - 1 do
		for y = ir.height - 1, 2, -1 do
			if air(x, y) and solid(x, y + 1) and air(x, y - 1) then
				return { x = x, y = y }
			end
		end
	end
	return { x = 3, y = math.max(2, ir.height - 3) }
end

--- Build IR from raw PXM/PXA/PXE byte strings.
-- @param opts.base_tile override CUSTOM_TILE_BASE
-- @param opts.keep_conditional if true, include appear/hide flag NPCs
-- @param opts.unmapped table to accumulate type→count
function M.to_ir(pxm_data, pxa_data, pxe_data, opts)
	opts = opts or {}
	local base = opts.base_tile or M.CUSTOM_TILE_BASE
	local tiles, w, h = fmt.read_pxm(pxm_data)
	local attrs = fmt.read_pxa(pxa_data or "")
	local ents = fmt.read_pxe(pxe_data or ("PXE\0\0\0\0\0"))

	local ir = irmod.new({
		source = "cavestory",
		width = w,
		height = h,
	})
	irmod.set_size(ir, w, h, base)

	-- Tile indices: CS 0 → empty (base), else base + index (1:1 sheet order)
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local tid = tiles[y * w + x + 1] or 0
			if tid == 0 then
				ir.tiles[x + 1][y + 1] = base
			else
				ir.tiles[x + 1][y + 1] = base + tid
			end
		end
	end

	-- Expose attrs for tileset writer (1-based tile index → props)
	ir.meta.pxa_props = {}
	for i = 0, 255 do
		ir.meta.pxa_props[i] = fmt.pxa_to_props(attrs[i + 1] or 0)
	end

	local function has_bit(flags, bit)
		return math.floor(flags / bit) % 2 == 1
	end

	local unmapped = opts.unmapped
	for _, e in ipairs(ents) do
		local appear = has_bit(e.flags, FLAG_APPEAR_WHEN)
		local hide = has_bit(e.flags, FLAG_HIDE_WHEN)
		if not opts.keep_conditional and (appear or hide) then
			-- skip flag-gated NPCs without TSC
		else
			local m = M.NPC_MAP[e.type]
			if not m then
				if unmapped then
					unmapped[e.type] = (unmapped[e.type] or 0) + 1
				end
			elseif m.kind == "enemy" then
				ir.entities[#ir.entities + 1] = {
					x = e.x + 1,
					y = e.y + 1,
					name = m.name,
				}
			elseif m.kind == "spawn" then
				ir.spawn = { x = e.x + 1, y = e.y + 1 }
			elseif m.kind == "door" then
				-- Level-1: doors as non-linked pipes (TSC TRA later)
				ir.entities[#ir.entities + 1] = {
					x = e.x + 1,
					y = e.y + 1,
					name = "pipe",
				}
			end
		end
	end

	if not ir.spawn then
		ir.spawn = place_spawn(ir)
	end
	if not ir.finish then
		ir.finish = place_flag(ir)
	end

	-- Encode spawn/flag as entities for emit
	ir.entities[#ir.entities + 1] = { x = ir.spawn.x, y = ir.spawn.y, name = "spawn" }
	ir.entities[#ir.entities + 1] = { x = ir.finish.x, y = ir.finish.y, name = "flag" }

	return ir
end

--- Histogram helper: type → count from PXE bytes.
function M.pxe_histogram(pxe_data)
	local ents = fmt.read_pxe(pxe_data)
	local hist = {}
	for _, e in ipairs(ents) do
		hist[e.type] = (hist[e.type] or 0) + 1
	end
	return hist
end

M.formats = fmt

return M
