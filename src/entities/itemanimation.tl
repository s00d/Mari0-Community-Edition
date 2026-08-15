--[[ Teal port of root itemanimation.lua ]]

rawset(_G, "itemanimation", rawget(_G, "itemanimation") or {})

local Core = require("assets.anim8_core")

function itemanimation.new(_: itemanimation, x: number, y: number, i: any): itemanimation
	local self = setmetatable({}, { __index = itemanimation }) as itemanimation
	self:init(x, y, i)
	return self
end

function itemanimation:init(x: number, y: number, i)
	self.x = x
	self.y = y
	self.i = i
	self.timer = 0
	
	self.v = enemiesdata[self.i] as EnemyDef
end

function itemanimation:update(dt: number): boolean
	self.timer = self.timer + dt
	if enemiesdata[self.i]["directfromblock"] then
		obj_insert("enemy", enemy:new(self.x, self.y, self.i as string, session.map[self.x][self.y]) as Entity)
		return true
	end
	if self.timer >= mushroomtime then
		obj_insert("enemy", enemy:new(self.x, self.y-1, self.i as string, session.map[self.x][self.y]) as Entity)
		return true
	end
end

function itemanimation:draw()
	local yoffset = Core.lerp_value(self.timer, mushroomtime, 0, 1)
	love.graphics.setScissor(screen_draw_x(self.x - 6), screen_draw_y(self.y - 6.5), 176 * scale, 80 * scale)
	local ox = ((self.v.spawnoffsetx as number) or 0)
	local oy = ((self.v.spawnoffsety as number) or 0)
	love.graphics.draw(
		self.v.graphic,
		self.v.quad,
		entity_draw_x(self.x - .5 - self.v.width / 2 + ox, self.v.offsetX),
		entity_draw_y(self.y - yoffset - self.v.height + oy, self.v.offsetY),
		0,
		world_draw_scale(),
		world_draw_scale(),
		self.v.quadcenterX,
		self.v.quadcenterY
	)
	love.graphics.setScissor()
end
