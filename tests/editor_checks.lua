--[[ Unit checks for editorutil (no LÖVE). ]]

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

require("core.stringutil")
require("core.mathutil")
require("util.editorutil")

-- mapsort: double-digit worlds sort after single-digit via special rule
do
	check("mapsort 1-1 before 1-2", mapsort("1-1.txt", "1-2.txt") == true)
	check("mapsort 2-1 after 10-1", mapsort("2-1.txt", "10-1.txt") == true)
	check("mapsort 10-1 before 2-1 false", mapsort("10-1.txt", "2-1.txt") == false)
	check("mapsort 10-1 before 10-2", mapsort("10-1.txt", "10-2.txt") == true)
	local files = {"10-2.txt", "1-1.txt", "2-1.txt", "10-1.txt"}
	table.sort(files, mapsort)
	check("mapsort stable order", table.concat(files, ",") == "1-1.txt,2-1.txt,10-1.txt,10-2.txt")
end

-- filter map files
do
	local files = {"settings.txt", "1-1.txt", "icon.png", "1-2_1.txt", "readme.md"}
	editor_filter_map_files(files)
	check("filter keeps levels", #files == 2 and files[1] == "1-1.txt" and files[2] == "1-2_1.txt")
end

-- tile list / mt button coords
do
	scale = 1
	tilesoffset = 0
	objectsguiarea = {5, 21, 378, 203}
	multitilesoffset = 0
	multitileobjects = {1, 2, 3, 4}

	check("tilelist outside", gettilelistpos(0, 0) == false)
	check("tilelist first cell", gettilelistpos(5, 38) == 1)
	check("tilelist col2", gettilelistpos(22, 38) == 2)
	check("tilelist row2", gettilelistpos(5, 55) == 23)

	check("listpos first", getlistpos(10, 21) == 0)
	check("listpos outside", getlistpos(0, 0) == false)

	check("mtbutton 4", getmtbutton(370) == 4)
	check("mtbutton 0 outside", getmtbutton(10) == 0)
end

-- hotkeys
do
	hotkeys = {}
	changeHotKey(3, 1, 42)
	check("hasHotkey set", hasHotkey(1, 42) == 3)
	check("hasHotkey miss", hasHotkey(1, 99) == false)
	changeHotKey(0, 1, 42)
	check("hasHotkey cleared", hasHotkey(1, 42) == false)

	local parsed = editor_hotkeys_parse("1=2,10\n5=1,7\n")
	check("hotkeys parse 1", parsed["1"][1] == 2 and parsed["1"][2] == 10)
	check("hotkeys parse 5", parsed["5"][1] == 1 and parsed["5"][2] == 7)
	local ser = editor_hotkeys_serialize({["1"] = {2, 10}, ["5"] = {1, 7}})
	check("hotkeys serialize has both", ser:find("1=2,10") ~= nil and ser:find("5=1,7") ~= nil)
	check("hotkeys empty parse", next(editor_hotkeys_parse("")) == nil)
end

-- minimap math
do
	scale = 2
	local xs = editor_minimap_xscroll_from_mouse(100, 2, 25, 0)
	check("minimap xscroll mid", xs == 11)
	check("minimap xscroll clamp low", editor_minimap_xscroll_from_mouse(0, 2, 25, 5) == 5)
	local hi = editor_minimap_xscroll_from_mouse(10000, 2, 25, 5)
	check("minimap xscroll clamp hi", hi == 175)
	local tx, ty = editor_minimap_tile_from_click(10, 64, 2, 3, 30, 0, 2)
	check("minimap tile click", tx == 1 and ty == 3, string.format("%s,%s", tostring(tx), tostring(ty)))
end

-- formatscrollnumber
do
	check("formatscroll pos", formatscrollnumber(1.5) == "1.50")
	check("formatscroll neg", formatscrollnumber(-1.25) == "-1.2")
	check("formatscroll short", formatscrollnumber(0.5) == "0.50")
end

-- pure helpers: normalize / labels / link pos
do
	local x, y, w, h = editor_normalize_rect(10, 20, -4, -6)
	check("normalize rect flip", x == 6 and y == 14 and w == 4 and h == 6)
	local m, s = editor_mode_labels("selection", false, false, nil)
	check("mode selection", m == "selection" and s == false)
	m, s = editor_mode_labels("lightdraw", false, false, "mushroom")
	check("mode lightdraw mushroom", m == "advanced draw tool" and s == "mushroom platforms")
	m, s = editor_mode_labels("tiles", true, true, nil)
	check("mode enemies", m == "tiles" and s == "enemies")
	xscroll, yscroll, scale = 2, 1, 2
	local x1, y1 = editor_link_screen_pos(3, 4)
	check("link screen pos", x1 == math.floor((3-2-.5)*32) and y1 == math.floor((4-1-1)*32))
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
