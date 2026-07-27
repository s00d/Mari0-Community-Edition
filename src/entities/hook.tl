--[[ Hookshot projectile: flies straight, attaches to solids, pulls enemies/boxes. ]]

rawset(_G, "hook", rawget(_G, "hook") or {})

local HOOK_SPEED = 22
local MAX_LEN = 9

function hook.new(_: hook, x: number, y: number, dx: number, dy: number, owner: any): hook
	local self = setmetatable({}, { __index = hook }) as hook
	self:init(x, y, dx, dy, owner)
	return self
end

function hook:init(x: number, y: number, dx: number, dy: number, owner: any)
	self.width = 8 / 16
	self.height = 8 / 16
	self.x = x - self.width / 2
	self.y = y - self.height / 2
	self.speedx = dx * HOOK_SPEED
	self.speedy = dy * HOOK_SPEED

	self.static = false
	self.active = true
	self.category = 13 -- same as fireball/gravityball: reuse masks
	self.mask = {	true,
					false, true, false, false, true,
					false, true, false, true, false,
					false, true, false, true, false,
					true, true, false, false, false,
					false, true, false, false, true,
					false, false, false, false, true}
	self.gravity = 0
	self.gravitydirection = math.pi / 2
	self.portalable = true
	self.autodelete = true
	self.emancipatecheck = true

	self.owner = owner
	self.travelled = 0
	self.state = "flying"
	self.destroy = false

	self.drawable = true
	self.graphic = fireballimg
	self.quad = fireballquad[1]
	self.offsetX = 4
	self.offsetY = 4
	self.quadcenterX = 4
	self.quadcenterY = 4
	self.rotation = 0
end

function hook:update(dt: number): boolean
	self.rotation = 0
	if self.destroy or self.state ~= "flying" then
		return true
	end

	self.travelled = (self.travelled as number) + HOOK_SPEED * dt
	if (self.travelled as number) > MAX_LEN then
		return true
	end

	if self.quad and fireballquad then
		self.quad = fireballquad[math.floor(((self.travelled as number) / 0.2) % 4) + 1]
	end
	return false
end

function hook:hitstuff(a: any, b: Entity)
	if self.state ~= "flying" then
		return
	end
	if a == "player" then
		return
	end

	local pl = self.owner as {string:any}
	if not pl or not Weapons then
		self.destroy = true
		self.state = "dead"
		return
	end

	local hs = Weapons.get and Weapons.get("hookshot")
	if not hs then
		self.destroy = true
		self.state = "dead"
		return
	end

	if a == "enemy" or a == "bowser" then
		local bag = b as {string:any}
		if bag.hookanchor then
			local ax = self.x + self.width / 2
			local ay = self.y + self.height / 2
			(hs.attach_body as function({string:any}, {string:any}, number, number))(pl, bag, ax, ay)
		else
			(hs.reel_target_to as function({string:any}, {string:any}))(pl, bag)
		end
		self.destroy = true
		self.state = "dead"
		self.active = false
		return
	end

	-- Movable body: swing-attach (anchor follows body).
	if a == "box" or a == "iceblock" or a == "lightbridgebody" then
		local ax = self.x + self.width / 2
		local ay = self.y + self.height / 2
		(hs.attach_body as function({string:any}, {string:any}, number, number))(pl, b as {string:any}, ax, ay)
		self.destroy = true
		self.state = "dead"
		self.active = false
		return
	end

	-- solid attach (tile / portalwall / etc.)
	local ax = self.x + self.width / 2
	local ay = self.y + self.height / 2
	local cox = (b.cox as number) or math.floor(ax) + 1
	local coy = (b.coy as number) or math.floor(ay) + 1
	(hs.attach as function({string:any}, number, number, number, number))(pl, ax, ay, cox, coy)
	self.destroy = true
	self.state = "dead"
	self.active = false
end

function hook:leftcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b)
	return false
end

function hook:rightcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b)
	return false
end

function hook:floorcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b)
	return false
end

function hook:ceilcollide(a: any, b: Entity): boolean
	self:hitstuff(a, b)
	return false
end

function hook:passivecollide(a: any, b: Entity): boolean
	self:hitstuff(a, b)
	return false
end

function hook:emancipate(): any
	self.destroy = true
	self.state = "dead"
	self.active = false
	return nil
end
