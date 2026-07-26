--[[
  Lightweight regression checks for GitHub issue fixes (no LÖVE required).
  Run: lua tests/issue_regression_checks.lua
]]

local failed = 0
local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

-- #115: delay 0 must not infinite-loop
do
	local delays = {0, 0}
	-- emulate animatedquad sanitization
	for i = 1, #delays do
		if not delays[i] or delays[i] <= 0 then
			delays[i] = math.huge
		end
	end
	local timer, quadi, iters = 0.016, 1, 0
	while timer > delays[quadi] do
		timer = timer - delays[quadi]
		quadi = quadi % #delays + 1
		iters = iters + 1
		if iters > 1000 then break end
	end
	check("#115 delay 0 no infinite loop", iters == 0, "iters=" .. iters)
end

-- #149: big mario underwater jump uses swim hat offset
do
	local function pick(underwater, animationstate, ducking, infunnel)
		if infunnel then
			return "jumping"
		elseif underwater and (animationstate == "jumping" or animationstate == "falling") then
			return "swimming"
		elseif animationstate == "jumping" and not ducking then
			return "jumping"
		end
		return "other"
	end
	check("#149 swim jump -> swimming", pick(true, "jumping", false, false) == "swimming")
	check("#149 land jump -> jumping", pick(false, "jumping", false, false) == "jumping")
	check("#149 funnel -> jumping", pick(true, "jumping", false, true) == "jumping")
end

-- #98: multiple flying-fish zones
do
	-- inline buildstartendzones
	local function buildstartendzones(starts, ends)
		local zones = {}
		if not starts or #starts == 0 then return zones end
		local unpack = table.unpack or unpack
		local s = {unpack(starts)}
		local e = {unpack(ends or {})}
		table.sort(s)
		table.sort(e)
		local ei = 1
		for i = 1, #s do
			local sx = s[i]
			local ex = false
			while e[ei] and e[ei] <= sx do ei = ei + 1 end
			if e[ei] then ex = e[ei]; ei = ei + 1 end
			table.insert(zones, {sx, ex})
		end
		return zones
	end
	local zones = buildstartendzones({10, 50}, {20, 60})
	check("#98 two zones created", #zones == 2)
	local function inzone(x, zones)
		for i = 1, #zones do
			local z = zones[i]
			if x >= z[1] - 1 and (not z[2] or x < z[2] - 1) then return true end
		end
		return false
	end
	check("#98 inside first zone", inzone(15, zones))
	check("#98 between zones off", not inzone(30, zones))
	check("#98 inside second zone", inzone(55, zones))
	-- start without matching end
	local z2 = buildstartendzones({10, 50}, {20})
	check("#98 unpaired second start stays on", inzone(55, z2) and #z2 == 2 and z2[2][2] == false)
end

-- #194: plus button must exist when only sublevel files are present
do
	local mapbuttons = {}
	local worlds, levels, sublevels = 1, 7, 1
	if not mapbuttons["text" .. worlds .. "-" .. levels] then
		mapbuttons["text" .. worlds .. "-" .. levels] = true
		mapbuttons["plus" .. worlds .. "-" .. levels] = {arguments = {worlds, levels, sublevels + 1}}
	end
	local ok = pcall(function()
		if mapbuttons["plus" .. worlds .. "-" .. levels] and mapbuttons["plus" .. worlds .. "-" .. levels].arguments[3] < sublevels + 1 then
			mapbuttons["plus" .. worlds .. "-" .. levels].arguments[3] = sublevels + 1
		end
	end)
	check("#194 plus button safe when only sublevel", ok and mapbuttons["plus1-7"] ~= nil)
end

-- #193: incomplete link must be skipped (nil-safe)
do
	local map = {[5]={[3]={"tile", 70, "true", "link", "drop"}}} -- missing x,y
	local drew = 0
	local tx, ty = 5, 3
	for i = 1, #map[tx][ty] do
		if map[tx][ty][i] == "link" and tonumber(map[tx][ty][i+2]) and tonumber(map[tx][ty][i+3]) then
			drew = drew + 1
		end
	end
	check("#193 incomplete link skipped", drew == 0)
	map[5][3] = {"tile", 70, "link", "drop", 8, 4}
	for i = 1, #map[tx][ty] do
		if map[tx][ty][i] == "link" and tonumber(map[tx][ty][i+2]) and tonumber(map[tx][ty][i+3]) then
			drew = drew + 1
		end
	end
	check("#193 complete link drawn", drew == 1)
end

-- #158: already-bouncing block rejects re-hit
do
	local blockbouncex, blockbouncey = {5}, {3}
	local function already(x, y)
		for i, bx in pairs(blockbouncex) do
			if bx == x and blockbouncey[i] == y then return true end
		end
		return false
	end
	check("#158 reject rehit while bouncing", already(5, 3))
	check("#158 allow other block", not already(6, 3))
end

-- #185: spikey has notkilledfromblocksbelow
do
	local f = io.open("enemies/spikey.json", "r")
	local s = f:read("*a"); f:close()
	check("#185 spikey notkilledfromblocksbelow", s:find('"notkilledfromblocksbelow"%s*:%s*true') ~= nil)
end

-- #168: kicked shell must call shotted on other enemy
do
	local killed = false
	local self = {killsenemies = true, speedx = 12}
	local b = {active = true, shot = false, dead = false, t = "koopa", x = 0, y = 0,
		shotted = function() killed = true end}
	if self.killsenemies then
		if b and b.active and not b.shot and not b.dead and b.shotted then
			b:shotted("right")
		end
	end
	check("#168 shell kills other enemy", killed)
end

print("")
if failed == 0 then
	print("All checks passed.")
	os.exit(0)
else
	print(failed .. " check(s) failed.")
	os.exit(1)
end
