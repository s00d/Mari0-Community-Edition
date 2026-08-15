--[[ Teal port of root bubble.lua ]]

rawset(_G, "bubble", rawget(_G, "bubble") or {})

function bubble.new(_: bubble, x: number, y: number): bubble
	local self = setmetatable({}, { __index = bubble }) as bubble
	self:init(x, y)
	return self
end

--"FUCKING BUBBLES!!!!"
--          -The Nostalgia Critic, when he wasn't shit.

function bubble:init(x: number, y: number)
	self.x = x
	self.y = y
	
	self.speedy = -bubblesspeed
end

function bubble:update(dt: number): boolean
	self.speedy = self.speedy + (math.random()-0.5)*dt*100
	
	if self.speedy < -bubblesspeed-bubblesmargin then
		self.speedy = -bubblesspeed-bubblesmargin
	elseif self.speedy > -bubblesspeed+bubblesmargin then
		self.speedy = -bubblesspeed+bubblesmargin
	end
	
	self.y = self.y + self.speedy*dt
	
	if self.y < bubblesmaxy then
		return true
	end
	
	if not underwater then
		local x = math.floor(self.x)+1
		local y = math.floor(self.y)+1
		
		if not inmap(x, y) then
			return true
		end
		
		if not tilequads[session.map[x][y][1]]:getproperty("water", x, y) then
			return true
		end
	end
	
	return false
end

function bubble:draw()
	love.graphics.draw(bubbleimg, tile_draw_x(self.x), math.floor(tile_draw_y_raw(self.y-.5)), 0, scale, scale, 2, 2)
end