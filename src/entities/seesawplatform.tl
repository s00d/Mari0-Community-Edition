--[[ Teal port of root seesawplatform.lua ]]

rawset(_G, "seesawplatform", rawget(_G, "seesawplatform") or {})

function seesawplatform.new(_: seesawplatform, x: number, y: number, size: any, callback: any, side: any): seesawplatform
	local self = setmetatable({}, { __index = seesawplatform }) as seesawplatform
	self:init(x, y, size, callback, side)
	return self
end

function seesawplatform:init(x: number, y: number, size, callback, side)
	--PHYSICS STUFF
	self.size = (size as number) or 2
	self.startx = x-(self.size as number)
	self.starty = y	
	self.x = x-(self.size as number)/2-0.5
	self.y = y-17/16
	self.speedx = 0 --!
	self.speedy = 0
	self.width = self.size as number
	self.height = 8/16
	self.static = true
	self.active = true
	self.category = 15
	self.mask = {true}
	self.gravity = 0
	
	self.callback = callback
	self.side = side
	
	--IMAGE STUFF
	self.drawable = false
	
	self.rotation = 0
	
	self.speedy = 0
end

function seesawplatform:update(dt: number): boolean
	local checktable: {string} = {}
	for _, v in ipairs(enemies) do
		if objects[v] then
			table.insert(checktable, v)
		end
	end
	table.insert(checktable, "player")
	
	local numberofobjects = 0
	
	for _, v in ipairs(checktable) do
		for _, w in pairs(objects[v]) do
			if not w.jumping and inrange(w.x, self.x-w.width, self.x+self.width) then
				if inrange(w.y, self.y - w.height - 0.1, self.y - w.height + 0.1) then
					numberofobjects = numberofobjects + 1
					w.y = self.y - w.height + self.speedy*dt
				end
			end
		end
	end
	
	self.y = self.y + self.speedy*dt
	
	--report back on number of objects
	if self.side == "left" then
		((self.callback as Entity).callbackleft as function(any, number))(self.callback, numberofobjects)
	else
		((self.callback as Entity).callbackright as function(any, number))(self.callback, numberofobjects)
	end
	
	if self.y > mapheight+1 then
		return true
	end
	
	return false
end

function seesawplatform:draw()
	for i = 1, (self.size as number) do
		if self.dir ~= "justright" then
			love.graphics.draw(platformimg, math.floor((self.x+i-1-xscroll)*16*scale), math.floor((self.y-yscroll-8/16)*16*scale), 0, scale, scale)
		else
			love.graphics.draw(platformbonusimg, math.floor((self.x+i-1-xscroll)*16*scale), math.floor((self.y-yscroll-8/16)*16*scale), 0, scale, scale)
		end
	end
	
	if math.ceil(self.size as number) ~= (self.size as number) then --draw 1 more on the rightest
		love.graphics.draw(platformimg, math.floor((self.x+(self.size as number)-1-xscroll)*16*scale), math.floor((self.y-yscroll-8/16)*16*scale), 0, scale, scale)
	end
end

function seesawplatform:rightcollide(_: any, _: Entity): any
	return false
end

function seesawplatform:leftcollide(_: any, _: Entity): any
	return false
end

function seesawplatform:ceilcollide(_: any, _: Entity): any
	return false
end

function seesawplatform:floorcollide(_: any, _: Entity): any
	return false
end