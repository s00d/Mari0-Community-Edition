--[[ Teal port of root button.lua ]]

rawset(_G, "button", rawget(_G, "button") or {})

function button.new(_: button, x: number, y: number, r: {any}): button
	local self = setmetatable({}, { __index = button }) as button
	self:init(x, y, r)
	return self
end

function button:init(x: number, y: number, r)
	self.cox = x
	self.coy = y
	
	--PHYSICS STUFF
	self.x = x-15/16
	self.y = y-3/16
	self.width = 30/16
	self.height = 3/16
	self.static = true
	self.active = false
	self.category = 22
	self.dir = "down"
	self.objtable = {"player", "enemy", "box"}
	
	self.mask = {true}
	
	self.drawable = false
	
	--Input list
	self.input1state = "off"
	self.r = {unpack(r as {any})}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	--DIRECTION
	if #self.r > 0 and self.r[1] ~= "link" then
		self.dir = self.r[1] as string
		table.remove(self.r, 1)
	end
	
	self.out = false
	self.outtable = {}
	self.pressings = {}
end

function button:update(_dt: number)
	local x: number = 0
	local y: number = 0
	local width: number = 0
	local height: number = 0
	if self.dir == "down" then
		x = self.x+5/16
		y = self.y-2/16
		width = 20/16
		height = 1
	elseif self.dir == "left" then
		x = self.x-12/16
		y = self.y-7/16
		width = 1
		height = 20/16
	elseif self.dir == "right" then
		x = self.x+10/16
		y = self.y-7/16
		width = 1
		height = 20/16
	elseif self.dir == "up" then
		x = self.x+5/16
		y = self.y-24/16
		width = 20/16
		height = 1
	end
	
	local colls = checkrect(x, y, width, height, self.objtable)
	
	for j = 1, #colls, 2 do
		local add = true
		for _, v in pairs(self.pressings) do
			if objects[colls[j]][colls[j+1]] == v then
				add = false
			end
		end
		
		if add then
			table.insert(self.pressings, objects[colls[j]][colls[j+1]])
			if objects[colls[j]][colls[j+1]].onbutton then
				objects[colls[j]][colls[j+1]]:onbutton(true)
			end
		end
	end
	
	
	local delete: {integer} = {}
	
	for i, v in pairs(self.pressings) do
		local rem = true
		for j = 1, #colls, 2 do
			if objects[colls[j]][colls[j+1]] == v then
				rem = false
			end
		end
		
		if rem then
			table.insert(delete, i as integer)
		end
	end
	
	table.sort(delete, function(a: integer, b: integer): boolean return a > b end)
	
	for _, v in ipairs(delete) do
		if self.pressings[v].onbutton then
			self.pressings[v]:onbutton(false)
		end
		table.remove(self.pressings, v)
	end
	
	if (#colls > 0) ~= self.out then
		self.out = not self.out
		for i = 1, #self.outtable do
			if (self.outtable[i] as {Entity, any})[1].input then
				if self.out then
					(self.outtable[i] as {Entity, any})[1]:input("on", (self.outtable[i] as {Entity, any})[2])
				else
					(self.outtable[i] as {Entity, any})[1]:input("off", (self.outtable[i] as {Entity, any})[2])
				end
			end
		end
	end
end

function button:draw()
	local quad = 1
	if self.out then
		quad = 2
	end
	local sc = world_draw_scale()

	if self.dir == "down" then	
		love.graphics.draw(buttonimg, buttonquad[quad], tile_draw_x(self.x-1/16), tile_draw_y(self.y, -10), 0, sc, sc)
	elseif self.dir == "left" then
		love.graphics.draw(buttonimg, buttonquad[quad], tile_draw_x(self.x+4/16), tile_draw_y(self.y, -21), math.pi/2, sc, sc)
	elseif self.dir == "right" then
		love.graphics.draw(buttonimg, buttonquad[quad], tile_draw_x(self.x+10/16), tile_draw_y(self.y, 11), -math.pi/2, sc, sc)
	elseif self.dir == "up" then
		love.graphics.draw(buttonimg, buttonquad[quad], tile_draw_x(self.x+31/16), tile_draw_y(self.y, -16), math.pi, sc, sc)
	end
end

function button:addoutput(a, t)
	table.insert(self.outtable, {a as Entity, t})
end