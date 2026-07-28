--[[ Autotile parse / mask / around (no LÖVE). ]]

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

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	package.path,
}, ";")

require("ui.autotile")
require("ui.editor_undo")

-- Fake map 5x5
mapwidth, mapheight = 5, 5
function inmap(x, y) return x >= 1 and y >= 1 and x <= mapwidth and y <= mapheight end
map = {}
coinmap = {}
for x = 1, 5 do
	map[x] = {}
	coinmap[x] = {}
	for y = 1, 5 do
		map[x][y] = {1}
		coinmap[x][y] = false
	end
end
function init_map_cell_gels() end
function generatespritebatch() end

local sample = [[
# comment
ground=4:10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25
brick=8:30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30
]]
autotile_load_text(sample)
check("parse ground", AUTOTILE_GROUPS.ground ~= nil)
check("parse brick mode8", AUTOTILE_GROUPS.brick and AUTOTILE_GROUPS.brick.mode == 8)
check("by_tile maps", AUTOTILE_BY_TILE[10] == "ground")

-- Paint center and neighbors
map[3][3][1] = 10
map[3][2][1] = 10 -- N
map[4][3][1] = 10 -- E
local mask = autotile_mask(3, 3, AUTOTILE_GROUPS.ground)
-- N=1 E=2 => 3
check("mask N+E", mask == 3, tostring(mask))
local pick = autotile_pick(AUTOTILE_GROUPS.ground, mask)
check("pick index", pick == AUTOTILE_GROUPS.ground.tiles[4], tostring(pick)) -- mask 3 → index 4

-- mode 8 blob: N+E with diagonal NE → bits 1+4+2=7 when NE present
map[4][2][1] = 30 -- NE of 3,3 for brick group
map[3][3][1] = 30
map[3][2][1] = 30
map[4][3][1] = 30
local m8 = autotile_mask(3, 3, AUTOTILE_GROUPS.brick)
check("mode8 has N+E", (m8 % 2 == 1) and (math.floor(m8/4)%2 == 1), tostring(m8))
check("mode8 NE culled ok", math.floor(m8/2)%2 == 1, tostring(m8)) -- both edges → NE kept
map[4][2][1] = 1 -- remove NE tile; diagonal should cull
local m8b = autotile_mask(3, 3, AUTOTILE_GROUPS.brick)
check("mode8 NE culled when empty", math.floor(m8b/2)%2 == 0, tostring(m8b))

editor_undo_clear()
editor_undo_begin()
local ok = autotile_paint(2, 2, 10, false)
check("autotile_paint", ok)
check("painted in group", AUTOTILE_BY_TILE[map[2][2][1]] == "ground")
autotile_paint(2, 3, 10, false)
autotile_around(2, 2)
check("around refreshed", AUTOTILE_BY_TILE[map[2][2][1]] == "ground")
if autotile_region then
	autotile_region(2, 2, 3, 3)
	check("region ok", true)
end

-- ALT/raw skip
check("raw skip", autotile_paint(1, 1, 10, true) == false)

-- Undo ring
editor_undo_commit()
local before = map[2][2][1]
-- mutate
editor_undo_begin()
editor_undo_record(2, 2)
map[2][2][1] = 1
editor_undo_commit()
check("undo works", editor_undo() == true)
check("undo restored", map[2][2][1] == before, tostring(map[2][2][1]))
check("redo works", editor_redo() == true)
check("redo applied", map[2][2][1] == 1)

-- layout grid
require("ui.editor_layout")
layout_recalc("tiles", true)
check("layout on grid", layout_rects_on_grid())
check("canvas size", EDITOR_LAYOUT.canvas.w >= 128 and EDITOR_LAYOUT.canvas.h == 176)
layout_toggle_palette()
check("palette collapse", EDITOR_LAYOUT.palette_collapsed == true)
layout_toggle_palette()

-- smb sample file parses
local f = io.open(root .. "/mappacks/smb/autotile.txt", "r")
check("smb autotile exists", f ~= nil)
if f then
	local data = f:read("*a")
	f:close()
	local g = autotile_parse(data)
	check("smb ground group", g.ground ~= nil and #g.ground.tiles >= 16)
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
