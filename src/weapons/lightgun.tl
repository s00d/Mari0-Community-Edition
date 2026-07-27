--[[ Hard light bridge projector — place one lightbridge at surface normal. ]]

local aimmod = require("weapons.aim") as {string:any}

local COOLDOWN = 0.25
local aim_surface = aimmod.aim_surface as function({string:any}): number, number, string
local aim = aimmod.aim as function({string:any}): number, number, number, number, number

local function remove_bridge(pl: {string:any})
	local brn = pl.lb_bridge as {string:any}|nil
	if brn == nil then
		return
	end
	local br = brn as {string:any}
	br.power = false
	if br.updaterange then
		(br.updaterange as function({string:any}))(br)
	end
	br.destroy = true
	pl.lb_bridge = nil
end

local function anchor_solid(br: {string:any}): boolean
	local cox = br.cox as number
	local coy = br.coy as number
	if not map or not map[cox] or not map[cox][coy] then
		return false
	end
	local tid = map[cox][coy][1] as number
	if not tid or not tilequads or not tilequads[tid] then
		return false
	end
	local tq = tilequads[tid]
	if tq.getproperty and tq:getproperty("collision", cox, coy) then
		return true
	end
	return false
end

local function fire(pl: {string:any}, button: any)
	if not pl.weapondelay then
		pl.weapondelay = {}
	end
	local d = pl.weapondelay as {string:number}
	if (d.lightgun or 0) > 0 then
		return
	end
	d.lightgun = COOLDOWN
	pl.lb_flash = 0.1
	if playsound then
		playsound("portalgun")
	end

	if button == "r" or button == 2 then
		remove_bridge(pl)
		return
	end

	local cox, coy, dir = aim_surface(pl)
	if dir == "" then
		return
	end

	remove_bridge(pl)

	if not lightbridge or not lightbridge.new then
		return
	end
	-- Pass dir in r so init's updaterange aims correctly (init defaults to "right").
	local br = (lightbridge.new as function(any, number, number, {any}): {string:any})(
		lightbridge, cox, coy, {"_", "_", dir})
	br.dir = dir
	br.power = true
	br.handheld = pl
	if objects and objects["lightbridge"] then
		table.insert(objects["lightbridge"] as {any}, br)
	end
	if br.updaterange then
		(br.updaterange as function({string:any}))(br)
	end
	pl.lb_bridge = br
end

local function update(pl: {string:any}, dt: number)
	if pl.lb_flash then
		pl.lb_flash = math.max(0, (pl.lb_flash as number) - dt)
		if (pl.lb_flash as number) <= 0 then
			pl.lb_flash = nil
		end
	end
	local brn = pl.lb_bridge as {string:any}|nil
	if brn == nil then
		return
	end
	local br = brn as {string:any}
	if br.destroy or not anchor_solid(br) then
		remove_bridge(pl)
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
	local flash = pl.lb_flash as number|nil
	if flash == nil or flash <= 0 then
		return
	end
	local sx, sy, dx, dy = aim(pl)
	local len = 4
	local x1, y1 = world_to_screen(sx, sy)
	local x2, y2 = world_to_screen(sx + dx * len, sy + dy * len)
	love.graphics.setColor(0.55, 0.85, 1.0, 0.55)
	love.graphics.setLineWidth(((scale as number) or 1) * 2)
	love.graphics.line(x1, y1, x2, y2)
	love.graphics.setColor(1, 1, 1, 1)
end

local function equip(_: {string:any})
end

local function unequip(pl: {string:any})
	remove_bridge(pl)
end

return {
	id = "lightgun",
	name = "hard light",
	icon = "assets/graphics/weapons/lightgun.png",
	anim = "portal",
	cooldown = COOLDOWN,
	fire = fire,
	update = update,
	draw = draw,
	equip = equip,
	unequip = unequip,
	remove_bridge = remove_bridge,
	aim_surface = aim_surface,
}
