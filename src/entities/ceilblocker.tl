--[[ Teal port of root ceilblocker.lua ]]

rawset(_G, "ceilblocker", rawget(_G, "ceilblocker") or {})

function ceilblocker.new(_: ceilblocker, x: any): ceilblocker
	local self = setmetatable({}, { __index = ceilblocker }) as ceilblocker
	self:init(x)
	return self
end

function ceilblocker:init(x)
	self.x = x-1
	self.y = -1000
	self.height = 1000
	self.width = 1
	self.static = true
	self.active = true
end