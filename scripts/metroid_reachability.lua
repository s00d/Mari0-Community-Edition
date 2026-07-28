#!/usr/bin/env lua
-- Check reachability for each metroidfault level (rooms/<level>.json), or a single rooms.json.
local pack = arg[1] or "mappacks/metroidfault"
local root = "."
local info = debug.getinfo(1, "S").source
if info:sub(1, 1) == "@" then root = info:sub(2):match("^(.*)/scripts/") or "." end
package.path = table.concat({
	root .. "/build/?.lua", root .. "/build/?/init.lua",
	root .. "/lib/?.lua", root .. "/lib/?/init.lua", package.path
}, ";")
globools = {}; globints = {}
function globoolSH(id, para)
	local k = tostring(id)
	if para == "true" then globools[k] = true elseif para == "false" then globools[k] = false end
	return globools[k] or false
end
function tilekey(x, y) return math.floor(x) * 65536 + math.floor(y) end
JSON = require("dkjson")
require("world.abilities"); require("world.roomcam"); require("world.reachability")

local base = pack
if not base:match("/") then base = "mappacks/" .. pack end
local rooms_dir = root .. "/" .. base .. "/rooms"
local failed = 0

local function check_one(label, body)
	rooms_set(rooms_parse_json(JSON.decode(body)))
	local errs = world_reachability_check()
	if #errs == 0 then
		print("OK", label, #ROOMS, "rooms")
	else
		failed = failed + 1
		print("FAIL", label)
		for _, e in ipairs(errs) do print("  ERR", e) end
	end
end

local checked = 0
local p = io.popen('ls "' .. rooms_dir .. '"/*.json 2>/dev/null')
if p then
	for path in p:lines() do
		local f = io.open(path, "r")
		if f then
			local body = f:read("*a"); f:close()
			local name = path:match("([^/]+)%.json$") or path
			check_one(name, body)
			checked = checked + 1
		end
	end
	p:close()
end

if checked == 0 then
	local jf = io.open(root .. "/" .. base .. "/rooms.json", "r")
	if not jf then
		io.stderr:write("no rooms\n"); os.exit(2)
	end
	local body = jf:read("*a"); jf:close()
	check_one("rooms.json", body)
	checked = 1
end

print(checked, "level(s) checked,", failed, "failed")
os.exit(failed > 0 and 1 or 0)
