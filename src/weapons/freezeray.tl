--[[ Freeze ray — replace enemy with iceblock (metatable box). ]]

local aimmod = require("weapons.aim") as {string:any}

local RANGE = 7
local COOLDOWN = 0.5
local BEAM_TIME = 0.1

local pick_entity = aimmod.pick_entity as function({string:any}, number|nil): {string:any}|nil
local aim = aimmod.aim as function({string:any}): number, number, number, number, number

local function fire(pl: {string:any}, button: any)
	local _: any = button
	if not pl.weapondelay then
		pl.weapondelay = {}
	end
	local d = pl.weapondelay as {string:number}
	if (d.freezeray or 0) > 0 then
		return
	end

	local target = pick_entity(pl, RANGE)
	d.freezeray = COOLDOWN
	pl.fz_beam = BEAM_TIME
	if playsound then
		playsound("portalgun")
	end

	if target == nil then
		return
	end
	local t = target as {string:any}
	if t.gg_group ~= "enemy" then
		return
	end
	if t.freezeimmune or t.dead or t.shot then
		return
	end

	t.kill = true
	t.drawable = false
	if not iceblock or not iceblock.new then
		return
	end
	if objects and objects["iceblock"] then
		table.insert(objects["iceblock"] as {any},
			(iceblock.new as function(any, {string:any}): any)(iceblock, t))
	end
end

local function update(pl: {string:any}, dt: number)
	if pl.fz_beam then
		pl.fz_beam = math.max(0, (pl.fz_beam as number) - dt)
		if (pl.fz_beam as number) <= 0 then
			pl.fz_beam = nil
		end
	end
end

local function world_to_screen(wx: number, wy: number): number, number
	local xs = (xscroll as number) or 0
	local ys = (yscroll as number) or 0
	local sc = (scale as number) or 1
	return math.floor((wx - xs) * 16 * sc), math.floor((wy - ys - 0.5) * 16 * sc)
end

local function draw(pl: {string:any})
	if not love or not love.graphics then
		return
	end
	local beam = pl.fz_beam as number|nil
	if beam == nil or beam <= 0 then
		return
	end
	local sx, sy, dx, dy = aim(pl)
	local len = RANGE
	local x1, y1 = world_to_screen(sx, sy)
	local x2, y2 = world_to_screen(sx + dx * len, sy + dy * len)
	love.graphics.setColor(0.55, 0.85, 1.0, 0.75)
	love.graphics.setLineWidth(((scale as number) or 1) * 2)
	love.graphics.line(x1, y1, x2, y2)
	love.graphics.setColor(1, 1, 1, 1)
end

local function equip(_: {string:any})
end

local function unequip(_: {string:any})
end

return {
	id = "freezeray",
	name = "freeze ray",
	icon = "assets/graphics/weapons/freezeray.png",
	anim = "portal",
	cooldown = COOLDOWN,
	RANGE = RANGE,
	BEAM_TIME = BEAM_TIME,
	fire = fire,
	update = update,
	draw = draw,
	equip = equip,
	unequip = unequip,
}
