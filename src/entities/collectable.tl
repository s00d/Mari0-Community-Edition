--[[ AE collectable gem. Port of mari0_ae/collectable.lua (simplified). ]]

rawset(_G, "collectable", rawget(_G, "collectable") or {})

function collectable.new(_: collectable, x: number, y: number, r: {any}): collectable
	local self = setmetatable({}, { __index = collectable }) as collectable
	self:init(x, y, r)
	return self
end

function collectable:init(x: number, y: number, r: {any})
	self.cox = x
	self.coy = y
	self.x = x - 1
	self.y = y - 1
	self.width = 1
	self.height = 1
	self.speedx = 0
	self.speedy = 0
	self.static = true
	self.active = true
	self.category = 1
	self.mask = {true}
	self.drawable = true
	self.graphic = collectableimg
	local iw = (collectableimg as Image):getWidth()
	local ih = (collectableimg as Image):getHeight()
	local fw = math.min(16, iw)
	self.quad = love.graphics.newQuad(0, 0, fw, math.min(16, ih), iw, ih)
	self.offsetX = 8
	self.offsetY = 0
	self.quadcenterX = 8
	self.quadcenterY = 8
	self.rotation = 0
	self.t = 1
	self.collected = false
	local rr = {unpack(r)}
	table.remove(rr, 1)
	table.remove(rr, 1)
	if #rr > 0 and rr[1] ~= "link" then
		self.t = tonumber(rr[1] as any) or 1
	end
	local key = "collectable_" .. tostring(x) .. "_" .. tostring(y)
	if globoolSH and globoolSH(key, "check") then
		self.collected = true
		self.active = false
		self.drawable = false
	end
end

function collectable:update(_: number): boolean
	if self.collected then
		return true
	end
	local col = checkrect(self.x, self.y, self.width, self.height, {"player"})
	if #col > 0 then
		self.collected = true
		self.active = false
		self.drawable = false
		local key = "collectable_" .. tostring(self.cox) .. "_" .. tostring(self.coy)
		if globoolSH then
			globoolSH(key, "true")
		end
		if addpoints then
			addpoints(1000, self.x, self.y)
		end
		playsound("coin")
		return true
	end
	return false
end
