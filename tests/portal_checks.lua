--[[
  Portal teleport fixtures (no LÖVE). Tests physicsportal.lua pure/fixture branches.
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
	eps = eps or 1e-9
	return math.abs(a - b) < eps
end

require("core.maputil") -- inrange
require("util.portalutil")
require("physics.portal")

yacceleration = 80
gdt = 1 / 60

-- portalcoords: left -> right preserves speed, shifts through exit
do
	local w, h = 12 / 16, 12 / 16
	local x, y = 4, 5
	local nx, ny, sx, sy, rot = portalcoords(
		x, y, 3, 0, w, h, 0, "right",
		5, 5, "left",
		10, 5, "right",
		nil, false
	)
	check("L->R speedx", sx == 3)
	check("L->R speedy", sy == 0)
	check("L->R rotation", rot == 0)
	check("L->R newx finite", type(nx) == "number" and nx == nx)
	check("L->R newy finite", type(ny) == "number" and ny == ny)
end

-- portalcoords: up -> up flips vertical speed + live minspeed
do
	local w, h = 1, 1
	local nx, ny, sx, sy, rot = portalcoords(
		5, 8, 0, 2, w, h, 0, "right",
		5, 10, "up",
		12, 10, "up",
		nil, true
	)
	local minspeed = math.sqrt(2 * yacceleration * h)
	check("U->U speedx", sx == 0)
	check("U->U speedy flipped+minspeed", almost(sy, -minspeed) or sy <= -minspeed)
	check("U->U rotation -pi", almost(rot, -math.pi))
	check("U->U exit near exit portal X", almost(nx + w / 2, (5 + w / 2) + (12 - 5)))
end

-- portalcoords: right -> right flips speedx
do
	local w, h = 1, 1
	local nx, ny, sx, sy = portalcoords(
		3, 4, 5, 1, w, h, 0, "right",
		4, 4, "right",
		9, 4, "right",
		nil, false
	)
	check("R->R speedx flip", sx == -5)
	check("R->R speedy same", sy == 1)
end

-- portalcoords: down -> up (original formula: exitportalY + directrange - 1)
do
	local w, h = 12 / 16, 12 / 16
	local nx, ny = portalcoords(
		4.2, 7.625, 0, -6, w, h, 0, "right",
		5, 7, "down",
		18, 20, "up",
		nil, true
	)
	local centerY = ny + h / 2
	-- directrange = centerY_entry - 7 = 1.0; exit center = 20 + 1 - 1 = 20
	check("D->U exit center at exit portal row", almost(centerY, 20), "centerY=" .. centerY)
end

-- portalcoords: up -> right swaps axes
do
	local w, h = 1, 1
	local nx, ny, sx, sy, rot = portalcoords(
		5, 8, 2, 4, w, h, 0, "right",
		5, 10, "up",
		15, 6, "right",
		nil, false
	)
	check("U->R speed swap", sx == 4 and sy == -2)
	check("U->R rotation -pi/2", almost(rot, -math.pi / 2))
end

-- checkportalHOR: wrong entry facing (left) rejects
do
	portals = {
		{
			x1 = 5, y1 = 8, facing1 = "left",
			x2 = 12, y2 = 8, facing2 = "right",
		},
	}
	local self = {
		x = 4.2, y = 7.5, width = 0.75, height = 0.75,
		speedx = 0, speedy = 3, rotation = 0, animationdirection = "right",
	}
	check("HOR reject left-facing", checkportalHOR(self, self.y + 1) == false)
end

-- checkportalHOR: moving away from up portal rejects (up detection plane y1-1)
do
	portals = {
		{
			x1 = 5, y1 = 8, facing1 = "up",
			x2 = 12, y2 = 8, facing2 = "down",
		},
	}
	local self = {
		x = 4.2, y = 6.5, width = 0.75, height = 0.75,
		speedx = 0, speedy = -3, rotation = 0, animationdirection = "right",
	}
	check("HOR reject up while rising", checkportalHOR(self, self.y - 1) == false)
end

-- checkportalHOR: down portal rejects falling (wrong direction)
do
	portals = {
		{
			x1 = 5, y1 = 7, facing1 = "down",
			x2 = 2, y2 = 12, facing2 = "up",
		},
	}
	local self = {
		x = 4.2, y = 8.0, width = 0.75, height = 0.75,
		speedx = 0, speedy = 4, rotation = 0, animationdirection = "right",
	}
	check("HOR reject down while falling", checkportalHOR(self, self.y + 1) == false)
end

-- checkportalHOR: rising through down portal under platform teleports to linked exit
do
	portals = {
		{
			x1 = 2, y1 = 12, facing1 = "up",
			x2 = 5, y2 = 7, facing2 = "down",
		},
	}
	function checkrect()
		return {}
	end
	local self = {
		x = 4.2, y = 7.0, width = 0.75, height = 0.75,
		speedx = 0, speedy = -5, rotation = 0, animationdirection = "right",
		jumping = true, falling = false,
	}
	local ok = checkportalHOR(self, self.y - 1)
	check("HOR down-under sweep ok", ok == true)
	check("HOR down-under exits at floor portal", self.y + self.height / 2 > 10)
end

-- checkportalVER: wrong entry facing (up) rejects
do
	portals = {
		{
			x1 = 5, y1 = 8, facing1 = "up",
			x2 = 12, y2 = 8, facing2 = "down",
		},
	}
	local self = {
		x = 4.5, y = 7.2, width = 0.75, height = 0.75,
		speedx = 3, speedy = 0, rotation = 0, animationdirection = "right",
	}
	check("VER reject up-facing", checkportalVER(self, self.x + 1) == false)
end

-- checkportalVER: successful right->left teleport when exit clear
do
	portals = {
		{
			x1 = 5, y1 = 8, facing1 = "right",
			x2 = 15, y2 = 8, facing2 = "left",
		},
	}
	function checkrect()
		return {}
	end
	local saw = nil
	local self = {
		x = 5.2, y = 7.2, width = 0.75, height = 0.75,
		speedx = -4, speedy = 0, rotation = 0, animationdirection = "left",
		jumping = true, falling = false,
		portaled = function(s, face)
			saw = face
		end,
	}
	local ok = checkportalVER(self, self.x - 2)
	check("VER teleport ok", ok == true)
	check("VER exit facing callback", saw == "left")
	check("VER cleared jump", self.jumping == false and self.falling == true)
	check("VER moved near exit", self.x > 10)
end

-- checkportalVER: blocked exit flips speedx
do
	portals = {
		{
			x1 = 5, y1 = 8, facing1 = "right",
			x2 = 15, y2 = 8, facing2 = "left",
		},
	}
	function checkrect()
		return {"tile", 1}
	end
	local self = {
		x = 5.2, y = 7.2, width = 0.75, height = 0.75,
		speedx = -4, speedy = 0, rotation = 0, animationdirection = "left",
	}
	local ok = checkportalVER(self, self.x - 2)
	check("VER blocked still true", ok == true)
	check("VER blocked speed flip", self.speedx == 4)
end

-- inportal: mask[2] early out
do
	portals = {
		{x1 = 1, y1 = 1, facing1 = "up", x2 = 2, y2 = 2, facing2 = "down"},
	}
	local self = {mask = {[2] = true}, x = 0, y = 0, width = 1, height = 1}
	check("inportal masked returns nil", inportal(self) == nil)
end

-- inportal: empty portals
do
	portals = {}
	local self = {mask = {}, x = 0, y = 0, width = 1, height = 1}
	check("inportal empty false", inportal(self) == false)
end

-- inportal: near platform from below (outside entry band) does not snap
do
	portals = {
		{
			x1 = 2, y1 = 12, facing1 = "up",
			x2 = 5, y2 = 7, facing2 = "down",
		},
	}
	local w, h = 12 / 16, 12 / 16
	for _, startY in ipairs({ 7.0, 8.0, 8.5 }) do
		local self = {
			mask = {}, x = 4.2, y = startY, width = w, height = h,
			speedx = 0, speedy = -6, rotation = 0, animationdirection = "right",
		}
		local ybefore = self.y
		inportal(self)
		check("inportal no snap below platform y=" .. startY, self.y == ybefore)
	end
end

-- inportal: same-tile up+down picks down entry when rising (not up->down snap)
do
	portals = {
		{
			x1 = 5, y1 = 7, facing1 = "up",
			x2 = 5, y2 = 7, facing2 = "down",
		},
	}
	function checkrect()
		return {}
	end
	local w, h = 12 / 16, 12 / 16
	local self = {
		mask = {}, x = 4.2, y = 6.625, width = w, height = h,
		speedx = 0, speedy = -6, rotation = 0, animationdirection = "right",
	}
	inportal(self)
	check("inportal same tile rising down entry", self.y < 6.8, "y=" .. self.y)
end

-- inportal: detection band at down portal plane teleports to linked exit
do
	portals = {
		{
			x1 = 2, y1 = 12, facing1 = "up",
			x2 = 5, y2 = 7, facing2 = "down",
		},
	}
	function checkrect()
		return {}
	end
	local w, h = 12 / 16, 12 / 16
	local self = {
		mask = {}, x = 4.2, y = 6.55, width = w, height = h,
		speedx = 0, speedy = -6, rotation = 0, animationdirection = "right",
	}
	inportal(self)
	check("inportal down band teleports to floor", self.y + h / 2 > 10)
end

return failed
