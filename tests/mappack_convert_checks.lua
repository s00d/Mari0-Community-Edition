--[[
  Mappack 1.6→CE convert checks (no LÖVE):
  1. Round-trip convert_level_text → decode → serialize
  2. Dimension mapwidth*15
  3. Pack invariants when converted dlc_* present
  4. Remap coverage: unhandled count 0
  5. version.txt not in converted output
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

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	package.path,
}, ";")

width = width or 25
height = height or 14

require("core.stringutil")
require("core.tableutil")
require("app.variables")
require("world.levelio")
require("world.entity_remap")
require("world.mappack_convert")

-- 1) Round-trip: minimal 1.6 level (25×15 empty-ish with spawn+flag)
do
	local cells = {}
	for y = 1, 15 do
		for x = 1, 25 do
			local t = "1"
			if x == 2 and y == 13 then
				t = "1-8" -- spawn
			elseif x == 24 and y == 13 then
				t = "1-11" -- flag
			elseif y == 15 then
				t = "2" -- ground-ish
			end
			table.insert(cells, t)
		end
	end
	-- 1.6 is column-major? loadmapold: x increments first, wrap to y — so order is row-major by columns... 
	-- Looking at loadmapold: starts x=0,y=1; for each cell x++; if x==mapwidth+1 then x=1,y++
	-- So cells are listed column-major? Actually first mapwidth cells are y=1,x=1..mapwidth — ROW of y=1.
	-- Wait: x goes 1..mapwidth for fixed y, then y++. That's row-major (x fastest).
	-- But mapsplit is flat list of mapwidth*15 — first mapwidth entries are y=1.
	-- Our nested loop above is for y, for x — same row-major. Good.
	-- Actually I nested for y for x and insert — that's row-major. Good.

	-- Rebuild properly as flat row-major matching loadmapold:
	cells = {}
	for y = 1, 15 do
		for x = 1, 25 do
			local t = "1"
			if x == 2 and y == 13 then t = "1-8"
			elseif x == 24 and y == 13 then t = "1-11"
			elseif y == 15 then t = "2"
			end
			table.insert(cells, t)
		end
	end

	local raw = table.concat(cells, ",") .. ";background=1;spriteset=1;music=2;timelimit=400"
	local out, err = convert_level_text(raw, {strict = true})
	check("convert_level_text ok", out ~= nil, err)
	if out then
		local parsed, perr = level_parse_tiles_only(out)
		check("decode converted", parsed ~= nil, perr)
		if parsed then
			check("height 15", parsed.mapheight == 15, tostring(parsed.mapheight))
			check("width 25", parsed.mapwidth == 25, tostring(parsed.mapwidth))
			check("cells == w*15", parsed.mapwidth * parsed.mapheight == 25 * 15)
			local spawn = parsed.map[2][13]
			check("spawn remapped", spawn and spawn[2] == 8, tostring(spawn and spawn[2]))
			local flag = parsed.map[24][13]
			check("flag pass-through", flag and flag[2] == 11, tostring(flag and flag[2]))

			local body = level_serialize_maptiles(parsed.map, parsed.coinmap, parsed.mapwidth, parsed.mapheight, 1)
			local again = level_parse_tiles_only(parsed.mapheight .. CATEGORYDELIMITER[1] .. body)
			check("serialize roundtrip", again ~= nil)
			if again then
				check("roundtrip spawn", again.map[2][13][2] == 8)
				check("roundtrip flag", again.map[24][13][2] == 11)
			end
		end
	end
end

-- Height hard-fail
do
	local bad = "1,1,1;background=1" -- 3 cells, not ×15
	local out, err = convert_level_text(bad, {strict = true})
	check("height fail", out == nil and err ~= nil, err)
end

-- Enemy remap smoke
do
	local ent, err = convertentity({6}, {strict = true})
	check("goomba→name", ent[1] == "goomba" and err == nil)
	ent, err = convertentity({15}, {strict = true})
	check("hammerbro→hammerbros", ent[1] == "hammerbros")
	ent, err = convertentity({28, "link", 3, 4}, {strict = true})
	check("door remap", ent[1] == 28 and ent[2] == "ver")
	check("door link open", ent[5] == "link" and ent[6] == "open" and ent[7] == 3 and ent[8] == 4)
	ent, err = convertentity({999}, {strict = true})
	check("unknown strict fail", err ~= nil)
