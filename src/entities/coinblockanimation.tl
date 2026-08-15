--[[ Teal port of root coinblockanimation.lua ]]

rawset(_G, "coinblockanimation", rawget(_G, "coinblockanimation") or {})

-- Matches coinblockanimationquads[1..30] in boot.tl
local COINBLOCK_FRAMES = 30

function coinblockanimation.new(_: coinblockanimation, x: number, y: number): coinblockanimation
	local self = setmetatable({}, { __index = coinblockanimation }) as coinblockanimation
	self:init(x, y)
	return self
end

function coinblockanimation:init(x: number, y: number)
	self.x = x
	self.y = y
	self.frame = 1
	self.finished = false
	self.tick_id = 0
	self.tick_id = self.tick_id + 1
	local token = self.tick_id
	HumpTimer.every(coinblockdelay, function()
		if self.tick_id ~= token or self.finished then
			return
		end
		if self.frame >= COINBLOCK_FRAMES then
			addpoints(-200, self.x, self.y)
			self.finished = true
			return
		end
		self.frame = self.frame + 1
		if self.frame >= COINBLOCK_FRAMES then
			addpoints(-200, self.x, self.y)
			self.finished = true
		end
	end, COINBLOCK_FRAMES)
end

function coinblockanimation:update(_: number): boolean
	return self.finished
end
