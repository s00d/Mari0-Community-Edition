--[[ AE conveyor belt. Port of mari0_ae/belt.lua (simplified). ]]

rawset(_G, "belt", rawget(_G, "belt") or {})

function belt.new(_: belt, x: number, y: number, r: {any}): belt
	local self = setmetatable({}, { __index = belt }) as belt
	self:init(x, y, r)
	return self
end

function belt:init(x: number, y: number, r: {any})
	self.cox = x
	self.coy = y
	self.x = x - 1
	self.y = y - 1
	self.height = 1
	self.speedx = 0
	self.speedy = 0
	self.static = true
	self.active = true
	self.category = 2
	self.gravity = 0
	self.mask = {
		true,
		false, false, false, false, false,
		false, false, false, true, false,
		false, false, true, false, false,
		true, true, false, false, false,
		false, true, true, false, false,
		true, false, true, true, true,
		false, true,
	}
	self.beltspeed = 3
	self.width = 3
	self.on = true
	local rr = {unpack(r)}
	table.remove(rr, 1)
	table.remove(rr, 1)
	if #rr > 0 and rr[1] ~= "link" then
		local s = tostring(rr[1])
		local parts = strsplit(s, "|")
		if parts[1] then
			local sp = tostring(parts[1]):gsub("n", "-")
			local n = tonumber(sp)
			if n then
				self.beltspeed = n
			elseif parts[1] == "left slow" then
				self.beltspeed = -3
			elseif parts[1] == "left fast" then
				self.beltspeed = -6
			elseif parts[1] == "right fast" then
				self.beltspeed = 6
			end
		end
		if parts[2] then
			self.width = math.min(99, math.max(2, math.floor(tonumber(parts[2]) or 3)))
		end
	end
	self.drawable = false
	self.graphic = beltimg
	local iw = (beltimg as Image):getWidth()
	local ih = (beltimg as Image):getHeight()
	self.quad = love.graphics.newQuad(0, 0, math.min(16, iw), math.min(16, ih), iw, ih)
	self.offsetX = 8
	self.offsetY = 0
	self.quadcenterX = 8
	self.quadcenterY = 8
	self.rotation = 0
	self.animtimer = 0
	self.PLATFORM = true
end

function belt:update(dt: number): boolean
	if not self.on then
		return false
	end
	self.animtimer = (self.animtimer + dt) % 1
	-- Push players / enemies standing on the belt
	local checks = {"player", "enemy", "box"}
	for ci = 1, #checks do
		local group = objects[checks[ci]]
		if group then
			for _, w in pairs(group) do
				local o = w as Dyn
				if o and ((o.gravity as number|nil) == nil or (o.gravity as number) ~= 0)
					and inrange(o.x as number, self.x - (o.width as number), self.x + self.width)
					and inrange(o.y as number, self.y - (o.height as number) - 0.1, self.y - (o.height as number) + 0.1)
				then
					rawset(o, "x", (o.x as number) + self.beltspeed * dt)
				end
			end
		end
	end
	return false
end

function belt:ceilcollide(_: any, _: Entity): any
	return true
end

function belt:draw()
	-- Tile the belt graphic across width (fallback if not using drawable path alone)
	if not beltimg then
		return
	end
	for i = 0, math.floor(self.width) - 1 do
		love.graphics.draw(
			beltimg,
			self.quad,
			tile_draw_x(self.x + i),
			tile_draw_y(self.y, -8),
			0,
			world_draw_scale(),
			world_draw_scale()
		)
	end
end
