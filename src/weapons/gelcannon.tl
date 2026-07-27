--[[ Gel cannon — hold-to-fire moved from game_update playertype chain. ]]

local function fire(pl: {string:any}, button: any)
	if not pl.weapondelay then
		pl.weapondelay = {}
	end
	local d = pl.weapondelay as {string:number}
	if (d.gelcannon or d.gel or 0) > 0 then
		return
	end
	local delay = gelcannondelay or 0.09
	d.gelcannon = delay
	d.gel = delay
	local i = 1
	if button == "r" or button == 2 then
		i = 2
	end
	if gel_pool_prepare then
		gel_pool_prepare()
	end
	if pl.shootgel then
		(pl.shootgel as function({string:any}, any))(pl, i)
	end
end

local function hold(pl: {string:any}, button: any, _: number)
	fire(pl, button)
end

local function equip(_: {string:any})
end

local function unequip(_: {string:any})
end

return {
	id = "gelcannon",
	name = "gel cannon",
	icon = "assets/graphics/weapons/gelcannon.png",
	anim = "gelcannon",
	cooldown = gelcannondelay or 0.09,
	fire = fire,
	hold = hold,
	equip = equip,
	unequip = unequip,
}
