--[[ Portal gun — flat weapon table. Fire path moved from game_mousepressed. ]]

local function fire(pl: {string:any}, button: any)
	if pl.portalgundisabled then
		return
	end
	if pl.pickup then
		return
	end

	local i = 1
	if button == "r" or button == 2 then
		i = 2
	end
	if not (pl.portalsavailable as {boolean})[i] then
		return
	end

	local sourcex = (pl.x as number) + 6 / 16
	local sourcey = (pl.y as number) + 6 / 16
	shootportal(pl.playernumber, i, sourcex, sourcey, pl.pointingangle)
end

local function equip(_: {string:any})
end

local function unequip(_: {string:any})
end

return {
	id = "portal",
	name = "portal gun",
	icon = "assets/graphics/weapons/portalgun.png",
	anim = "portal",
	cooldown = 0.2,
	fire = fire,
	equip = equip,
	unequip = unequip,
}