end

-- Remap validation
do
	local problems = validate_remap({
		enemy_json_exists = function(name)
			local f = io.open(root .. "/assets/enemies/" .. name .. ".json", "r")
			if f then f:close() return true end
			return false
		end,
	})
	check("validate_remap clean", #problems == 0, table.concat(problems, "; "))
end

-- Coverage: scan toconvert if present — unhandled must be 0
do
	local function list(dir)
		local t = {}
		local p = io.popen('ls -1 "' .. dir:gsub('"', '\\"') .. '" 2>/dev/null')
		if p then for line in p:lines() do table.insert(t, line) end p:close() end
		return t
	end
	local src = root .. "/toconvert"
	local hole = 0
	local seen = {}
	for _, pack in ipairs(list(src)) do
		for _, fname in ipairs(list(src .. "/" .. pack)) do
			if fname:match("^%d+%-%d+") and fname:match("%.txt$") then
				local f = io.open(src .. "/" .. pack .. "/" .. fname, "r")
				if f then
					local raw = f:read("*a")
					f:close()
					local mapsplit = strsplit(strsplit(raw, ";")[1] or "", ",")
					for _, cell in ipairs(mapsplit) do
						local bits = strsplit(cell, "-")
						if #bits >= 2 and bits[2] ~= "link" then
							local eid = tonumber(bits[2])
							if eid and remap_kind(eid) == "unknown" then
								hole = hole + 1
								seen[eid] = true
							end
						end
					end
				end
			end
		end
	end
	local hole_ids = {}
	for id in pairs(seen) do table.insert(hole_ids, id) end
	table.sort(hole_ids)
	check("toconvert unhandled==0", hole == 0, "count=" .. hole .. " ids=" .. table.concat(hole_ids, ","))
end

-- Converted pack invariants (if mappacks/dlc_* exist)
do
	local function list(dir)
		local t = {}
		local p = io.popen('ls -1 "' .. dir:gsub('"', '\\"') .. '" 2>/dev/null')
		if p then for line in p:lines() do table.insert(t, line) end p:close() end
		return t
	end
	local packs = {}
	for _, name in ipairs(list(root .. "/mappacks")) do
		if name:match("^dlc_") then
			table.insert(packs, name)
		end
	end
	if #packs == 0 then
		print("SKIP pack invariants (no mappacks/dlc_* yet)")
	else
		for _, pack in ipairs(packs) do
			local dir = root .. "/mappacks/" .. pack
			local ver = io.open(dir .. "/version.txt", "r")
			check(pack .. " no version.txt", ver == nil)
			if ver then ver:close() end
			local settings = io.open(dir .. "/settings.txt", "r")
			check(pack .. " has settings.txt", settings ~= nil)
			if settings then settings:close() end

			local levels = 0
			local has_spawn, has_finish = false, false
			for _, fname in ipairs(list(dir)) do
				if fname:match("^%d+%-%d+") and fname:match("%.txt$") then
					levels = levels + 1
					local f = io.open(dir .. "/" .. fname, "r")
					if f then
						local raw = f:read("*a")
						f:close()
						local parsed = level_parse_tiles_only(raw)
						if parsed then
							check(pack .. "/" .. fname .. " w*h", parsed.mapwidth * parsed.mapheight % 15 == 0
								and parsed.mapheight % 15 == 0)
							for x = 1, parsed.mapwidth do
								for y = 1, parsed.mapheight do
									local cell = parsed.map[x][y]
									if cell and cell[2] == 8 then has_spawn = true end
									if cell and (cell[2] == 11 or cell[2] == 91) then has_finish = true end
									if cell and type(cell[2]) == "string" then
										local ej = io.open(root .. "/assets/enemies/" .. cell[2] .. ".json", "r")
										check(pack .. " enemy " .. tostring(cell[2]), ej ~= nil)
										if ej then ej:close() end
									end
								end
							end
						else
							failed = failed + 1
							print("FAIL parse " .. pack .. "/" .. fname)
						end
					end
				end
			end
			check(pack .. " has levels", levels > 0, tostring(levels))
			check(pack .. " has spawn somewhere", has_spawn)
			check(pack .. " has flag/axe somewhere", has_finish)
		end
	end
end

return failed
