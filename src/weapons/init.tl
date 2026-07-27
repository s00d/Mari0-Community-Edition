--[[ Weapon registry + dispatcher. Only entry points: fire/hold/update/draw/switch/release. ]]

local portalgun = require("weapons.portalgun") as {string:any}
local gelcannon = require("weapons.gelcannon") as {string:any}
local gravitygun = require("weapons.gravitygun") as {string:any}

local registry: {string:{string:any}} = {
	portal = portalgun,
	gel = gelcannon,
	gravitygun = gravitygun,
}

local icon_cache: {string:any} = {}

local function get(id: string): {string:any}
	return registry[id]
end

local function current(pl_any: any): {string:any}
	local pl = pl_any as {string:any}
	if not pl or not pl.weapons or not pl.weaponi then
		return nil as {string:any}
	end
	local id = (pl.weapons as {string})[pl.weaponi as integer]
	if id then
		return registry[id]
	end
	return nil as {string:any}
end

local function icon_image(path: string): any
	if icon_cache[path] then
		return icon_cache[path]
	end
	-- load via AssetStore (newImage confined to assets/boot by lint)
	if AssetStore and AssetStore.load_image then
		local ok, img = pcall(AssetStore.load_image, path)
		if ok and img then
			icon_cache[path] = img
			return img
		end
	end
	return nil
end

local function default_loadout(): {string}
	if levelweapons and #levelweapons > 0 then
		local out = {} as {string}
		for i = 1, #levelweapons do
			local id = levelweapons[i]
			if registry[id] then
				table.insert(out, id)
			end
		end
		if #out > 0 then
			return out
		end
	end
	local list = {} as {string}
	if playertype == "gelcannon" then
		table.insert(list, "gel")
	elseif portalsavailable and (portalsavailable[1] or portalsavailable[2]) then
		table.insert(list, "portal")
	end
	table.insert(list, "gravitygun")
	return list
end

local function setup_player(pl_any: any)
	local pl = pl_any as {string:any}
	pl.weapons = default_loadout()
	pl.weaponi = 1
	pl.weapondelay = pl.weapondelay or {}
	pl.gg_state = "idle"
	pl.gg_pulling = nil
	pl.gg_vx = 0
	pl.gg_vy = 0
	local w = current(pl)
	if w and w.equip then
		(w.equip as function({string:any}))(pl)
	end
end

local function give(pl_any: any, id: string)
	local pl = pl_any as {string:any}
	if not registry[id] or not pl.weapons then
		return
	end
	local list = pl.weapons as {string}
	for i = 1, #list do
		if list[i] == id then
			pl.weaponi = i
			return
		end
	end
	table.insert(list, id)
	pl.weaponi = #list
	local w = registry[id]
	if w.equip then
		(w.equip as function({string:any}))(pl)
	end
end

local function release(pl_any: any, reason: string)
	local pl = pl_any as {string:any}
	if not pl then
		return
	end
	(gravitygun.release_obj as function({string:any}, string))(pl, reason or "release")
end

local function switch(pl_any: any, dir: number)
	local pl = pl_any as {string:any}
	if not pl or not pl.weapons or #(pl.weapons as {any}) < 2 then
		return
	end
	local list = pl.weapons as {string}
	local cur = current(pl)
	if cur and cur.unequip then
		(cur.unequip as function({string:any}))(pl)
	end
	local i = (pl.weaponi as integer) + (dir >= 0 and 1 or -1)
	if i < 1 then
		i = #list
	elseif i > #list then
		i = 1
	end
	pl.weaponi = i
	local nxt = current(pl)
	if nxt and nxt.equip then
		(nxt.equip as function({string:any}))(pl)
	end
end

local function fire(pl_any: any, button: any)
	local pl = pl_any as {string:any}
	local w = current(pl)
	if w and w.fire then
		(w.fire as function({string:any}, any))(pl, button)
	end
end

local function hold(pl_any: any, button: any, dt: number)
	local pl = pl_any as {string:any}
	local w = current(pl)
	if w and w.hold then
		(w.hold as function({string:any}, any, number))(pl, button, dt)
	end
end

local function update(pl_any: any, dt: number)
	local pl = pl_any as {string:any}
	if not pl or not pl.weapondelay then
		return
	end
	local d = pl.weapondelay as {string:number}
	local tick = dt
	if speed and speed ~= 0 then
		tick = dt / speed
	end
	for k, v in pairs(d) do
		if v > 0 then
			d[k] = math.max(0, v - tick)
			if k == "portal" and portaldelay and pl.playernumber then
				portaldelay[pl.playernumber as number] = d[k]
			end
		end
	end
	local w = current(pl)
	if w and w.update then
		(w.update as function({string:any}, number))(pl, dt)
	end
end

local function update_all(dt: number)
	if not playerobjs then
		return
	end
	for i = 1, players do
		local pl = playerobjs[i]
		if pl and not pl.dead then
			update(pl, dt)
			if i == mouseowner and pl.controlsenabled and not pl.vine then
				local w = current(pl)
				if w and w.hold then
					if love.mouse.isDown(1) then
						hold(pl, "l", dt)
					elseif love.mouse.isDown(2) then
						hold(pl, "r", dt)
					end
				end
			end
		end
	end
end

local function draw(pl_any: any)
	local pl = pl_any as {string:any}
	local w = current(pl)
	if w and w.draw then
		(w.draw as function({string:any}))(pl)
	end
end

local function draw_hud(pl_any: any)
	local pl = pl_any as {string:any}
	if not pl or not pl.weapons or editormode then
		return
	end
	local list = pl.weapons as {string}
	if #list < 1 then
		return
	end
	local slot = 18
	local base_x = 8
	local base_y = 28
	for i = 1, #list do
		local id = list[i]
		local w = registry[id]
		local x = base_x + (i - 1) * slot
		local y = base_y
		if i == pl.weaponi then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.rectangle("line", x * scale - 1, y * scale - 1, 17 * scale, 17 * scale)
		else
			love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
		end
		local img = w and icon_image(w.icon as string)
		if img then
			love.graphics.setColor(1, 1, 1, i == pl.weaponi and 1 or 0.55)
			love.graphics.draw(img, x * scale, y * scale, 0, scale / 2, scale / 2)
		else
			love.graphics.setColor(i == pl.weaponi and 1 or 0.4, 0.8, 0.2, 1)
			love.graphics.rectangle("fill", x * scale, y * scale, 16 * scale, 16 * scale)
		end
	end
	love.graphics.setColor(1, 1, 1, 1)
end

local Weapons: WeaponsModule = {
	registry = registry,
	gravitygun = gravitygun,
	get = get,
	current = current,
	icon_image = icon_image,
	default_loadout = default_loadout,
	setup_player = setup_player,
	give = give,
	release = release,
	switch = switch,
	fire = fire,
	hold = hold,
	update = update,
	update_all = update_all,
	draw = draw,
	draw_hud = draw_hud,
}

rawset(_G, "Weapons", Weapons)

return Weapons
