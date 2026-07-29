--[[ Ability-gated door (F1). ]]

rawset(_G, "gatedoor", rawget(_G, "gatedoor") or {})

function gatedoor.new(_: gatedoor, x: number, y: number, r: {any}): gatedoor
	local self = setmetatable({}, { __index = gatedoor }) as gatedoor
	self:init(x, y, r)
	return self
end

function gatedoor:init(x: number, y: number, r)
	self.cox = x; self.coy = y; self.dir = "ver"; self.kind = "open"; self.keyid = nil as string|nil
	self.open = false; self.timer = 0; self.uid = door_uid(x, y)
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1); table.remove(self.r, 1)
	if #self.r > 0 and self.r[1] ~= "link" then self.dir = self.r[1] as string; table.remove(self.r, 1) end
	if #self.r > 0 and self.r[1] ~= "link" then self.kind = self.r[1] as string; table.remove(self.r, 1) end
	if #self.r > 0 and self.r[1] ~= "link" then self.keyid = self.r[1] as string; table.remove(self.r, 1) end
	if door_is_open(self.uid) then self.open = true end
	if self.dir == "hor" then
		self.x = x - 1; self.y = y - 12 / 16; self.width = 32 / 16; self.height = 8 / 16
	else
		self.x = x - 12 / 16; self.y = y - 2; self.width = 8 / 16; self.height = 32 / 16
	end
	self.category = 25; self.mask = {true}; self.static = true; self.active = not self.open; self.drawable = true
end

function gatedoor:update(dt: number)
	if self.open then
		self.active = false
		if self.timer < 1 then self.timer = math.min(1, self.timer + (doorspeed or 2) * dt) end
		return
	end
	if playerobjs then
		for i = 1, players or 1 do
			local pl = playerobjs[i]
			if pl and not (pl as Dyn).dead then
				if door_try_open(self.uid, self.kind, pl, { keyid = self.keyid, kind = self.kind }) then
					self.open = true; self.active = false
					if updateranges then updateranges() end
					return
				end
			end
		end
	end
end

function gatedoor:draw()
	local col = (DOOR_COLOR and DOOR_COLOR[self.kind]) or {1.0, 1.0, 1.0, 1.0}
	love.graphics.setColor(col[1] as number, col[2] as number, col[3] as number, self.open and 0.25 or 0.9)
	love.graphics.rectangle("fill", tile_draw_x(self.x), tile_draw_y(self.y, 0), self.width * 16 * world_draw_scale(), self.height * 16 * world_draw_scale())
	love.graphics.setColor(1, 1, 1, 1)
end

return gatedoor
