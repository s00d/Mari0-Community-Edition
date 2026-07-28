--[[ Ability table + ability-gated doors (F1/F2). openmv MIT — licenses/openmv.MIT ]]

global ABILITIES: {string:{string:string}} = {
	portal = { name = "Portal Device", gate = "blue" },
	gravitygun = { name = "Grav Manipulator", gate = "green" },
	hookshot = { name = "Grapple", gate = "gap" },
	gelcannon = { name = "Gel Sprayer", gate = "wall" },
	morphball = { name = "Morph Ball", gate = "morph" },
	highjump = { name = "High Jump", gate = "high" },
}

global ABILITY_TEXT: {string:string} = {
	portal = "Create linked portals.", gravitygun = "Grab and fling objects.",
	hookshot = "Grapple across gaps.", gelcannon = "Spray propulsion gels.",
	morphball = "Fit through one-tile shafts.", highjump = "Jump higher.",
}

global DOOR_TYPES: {string:function(any, any): boolean} = {
	open = function(_: any, _: any): boolean return true end,
	blue = function(pl: any, _: any): boolean return has_weapon(pl, "portal") or has_ability(pl, "portal") end,
	red = function(pl: any, _: any): boolean return has_weapon(pl, "hookshot") or has_ability(pl, "hookshot") end,
	green = function(pl: any, _: any): boolean return has_weapon(pl, "gravitygun") or has_ability(pl, "gravitygun") end,
	bomb = function(pl: any, _: any): boolean
		local ch = pl and (pl as {string:any}).char as {string:any}
		return ch ~= nil and ((ch.bomb and true) or (ch.bomber and true))
	end,
	morph = function(pl: any, _: any): boolean
		local p = pl as {string:any}
		return p ~= nil and (p.morphed and true or has_ability(pl, "morphball"))
	end,
	key = function(_: any, d: any): boolean
		local dd = d as {string:any}
		local kid = dd and (dd.keyid or dd.key)
		return kid ~= nil and globoolSH("key_" .. tostring(kid), "check")
	end,
}

global DOOR_COLOR: {string:{number}} = {
	open = {0.75, 0.75, 0.80, 1}, blue = {0.25, 0.55, 1.00, 1}, red = {0.95, 0.25, 0.25, 1},
	green = {0.25, 0.85, 0.35, 1}, bomb = {0.95, 0.70, 0.20, 1}, morph = {0.70, 0.40, 0.95, 1}, key = {1.00, 0.84, 0.22, 1},
}

global function has_weapon(pl_any: any, id: string): boolean
	local pl = pl_any as {string:any}
	if not pl or not pl.weapons then return false end
	local list = pl.weapons as {string}
	for i = 1, #list do
		local w = list[i]
		if w == id or (id == "gelcannon" and w == "gel") or (id == "gel" and w == "gelcannon") then return true end
	end
	return false
end

global function has_ability(pl_any: any, id: string): boolean
	if globoolSH("ability_" .. id, "check") then return true end
	if id == "portal" or id == "gravitygun" or id == "hookshot" or id == "gelcannon" then
		return has_weapon(pl_any, id)
	end
	local pl = pl_any as {string:any}
	if id == "morphball" and pl and pl.char then return ((pl.char as {string:any}).morphball and true) end
	return false
end

local function apply_ability_effects(pl_any: any, id: string)
	local pl = pl_any as {string:any}
	if Weapons and Weapons.give and (id == "portal" or id == "gravitygun" or id == "hookshot" or id == "gelcannon") then
		Weapons.give(pl, id)
	end
	if id == "morphball" and pl then
		if not pl.char then pl.char = {} end
		(pl.char as {string:any}).morphball = true
	end
	if id == "highjump" and pl then pl.metroid_highjump = 1.35 end
end

global function grant_ability(pl_any: any, id: string)
	if not ABILITIES[id] then return end
	globoolSH("ability_" .. id, "true")
	apply_ability_effects(pl_any, id)
	local def = ABILITIES[id]
	if notice and notice.new then notice.new(def.name .. " GET", notice.white, 2) end
	if createdialogbox and ABILITY_TEXT[id] then createdialogbox(ABILITY_TEXT[id], def.name) end
end

-- Re-apply owned abilities after player respawn / nextlevel (globools persist; player does not).
global function metroid_reapply_abilities(pl_any: any)
	if not pl_any or not ABILITIES then return end
	for id in pairs(ABILITIES) do
		if globoolSH("ability_" .. id, "check") then
			apply_ability_effects(pl_any, id)
		end
	end
end

global function door_uid(x: number, y: number): string
	if tilekey then return tostring(tilekey(x, y)) end
	return tostring(math.floor(x)) .. "_" .. tostring(math.floor(y))
end

global function door_is_open(uid: string): boolean
	return globoolSH("door_" .. uid, "check")
end

global function door_set_open(uid: string, open: boolean)
	globoolSH("door_" .. uid, open and "true" or "false")
end

global function door_can_pass(kind: string, pl_any: any, door_data: any): boolean
	local fn = DOOR_TYPES[kind or "open"]
	return fn ~= nil and fn(pl_any, door_data)
end

global function fake_player_from_abilities(have: {string:boolean}): {string:any}
	local weapons: {string} = {}
	local char: {string:any} = {}
	for id, on in pairs(have) do
		if on then
			if id == "morphball" then char.morphball = true
			elseif id == "bomb" then char.bomb = true
			elseif id == "portal" or id == "gravitygun" or id == "hookshot" or id == "gelcannon" then
				table.insert(weapons, id)
			end
		end
	end
	return { weapons = weapons, char = char, morphed = have["morphball"] == true }
end

global function door_try_open(uid: string, kind: string, pl_any: any, door_data: any): boolean
	if door_is_open(uid) then return true end
	if door_can_pass(kind, pl_any, door_data) then door_set_open(uid, true); return true end
	return false
end

return {
	ABILITIES = ABILITIES, DOOR_TYPES = DOOR_TYPES, DOOR_COLOR = DOOR_COLOR,
	has_ability = has_ability, grant_ability = grant_ability, has_weapon = has_weapon,
	door_can_pass = door_can_pass, door_try_open = door_try_open, door_uid = door_uid,
	fake_player_from_abilities = fake_player_from_abilities,
	metroid_reapply_abilities = metroid_reapply_abilities,
}
