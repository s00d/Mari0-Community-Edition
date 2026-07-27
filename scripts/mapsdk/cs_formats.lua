--[[ Ported from doukutsu-rs (https://github.com/doukutsu-rs/doukutsu-rs)
     Copyright 2020 doukutsu-rs contributors. MIT License — see licenses/doukutsu-rs.MIT

  Pure Lua Cave Story format readers (PXM / PXA / PXE / optional npc.tbl).
  No Pixel assets required — tests use synthetic binaries.
]]

local M = {}

local function u16(d, o)
	return d:byte(o) + d:byte(o + 1) * 256
end

local function u32(d, o)
	return u16(d, o) + u16(d, o + 2) * 65536
end

--- Strip water bit 0x20 (attrib & ~0x20).
local function strip_water(a)
	local water = math.floor(a / 0x20) % 2 == 1
	if water then
		return a - 0x20, true
	end
	return a, false
end

--- Read PXM map: magic "PXM", version 0x10, u16le w/h, then w*h tile bytes.
-- @return tiles (1-based flat), width, height
function M.read_pxm(data)
	assert(type(data) == "string", "read_pxm expects string")
	assert(#data >= 8, "PXM too short")
	assert(data:sub(1, 3) == "PXM" and data:byte(4) == 0x10, "bad PXM header")
	local w = u16(data, 5)
	local h = u16(data, 7)
	assert(#data >= 8 + w * h, "PXM truncated")
	local tiles = {}
	for i = 1, w * h do
		tiles[i] = data:byte(8 + i)
	end
	return tiles, w, h
end

--- Read PXA attributes: 256 bytes, index = tile_id+1 → attrib byte.
function M.read_pxa(data)
	assert(type(data) == "string", "read_pxa expects string")
	local a = {}
	for i = 1, 256 do
		a[i] = data:byte(i) or 0
	end
	return a
end

--- Read PXE entities.
-- @return array of {x,y,flag,event,type,flags} (tile coords, 0-based)
function M.read_pxe(data)
	assert(type(data) == "string", "read_pxe expects string")
	assert(#data >= 8, "PXE too short")
	assert(data:sub(1, 3) == "PXE", "bad PXE magic")
	local ver = data:byte(4)
	assert(ver == 0x00 or ver == 0x10, "unsupported PXE version")
	local n = u32(data, 5)
	assert(#data >= 8 + n * 12, "PXE truncated")
	local out = {}
	for i = 0, n - 1 do
		local o = 9 + i * 12
		out[i + 1] = {
			x = u16(data, o),
			y = u16(data, o + 2),
			flag = u16(data, o + 4),
			event = u16(data, o + 6),
			type = u16(data, o + 8),
			flags = u16(data, o + 10),
		}
	end
	return out
end

-- PXA → Mari0 props. Semantics from doukutsu-rs physics.rs + user plan mapping.
-- Bit 0x20 = underwater variant. Floor slopes 0x54–0x57; 0x50–0x53 ceiling→solid for U1.
-- User plan 4-step floor mapping applied to 0x50–0x57 for converter slopes.
local PXA_MAP = {
	[0x00] = {},
	[0x01] = { collision = true },
	[0x02] = { collision = true },
	[0x03] = { collision = true },
	[0x04] = { collision = true },
	[0x05] = { collision = true },
	[0x41] = { collision = true },
	[0x42] = { collision = true, spikestop = true },
	[0x43] = { collision = true, breakable = true },
	[0x44] = { collision = true },
	[0x46] = { collision = true },
	[0x4a] = { collision = true, platform = true },
	-- 4-step slopes (plan): ur 0x50–0x53, ul 0x54–0x57
	[0x50] = { collision = true, slantupright = true, slopestep = 1 },
	[0x51] = { collision = true, slantupright = true, slopestep = 2 },
	[0x52] = { collision = true, slantupright = true, slopestep = 3 },
	[0x53] = { collision = true, slantupright = true, slopestep = 4 },
	[0x54] = { collision = true, slantupleft = true, slopestep = 4 },
	[0x55] = { collision = true, slantupleft = true, slopestep = 3 },
	[0x56] = { collision = true, slantupleft = true, slopestep = 2 },
	[0x57] = { collision = true, slantupleft = true, slopestep = 1 },
	[0x5a] = { water = true },
}

function M.pxa_to_props(attrib)
	local a = (attrib or 0) % 256
	local key, water = strip_water(a)
	local src = PXA_MAP[key]
	local p = {}
	if src then
		for k, v in pairs(src) do
			p[k] = v
		end
	end
	if water then
		p.water = true
	end
	return p
end

--- Optional column-major npc.tbl reader (361 entries).
function M.read_npc_tbl(data)
	assert(type(data) == "string", "read_npc_tbl expects string")
	local N = 361
	local function slice_u16(off0)
		local t = {}
		for i = 0, N - 1 do
			t[i + 1] = u16(data, off0 + 1 + i * 2)
		end
		return t
	end
	local function slice_u8(off0)
		local t = {}
		for i = 0, N - 1 do
			t[i + 1] = data:byte(off0 + 1 + i) or 0
		end
		return t
	end
	local function slice_u32(off0)
		local t = {}
		for i = 0, N - 1 do
			t[i + 1] = u32(data, off0 + 1 + i * 4)
		end
		return t
	end
	local o = 0
	local flags = slice_u16(o)
	o = o + N * 2
	local life = slice_u16(o)
	o = o + N * 2
	local spritesheet = slice_u8(o)
	o = o + N
	local death_sound = slice_u8(o)
	o = o + N
	local hurt_sound = slice_u8(o)
	o = o + N
	local size = slice_u8(o)
	o = o + N
	assert(#data >= o + N * 4 * 2 + N * 8, "npc.tbl truncated")
	local exp = slice_u32(o)
	o = o + N * 4
	local damage = slice_u32(o)
	o = o + N * 4
	local hit = {}
	for _, side in ipairs({ "left", "top", "right", "bottom" }) do
		hit[side] = slice_u8(o)
		o = o + N
	end
	local view = {}
	for _, side in ipairs({ "left", "top", "right", "bottom" }) do
		view[side] = slice_u8(o)
		o = o + N
	end
	local out = {}
	for i = 1, N do
		out[i] = {
			flags = flags[i],
			life = life[i],
			spritesheet = spritesheet[i],
			death_sound = death_sound[i],
			hurt_sound = hurt_sound[i],
			size = size[i],
			exp = exp[i],
			damage = damage[i],
			hit = {
				left = hit.left[i],
				top = hit.top[i],
				right = hit.right[i],
				bottom = hit.bottom[i],
			},
			view = {
				left = view.left[i],
				top = view.top[i],
				right = view.right[i],
				bottom = view.bottom[i],
			},
		}
	end
	return out
end

--- Optional TSC decrypt (middle-byte key). Stub for later F7.
function M.tsc_decrypt(data)
	local half = math.floor(#data / 2) + 1
	local key = data:byte(half) or 7
	if key == 0 then
		key = 7
	end
	local out = {}
	for i = 1, #data do
		local b = data:byte(i)
		if i == half then
			out[i] = string.char(b)
		else
			out[i] = string.char((b - key) % 256)
		end
	end
	return table.concat(out)
end

M.PXA_MAP = PXA_MAP
M.strip_water = strip_water

return M
