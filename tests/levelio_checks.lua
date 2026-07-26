--[[
  Level IO contract checks (no LÖVE): filenames, delimiters, parse/serialize roundtrip,
  and real mappacks/smb/1-1.txt tile smoke.
]]

local root = ... or "."
local failed = 0

-- variables.lua references screen width/height at load time
width = width or 25
height = height or 14

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

dofile(root .. "/stringutil.lua")
dofile(root .. "/variables.lua")
dofile(root .. "/levelio.lua")

check("loadmap exists", type(loadmap) == "function")
check("savemap exists", type(savemap) == "function")
check("renderpreview exists", type(renderpreview) == "function")
check("savelevel exists", type(savelevel) == "function")
check("level_parse_tiles_only exists", type(level_parse_tiles_only) == "function")
check("level_serialize_maptiles exists", type(level_serialize_maptiles) == "function")

check("filename 1-1", level_filename(1, 1, 0) == "1-1")
check("filename 1-1 sub0 nil", level_filename(1, 1) == "1-1")
check("filename 1-1_2", level_filename(1, 1, 2) == "1-1_2")
check("filename world M", level_filename("M", 1, 0) == "M-1")

-- v1 fixture: height; RLE tiles; one layered cell; options with 0-255 colors
do
	local v = 1
	local bd, ld, cd, md, eq = level_delimiters(v)
	-- 3x3 grid (column-major): seven 1s, coin-2, layered 5×99 last
	-- (layered-last avoids a legacy savemap empty-token when a simple tile follows a layer cell)
	local fixture = table.concat({
		"3",
		"1" .. md .. "7" .. bd .. "2c" .. bd .. "5" .. ld .. "99",
		"backgroundr" .. eq .. "92",
		"backgroundg" .. eq .. "148",
		"backgroundb" .. eq .. "252",
		"timelimit" .. eq .. "400",
	}, cd)

	check("detect v1", level_detect_format_version(fixture) == 1)

	local parsed, err = level_parse_tiles_only(fixture)
	check("parse fixture ok", parsed ~= nil, err)
	if parsed then
		check("fixture width", parsed.mapwidth == 3, tostring(parsed.mapwidth))
		check("fixture height", parsed.mapheight == 3, tostring(parsed.mapheight))
		check("fixture [1,1]=1", parsed.map[1][1][1] == 1)
		check("fixture [1,3]=1", parsed.map[1][3][1] == 1)
		check("fixture [2,3] coin", parsed.coinmap[2][3] == true)
		check("fixture [2,3]=2", parsed.map[2][3][1] == 2)
		check("fixture [3,3] layered", parsed.map[3][3][1] == 5 and parsed.map[3][3][2] == 99)

		local body = level_serialize_maptiles(parsed.map, parsed.coinmap, parsed.mapwidth, parsed.mapheight, v)
		local round = level_parse_tiles_only(parsed.mapheight .. cd .. body)
		check("roundtrip ok", round ~= nil)
		if round then
			local same = true
			for y = 1, 3 do
				for x = 1, 3 do
					if round.map[x][y][1] ~= parsed.map[x][y][1] then
						same = false
					end
					if (round.coinmap[x][y] and true or false) ~= (parsed.coinmap[x][y] and true or false) then
						same = false
					end
					if #(round.map[x][y]) ~= #(parsed.map[x][y]) then
						same = false
					elseif #(parsed.map[x][y]) > 1 then
						for i = 2, #parsed.map[x][y] do
							if round.map[x][y][i] ~= parsed.map[x][y][i] then
								same = false
							end
						end
					end
				end
			end
			check("roundtrip tiles match", same)
		end
	end
end

-- v2 ASCII delimiters
do
	local fixture = "2;1*3,3c;timelimit=100"
	check("detect v2", level_detect_format_version(fixture) == 2)
	local parsed, err = level_parse_tiles_only(fixture)
	check("parse v2 ok", parsed ~= nil, err)
	if parsed then
		check("v2 size 2x2", parsed.mapwidth == 2 and parsed.mapheight == 2,
			tostring(parsed.mapwidth) .. "x" .. tostring(parsed.mapheight))
		check("v2 coin", parsed.coinmap[2][2] == true)
		check("v2 last tile", parsed.map[2][2][1] == 3)
	end
end

-- Real smb/1-1.txt
do
	local path = root .. "/mappacks/smb/1-1.txt"
	local f = io.open(path, "r")
	check("smb/1-1.txt readable", f ~= nil, path)
	if f then
		local s = f:read("*a")
		f:close()
		check("smb/1-1 detect v1", level_detect_format_version(s) == 1)
		local parsed, err = level_parse_tiles_only(s)
		check("smb/1-1 parse ok", parsed ~= nil, err)
		if parsed then
			check("smb/1-1 height 15", parsed.mapheight == 15, tostring(parsed.mapheight))
			check("smb/1-1 width > 0", parsed.mapwidth > 0, tostring(parsed.mapwidth))
			check("smb/1-1 entries", parsed.mapwidth * parsed.mapheight > 0)
			-- Spot-check: file starts with RLE of tile 1
			check("smb/1-1 [1,1] tile", type(parsed.map[1][1][1]) == "number" and parsed.map[1][1][1] >= 1)
			-- Options still on disk as 0-255 channel keys
			local has_bg = false
			for i = 3, #parsed.categories do
				local key = parsed.categories[i]:split(parsed.equalsign)[1]
				if key == "backgroundr" or key == "backgroundg" or key == "backgroundb" then
					has_bg = true
					local val = tonumber(parsed.categories[i]:split(parsed.equalsign)[2])
					check("smb/1-1 " .. key .. " 0-255", val ~= nil and val >= 0 and val <= 255, tostring(val))
				end
			end
			check("smb/1-1 has background channels", has_bg)
		end
	end
end

-- game.lua must not redefine moved APIs
do
	local f = io.open(root .. "/game.lua", "r")
	local body = f and f:read("*a") or ""
	if f then f:close() end
	check("game.lua no function loadmap", not body:find("function loadmap%s*%("))
	check("game.lua no function savemap", not body:find("function savemap%s*%("))
	check("game.lua no function savelevel", not body:find("function savelevel%s*%("))
	check("game.lua no function renderpreview", not body:find("function renderpreview%s*%("))
	local mainf = io.open(root .. "/main.lua", "r")
	local main = mainf and mainf:read("*a") or ""
	if mainf then mainf:close() end
	check("main requires levelio", main:find('require%s+"levelio"') ~= nil)
	check("main keeps early stringutil", main:find('require%s+"stringutil"') ~= nil)
end

return failed
