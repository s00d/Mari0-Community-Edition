--[[ Bomberman bomb — fuse then break breakables + kill nearby enemies. ]]

rawset(_G, "bomb", rawget(_G, "bomb") or {})

function bomb.new(_: bomb, x: number, y: number): bomb
	local self = setmetatable({}, { __index = bomb }) as bomb
	self:init(x, y)
	return self
end

function bomb:init(x: number, y: number)
	self.x = x
	self.y = y
	self.width = 0.75
	self.height = 0.75
	self.speedx = 0
	self.speedy = 0
	self.active = true
	self.static = false
	self.category = 9
	self.mask = {true}
	self.gravity = 80
	self.fuse = 2.0
	self.drawable = true
	self.rotation = 0
	self.gravitydirection = math.pi / 2
	-- reuse box graphic if present; else invisible until sprites
	if boximg then
		self.graphic = boximg
		self.quad = love.graphics.newQuad(0, 0, 16, 16, 16, 16)
	end
	self.offsetX = 6
	self.offsetY = 3
	self.quadcenterX = 8
	self.quadcenterY = 8
end

function bomb:update(dt: number): boolean
	self.fuse = self.fuse - dt
	if self.fuse > 0 then
		return false
	end
	local cx = math.floor(self.x) + 1
	local cy = math.floor(self.y) + 1
	local offsets: {{number}} = {{0, 0}, {1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for i = 1, #offsets do
		local o = offsets[i]
		local x, y = cx + o[1], cy + o[2]
		if inmap and inmap(x, y) and map and map[x] and map[x][y] and tilequads then
			local tid = map[x][y][1] as number
			local tq = tilequads[tid]
			if tq and tq.getproperty and tq:getproperty("breakable", x, y) and destroyblock then
				destroyblock(x, y)
			end
		end
	end
	if objects and objects["enemy"] then
		for _, e in pairs(objects["enemy"] as {any:{string:any}}) do
			local en = e as {string:any}
			if en and not en.dead and not en.shot then
				local ex = (en.x as number) + ((en.width as number) or 0.75) / 2
				local ey = (en.y as number) + ((en.height as number) or 0.75) / 2
				local dx = ex - (self.x + self.width / 2)
				local dy = ey - (self.y + self.height / 2)
				if dx * dx + dy * dy < 2.25 then
					if en.shotted then
						(en.shotted as function({string:any}, any, any, any, any, any): any)(en, "right", false, false, false, false)
					else
						en.kill = true
					end
				end
			end
		end
	end
	earthquake = math.max((earthquake as number) or 0, 0.3)
	if playsound then
		playsound("blockhit")
	end
	return true
end

function bomb:leftcollide(_: any, _: Entity): boolean
	return false
end

function bomb:rightcollide(_: any, _: Entity): boolean
	return false
end

function bomb:floorcollide(_: any, _: Entity): boolean
	self.speedy = 0
	return false
end

function bomb:ceilcollide(_: any, _: Entity): boolean
	return false
end
