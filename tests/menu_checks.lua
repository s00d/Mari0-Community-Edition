--[[ Menu layout / input-mode checks (no LÖVE). ]]

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
require("util.menuutil")
require("ui.menu_layout")

-- Fixture screen (actions are stubs; must exist for walk)
local activated = nil
local continue_on = true
local screen = {
	title = "mari0",
	items = {
		{
			id = "continue",
			label = "continue game",
			visible = function()
				return continue_on
			end,
			action = function()
				activated = "continue"
			end,
		},
		{
			id = "newgame",
			label = "player game",
			action = function()
				activated = "newgame"
			end,
		},
		{
			id = "editor",
			label = "level editor",
			action = function()
				activated = "editor"
			end,
		},
		{
			id = "mappacks",
			label = "select mappack",
			action = function()
				activated = "mappacks"
			end,
		},
		{
			id = "options",
			label = "options",
			action = function()
				activated = "options"
			end,
		},
		{
			id = "online",
			label = "online play",
			action = function()
				activated = "online"
			end,
		},
	},
	spinners = {
		{
			id = "players",
			get = function()
				return "1"
			end,
			dec = function() end,
			inc = function() end,
		},
	},
}

do
	continue_on = false
	local vis = menu_visible_items(screen)
	local has_continue = false
	for i = 1, #vis do
		if vis[i].id == "continue" then
			has_continue = true
		end
	end
	check("visible_items hides continue", not has_continue and #vis == 5)
	continue_on = true
	vis = menu_visible_items(screen)
	check("visible_items shows continue", #vis == 6 and vis[1].id == "continue")
end

do
	local lay = menu_layout_main(screen)
	local rects = lay.rects
	check("layout rect count", #rects == 6, tostring(#rects))
	check("layout on 8px grid", menu_rects_on_grid(rects))
	check("layout non-overlap", menu_rects_non_overlap(rects))
	local panel = lay.panel
	check("panel multiples of 8", panel.x % 8 == 0 and panel.y % 8 == 0 and panel.w % 8 == 0 and panel.h % 8 == 0)

	for i = 1, #rects do
		local r = rects[i]
		local cx, cy = r.x + r.w / 2, r.y + r.h / 2
		check("hit center " .. i, menu_hit(rects, cx, cy) == i)
	end
	-- between first and second row
	local r1, r2 = rects[1], rects[2]
	local mid_y = r1.y + r1.h -- boundary: half-open [y,y+h) so y+h is next or nil
	-- gapless rows: y+h of first == y of second, so mid is still a hit on second
	check("hit at row boundary is second", menu_hit(rects, r1.x + 8, mid_y) == 2)
	check("hit outside nil", menu_hit(rects, 0, 0) == nil)
end

do
	-- every item has action (walk MENU_SCREENS-shaped table)
	for _, it in ipairs(screen.items) do
		check("item action " .. it.id, type(it.action) == "function")
	end
end

do
	-- mode switch contract (mirrors ui_input helpers without love)
	local mode = "kbd"
	local function note_mouse(dx, dy)
		if math.abs(dx) + math.abs(dy) < 1 then
			return false
		end
		mode = "mouse"
		return true
	end
	local function note_kbd()
		mode = "kbd"
	end
	check("mode starts kbd", mode == "kbd")
	check("jitter ignored", note_mouse(0.2, 0.2) == false and mode == "kbd")
	check("mouse move sets mouse", note_mouse(2, 0) and mode == "mouse")
	note_kbd()
	check("key sets kbd", mode == "kbd")
end

do
	-- click off selection does not activate
	local selection = 2
	local lay = menu_layout_main(screen)
	local i = menu_hit(lay.rects, lay.rects[1].x + 4, lay.rects[1].y + 4)
	activated = nil
	if i and i == selection then
		screen.items[i].action()
	elseif i then
		selection = i
	end
	check("click off selection no activate", activated == nil and selection == 1)
	-- second click on selection activates
	i = menu_hit(lay.rects, lay.rects[1].x + 4, lay.rects[1].y + 4)
	if i and i == selection then
		screen.items[1].action() -- continue is index 1 in items table when visible
	end
	-- activate via visible index
	local vis = menu_visible_items(screen)
	activated = nil
	selection = 1
	i = 1
	if i == selection then
		vis[i].action()
	end
	check("click on selection activates", activated == "continue")
end

-- Also parse checks from prior menu_checks
do
	local n, a, d = menu_parse_settings_text("name=Test Pack\nauthor=Ada\ndescription=Hello world\n")
	check("parse name", n == "Test Pack")
	check("parse author", a == "Ada")
	check("parse desc", d == "Hello world")
end

-- Mappack filter + two-panel layout
do
	local names = { "Super Mario", "Portal Pack", "Custom" }
	local all = menu_mappack_filter_indices(names, "")
	check("filter empty keeps all", #all == 3)
	local portal = menu_mappack_filter_indices(names, "portal")
	check("filter substring", #portal == 1 and portal[1] == 2)
	local none = menu_mappack_filter_indices(names, "zzz")
	check("filter miss empty", #none == 0)

	local lay = menu_layout_mappack({ visible_count = 3, scroll = 0 })
	check("mappack list panel grid", lay.list.x % 8 == 0 and lay.list.w % 8 == 0 and lay.list.h % 8 == 0)
	check("mappack preview panel grid", lay.preview.x % 8 == 0 and lay.preview.w % 8 == 0)
	check("mappack rows count", #lay.rows == 3)
	check("mappack rows on grid", menu_rects_on_grid(lay.rows))
	check("mappack rows non-overlap", menu_rects_non_overlap(lay.rows))
	local mid = lay.rows[2]
	check("mappack hit row2", menu_hit(lay.rows, mid.x + 4, mid.y + 4) == 2)
	check("mappack three tabs", #lay.tabs == 3)
end

-- Options tabs + pause layout
do
	local tabs = menu_layout_options_tabs()
	check("options 4 tabs", #tabs == 4)
	check("options tabs on grid", menu_rects_on_grid(tabs))
	local body = menu_layout_options_rows(5)
	check("options body rows", #body.rows == 4) -- selection 2..5
	check("options body grid", menu_rects_on_grid(body.rows))

	local pause = menu_layout_pause(400)
	check("pause 6 rows", #pause.rects == 6)
	check("pause panel grid", pause.panel.w % 8 == 0 and pause.panel.h % 8 == 0)
	check("pause rows grid", menu_rects_on_grid(pause.rects))
	check("pause hit first", menu_hit(pause.rects, pause.rects[1].x + 4, pause.rects[1].y + 4) == 1)

	local ls = menu_layout_levelscreen(400)
	check("levelscreen panel grid", ls.panel.x % 8 == 0 and ls.panel.w % 8 == 0)
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
