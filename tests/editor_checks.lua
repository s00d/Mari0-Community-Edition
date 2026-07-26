--[[
  Structural + unit checks for editorutil / editor_draw chrome peel (no LÖVE).
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

dofile(root .. "/stringutil.lua")
dofile(root .. "/mathutil.lua")
dofile(root .. "/editorutil.lua")

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
	multitileobjects = {1, 2, 3, 4} -- length 4 → indices 0..3 valid

	check("tilelist outside", gettilelistpos(0, 0) == false)
	-- first cell: x=5..21, y=38..54 → index 1
	check("tilelist first cell", gettilelistpos(5, 38) == 1)
	-- second column: x=22 → floor(17/17)+1 = 2
	check("tilelist col2", gettilelistpos(22, 38) == 2)
	-- second row: y=55 → floor(17/17)=1 → +22
	check("tilelist row2", gettilelistpos(5, 55) == 23)

	check("listpos first", getlistpos(10, 21) == 0)
	check("listpos outside", getlistpos(0, 0) == false)

	-- button 4 band: [378-15, 378-1) = [363, 377)
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
	-- (100/2 - 3 - 25)/2 + 0 = (50-28)/2 = 11
	check("minimap xscroll mid", xs == 11)
	check("minimap xscroll clamp low", editor_minimap_xscroll_from_mouse(0, 2, 25, 5) == 5)
	local hi = editor_minimap_xscroll_from_mouse(10000, 2, 25, 5)
	check("minimap xscroll clamp hi", hi == 175)
	local tx, ty = editor_minimap_tile_from_click(10, 64, 2, 3, 30, 0, 2)
	-- floor((10-6+0)/2/2)=floor(4/4)=1 ; floor((64-60)/2/2 + 2)=floor(4/4 + 2)=3
	check("minimap tile click", tx == 1 and ty == 3, string.format("%s,%s", tostring(tx), tostring(ty)))
end

-- formatscrollnumber
do
	check("formatscroll pos", formatscrollnumber(1.5) == "1.50")
	check("formatscroll neg", formatscrollnumber(-1.25) == "-1.2")
	check("formatscroll short", formatscrollnumber(0.5) == "0.50")
end

-- editor.lua structural: draw phases + no duplicate defs
do
	local f = assert(io.open(root .. "/editor.lua", "r"))
	local src = f:read("*a")
	f:close()

	local function extract_top(name)
		local a, b = src:find("function " .. name .. "%b()\n")
		if not a then
			return nil
		end
		local rest = src:sub(b + 1)
		return rest:match("^(.-)\nfunction ")
	end

	check("editor_draw exists", src:find("function editor_draw%(") ~= nil)
	check("editor_draw_overlay exists", src:find("function editor_draw_overlay%(") ~= nil)
	check("editor_draw_linking exists", src:find("function editor_draw_linking%(") ~= nil)
	check("editor_draw_status exists", src:find("function editor_draw_status%(") ~= nil)
	check("editor_draw_menu exists", src:find("function editor_draw_menu%(") ~= nil)
	check("editor_draw_chrome exists", src:find("function editor_draw_chrome%(") ~= nil)

	local gd = extract_top("editor_draw")
	check("editor_draw body", gd ~= nil)
	if gd then
		local nlines = select(2, gd:gsub("\n", "\n")) + 1
		check("editor_draw thin (<=25 lines)", nlines <= 25, tostring(nlines))
		check("gd calls overlay", gd:find("editor_draw_overlay%(") ~= nil)
		check("gd calls linking", gd:find("editor_draw_linking%(") ~= nil)
		check("gd calls status", gd:find("editor_draw_status%(") ~= nil)
		check("gd calls menu", gd:find("editor_draw_menu%(") ~= nil)
		check("gd calls chrome", gd:find("editor_draw_chrome%(") ~= nil)
		check("gd no inline tiles tab", gd:find('editorstate == "tiles"') == nil)
	end

	local ov = extract_top("editor_draw_overlay")
	check("overlay has selection", ov and ov:find('editorstate == "selection"') ~= nil)
	check("overlay uses normalize_rect", ov and ov:find("editor_normalize_rect%(") ~= nil)
	check("overlay no rightclickm:draw", ov and ov:find("rightclickm:draw") == nil)

	local lk = extract_top("editor_draw_linking")
	check("linking has drawalllinks", lk and lk:find("drawalllinks") ~= nil)
	check("linking has rightclickm:draw", lk and lk:find("rightclickm:draw") ~= nil)
	check("linking uses link_screen_pos", lk and lk:find("editor_link_screen_pos%(") ~= nil)

	local st = extract_top("editor_draw_status")
	check("status uses mode_labels", st and st:find("editor_mode_labels%(") ~= nil)
	check("status has f1 help", st and st:find('"f1"') ~= nil)

	local mn = extract_top("editor_draw_menu")
	check("menu thin orchestrator", mn ~= nil)
	if mn then
		local nlines = select(2, mn:gsub("\n", "\n")) + 1
		check("menu_draw_menu thin (<=45 lines)", nlines <= 45, tostring(nlines))
		check("menu calls tiles", mn:find("editor_draw_menu_tiles%(") ~= nil)
		check("menu calls main", mn:find("editor_draw_menu_main%(") ~= nil)
		check("menu calls maps", mn:find("editor_draw_menu_maps%(") ~= nil)
		check("menu calls tools", mn:find("editor_draw_menu_tools%(") ~= nil)
		check("menu calls animations", mn:find("editor_draw_menu_animations%(") ~= nil)
		check("menu calls objects", mn:find("editor_draw_menu_objects%(") ~= nil)
		check("menu calls changewidth", mn:find("editor_draw_menu_changewidth%(") ~= nil)
		check("menu no inline TILES comment", mn:find("%-%-TILES") == nil)
	end

	for _, name in ipairs({
		"editor_draw_menu_changewidth",
		"editor_draw_menu_tiles",
		"editor_draw_menu_main",
		"editor_draw_menu_maps",
		"editor_draw_menu_tools",
		"editor_draw_menu_animations",
		"editor_draw_menu_objects",
	}) do
		check(name .. " exists", src:find("function " .. name .. "%(") ~= nil)
	end

	-- update phases
	local ud = extract_top("editor_update")
	check("editor_update exists", ud ~= nil)
	if ud then
		local nlines = select(2, ud:gsub("\n", "\n")) + 1
		check("editor_update thin (<=60 lines)", nlines <= 60, tostring(nlines))
		check("upd calls rightclick", ud:find("editor_update_rightclick%(") ~= nil)
		check("upd calls keyscroll", ud:find("editor_update_keyscroll%(") ~= nil)
		check("upd calls modifiers", ud:find("editor_update_modifiers%(") ~= nil)
		check("upd calls closed", ud:find("editor_update_closed%(") ~= nil)
		check("upd calls main", ud:find("editor_update_main%(") ~= nil)
		check("upd calls tiles", ud:find("editor_update_tiles%(") ~= nil)
		check("upd calls objects", ud:find("editor_update_objects%(") ~= nil)
	end

	-- mousepressed phases
	local mp = extract_top("editor_mousepressed")
	check("editor_mousepressed exists", mp ~= nil)
	if mp then
		local nlines = select(2, mp:gsub("\n", "\n")) + 1
		check("mousepressed thin (<=55 lines)", nlines <= 55, tostring(nlines))
		check("mp calls left", mp:find("editor_mousepressed_left%(") ~= nil)
		check("mp calls right", mp:find("editor_mousepressed_right%(") ~= nil)
		check("mp calls wheel_up", mp:find("editor_mousepressed_wheel_up%(") ~= nil)
		check("mp calls wheel_down", mp:find("editor_mousepressed_wheel_down%(") ~= nil)
		check("mp keeps rightclickm guard", mp:find("rightclickm") ~= nil)
		check("mp keeps regiondragging guard", mp:find("regiondragging") ~= nil)
	end

	check("no local mapsort in editor", src:find("function mapsort%(") == nil)
	check("no local hasHotkey in editor", src:find("function hasHotkey%(") == nil)
	check("no local gettilelistpos in editor", src:find("function gettilelistpos%(") == nil)
	check("no local formatscrollnumber in editor", src:find("function formatscrollnumber%(") == nil)
	check("getmaps uses filter", src:find("editor_filter_map_files%(") ~= nil)
	check("loadHotKeys uses parse", src:find("editor_hotkeys_parse%(") ~= nil)
	check("saveHotKeys uses serialize", src:find("editor_hotkeys_serialize%(") ~= nil)
	check("hotkeys/rightclick kept", src:find("function closerightclickmenu%(") ~= nil and src:find("function editor_keypressed%(") ~= nil)

	local chrome = extract_top("editor_draw_chrome")
	check("chrome find", chrome ~= nil)
	if chrome then
		local nlines = select(2, chrome:gsub("\n", "\n")) + 1
		check("chrome thin (<=50 lines)", nlines <= 50, tostring(nlines))
		check("chrome draws region", chrome:find("regiondragging") ~= nil)
		check("chrome draws tooltip", chrome:find("entitytooltipobject") ~= nil)
	end
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

-- main.lua requires editorutil before editor
do
	local f = assert(io.open(root .. "/main.lua", "r"))
	local main = f:read("*a")
	f:close()
	local eu = main:find('require%s+"editorutil"')
	local ed = main:find('require%s+"editor"')
	check("main requires editorutil", eu ~= nil)
	check("editorutil before editor", eu and ed and eu < ed)
	local mu = main:find('require%s+"menuutil"')
	local menu = main:find('require%s+"menu"')
	check("main requires menuutil", mu ~= nil)
	check("menuutil before menu", mu and menu and mu < menu)
	check("main early stringutil kept", main:find('require%s+"stringutil"') ~= nil)
	check("main early mathutil kept", main:find('require%s+"mathutil"') ~= nil)
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
