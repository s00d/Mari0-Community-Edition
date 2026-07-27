--[[
  Strict portal regression scenarios (no LÖVE).
  Covers platform-under-ceiling, same-tile pairs, pipe exits, physics order, edge velocities.
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

local function almost(a, b, eps)
	eps = eps or 1e-6
	return math.abs(a - b) < eps
end

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	package.path,
}, ";")

require("core.maputil")
require("util.portalutil")
require("physics.portal")

yacceleration = 80
gdt = 1 / 60

local W, H = 12 / 16, 12 / 16

local function mario(x, y, speedy, speedx)
	return {
		mask = {},
		x = x,
		y = y,
		width = W,
		height = H,
		speedx = speedx or 0,
		speedy = speedy or 0,
		rotation = 0,
		animationdirection = (speedx or 0) < 0 and "left" or "right",
		jumping = true,
		falling = false,
	}
end

function checkrect()
	return {}
end

local function center_y(self)
	return self.y + self.height / 2
end

-- One physics frame: portal sweep (VER then HOR), move, inportal, gravity half-step.
local function physics_frame(self, dt)
	dt = dt or 1 / 60
	local passed = false
	if not checkportalVER(self, self.x + self.speedx * dt) then
		if checkportalHOR(self, self.y + self.speedy * dt) then
			passed = true
		end
	else
		passed = true
	end
	if not passed then
		self.y = self.y + self.speedy * dt
		self.x = self.x + self.speedx * dt
	end
	inportal(self)
	self.speedy = self.speedy + yacceleration * dt * 0.5
	return passed
end

local function simulate(self, frames, dt)
	local teleports = 0
	for _ = 1, frames do
		if physics_frame(self, dt) then
			teleports = teleports + 1
		end
	end
	return teleports
end

-- Scenario A: down portal on platform ceiling (5,7) -> floor up (2,12)
do
	portals = {
		{ x1 = 2, y1 = 12, facing1 = "up", x2 = 5, y2 = 7, facing2 = "down" },
	}

	-- Must not snap before down detection plane (center < portalY+1).
	for _, startY in ipairs({ 6.0, 6.5, 7.0, 7.5, 8.0, 8.4 }) do
		local self = mario(4.2, startY, -6)
		local ybefore = self.y
		inportal(self)
		check(
			"A no pre-plane inportal y=" .. startY,
			self.y == ybefore,
			"y=" .. self.y
		)
	end

	-- At plane: exit at linked floor portal, not platform top (~7).
	do
		local self = mario(4.2, 7.625, -6)
		inportal(self)
		local cy = center_y(self)
		check("A exits linked floor y", cy > 10, "cy=" .. cy)
		check("A not platform top", cy > 8.5, "cy=" .. cy)
		check("A near exit X", almost(self.x + W / 2, 2 + W / 2, 0.5), "x=" .. self.x)
	end

	-- Full jump from under platform (y>7): one teleport, floor exit.
	do
		local self = mario(4.2, 8.2, -8)
		local count = 0
		for _ = 1, 30 do
			if physics_frame(self) then
				count = count + 1
			end
			if center_y(self) > 10 then
				break
			end
		end
		check("A jump sim single teleport", count == 1, "count=" .. count)
		check("A jump sim floor exit", center_y(self) > 10, "cy=" .. center_y(self))
		check("A jump sim not stuck on platform", self.y > 9.5, "y=" .. self.y)
	end
end

-- Scenario B: up+down on same tile (5,7)
do
	portals = {
		{ x1 = 5, y1 = 7, facing1 = "up", x2 = 5, y2 = 7, facing2 = "down" },
	}

	-- Rising from below: must not use up entry early.
	do
		local self = mario(4.2, 5.5, -6)
		local ybefore = self.y
		inportal(self)
		check("B rising no early up snap", self.y == ybefore)
	end

	-- Falling from above: must not use down entry.
	do
		local self = mario(4.2, 5.5, 6)
		local ybefore = self.y
		inportal(self)
		check("B falling no early down snap", self.y == ybefore)
	end

	-- Rising through down plane: same-tile exit above platform, not stuck at y=6.9.
	do
		local self = mario(4.2, 7.625, -6)
		inportal(self)
		local cy = center_y(self)
		check("B down entry fires at plane", cy < 8, "cy=" .. cy)
		check("B same-tile not stuck below", self.y < 7.5, "y=" .. self.y)
	end

	-- Falling through up plane: up entry (cross plane y-1 while falling).
	do
		local self = mario(4.2, 5.6, 6)
		local saw
		self.portaled = function(_, face)
			saw = face
		end
		local ok = checkportalHOR(self, self.y + self.speedy / 60)
		check("B fall uses up entry HOR", ok == true)
		check("B fall exit facing down", saw == "down")
	end
