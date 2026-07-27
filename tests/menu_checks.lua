--[[ Unit checks for menuutil (no LÖVE). ]]

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

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
