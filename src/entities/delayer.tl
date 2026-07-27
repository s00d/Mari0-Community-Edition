--[[ Teal port of root delayer.lua ]]

rawset(_G, "delayer", rawget(_G, "delayer") or {})

function delayer.new(_: delayer, x: number, y: number, r: {any}): delayer
	local self = setmetatable({}, { __index = delayer }) as delayer
	self:init(x, y, r)
	return self
end

function delayer:init(x: number, y: number, r)
	self.x = x
	self.y = y
	self.cox = x
	self.coy = y
	
	self.outtable = {}
	self.delay = 1
	self.visible = true
	
	--Input list
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)	
	--VISIBLE
	if #self.r > 0 and self.r[1] ~= "link" then
		self.visible = (self.r[1] == "true")
		table.remove(self.r, 1)
	end
	--TIME
	if #self.r > 0 and self.r[1] ~= "link" then
		self.delay = tonumber(self.r[1]) or 1
		table.remove(self.r, 1)
	end
	
	self.timers = {}
end

function delayer:link()
	while #self.r > 3 do
		for j, w in pairs(outputs) do
			for i, v in pairs(objects[w]) do
				if tonumber(self.r[3]) == v.cox and tonumber(self.r[4]) == v.coy then
					v:addoutput(self, self.r[2])
				end
			end
		end
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
	end
end

function delayer:addoutput(a, t)
	table.insert(self.outtable, {a, t} as {any})
end

function delayer:update(dt: number): any...
	local delete = {}
	
	for i = 1, #self.timers do
		local v = self.timers[i]
		v.timeleft = v.timeleft - dt
		if v.timeleft <= 0 then
			self:out(v.t)
		
			table.insert(delete, i)
		end
	end
	
	remove_indices_desc(self.timers, delete)
end

function delayer:draw()
	if self.visible then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(delayerimg, math.floor((self.x-1-xscroll)*16*scale), ((self.y-yscroll-1)*16-8)*scale, 0, scale, scale)
	end
end

function delayer:out(t)
	for i = 1, #self.outtable do
		if (self.outtable[i] as {Entity, any})[1].input then
			(self.outtable[i] as {Entity, any})[1]:input(t, (self.outtable[i] as {Entity, any})[2])
		end
	end
end

function delayer:input(t, input)
	table.insert(self.timers, {t=t, timeleft=self.delay})
end