--[[ Teal port of root vine.lua ]]

rawset(_G, "vine", rawget(_G, "vine") or {})

function vine.new(_: vine, x: number, y: number, t: any): vine
	local self = setmetatable({}, { __index = vine }) as vine
	self:init(x, y, t)
	return self
end

function vine:init(x: number, y: number, t)
	self.cox = x
	self.coy = y
	self.t = t as string
	
	if self.t == "start" then
		self.limit = session.mapheight-5-15/16
	else
		self.limit = -1
		for y = self.coy-1, 1, -1 do
			if session.map[self.cox][y][2] and entitylist[session.map[self.cox][y][2]] and entitylist[session.map[self.cox][y][2]].t == "vinestop" then
				self.limit = y-1
				if tilequads[session.map[self.cox][y][1]]:getproperty("collision", self.cox, y) then
					self.hidetop = true
					self.limit = self.limit + 0.5
				end
				break
			end
		end
	end
	
	self.timer = 0
	
	self.width = 10/16
	self.height = 0
	
	self.x = x-0.5-self.width/2
	self.y = y-1
	
	self.static = true
	self.active = true
	
	self.category = 18
	
	self.mask = {true}
	
	testtimer = love.timer.getTime()
	
	--IMAGE STUFF
	self.drawable = false
end

function vine:update(dt: number)
	if self.y > self.limit then
		self.y = self.y - vinespeed*dt
		if self.y <= self.limit then
			self.y = self.limit
		end
		self.height = math.max(0, self.coy-1-self.y)
	end
end

function vine:draw()
	-- Scissor is screen-space; vine sprites use world helpers under attach.
	local top = world_screen_y(self.limit)
	if not self.hidetop then
		top = top - 16 * scale
	end
	local bottom = world_screen_y(self.coy - 1.5)

	if bottom > top then
		love.graphics.setScissor(0, top, width * 16 * scale, bottom - top)

		local vine_x = tile_draw_x(self.x - 1/16 - ((1 - self.width) / 2))
		love.graphics.draw(vineimg, vinequad[spriteset][1], vine_x, tile_draw_y_raw(self.y - 0.5 - 2/16), 0, world_draw_scale(), world_draw_scale())
		for i = 1, math.ceil(self.height - 14/16 + .7) do
			love.graphics.draw(vineimg, vinequad[spriteset][2], vine_x, tile_draw_y_raw(self.y - 0.5 - 2/16 + i), 0, world_draw_scale(), world_draw_scale())
		end

		love.graphics.setScissor()
	end
end