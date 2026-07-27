--[[ Teal port of root entitylistitem.lua ]]

rawset(_G, "entitylistitem", rawget(_G, "entitylistitem") or {})

function entitylistitem.new(_: entitylistitem, t: any, i: any): entitylistitem
	local self = setmetatable({}, { __index = entitylistitem }) as entitylistitem
	self:init(t, i)
	return self
end

function entitylistitem:init(t, i)
	-- Original uses ambient globals x/y; layout overwrites these in generateentitylist.
	self.x = ((_G as {string:any})["x"] as number) or 0
	self.y = ((_G as {string:any})["y"] as number) or 0
	self.t = t as string
	self.i = i as number
end

function entitylistitem:gethighlight(x, y): boolean
	local nx = (x as number)/scale-5
	local ny = (y as number)/scale-38+tilesoffset/scale
	
	return nx >= self.x and nx < self.x+16 and ny >= self.y and ny < self.y+16
end

global function getentityhighlight(x: any, y: any): entitylistitem|nil
	
	for i, v in ipairs(entitylistitems) do
		for j, k in ipairs(v.entries) do
			if k:gethighlight(mouse.getX(), mouse.getY()) then
				return k
			end
		end
	end
end
