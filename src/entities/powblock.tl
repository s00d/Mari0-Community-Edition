--[[ AE POW block — stomping/hitting knocks nearby enemies. Port of mari0_ae/powblock.lua. ]]

rawset(_G, "powblock", rawget(_G, "powblock") or {})

function powblock.new(_: powblock, x: number, y: number): powblock
	local self = setmetatable({}, { __index = powblock }) as powblock
	self:init(x, y)
	return self
end

function powblock:init(x: number, y: number)
	self.x = x - 1
	self.y = y - 1
	self.cox = x
	self.coy = y
	self.width = 1
	self.height = 1
	self.speedx = 0
	self.speedy = 0
	self.static = false
	self.active = true
	self.category = 2
	self.mask = {
		true,
		false, false, false, false, false,
		false, true, false, true, false,
		false, false, true, false, false,
		true, true, false, false, false,
		false, true, true, false, false,
		true, false, true, true, true,
		false, true,
	}
	self.autodelete = true
	self.drawable = true
	self.graphic = powblockimg
	self.quad = love.graphics.newQuad(0, 0, 16, 16, (powblockimg as Image):getWidth(), (powblockimg as Image):getHeight())
	self.offsetX = 8
	self.offsetY = 0
	self.quadcenterX = 8
	self.quadcenterY = 8
	self.rotation = 0
	self.explode = false
	self.explodetimer = 0
	self.scale = 1
end

function powblock:hit()
	if self.explode then
		return
	end
	playsound("blockhit")
	self.explode = true
	self.active = false
	if objects and objects["enemy"] then
		for _, v in pairs(objects["enemy"]) do
			local e = v as enemy
			if e.active and e.shotted and onscreen(e.x, e.y, e.width, e.height) then
				local dir = (math.random(1, 2) == 1) and "left" or "right"
				e:shotted(dir)
			end
		end
	end
end

function powblock:update(dt: number): boolean
	if self.explode then
		self.explodetimer = self.explodetimer + dt
		self.scale = 1 + (math.abs(math.sin(self.explodetimer * 30)) * (1 + self.explodetimer * 5)) / 2
		return self.explodetimer > 0.2
	end
	if self.speedx > 0 then
		self.speedx = math.max(0, self.speedx - friction * dt * 2)
	elseif self.speedx < 0 then
		self.speedx = math.min(0, self.speedx + friction * dt * 2)
	end
	return false
end

function powblock:floorcollide(a: any, _: Entity): any
	if a == "player" then
		self:hit()
	end
	return true
end

function powblock:ceilcollide(a: any, _: Entity): any
	if a == "player" or a == "enemy" then
		self:hit()
	end
	return true
end

function powblock:leftcollide(a: any, _: Entity): any
	if a == "enemy" then
		self:hit()
	end
	return true
end

function powblock:rightcollide(a: any, _: Entity): any
	if a == "enemy" then
		self:hit()
	end
	return true
end
