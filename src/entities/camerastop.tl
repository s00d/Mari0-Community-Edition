--[[ AE camera stop region. Port of mari0_ae/camerastop.lua (simplified). ]]

rawset(_G, "camerastop", rawget(_G, "camerastop") or {})

function camerastop.new(_: camerastop, x: number, y: number, r: {any}): camerastop
	local self = setmetatable({}, { __index = camerastop }) as camerastop
	self:init(x, y, r)
	return self
end

function camerastop:init(x: number, y: number, r: {any})
	self.cox = x
	self.coy = y
	self.rx = x - 1
	self.ry = y - 1
	self.rw = 1
	self.rh = 1
	self.power = true
	self.static = true
	self.active = false
	self.drawable = false
	self.x = self.rx
	self.y = self.ry
	self.width = self.rw
	self.height = self.rh
	self.speedx = 0
	self.speedy = 0
	self.category = 1
	self.mask = {true}
	local rr = {unpack(r)}
	table.remove(rr, 1)
	table.remove(rr, 1)
	if #rr > 0 and rr[1] ~= "link" then
		-- "w|h|ox|oy|..."
		local parts = strsplit(tostring(rr[1]), "|")
		self.rw = tonumber(parts[1]) or 1
		self.rh = tonumber(parts[2]) or 1
		local ox = tonumber(parts[3]) or 0
		local oy = tonumber(parts[4]) or 0
		self.rx = (x - 1) + ox
		self.ry = (y - 1) + oy
		self.x = self.rx
		self.y = self.ry
		self.width = self.rw
		self.height = self.rh
	end
end

function camerastop:update(_: number): boolean
	if not self.power then
		return false
	end
	-- Soft clamp main camera scroll away from region interior
	local x1, y1, w1, h1 = self.rx, self.ry - 0.5, self.rw, self.rh
	if session.xscroll + width > x1 and session.xscroll < x1 + w1 and session.yscroll + height > y1 and session.yscroll < y1 + h1 then
		-- Prefer pushing camera left of region if overlapping from left
		if session.xscroll + width / 2 < x1 + w1 / 2 then
			session.xscroll = math.max(0, x1 - width)
		else
			session.xscroll = math.min(session.mapwidth - width, x1 + w1)
		end
	end
	return false
end
