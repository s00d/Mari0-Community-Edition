--[[ Teal port of root scrollingtext.lua ]]

rawset(_G, "scrollingtext", rawget(_G, "scrollingtext") or {})

function scrollingtext.new(_: scrollingtext, s: any, x: any, y: any): scrollingtext
	local self = setmetatable({}, { __index = scrollingtext }) as scrollingtext
	self:init(s, x, y)
	return self
end

function scrollingtext:init(s: any, x: any, y: any)
	self.x = x as number
	self.y = y as number
	self.s = s
	self.timer = 0
end

function scrollingtext:update(dt: number): boolean
	self.timer = self.timer + dt
	if self.timer > scrollingscoretime then
		return true
	end

	return false
end

function scrollingtext:draw()
	properprintbackground(
		self.s,
		tile_draw_x(self.x),
		tile_draw_y(self.y - 0.5 - self.timer, 0),
		true,
		nil,
		world_draw_scale()
	)
end