end

-- Scenario C: horizontal pipe exits (correct side of linked portal)
local function hor_teleport_test(name, facing1, facing2, entryX, exitX, startX, speedx, expectMinX, expectMaxX)
	portals = {
		{ x1 = entryX, y1 = 8, facing1 = facing1, x2 = exitX, y2 = 8, facing2 = facing2 },
	}
	local self = mario(startX, 7.2, 0, speedx)
	local nextX = self.x + (speedx < 0 and -2 or 2)
	local ok = checkportalVER(self, nextX)
	check(name .. " teleports", ok == true)
	if ok then
		check(name .. " exit X range", self.x >= expectMinX and self.x <= expectMaxX, "x=" .. self.x)
	end
end

hor_teleport_test("C L->R", "right", "left", 5, 15, 5.2, -4, 13, 16)
hor_teleport_test("C R->L", "left", "right", 15, 5, 13, 4, 3, 7)
hor_teleport_test("C L->L flip", "right", "right", 5, 15, 5.2, -4, 13, 16)
hor_teleport_test("C R->R flip", "left", "left", 15, 5, 13, 4, 3, 7)

-- portalcoords: horizontal exit must preserve side relative to exit portal facing.
do
	local nx, ny, sx = portalcoords(
		5.2, 7.2, -4, 0, W, H, 0, "left",
		5, 8, "right",
		15, 8, "left",
		nil, false
	)
	check("C coords L->R exit left of exit portal", nx + W / 2 < 15, "cx=" .. (nx + W / 2))
	check("C coords L->R speed preserved", sx == -4)
end

do
	local nx, ny, sx = portalcoords(
		14.8, 7.2, 4, 0, W, H, 0, "right",
		15, 8, "left",
		5, 8, "right",
		nil, false
	)
	check("C coords R->L exit right of exit portal", nx + W / 2 > 5, "cx=" .. (nx + W / 2))
	check("C coords R->L speed preserved", sx == 4)
end

-- Scenario D: checkportalHOR vs inportal order — only one teleport per frame.
do
	portals = {
		{ x1 = 2, y1 = 12, facing1 = "up", x2 = 5, y2 = 7, facing2 = "down" },
	}
	local self = mario(4.2, 7.625, -10)
	local horCount, inportalMoved = 0, false
	local ybefore = self.y
	local nextY = self.y + self.speedy / 60
	if checkportalHOR(self, nextY) then
		horCount = horCount + 1
	end
	local ymid = self.y
	inportal(self)
	if self.y ~= ymid then
		inportalMoved = true
	end
	check("D HOR or inportal not both", not (horCount > 0 and inportalMoved))
	check("D at least one path teleports", horCount > 0 or self.y ~= ybefore)
end

-- Scenario E: edge velocities + multiple pairs (goto continue)
do
	portals = {
		{ x1 = 5, y1 = 7, facing1 = "up", x2 = 5, y2 = 7, facing2 = "down" },
		{ x1 = 2, y1 = 12, facing1 = "up", x2 = 8, y2 = 7, facing2 = "down" },
	}

	-- Wrong velocity for first pair, second pair should still work at plane.
	do
		local self = mario(7.2, 7.625, 6) -- falling: first pair wants up, second wants down
		local ybefore = self.y
		inportal(self)
		check("E velocity mismatch skips wrong pair", self.y == ybefore)
	end

	do
		local self = mario(7.2, 7.625, -6) -- rising into second pair down portal
		inportal(self)
		check("E second pair linked exit", center_y(self) > 10, "cy=" .. center_y(self))
	end

	-- Barely crossing plane vs deep inside: exit tracks depth.
	do
		local _, nyShallow = portalcoords(4.2, 7.625, 0, -6, W, H, 0, "right", 5, 7, "down", 2, 12, "up", nil, true)
		local _, nyDeep = portalcoords(4.2, 8.5, 0, -6, W, H, 0, "right", 5, 7, "down", 2, 12, "up", nil, true)
		local cyShallow = nyShallow + H / 2
		local cyDeep = nyDeep + H / 2
		check("E shallow deeper than deep exit", cyShallow > cyDeep, string.format("%.3f vs %.3f", cyShallow, cyDeep))
	end
end

-- inportal must not handle horizontal portals (checkportalVER owns them).
do
	portals = {
		{ x1 = 5, y1 = 8, facing1 = "right", x2 = 15, y2 = 8, facing2 = "left" },
	}
	local self = mario(5.2, 7.2, 0, -4)
	local ybefore = self.y
	inportal(self)
	check("C inportal ignores horizontal", self.y == ybefore and self.x == 5.2)
end

return failed
