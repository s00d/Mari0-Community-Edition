--[[ Teal port of root animatedquad.lua ]]

rawset(_G, "animatedquad", rawget(_G, "animatedquad") or {})

function animatedquad.new(_: animatedquad, imgpath: any, s: any, number: any): animatedquad
	local self = setmetatable({}, { __index = animatedquad }) as animatedquad
	self:init(imgpath, s, number)
	return self
end

function animatedquad:init(imgpath, s, number): any
	self.number = number
	self.image = AssetStore.load_image(imgpath)
	self.imagedata = love.image.newImageData(imgpath)
	self.quadlist = {}
	for x = 1, math.floor(self.image:getWidth()/17) do
		table.insert(self.quadlist, love.graphics.newQuad((x-1)*17, 0, 16, 16, self.image:getWidth(), self.image:getHeight()))
	end
	self.quadi = 1
	self.properties = {}
	for x = 1, #self.quadlist do
		self.properties[x] = getquadprops(self.imagedata, x, 1)
	end
	self.props = self.properties[self.quadi]
	self.delays = {}
	self.timer = 0
	self.spikes = {}
	
	self.delays = strsplit(s, ",")
	
	if self.delays[1] == "triggered" then
		self.triggered = true
		table.remove(self.delays, 1)
	elseif self.delays[1] == "boolean" then
		self.boolean = true
		self.boolid = self.delays[2]
		table.remove(self.delays, 1)
		table.remove(self.delays, 1)
	else
		for i, v in ipairs(self.properties) do
			if self.props.collision ~= v.collision or self.props.portalable ~= v.portalable then
				self.cache = {}
				break
			end
		end
	end
	
	for i = 1, #self.delays do
		self.delays[i] = tonumber(self.delays[i]) as any
		-- Delay 0 causes an infinite loop in update(); treat as a static frame.
		if not self.delays[i] or self.delays[i] <= 0 then
			self.delays[i] = math.huge as any
		end
	end
	
	local delaycount = #self.delays
	for j = #self.delays+1, #self.quadlist do
		self.delays[j] = self.delays[math.fmod(j-1, delaycount)+1]
	end
	
end

function animatedquad:updateproperties(): any
	local oldcol = self.props.collision
	local oldportalable = self.props.portalable
	
	self.props = self.properties[self.quadi]
	
	if self.cache then
		if oldcol ~= self.props.collision then
			for i, v in ipairs(self.cache) do
				local x = v.x
				local y = v.y
				if self.props.collision then
					objects["tile"][tilekey(x, y)] = tile:new(x-1, y-1)
				else
					objects["tile"][tilekey(x, y)] = nil
					checkportalremove(x, y)
				end
			end
		end
		
		if oldportalable ~= self.props.portalable then
			for i, v in ipairs(self.cache) do
				local x = v.x
				local y = v.y
				if oldportalable ~= self.portalable then
					if not self.props.portalable then
						checkportalremove(x, y)
					end
				end
			end
		end
	end
end

function animatedquad:update(dt: number): any
	self.timer = self.timer + dt
	while self.timer > self.delays[self.quadi] do
		self.timer = self.timer - self.delays[self.quadi]
		self.quadi = self.quadi + 1
		if self.quadi > #self.quadlist then
			self.quadi = 1
		end
		if objects and not self.triggered and not self.boolean then
			self:updateproperties()
		end
	end
end

function animatedquad:quad(x, y): any
	if self.triggered and x and y and animatedtimers[x][y] then
		return self.quadlist[animatedtimers[x][y]:geti()]
	elseif self.boolean and x and y and animatedbooltimers[x][y] then
		return self.quadlist[animatedbooltimers[x][y]:geti()]
	else
		return self.quadlist[self.quadi]
	end
end

function animatedquad:getproperty(s, x, y): any
	if self.triggered and x and y and animatedtimers[x] and animatedtimers[x][y] then
		if self.properties[animatedtimers[x][y]:geti()] then
			return self.properties[animatedtimers[x][y]:geti()][s]
		end
	elseif self.boolean and x and y and animatedbooltimers[x] and animatedbooltimers[x][y] then
		if self.properties[animatedbooltimers[x][y]:geti()] then
			return self.properties[animatedbooltimers[x][y]:geti()][s]
		end
	end
	return self.props[s]
end