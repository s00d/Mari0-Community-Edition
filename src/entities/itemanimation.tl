--[[ Teal port of root itemanimation.lua ]]

rawset(_G, "itemanimation", rawget(_G, "itemanimation") or {})

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
		table.insert(objects["enemy"], enemy:new(self.x, self.y, self.i as string, map[self.x][self.y]))
		return true
	end
	if self.timer >= mushroomtime then
		table.insert(objects["enemy"], enemy:new(self.x, self.y-1, self.i as string, map[self.x][self.y]))
		return true
	end
end

function itemanimation:draw()
	local yoffset = self.timer/mushroomtime*1
	love.graphics.setScissor((self.x-xscroll-6)*16*scale, (self.y-yscroll-6.5)*16*scale, 176*scale, 80*scale)
	love.graphics.draw(self.v.graphic, self.v.quad, math.floor(((self.x-xscroll-.5-self.v.width/2+((self.v.spawnoffsetx as number) or 0))*16+self.v.offsetX)*scale), math.floor(((self.y-yscroll-yoffset-self.v.height+((self.v.spawnoffsety as number) or 0))*16-self.v.offsetY)*scale), 0, scale, scale, self.v.quadcenterX, self.v.quadcenterY)
	love.graphics.setScissor()
end
