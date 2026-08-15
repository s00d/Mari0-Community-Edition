--[[ Stage 9+: editor/menu monolith extracts (mechanical move, no behavior change). ]]

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

local function exists(rel)
	local f = io.open(root .. "/" .. rel, "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function read(rel)
	local f = io.open(root .. "/" .. rel, "r")
	if not f then
		return nil
	end
	local s = f:read("*a")
	f:close()
	return s
end

local mods = {
	"editor_draw", "editor_tabs", "editor_tilefilters", "editor_animation",
	"editor_mapio", "editor_settings", "editor_input", "menu_options_draw",
}
for _, m in ipairs(mods) do
	check(m .. ".tl exists", exists("src/ui/" .. m .. ".tl"))
end

local ed = read("src/ui/editor.tl") or ""
check("editor keeps editor_draw dispatcher", ed:find("function editor_draw()", 1, true) ~= nil)
check("editor keeps editor_load", ed:find("function editor_load()", 1, true) ~= nil)
check("editor keeps placetile", ed:find("function placetile", 1, true) ~= nil)
check("editor dropped function editor_draw_menu", ed:find("function editor_draw_menu", 1, true) == nil)
check("editor dropped function maintab", ed:find("function maintab", 1, true) == nil)
check("editor dropped function tilesall", ed:find("function tilesall", 1, true) == nil)
check("editor dropped function generateanimationgui", ed:find("function generateanimationgui", 1, true) == nil)
check("editor dropped function editor_mousepressed", ed:find("function editor_mousepressed", 1, true) == nil)
check("editor dropped function toggleautoscroll", ed:find("function toggleautoscroll", 1, true) == nil)
check("editor dropped function getmaps", ed:find("function getmaps", 1, true) == nil)
check("editor still calls editor_draw_menu", ed:find("editor_draw_menu(", 1, true) ~= nil)

check("tilefilters has tilesall", (read("src/ui/editor_tilefilters.tl") or ""):find("function tilesall", 1, true) ~= nil)
check("animation has generateanimationgui", (read("src/ui/editor_animation.tl") or ""):find("function generateanimationgui", 1, true) ~= nil)
check("mapio has getmaps", (read("src/ui/editor_mapio.tl") or ""):find("function getmaps", 1, true) ~= nil)
check("input has editor_mousepressed", (read("src/ui/editor_input.tl") or ""):find("function editor_mousepressed", 1, true) ~= nil)
check("settings has toggleautoscroll", (read("src/ui/editor_settings.tl") or ""):find("function toggleautoscroll", 1, true) ~= nil)

local menu = read("src/ui/menu.tl") or ""
check("menu dropped function menu_draw_options", menu:find("function menu_draw_options", 1, true) == nil)
check("menu still calls menu_draw_options", menu:find("menu_draw_options()", 1, true) ~= nil)

local boot = read("src/app/boot.tl") or ""
local editor_req = boot:find('require "ui.editor"', 1, true) or 0
for _, m in ipairs({
	"ui.editor_draw", "ui.editor_tabs", "ui.editor_tilefilters", "ui.editor_animation",
	"ui.editor_mapio", "ui.editor_settings", "ui.editor_input",
}) do
	local pos = boot:find('require "' .. m .. '"', 1, true)
	check("boot requires " .. m .. " before editor", pos ~= nil and pos < editor_req)
end
check("boot requires menu_options_draw before menu", (boot:find('require "ui.menu_options_draw"', 1, true) or 0)
	< (boot:find('require "ui.menu"', 1, true) or 0))

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
