--[[ Black Hole Gun — fires a singularity that sucks then flings. ]]

local aimmod = require("weapons.aim") as {string:any}
local aim = aimmod.aim as function({string:any}): number, number, number, number, number
local bhfx = require("weapons.blackhole_fx") as {string:any}

local COOLDOWN = 0.9

local function on_cooldown(pl: {string:any}): boolean
	local d = pl.weapondelay as {string:number}|nil
	if d == nil then
		return false
	end
	return ((d as {string:number}).blackhole or 0) > 0
end

local function fire(pl: {string:any}, button: any)
	local lmb = button == "l" or button == 1
	if not lmb then
		return
	end
	if on_cooldown(pl) then
		return
	end
	if not blackhole or not blackhole.new then
		return
	end
	local sx, sy, dx, dy = aim(pl)
	local list = session.objects and session.objects["blackhole"] as {any}|nil
	if list == nil then
		list = {} as {any}
		if session.objects then
			session.objects["blackhole"] = list as {any:Entity}
		end
	end
	-- One active hole at a time: despawn previous flying/sucking
	local holes = list as {any}
	for i = #holes, 1, -1 do
		local h = holes[i] as {string:any}
		if h and (h.state == "flying" or h.state == "sucking") then
			h.state = "blast"
			h.phasetimer = 99
		end
	end
	local fx = sx + dx * 0.7
	local fy = sy + dy * 0.7
	table.insert(holes, (blackhole.new as function(any, number, number, number, number, any): any)(
		blackhole, fx, fy, dx, dy, pl))

	if not pl.weapondelay then
		pl.weapondelay = {}
	end
	(pl.weapondelay as {string:number}).blackhole = COOLDOWN
	if bhfx.pulse_muzzle then
		(bhfx.pulse_muzzle as function(number, number))(fx, fy)
	end
	if playsound then
		playsound("fireball")
	end
	pl.speedx = ((pl.speedx as number) or 0) - dx * 2
	pl.speedy = ((pl.speedy as number) or 0) - dy * 2
	pl.falling = true
end

local function equip(_: {string:any})
end

local function unequip(_: {string:any})
end

return {
	id = "blackhole",
	name = "black hole gun",
	icon = "assets/graphics/weapons/blackhole.png",
	anim = "portal",
	cooldown = COOLDOWN,
	fire = fire,
	equip = equip,
	unequip = unequip,
}
