--[[ Teal port of root tile.lua ]]

rawset(_G, "tile", rawget(_G, "tile") or {})

function tile.new(_: tile, ...: any): tile
	local x, y, slant = ...
	local self = setmetatable({}, { __index = tile }) as tile
	self:init(x as number, y as number, slant)
	return self
end

function tile:init(x: number, y: number, slant)
	self.cox = x+1
	self.coy = y+1
	self.x = x
	self.y = y
	self.speedx = 0
	self.speedy = 0
	self.width = 1
	self.height = 1
	self.active = true
	self.static = true
	self.category = 2
	self.mask = {true}
end