--[[ Gel cannon — hold-to-fire moved from game_update playertype chain. ]]

local function fire(pl: {string:any}, button: any)
	if not pl.weapondelay then
		pl.weapondelay = {}
	end
	local d = pl.weapondelay as {string:number}
	if (d.gel or 0) > 0 then
		return
	end
	d.gel = gelcannondelay or 0.05
	local i = 1
	if button == "r" or button == 2 then
		i = 2
	end
	(pl.shootgel as function({string:any}, any))(pl, i)
end

local function hold(pl: {string:any}, button: any, _: number)
	fire(pl, button)
end

local function equip(_: {string:any})
end

local function unequip(_: {string:any})
end

return {
	id = "gel",
	name = "gel cannon",
	icon = "assets/graphics/gel1.png",
	anim = "gelcannon",
	cooldown = gelcannondelay or 0.05,
	fire = fire,
	hold = hold,
	equip = equip,
	unequip = unequip,
}
