--[[ Teal port of root quad.lua ]]

rawset(_G, "quad", rawget(_G, "quad") or {})

function quad.new(_: quad, img: any, imgdata: any, x: any, y: any, width: any, height: any): quad
	local self = setmetatable({}, { __index = quad }) as quad
	self:init(img, imgdata, x, y, width, height)
	return self
end

--COLLIDE?
--INVISIBLE?
--BREAKABLE?
--COINBLOCK?
--COIN?
--_NOT_ PORTALABLE?
--LEFT SLANT?
--RIGHT SLANT?
--MIRROR?
--GRATE?
--PLATFORM TYPE?
--WATER TILE?
--BRIDGE?
--SPIKES?
--FOREGROUND?
function quad:init(img: any, imgdata: any, x: any, y: any, width: any, height: any)
	--get if empty?

	self.image = img as Image
	local xn = x as number
	local yn = y as number
	local wn = width as number
	local hn = height as number
	self.quadobj = love.graphics.newQuad((xn-1)*17, (yn-1)*17, 16, 16, wn, hn)
	
	self.props = getquadprops(imgdata as ImageData, xn, yn)
end

function quad:getproperty(s: any): any
	return (self.props as {any:any})[s]
end

function quad:quad(): Quad
	return self.quadobj
end

global function getquadprops(imgdata: ImageData, x: number, y: number): {string:any}
	local self: {string:any} = {}
	
	--get collision
	self.collision = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17)
	if a > 0.5*LOVE_COLOR_MAX then
		self.collision = true
	end
	
	--get invisible
	self.invisible = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+1)
	if a > 0.5*LOVE_COLOR_MAX then
		self.invisible = true
	end
	
	--get breakable
	self.breakable = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+2)
	if a > 0.5*LOVE_COLOR_MAX then
		self.breakable = true
	end
	
	--get coinblock
	self.coinblock = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+3)
	if a > 0.5*LOVE_COLOR_MAX then
		self.coinblock = true
	end
	
	--get coin
	self.coin = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+4)
	if a > 0.5*LOVE_COLOR_MAX then
		self.coin = true
	end
	
	--get not portalable
	self.portalable = true
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+5)
	if a > 0.5*LOVE_COLOR_MAX then
		self.portalable = false
	end
	
	--get left slant
	self.slantupleft = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+6)
	if a > 0.5*LOVE_COLOR_MAX then
		self.slantupleft = true
	end
	
	--get right slant
	self.slantupright = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+7)
	if a > 0.5*LOVE_COLOR_MAX then
		self.slantupright = true
	end
	
	--get mirror
	self.mirror = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+8)
	if a > 0.5*LOVE_COLOR_MAX then
		self.mirror = true
	end
	
	--get grate
	self.grate = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+9)
	if a > 0.5*LOVE_COLOR_MAX then
		self.grate = true
	end
	
	--get platform
	self.platform = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+10)
	if a > 0.5*LOVE_COLOR_MAX then
		self.platform = true
	end
	
	--get watertile
	self.water = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+11)
	if a > 0.5*LOVE_COLOR_MAX then
		self.water = true
	end
	
	--get bridge
	self.bridge = false
	local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+12)
	if a > 0.5*LOVE_COLOR_MAX then
		self.bridge = true
	end
	
	--get spikes
	local t = {"left", "top", "right", "bottom"}
	for i = 1, #t do
		local v = t[i]
		self["spikes" .. v] = false
		local _, _, _, a = imgdata:getPixel(x*17-1, (y-1)*17+12+i)
		if a > 0.5*LOVE_COLOR_MAX then
			self["spikes" .. v] = true
		end
	end
	
	--get foreground
	self.foreground = false
	local _, _, _, a = imgdata:getPixel(x*17-2, (y-1)*17+16)
	if a > 0.5 then
		self.foreground = true
	end
	
	return self
end