--[[ Teal port of root scrollingtext.lua ]]

rawset(_G, "scrollingtext", rawget(_G, "scrollingtext") or {})

function scrollingtext.new(_: scrollingtext, s: any, x: any, y: any): scrollingtext
	local self = setmetatable({}, { __index = scrollingtext }) as scrollingtext
	self:init(s, x, y)
	return self
end

function scrollingtext:init(s, x, y)
	self.x = x-xscroll
	self.y = y-yscroll
	self.s = s
	self.timer = 0
end

function scrollingtext:update(dt: number)
	self.timer = self.timer + dt
	if self.timer > scrollingscoretime then
		return true
	end
	
	return false
end

function scrollingtext:draw()
	properprintbackground(self.s, self.x*16*scale, (self.y-.5-self.timer)*16*scale, true, nil, scale)
end
