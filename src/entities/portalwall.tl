--[[ Teal port of root portalwall.lua ]]

rawset(_G, "portalwall", rawget(_G, "portalwall") or {})

function portalwall.new(_: portalwall, x: number, y: number, width: any, height: any, _ignore: any): portalwall
	local self = setmetatable({}, { __index = portalwall }) as portalwall
	self:init(x, y, width, height)
	return self
end

function portalwall:init(x: number, y: number, width, height, _ignore: any)
	self.x = x
	self.y = y	
	self.width = width as number
	self.height = height as number
	self.static = true
	self.active = true
	self.category = 12
	self.mask = {true}
end

function portalwall:draw()--debug
	love.graphics.setColor(1, 0, 0)
	love.graphics.setPointSize(5)
	if self.width ~= 0 or self.height ~= 0 then
		love.graphics.line((self.x-xscroll)*16*scale, (self.y-.5-yscroll)*16*scale, (self.x-xscroll)*16*scale+self.width*16*scale, (self.y-.5-yscroll)*16*scale+self.height*16*scale)
	else
		love.graphics.line((self.x-xscroll)*16*scale, (self.y-.5-yscroll)*16*scale, (self.x-xscroll)*16*scale+self.width*16*scale, (self.y-.5-yscroll)*16*scale+self.height*16*scale)
	end
end