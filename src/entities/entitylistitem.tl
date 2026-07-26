--[[ Teal port of root entitylistitem.lua ]]

rawset(_G, "entitylistitem", rawget(_G, "entitylistitem") or {})

function entitylistitem.new(_: entitylistitem, t: any, i: any): entitylistitem
	local self = setmetatable({}, { __index = entitylistitem }) as entitylistitem
	self:init(t, i)
	return self
end

function entitylistitem:init(t, i)
	self.x = x
	self.y = y
	self.t = t
	self.i = i
end

function entitylistitem:gethighlight(x, y)
	x = x/scale-5
	y = y/scale-38+tilesoffset/scale
	
	return x >= self.x and x < self.x+16 and y >= self.y and y < self.y+16
end

global function getentityhighlight(...: any): any
	local x, y = ...
	for i, v in ipairs(entitylistitems) do
		for j, k in ipairs(v.entries) do
			if k:gethighlight(mouse.getX(), mouse.getY()) then
				return k
			end
		end
	end
end