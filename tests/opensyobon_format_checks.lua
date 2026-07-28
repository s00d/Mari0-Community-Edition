--[[
  OpenSyobon stage array parse helpers — synthetic C snippet, no game assets.
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

-- Mirror of build_opensyobon.py tile code classes (documentation lock)
local SOLID = { [1] = true, [2] = true, [4] = true, [5] = true, [6] = true, [7] = true }
local ENEMY_LO, ENEMY_HI = 50, 79

check("solid brick", SOLID[1] == true)
check("solid ground", SOLID[5] == true and SOLID[6] == true)
check("air not solid", SOLID[0] == nil and SOLID[3] == nil)
check("enemy range", ENEMY_LO == 50 and ENEMY_HI == 79)

-- Fake stagedatex row parse (numbers from braces)
local function parse_row(s)
	local nums = {}
	for n in s:gmatch("%d+") do
		nums[#nums + 1] = tonumber(n)
	end
	return nums
end
local row = parse_row("{0, 0, 5, 5, 50, 0, 99}")
check("row len", #row == 7)
check("row ground", row[3] == 5 and row[4] == 5)
check("row enemy", row[5] == 50)
check("row flag", row[7] == 99)

-- Level filename convention
local function level_filename(world, level, sub)
	if sub == 0 then
		return world .. "-" .. level .. ".txt"
	end
	return world .. "-" .. level .. "_" .. sub .. ".txt"
end
check("fn overworld", level_filename(1, 1, 0) == "1-1.txt")
check("fn sub", level_filename(1, 2, 1) == "1-2_1.txt")

-- Pack naming: opensyobon ≠ cavestory
check("pack name distinct", "opensyobon" ~= "cavestory")

return failed
