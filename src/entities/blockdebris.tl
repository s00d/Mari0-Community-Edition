--[[ Teal port of root blockdebris.lua ]]

rawset(_G, "blockdebris", rawget(_G, "blockdebris") or {})

local Core = require("assets.anim8_core")

function blockdebris.new(_: blockdebris, x: number, y: number, speedx: any, speedy: any): blockdebris
	local self = setmetatable({}, { __index = blockdebris }) as blockdebris
	self:init(x, y, speedx, speedy)
	return self
end

function blockdebris:init(x: number, y: number, speedx, speedy)
	updateranges()
	self.x = x
	self.y = y
	self.speedx = speedx as number
	self.speedy = speedy as number
	
	self.timer = 0
	self.frame = 1
end

function blockdebris:update(dt: number): boolean
	local ticked: boolean
	self.timer, ticked = Core.tick_interval(self.timer, dt, blockdebrisanimationtime)
	if ticked then
		if self.frame == 1 then
			self.frame = 2
		else
			self.frame = 1
		end
	end
	
	self.speedy = self.speedy + blockdebrisgravity*dt
	
	self.x = self.x + self.speedx*dt
	self.y = self.y + self.speedy*dt
	
	
	if self.y > mapheight then
		return true
	end
	
	return false
end

function blockdebris:draw()
	love.graphics.draw(blockdebrisimg, blockdebrisquads[spriteset][self.frame], tile_draw_x(self.x), math.floor(tile_draw_y_raw(self.y-.5)), 0, scale, scale, 4, 4)
end
