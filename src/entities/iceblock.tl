--[[ Ice block — frozen enemy stand-in. Metatable inherits box physics. ]]

rawset(_G, "iceblock", rawget(_G, "iceblock") or {})
setmetatable(iceblock as {any}, { __index = box })

local THAW_TIME = 8.0
local SHATTER_SPEED = 14.0

local function unfreeze(self: {string:any}, restore: boolean)
	if self.beamed and Weapons then
		Weapons.release(self.beamed as {string:any}, "thaw")
	end
	if restore and self.victim_t and enemy and enemy.new then
		local e = (enemy.new as function(any, number, number, string, any): {string:any})(
			enemy, 1, 1, self.victim_t as string, nil)
		e.x = self.x
		e.y = self.y
		e.animationdirection = self.victim_dir
		if objects and objects["enemy"] then
			table.insert(objects["enemy"] as {any}, e)
		end
	end
	if blockdebristable and blockdebris and blockdebris.new then
		for i = 1, 4 do
			table.insert(blockdebristable as {any}, (blockdebris.new as function(any, number, number, number, number): any)(
				blockdebris, self.x as number, self.y as number,
				(i % 2 == 0) and 4 or -4, -6 + math.floor(i / 2) * 3))
		end
	end
	if playsound then
		playsound("blockhit")
	end
end

function iceblock.new(_: iceblock, victim: {string:any}): iceblock
	local self = setmetatable({}, { __index = iceblock }) as {string:any}
	local cox = (victim.cox as number) or math.floor((victim.x as number) + 1)
	local coy = (victim.coy as number) or math.floor((victim.y as number) + 1)
	;(box.init as function({string:any}, number, number))(self, cox, coy)

	self.x = victim.x as number
	self.y = victim.y as number
	self.victim_t = victim.t
	self.victim_dir = victim.animationdirection
	self.thaw = THAW_TIME
	self.frozen = true
	self.graphic = victim.graphic
	self.quad = victim.quad
	self.offsetX = victim.offsetX or self.offsetX
	self.offsetY = victim.offsetY or self.offsetY
	self.quadcenterX = victim.quadcenterX or self.quadcenterX
	self.quadcenterY = victim.quadcenterY or self.quadcenterY
	local vw = (victim.width as number) or 0.75
	local vh = (victim.height as number) or 0.75
	if vw < 0.75 then vw = 0.75 end
	if vh < 0.75 then vh = 0.75 end
	self.width = vw
	self.height = vh
	self.grabbable = true
	self.gg_group = "iceblock"
	return self as iceblock
end

function iceblock.melt(self: iceblock)
	unfreeze(self as {string:any}, true)
end

function iceblock.shatter(self: iceblock)
	unfreeze(self as {string:any}, false)
end

function iceblock.update(self: iceblock, dt: number): boolean
	local s = self as {string:any}
	s.thaw = (s.thaw as number) - dt
	if (s.thaw as number) <= 0 then
		iceblock.melt(self)
		return true
	end
	local sy = (s.speedy as number) or 0
	local sx = (s.speedx as number) or 0
	if math.abs(sy) > SHATTER_SPEED or math.abs(sx) > SHATTER_SPEED then
		iceblock.shatter(self)
		return true
	end
	return (box.update as function({string:any}, number): boolean)(s, dt)
end
