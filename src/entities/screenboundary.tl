--[[ Teal port of root screenboundary.lua ]]

rawset(_G, "screenboundary", rawget(_G, "screenboundary") or {})

function screenboundary.new(_: screenboundary, x: any): screenboundary
	local self = setmetatable({}, { __index = screenboundary }) as screenboundary
	self:init(x)
	return self
end

function screenboundary:init(x)
	self.x = x
	self.y = -1000	
	self.width = 0
	self.height = 1000+mapheight
	self.static = true
	self.active = true
	self.category = 10
	self.mask = {true}
end