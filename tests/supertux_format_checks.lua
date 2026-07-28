--[[
  SuperTux sexpr / RLE / license / convert (synthetic .stl — no game assets).
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

local sexpr = dofile(root .. "/scripts/mapsdk/sources/sexpr.lua")
local st = dofile(root .. "/scripts/mapsdk/sources/supertux.lua")
local emit = dofile(root .. "/scripts/mapsdk/emit_mari0.lua")

-- sexpr basics
local n = sexpr.parse_sexpr('(a 1 "b" (c #t) (_ "hi"))')
check("sexpr head", n[1] == "a")
check("sexpr num", n[2] == 1)
check("sexpr str", n[3] == "b")
check("sexpr nested", type(n[4]) == "table" and n[4][1] == "c")
check("sexpr bool", n[4][2] == "#t")
check("field", sexpr.field(n, "missing") == nil)
local v, full = sexpr.field({ "root", { "license", "CC-BY-SA 4.0" } }, "license")
check("field license", v == "CC-BY-SA 4.0" and full[1] == "license")
check("as_string _", sexpr.as_string({ "_", "Hello" }) == "Hello")

-- comment skip
local nc = sexpr.parse_sexpr("(x ; comment\n 2)")
check("sexpr comment", nc[1] == "x" and nc[2] == 2)

-- RLE decode
local tiles_node = { "tiles", -3, 0, 5, -2, 7 }
local flat = sexpr.decode_tiles(tiles_node, 3, 2)
check("rle len", #flat == 6)
check("rle zeros", flat[1] == 0 and flat[2] == 0 and flat[3] == 0)
check("rle mid", flat[4] == 5)
check("rle run7", flat[5] == 7 and flat[6] == 7)

local ok_assert = pcall(sexpr.decode_tiles, { "tiles", 1, 2 }, 2, 2)
check("rle assert fail", not ok_assert)

-- license allowlist
local good = sexpr.parse_sexpr([[
(supertux-level
  (license "CC-BY-SA 4.0 International")
  (author "A")
  (name (_ "Test"))
)
]])
local ok_lic = st.license_ok(good)
check("license ok 4.0", ok_lic)

local bad = sexpr.parse_sexpr('(supertux-level (license "Proprietary"))')
check("license reject", not st.license_ok(bad))

local gpl_cc = sexpr.parse_sexpr('(supertux-level (license "GPL 2+ / CC-by-sa 3.0"))')
check("license gpl+cc", st.license_ok(gpl_cc))

-- attr bits
local solid = st.attr_to_props(1, 0)
check("attr solid", solid.collision == true)
local uni = st.attr_to_props(3, 0)
check("attr unisolid", uni.platform == true and uni.collision == true)
local hurt = st.attr_to_props(1024, 0)
check("attr hurts", hurt.spikestop == true)
local water = st.attr_to_props(512, 0)
check("attr water", water.water == true)
local brick = st.attr_to_props(4, 0)
check("attr brick", brick.breakable == true)
local slope = st.attr_to_props(17, 1)
check("attr slope", slope.slantupleft == true and slope.collision == true)

-- synthetic level 4x3
local stl = [[
(supertux-level
  (version 3)
  (name (_ "Tiny"))
  (author "Tester")
  (license "CC-BY-SA 4.0 International")
  (sector
    (name "main")
    (tilemap
      (solid #f)
      (width 4)
      (height 3)
      (tiles -12 0)
    )
    (tilemap
      (solid #t)
      (width 4)
      (height 3)
      (tiles -8 0  11 11 11 11)
    )
    (spawnpoint (name "main") (x 32) (y 32))
    (snowball (x 64) (y 32))
    (sequencetrigger (x 96) (y 32))
  )
)
]]

local unmapped = {}
local attr = {}
local ir = st.convert_stl(stl, { unmapped = unmapped, attribution = attr, filename = "tiny.stl" })
check("convert ir", ir ~= nil)
check("ir size", ir and ir.width == 4 and ir.height == 3)
check("ir no crop", ir and ir.height == 3)
check("ir spawn", ir and ir.spawn and ir.spawn.x == 2 and ir.spawn.y == 2)
check("ir attribution", #attr == 1 and attr[1].author == "Tester")

local has_goomba, has_flag, has_spawn = false, false, false
for _, e in ipairs(ir.entities) do
	if e.name == "goomba" then
		has_goomba = true
	end
	if e.name == "flag" then
		has_flag = true
	end
	if e.name == "spawn" then
		has_spawn = true
	end
end
check("snowball→goomba", has_goomba)
check("has flag", has_flag)
check("has spawn ent", has_spawn)

local text = emit.emit(ir, { spriteset = 1, timelimit = 0 })
check("emit height prefix", text:sub(1, 1) == "3")
check("emit has body", #text > 10)

-- skip bad license
local skipped, reason = st.convert_stl('(supertux-level (license "nope") (sector (name "main")))')
check("skip bad lic", skipped == nil and reason and reason:find("license", 1, true))

-- parse_strf snippet
local strf = [[
(supertux-tiles
  (tile (id 79) (images "snow.png") (solid #t))
  (tile (id 359) (images "x.png") (unisolid #t))
  (tiles
    (width 2) (height 1)
    (ids 10 11)
    (attributes 1 1024)
    (images "sheet.png")
  )
)
]]
local props, imgs = st.parse_strf(strf)
check("strf solid", props[79] and props[79].collision)
check("strf unisolid", props[359] and props[359].platform)
check("strf batch solid", props[10] and props[10].collision)
check("strf batch hurts", props[11] and props[11].spikestop)
check("strf image", imgs[79] == "snow.png")

-- brick / coin via object-data
local brick_strf = [[
(supertux-tiles
  (tile (id 78) (images "brick.png") (solid #t)
    (object-name "brick")
    (object-data "(breakable #t)"))
  (tile (id 44) (images "objects/coin/coin-0.png") (object-name "coin"))
)
]]
local bp, _bi = st.parse_strf(brick_strf)
check("strf brick breakable", bp[78] and bp[78].breakable and bp[78].collision)
check("strf coin prop", bp[44] and bp[44].coin and not bp[44].collision)

return failed
