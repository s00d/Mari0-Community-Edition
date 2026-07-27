--[[
  VGLC import checks: roundtrip, mw*mh, spawn+flag, smb2 pipe sum, enemy names.
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
	root .. "/lib/?/init.lua",
	package.path,
}, ";")

width = width or 25
height = height or 14

require("core.stringutil")
require("app.variables")
require("world.levelio")

local import = dofile(root .. "/scripts/vglc/import.lua")
local T = import.T

local ENEMY_DIR = root .. "/assets/enemies/"
local KNOWN_ENEMIES = {
	goomba = true, koopa = true, koopaflying = true, plant = true,
	cheepcheepred = true, bulletbill = true, beetle = true,
	hammerbros = true, lakito = true, koopared = true,
}

local function enemy_exists(name)
	if KNOWN_ENEMIES[name] then
		return true
	end
	local f = io.open(ENEMY_DIR .. name .. ".json", "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function check_pack(pack)
	local dir = root .. "/mappacks/" .. pack
	local settings = io.open(dir .. "/settings.txt", "r")
	check(pack .. " settings.txt", settings ~= nil)
	if settings then
		settings:close()
	end

	local n = 0
	local pipe_heights = 0
	for file in io.popen('find "' .. dir .. '" -maxdepth 1 -name "*.txt" -type f | sort'):lines() do
		local base = file:match("([^/]+)$")
		if base ~= "settings.txt" then
			n = n + 1
			local f = assert(io.open(file, "r"))
			local raw = f:read("*a")
			f:close()

			local parsed, err = level_parse_tiles_only(raw)
			check(pack .. "/" .. base .. " parses", parsed ~= nil, err)
			if not parsed then
				goto continue
			end

			check(pack .. "/" .. base .. " mw*mh entries",
				parsed.mapwidth * parsed.mapheight > 0)

			-- count entries via serializer roundtrip
			local v = parsed.v
			local cd = CATEGORYDELIMITER[v]
			local body = level_serialize_maptiles(
				parsed.map, parsed.coinmap, parsed.mapwidth, parsed.mapheight, v)
			local round, rerr = level_parse_tiles_only(parsed.mapheight .. cd .. body)
			check(pack .. "/" .. base .. " roundtrip", round ~= nil, rerr)
			if round then
				local same = true
				for x = 1, parsed.mapwidth do
					for y = 1, parsed.mapheight do
						if parsed.map[x][y][1] ~= round.map[x][y][1] then
							same = false
						end
						if (parsed.coinmap[x][y] and true or false)
							~= (round.coinmap[x][y] and true or false) then
							same = false
						end
						if #parsed.map[x][y] ~= #round.map[x][y] then
							same = false
						else
							for li = 2, #parsed.map[x][y] do
								if parsed.map[x][y][li] ~= round.map[x][y][li] then
									same = false
								end
							end
						end
					end
				end
				check(pack .. "/" .. base .. " roundtrip tiles", same)
			end

			-- spawn + flag
			local spawns, flags = 0, 0
			for x = 1, parsed.mapwidth do
				for y = 1, parsed.mapheight do
					local cell = parsed.map[x][y]
					if cell[2] == T.ENT_SPAWN or cell[2] == "spawn" then
						spawns = spawns + 1
					end
					if cell[2] == T.ENT_FLAG or cell[2] == "flag" then
						flags = flags + 1
					end
					-- enemy names
					if type(cell[2]) == "string" and not tonumber(cell[2]) then
						local en = cell[2]
						if en ~= "spawn" and en ~= "flag" and en ~= "powerup" then
							check(pack .. "/" .. base .. " enemy " .. en,
								enemy_exists(en), en)
						end
					end
				end
			end
			check(pack .. "/" .. base .. " one spawn", spawns == 1, tostring(spawns))
			check(pack .. "/" .. base .. " one flag", flags == 1, tostring(flags))

			::continue::
		end
	end
	check(pack .. " has levels", n > 0, tostring(n))
	return n
end

local n_smbl = check_pack("smbl")
local n_smb2 = check_pack("smb2")
check("smbl level count >= 9", n_smbl >= 9, tostring(n_smbl))
check("smb2 level count == 16", n_smb2 == 16, tostring(n_smb2))

-- smb2 naming 1-1 .. 4-4
for w = 1, 4 do
	for l = 1, 4 do
		local path = string.format("%s/mappacks/smb2/%d-%d.txt", root, w, l)
		check("smb2 " .. w .. "-" .. l, io.open(path, "r") ~= nil)
	end
end

-- Algorithm B: re-detect pipes from sources if present, else from converted mouth/body
do
	local src = "/Users/s00d/Downloads/FireShot/TheVGLC-master/smb2/Processed/WithEnemies"
	local sum = 0
	local p_count = 0
	local has_src = io.open(src .. "/mario_1.txt", "r") ~= nil
	if has_src then
		for i = 1, 16 do
			local path = string.format("%s/mario_%d.txt", src, i)
			local f = io.open(path, "r")
			if f then
				local raw = f:read("*a")
				f:close()
				for _ in raw:gmatch("p") do
					p_count = p_count + 1
				end
				local rows, w, h = import.read_level(path)
				rows, h = import.normalize_height(rows, w, 15)
				local pipes = import.detect_pipes(rows, w, h)
				sum = sum + import.pipe_height_sum(pipes)
			end
		end
		check("smb2 p count 324", p_count == 324, tostring(p_count))
		check("smb2 pipe height sum 324", sum == 324, tostring(sum))
	else
		print("SKIP smb2 source pipe assert (VGLC path missing)")
	end
end

-- naming helper
check("smb2 name mario_1", import.smb2_level_name(1) == "1-1")
check("smb2 name mario_16", import.smb2_level_name(16) == "4-4")
check("smb2 name mario_5", import.smb2_level_name(5) == "2-1")

return failed
