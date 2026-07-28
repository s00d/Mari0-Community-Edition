--[[
  Cave Story format parsers + pxa_to_props (synthetic binaries, no Pixel assets).
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

local fmt = dofile(root .. "/scripts/mapsdk/cs_formats.lua")
local cs = dofile(root .. "/scripts/mapsdk/sources/cavestory.lua")

-- Build tiny PXM 4x3
local function u16le(n)
	return string.char(n % 256, math.floor(n / 256) % 256)
end
local function u32le(n)
	return u16le(n % 65536) .. u16le(math.floor(n / 65536))
end

local tiles = { 1, 2, 0, 3, 4, 5, 0, 0, 6, 7, 8, 9 }
local pxm = "PXM" .. string.char(0x10) .. u16le(4) .. u16le(3)
for i = 1, 12 do
	pxm = pxm .. string.char(tiles[i])
end

local t, w, h = fmt.read_pxm(pxm)
check("pxm size", w == 4 and h == 3)
check("pxm tile[1]", t[1] == 1)
check("pxm tile[12]", t[12] == 9)

-- PXA
local pxa_bytes = string.rep("\0", 256)
pxa_bytes = string.char(0x00) .. string.char(0x01) .. string.char(0x50) .. string.char(0x70) .. string.sub(pxa_bytes, 5)
-- indices 0,1,2,3 → wait byte 1 is index 0
local pxa = fmt.read_pxa(string.char(0x00, 0x01, 0x50, 0x70) .. string.rep("\0", 252))
check("pxa len", #pxa == 256)
check("pxa solid", fmt.pxa_to_props(pxa[2]).collision == true)
local slope = fmt.pxa_to_props(0x50)
check("pxa slope step", slope.slantupright == true and slope.slopestep == 1)
local wet = fmt.pxa_to_props(0x70) -- 0x50|0x20
check("pxa water bit", wet.water == true and wet.slantupright == true and wet.slopestep == 1)

-- PXE with 2 entities
local pxe = "PXE" .. string.char(0x00) .. u32le(2)
-- ent0: x=1 y=2 type=64 flags=0
pxe = pxe .. u16le(1) .. u16le(2) .. u16le(0) .. u16le(0) .. u16le(64) .. u16le(0)
-- ent1: x=3 y=1 type=65 flags=0x2000
pxe = pxe .. u16le(3) .. u16le(1) .. u16le(0) .. u16le(0) .. u16le(65) .. u16le(0x2000)
local ents = fmt.read_pxe(pxe)
check("pxe count", #ents == 2)
check("pxe type64", ents[1].type == 64 and ents[1].x == 1 and ents[1].y == 2)
check("pxe type65", ents[2].type == 65)

-- IR conversion
local ir = cs.to_ir(pxm, string.char(0x00, 0x01) .. string.rep("\0", 254), pxe, {})
check("ir size", ir.width == 4 and ir.height == 3)
check("ir no crop", ir.height == 3)
check("ir has spawn", ir.spawn ~= nil)
check("ir has finish", ir.finish ~= nil)
local has_goomba = false
for _, e in ipairs(ir.entities) do
	if e.name == "goomba" then
		has_goomba = true
	end
end
check("ir critter→goomba", has_goomba)

-- Histogram
local hist = cs.pxe_histogram(pxe)
check("hist 64", hist[64] == 1 and hist[65] == 1)

-- TSC decrypt stub roundtrip shape
local src = "ABCDEFGHIJKLMNOP"
local dec = fmt.tsc_decrypt(src)
check("tsc_decrypt len", #dec == #src)
check("tsc mid unchanged", dec:byte(math.floor(#src / 2) + 1) == src:byte(math.floor(#src / 2) + 1))

-- Bad headers
local okp = pcall(fmt.read_pxm, "XXX")
check("pxm reject", not okp)

check("cavestory settings.txt", io.open(root .. "/mappacks/cavestory/settings.txt", "r") ~= nil)

return failed
