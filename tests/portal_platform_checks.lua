--[[
  Portal regression scenarios aligned with original Mari0 portal math (7058e92).
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

-- Scenario A: down portal on platform ceiling (5,7) -> floor up (2,12)
do
	portals = {
		{ x1 = 2, y1 = 12, facing1 = "up", x2 = 5, y2 = 7, facing2 = "down" },
	}

	-- Below platform (outside down-portal entry band): no inportal snap.
	for _, startY in ipairs({ 7.0, 8.0, 8.5 }) do
		local self = mario(4.2, startY, -6)
		local ybefore = self.y
		inportal(self)
		check("A no inportal snap y=" .. startY, self.y == ybefore, "y=" .. self.y)
	end

	-- Same tile up+down: rising inportal must use down entry (not up->down onto platform).
	do
		portals = {
			{ x1 = 5, y1 = 7, facing1 = "up", x2 = 5, y2 = 7, facing2 = "down" },
		}
		local self = mario(4.2, 6.625, -6)
		inportal(self)
		check("A same-tile rising down entry not up->down", self.y < 6.8, "y=" .. self.y)
		portals = {
			{ x1 = 2, y1 = 12, facing1 = "up", x2 = 5, y2 = 7, facing2 = "down" },
		}
	end

	-- Rising jump: checkportalHOR sweep crosses down portal plane and exits at floor.
	do
		local self = mario(4.2, 7.5, -12)
		local teleported = false
		for _ = 1, 30 do
			local nextY = self.y + self.speedy / 60
			if checkportalHOR(self, nextY) then
				teleported = true
				break
			end
			self.y = nextY
			self.speedy = self.speedy + yacceleration / 60 * 0.5
		end
		check("A HOR sweep teleports", teleported)
		check("A HOR sweep floor exit", center_y(self) > 10, "cy=" .. center_y(self))
	end
end

-- Scenario B: up+down on same tile (5,7) — direction gating via checkportalHOR
do
	portals = {
		{ x1 = 5, y1 = 7, facing1 = "up", x2 = 5, y2 = 7, facing2 = "down" },
	}

	do
		local self = mario(4.2, 5.5, -6)
		local ybefore = self.y
		inportal(self)
		check("B rising no inportal snap", self.y == ybefore)
	end

	do
		local self = mario(4.2, 5.5, 6)
		local ybefore = self.y
		inportal(self)
		check("B falling no inportal snap", self.y == ybefore)
	end

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

	do
		local self = mario(4.2, 7.0, -6)
		local saw
		self.portaled = function(_, face)
			saw = face
		end
		local ok = checkportalHOR(self, self.y - 1)
		check("B rise uses down entry HOR", ok == true)
		check("B rise exit facing up", saw == "up")
	end
end

-- Scenario C: horizontal pipe exits (correct side only)
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

-- Wrong approach direction must not teleport
do
	portals = {
		{ x1 = 5, y1 = 8, facing1 = "right", x2 = 15, y2 = 8, facing2 = "left" },
	}
	local self = mario(4.0, 7.2, 0, 4)
	local xbefore = self.x
	check("C reject wrong direction", checkportalVER(self, self.x + 2) == false)
	check("C no move on reject", self.x == xbefore)
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
