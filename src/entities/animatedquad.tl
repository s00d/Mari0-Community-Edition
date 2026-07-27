--[[ Teal port of root animatedquad.lua ]]

rawset(_G, "animatedquad", rawget(_G, "animatedquad") or {})

function animatedquad.new(_: animatedquad, imgpath: any, s: any, number: any): animatedquad
	local self = setmetatable({}, { __index = animatedquad }) as animatedquad
	self:init(imgpath, s, number)
	return self
end

function animatedquad:init(imgpath, s, number)
	self.number = number
	self.image = AssetStore.load_image(tostring(imgpath)) as Image
	self.imagedata = love.image.newImageData(tostring(imgpath))
	self.quadlist = {}
	for x = 1, math.floor(self.image:getWidth()/17) do
		table.insert(self.quadlist, love.graphics.newQuad((x-1)*17, 0, 16, 16, self.image:getWidth(), self.image:getHeight()))
	end
	self.quadi = 1
	self.properties = {}
	for x = 1, #self.quadlist do
		self.properties[x] = getquadprops(self.imagedata, x, 1)
	end
	self.props = (self.properties as {any})[self.quadi as integer] as {any:any}
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
			local vv = v as {any:any}
			if self.props.collision ~= vv.collision or self.props.portalable ~= vv.portalable then
				self.cache = {}
				break
			end
		end
	end
	
	for i = 1, #self.delays do
		self.delays[i] = tonumber(self.delays[i])
		-- Delay 0 causes an infinite loop in update(); treat as a static frame.
		if not self.delays[i] or (self.delays[i] as number) <= 0 then
			self.delays[i] = math.huge
		end
	end
	
	local delaycount = #self.delays
	for j = #self.delays+1, #self.quadlist do
		self.delays[j] = self.delays[math.fmod(j-1, delaycount)+1]
	end
	
end

function animatedquad:updateproperties()
	local oldcol = self.props.collision
	local oldportalable = self.props.portalable
	
	self.props = (self.properties as {any})[self.quadi as integer] as {any:any}
	
	if self.cache then
		if oldcol ~= self.props.collision then
			for i, v in ipairs(self.cache) do
				local vv = v as {any:any}
				local x = vv.x
				local y = vv.y
				if self.props.collision then
					objects["tile"][tilekey(x as number, y as number)] = tile:new((x as number)-1, (y as number)-1) as Entity
				else
					objects["tile"][tilekey(x, y)] = nil
					checkportalremove(x as number, y as number)
				end
			end
		end
		
		if oldportalable ~= self.props.portalable then
			for i, v in ipairs(self.cache) do
				local vv = v as {any:any}
				local x = vv.x
				local y = vv.y
				if oldportalable ~= self.portalable then
					if not self.props.portalable then
						checkportalremove(x as number, y as number)
					end
				end
			end
		end
	end
end

function animatedquad:update(dt: number)
	self.timer = (self.timer as number) + dt
	local qi = self.quadi as integer
	while (self.timer as number) > (self.delays[qi] as number) do
		self.timer = (self.timer as number) - (self.delays[qi] as number)
		qi = qi + 1
		if qi > #self.quadlist then
			qi = 1
		end
		self.quadi = qi
		if objects and not self.triggered and not self.boolean then
			self:updateproperties()
		end
	end
end

function animatedquad:quad(x, y): any
	local ql = self.quadlist as {any}
	if self.triggered and x and y and animatedtimers[x][y] then
		return ql[animatedtimers[x][y]:geti() as integer]
	elseif self.boolean and x and y and animatedbooltimers[x][y] then
		return ql[animatedbooltimers[x][y]:geti() as integer]
	else
		return ql[self.quadi as integer]
	end
end

function animatedquad:getproperty(s, x, y): any
	local props = self.properties as {any}
	if self.triggered and x and y and animatedtimers[x] and animatedtimers[x][y] then
		local gi = animatedtimers[x][y]:geti() as integer
		if props[gi] then
			return (props[gi] as {any:any})[s]
		end
	elseif self.boolean and x and y and animatedbooltimers[x] and animatedbooltimers[x][y] then
		local gi = animatedbooltimers[x][y]:geti() as integer
		if props[gi] then
			return (props[gi] as {any:any})[s]
		end
	end
	return self.props[s]
end