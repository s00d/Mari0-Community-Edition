--[[ Metroid ability pedestal / pickup (F1 content). ]]

rawset(_G, "abilitypickup", rawget(_G, "abilitypickup") or {})

function abilitypickup.new(_: abilitypickup, x: number, y: number, r: {any}): abilitypickup
	local self = setmetatable({}, { __index = abilitypickup }) as abilitypickup
	self:init(x, y, r)
	return self
end

function abilitypickup:init(x: number, y: number, r)
	self.cox = x
	self.coy = y
	self.x = x - 0.75
	self.y = y - 1
	self.width = 0.75
	self.height = 0.75
	self.ability = "portal"
	self.uid = door_uid(x, y)
	self.taken = false
	self.timer = 0
	self.category = 1
	self.mask = {true}
	self.static = true
	self.active = false
	self.drawable = true
	self.destroy = false
	local rr = {unpack(r as {any})}
	table.remove(rr, 1)
	table.remove(rr, 1)
	if #rr > 0 and rr[1] ~= "link" then
		self.ability = tostring(rr[1])
		table.remove(rr, 1)
	end
	if #rr > 0 and rr[1] ~= "link" then
		self.uid = tostring(rr[1])
		table.remove(rr, 1)
	end
	if globoolSH("item_" .. self.uid, "check") or (self.ability ~= "" and globoolSH("ability_" .. self.ability, "check")) then
		self.taken = true
		self.destroy = true
	end
end

function abilitypickup:update(dt: number)
	if self.taken or self.destroy then
		return
	end
	self.timer = (self.timer or 0) + (dt or 0)
	local col = checkrect(self.x, self.y, self.width, self.height, {"player"})
	if #col > 0 then
		for i = 2, #col, 2 do
			local pl = playerobjs and playerobjs[col[i] as integer]
			if pl and not (pl as Dyn).dead then
				grant_ability(pl, self.ability)
				globoolSH("item_" .. self.uid, "true")
				self.taken = true
				self.destroy = true
				playsound("mushroomeat")
				return
			end
		end
	end
end

function abilitypickup:draw()
	if self.taken or self.destroy then
		return
	end
	local def = ABILITIES and ABILITIES[self.ability]
	local gate = def and def.gate or "open"
	local col = (DOOR_COLOR and DOOR_COLOR[gate as string]) or {1.0, 0.9, 0.2, 1.0}
	local bob = math.sin((self.timer or 0) * 4) * 2
	local px = tile_draw_x(self.x)
	local py = tile_draw_y(self.y, -bob)
	love.graphics.setColor(col[1] as number, col[2] as number, col[3] as number, 0.95)
	love.graphics.rectangle("fill", px, py, self.width * 16 * world_draw_scale(), self.height * 16 * world_draw_scale())
	love.graphics.setColor(1, 1, 1, 0.9)
	love.graphics.rectangle("line", px, py, self.width * 16 * world_draw_scale(), self.height * 16 * world_draw_scale())
	love.graphics.setColor(1, 1, 1, 1)
end

return abilitypickup
