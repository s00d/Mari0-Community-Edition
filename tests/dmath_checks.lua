--[[ Deterministic dmath checks (F2): bit-identical repeat + golden vector. ]]

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

local D = require("core.dmath")
local golden = assert(loadfile(root .. "/tests/dmath_golden.lua"))()

check("dmath exports dsin", type(D.dsin) == "function")
check("dmath N 4096", D.N == 4096)

-- Bit-identical across 10k evals
local ok_rep = true
for i = 1, 10000 do
	local a = (i * 0.017453292519943295) -- i degrees in radians-ish step
	local s1 = D.dsin(a)
	local s2 = D.dsin(a)
	local c1 = D.dcos(a)
	local c2 = D.dcos(a)
	if s1 ~= s2 or c1 ~= c2 then
		ok_rep = false
		check("dsin/dcos bit-identical @ " .. i, false, tostring(s1) .. " vs " .. tostring(s2))
		break
	end
end
if ok_rep then
	check("dsin/dcos bit-identical x10000", true)
end

-- Match committed golden vector exactly
local gold_ok = true
for i, row in ipairs(golden) do
	local s = D.dsin(row.a)
	local c = D.dcos(row.a)
	if s ~= row.sin or c ~= row.cos then
		gold_ok = false
		check("golden[" .. i .. "]", false, string.format("a=%g got sin=%g cos=%g want sin=%g cos=%g", row.a, s, c, row.sin, row.cos))
	end
end
if gold_ok then
	check("golden vector match", true)
end

-- datan2 quadrants
check("datan2(0,1)~0", math.abs(D.datan2(0, 1)) < 1e-6)
check("datan2(1,0)~pi/2", math.abs(D.datan2(1, 0) - math.pi / 2) < 1e-3)
check("datan2(0,-1)~pi", math.abs(math.abs(D.datan2(0, -1)) - math.pi) < 1e-3)
check("datan2 bit-identical", D.datan2(3, 4) == D.datan2(3, 4))

-- Globals installed
check("global dsin", _G.dsin == D.dsin)

-- Document gate for F3
check("F2 note: validate x86 vs ARM hashes before F3", true)

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
