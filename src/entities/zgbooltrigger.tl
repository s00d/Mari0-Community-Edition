--[[ Teal port of root zgbooltrigger.lua ]]

rawset(_G, "zgbooltrigger", rawget(_G, "zgbooltrigger") or {})

function zgbooltrigger.new(_: zgbooltrigger, x: number, y: number, r: {any}): zgbooltrigger
	local self = setmetatable({}, { __index = zgbooltrigger }) as zgbooltrigger
	self:init(x, y, r)
	return self
end

function zgbooltrigger:init(x: number, y: number, r)
	self.x = x
	self.y = y
	self.cox = x
	self.coy = y
	
	self.inverted = false
	self.outtable = {}
	self.id = false
	self.invisible = false
	--Input list
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	self.checktable = false
	
	--TRIGGER ON PLAYER?
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			self.inverted = true
		end			
		table.remove(self.r, 1)
	end
	
	--TRIGGER ON ENEMY?
	if #self.r > 0 and self.r[1] ~= "link" then
		self.id = self.r[1]	
		table.remove(self.r, 1)
	end
	
	--REGION
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			self.invisible = true
		end	
		table.remove(self.r, 1)
	end
	
	self.out = "off"
end

function zgbooltrigger:update(_: number)
	local col = globoolSH(self.id, "check") 
	
	if self.inverted then
		col = not col
	end
	
	if self.out == "off" and col then
		self.out = "on"
		for i = 1, #self.outtable do
			if (self.outtable[i] as {Entity, any})[1].input then
				(self.outtable[i] as {Entity, any})[1]:input(self.out, (self.outtable[i] as {Entity, any})[2])
			end
		end
	elseif self.out == "on" and not col then
		self.out = "off"
		for i = 1, #self.outtable do
			if (self.outtable[i] as {Entity, any})[1].input then
				(self.outtable[i] as {Entity, any})[1]:input(self.out, (self.outtable[i] as {Entity, any})[2])
			end
		end
	end
end

function zgbooltrigger:draw()
	love.graphics.setColor(1, 1, 1)
	local quad = 1
	if self.out=="on" then
		quad = 2
	end
	
	if not self.invisible then
		love.graphics.draw(zgbooltriggerimg, zgbooltriggerquad[quad], tile_draw_x(self.x-1), tile_draw_y(self.y-1, -8), 0, world_draw_scale(), world_draw_scale())
	end
end

function zgbooltrigger:addoutput(a, t)
	table.insert(self.outtable, {a, t} as {any})
end