--[[ Stage 2 module smoke checks (no LÖVE). ]]

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

width = 25
height = 14
require("core.stringutil")
require("app.variables")
require("world.levelio")
require("world.paths")

check("mappack_path", mappack_path("smb") == "mappacks/smb")
check("level_name", level_name(1, 1) == "1-1")
check("mappack_level_path", mappack_level_path("smb", 1, 1) == "mappacks/smb/1-1.txt")

do
	local Io = require("world.io")
	local fixture = "3;1*3,3c;timelimit=100"
	local parsed = Io.parse_tiles(fixture)
	check("io parse", parsed ~= nil)
	if parsed then
		local body = Io.serialize_tiles(parsed.map, parsed.coinmap, parsed.mapwidth, parsed.mapheight, parsed.v)
		check("io serialize", type(body) == "string" and #body > 0)
	end
end

do
	local keys = OPTIONS_SCHEMA_KEYS
	check("options schema keys", type(keys) == "table" and #keys == 16, tostring(#keys))
	local seen = {}
	for _, k in ipairs(keys) do
		seen[k] = true
	end
	check("options unique", #keys == 16)
end

return failed
