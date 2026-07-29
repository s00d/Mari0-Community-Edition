--[[ Teal port of root coinblockanimation.lua ]]

rawset(_G, "coinblockanimation", rawget(_G, "coinblockanimation") or {})

local Core = require("assets.anim8_core")

function coinblockanimation.new(_: coinblockanimation, x: number, y: number): coinblockanimation
	local self = setmetatable({}, { __index = coinblockanimation }) as coinblockanimation
	self:init(x, y)
	return self
end

function coinblockanimation:init(x: number, y: number)
	self.x = x
	self.y = y
	
	self.timer = 0
	self.frame = 1
end

function coinblockanimation:update(dt: number): boolean
	local ticked: boolean
	self.timer, ticked = Core.tick_interval(self.timer, dt, coinblockdelay)
	if ticked then
		self.frame = self.frame + 1
	end
	
	if self.frame >= 31 then
		addpoints(-200, self.x, self.y)
		return true
	end
	
	return false
end