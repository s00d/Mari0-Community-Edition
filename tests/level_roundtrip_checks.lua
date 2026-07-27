--[[ Level tile round-trip for every mappacks/smb/*.txt level (no LÖVE). ]]

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
	root .. "/lib/?.lua",
	package.path,
}, ";")

width = width or 25
height = height or 14

require("core.stringutil")
require("app.variables")
require("world.levelio")

local sha1 = require("sha1")

local function tile_fingerprint(parsed)
	local parts = {}
	table.insert(parts, tostring(parsed.mapwidth))
	table.insert(parts, tostring(parsed.mapheight))
	for x = 1, parsed.mapwidth do
		for y = 1, parsed.mapheight do
			local cell = parsed.map[x][y]
			local coin = parsed.coinmap[x][y] and "c" or ""
			local layers = {}
			for i = 1, #cell do
				layers[#layers + 1] = tostring(cell[i])
			end
			table.insert(parts, string.format("%d,%d:%s%s", x, y, table.concat(layers, "+"), coin))
		end
	end
	return sha1(table.concat(parts, "|"))
end

local function tiles_match(a, b)
	if a.mapwidth ~= b.mapwidth or a.mapheight ~= b.mapheight then
		return false
	end
	for x = 1, a.mapwidth do
		for y = 1, a.mapheight do
			if (a.coinmap[x][y] and true or false) ~= (b.coinmap[x][y] and true or false) then
				return false
			end
			if #a.map[x][y] ~= #b.map[x][y] then
				return false
			end
			for i = 1, #a.map[x][y] do
				if a.map[x][y][i] ~= b.map[x][y][i] then
					return false
				end
			end
		end
	end
	return true
end

local level_count = 0
local dir = root .. "/mappacks/smb"
for file in io.popen('find "' .. dir .. '" -maxdepth 1 -name "*.txt" -type f | sort'):lines() do
	local base = file:match("([^/]+)$")
	if base ~= "settings.txt" then
		level_count = level_count + 1
		local f = assert(io.open(file, "r"))
		local raw = f:read("*a")
		f:close()

		local parsed, err = level_parse_tiles_only(raw)
		check(base .. " parses", parsed ~= nil, err)
		if parsed then
			local v = parsed.v
			local cd = CATEGORYDELIMITER[v]
			local body = level_serialize_maptiles(parsed.map, parsed.coinmap, parsed.mapwidth, parsed.mapheight, v)
			local round, rerr = level_parse_tiles_only(parsed.mapheight .. cd .. body)
			check(base .. " roundtrip parse", round ~= nil, rerr)
			if round then
				check(base .. " roundtrip tiles", tiles_match(parsed, round))
				local h1 = tile_fingerprint(parsed)
				local h2 = tile_fingerprint(round)
				check(base .. " roundtrip hash", h1 == h2, h1 .. " vs " .. h2)
			end
		end
	end
end

check("smb level count > 0", level_count > 0, tostring(level_count))
print(string.format("roundtrip levels: %d", level_count))

return failed
