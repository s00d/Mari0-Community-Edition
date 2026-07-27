--[[ Teal port of root squarewave.lua ]]

rawset(_G, "squarewave", rawget(_G, "squarewave") or {})

function squarewave.new(_: squarewave, x: number, y: number, r: {any}): squarewave
	local self = setmetatable({}, { __index = squarewave }) as squarewave
	self:init(x, y, r)
	return self
end

function squarewave:init(x: number, y: number, r)
	self.x = x
	self.y = y
	self.cox = x
	self.coy = y
	self.r = r as {any}
	
	self.outtable = {}
	
	self.timer = 0
	self.time1 = 1
	self.time2 = 1
	self.visible = false
	self.initial = true
	
	--Input list
	self.input1state = "off"
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	--TIME1
	if #self.r > 0 and self.r[1] ~= "link" then
		self.time1 = self.r[1] as number
		table.remove(self.r, 1)
	end
	--TIME2
	if #self.r > 0 and self.r[1] ~= "link" then
		self.time2 = self.r[1] as number
		table.remove(self.r, 1)
	end
	--START
	if #self.r > 0 and self.r[1] ~= "link" then
		self.timer = (self.r[1] as number)*(self.time1+self.time2)
		table.remove(self.r, 1)
	end
	--VISIBLE
	if #self.r > 0 and self.r[1] ~= "link" then
		self.visible = (self.r[1] == "true")
		table.remove(self.r, 1)
	end
end

function squarewave:addoutput(a, t)
	table.insert(self.outtable, {a, t} as {any})
end

function squarewave:update(dt: number): any...
	if self.initial then
		self.initial = false
		if self.timer > self.time1 then
			self:out("on")
		end
	end
	
	self.timer = self.timer + dt
	if self.timer - dt <= self.time1 and self.timer > self.time1 then
		self:out("on")
	end
	
	if self.timer - dt <= self.time2+self.time1 and self.timer > self.time2+self.time1 then
		self:out("off")
		self.timer = self.timer - self.time2-self.time1
	end
end

function squarewave:draw()
	if self.visible then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(squarewaveimg, math.floor((self.x-1-xscroll)*16*scale), ((self.y-yscroll-1)*16-8)*scale, 0, scale, scale)
	end
end

function squarewave:out(t)
	for i = 1, #self.outtable do
		if (self.outtable[i] as {Entity, any})[1].input then
			(self.outtable[i] as {Entity, any})[1]:input(t, (self.outtable[i] as {Entity, any})[2])
		end
	end
end