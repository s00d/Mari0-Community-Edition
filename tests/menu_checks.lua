--[[
  Unit checks for menuutil (no LÖVE).
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

require("core.stringutil")
require("util.menuutil")

do
	local n, a, d = menu_parse_settings_text("name=Test Pack\nauthor=Ada\ndescription=Hello world\n")
	check("parse name", n == "Test Pack")
	check("parse author", a == "Ada")
	check("parse desc", d == "Hello world")
	n, a, d = menu_parse_settings_text("")
	check("parse empty nils", n == nil and a == nil and d == nil)
end

do
	check("title trunc", menu_mappack_title("ABCDEFGHIJKLMNOPQRST") == "abcdefghijklmnopq")
	check("title lower", menu_mappack_title("Hi") == "hi")
	check("author line", menu_mappack_author_line("Bob") == "by bob")
	local d1, d2, d3 = menu_mappack_desc_lines("12345678901234567890123456789012345678901234567890123")
	check("desc line1 len", #d1 == 17)
	check("desc line2 len", #d2 == 17)
	check("desc line3 len", #d3 == 17)
end

-- menu.lua uses helpers; draw is orchestrated
do
	local f = assert(io.open(root .. "/src/ui/menu.tl", "r"))
	local src = f:read("*a")
	f:close()
	check("menu parse settings", src:find("menu_parse_settings_text%(") ~= nil)
	check("menu title helper", src:find("menu_mappack_title%(") ~= nil)
	check("menu author helper", src:find("menu_mappack_author_line%(") ~= nil)
	check("menu desc helper", src:find("menu_mappack_desc_lines%(") ~= nil)
	check("menu_draw kept", src:find("function menu_draw%(") ~= nil)
	check("menu_draw_title exists", src:find("function menu_draw_title%(") ~= nil)
	check("menu_draw_mappackmenu exists", src:find("function menu_draw_mappackmenu%(") ~= nil)
	check("menu_draw_options exists", src:find("function menu_draw_options%(") ~= nil)
	check("menu_load kept", src:find("function menu_load%(") ~= nil)

	local a, b = src:find("function menu_draw%b()")
	check("menu_draw find", a ~= nil)
	if a then
		local rest = src:sub(b + 1):gsub("^:[^\n]*", "", 1)
		local body = rest:match("^\n?(.-)\nglobal function ") or rest:match("^\n?(.-)\nfunction ")
		local nlines = select(2, (body or ""):gsub("\n", "\n")) + 1
		check("menu_draw thin (<=50 lines)", nlines <= 50, tostring(nlines))
		check("md calls title", (body or ""):find("menu_draw_title%(") ~= nil)
		check("md calls mappack", (body or ""):find("menu_draw_mappackmenu%(") ~= nil)
		check("md calls options", (body or ""):find("menu_draw_options%(") ~= nil)
		check("md keeps online/lobby", (body or ""):find("onlinemenu_draw%(") ~= nil and (body or ""):find("lobby_draw%(") ~= nil)
	end
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
