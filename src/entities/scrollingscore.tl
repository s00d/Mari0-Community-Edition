--[[ Teal port of root scrollingscore.lua ]]

rawset(_G, "scrollingscore", rawget(_G, "scrollingscore") or {})

function scrollingscore.new(_: scrollingscore, i: any, x: any, y: any): scrollingscore
	local self = setmetatable({}, { __index = scrollingscore }) as scrollingscore
	self:init(i, x, y)
	return self
end

function scrollingscore:init(i: any, x: any, y: any)
	self.x = (x as number)-xscroll
	self.y = (y as number)-yscroll
	self.i = i
	self.timer = 0
end

function scrollingscore:update(dt: number): any...
	self.timer = self.timer + dt
	if self.timer > scrollingscoretime then
		return true
	end
	
	return false
end
