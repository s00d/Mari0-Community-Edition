--[[ Mari0 1.6 → CE entity remaps (tables, not if-chains).
   Enemies become string names (JSON under assets/enemies/).
   Variant entities (doors, gels, platforms, …) collapse into one CE id + params.
   PASS_THROUGH ids keep the numeric CE slot (same/compatible meaning). ]]

-- Old 1.6 entitylist names (1-indexed), for coverage reports.
global OLD_ENTITY_NAMES: {string} = {
	"remove", "mushroom", "oneup", "star", "manycoins", "goomba", "koopa", "spawn",
	"goombahalf", "koopahalf", "flag", "koopared", "kooparedhalf", "vine", "hammerbro",
	"cheepred", "cheepwhite", "platformup", "platformright", "box", "pipe", "lakito",
	"mazestart", "mazeend", "mazegate", "emancehor", "emancever", "doorver", "doorhor",
	"wallindicator", "pipespawn", "platformfall", "bulletbillstart", "bulletbillend",
	"drain", "lightbridgeright", "lightbridgeleft", "lightbridgedown", "lightbridgeup",
	"button", "platformspawnerdown", "platformspawnerup", "groundlightver", "groundlighthor",
	"groundlightupright", "groundlightrightdown", "groundlightdownleft", "groundlightleftup",
	"faithplateup", "faithplateright", "faithplateleft", "laserright", "laserdown",
	"laserleft", "laserup", "laserdetectorright", "laserdetectordown", "laserdetectorleft",
	"laserdetectorup", "bulletbill", "bluegeldown", "bluegelright", "bluegelleft",
	"orangegeldown", "orangegelright", "orangegelleft", "boxtube", "pushbuttonleft",
	"pushbuttonright", "plant", "whitegeldown", "whitegelright", "whitegelleft", "timer",
	"beetle", "beetlehalf", "kooparedflying", "koopaflying", "castlefireccw", "seesaw",
	"warppipe", "castlefirecw", "lakitoend", "notgate", "geltop", "gelleft", "gelbottom",
	"gelright", "firestart", "bowser", "axe", "platformbonus", "spring", "squid",
	"flyingfishstart", "flyingfishend", "upfire", "spikey", "spikeyhalf", "checkpoint",
}

-- old_id → enemy JSON basename (assets/enemies/<name>.json)
global ENEMY_REMAP: {number:string} = {
	[3] = "oneup",
	[4] = "star",
	[6] = "goomba",
	[7] = "koopa",
	[9] = "goombahalf",
	[10] = "koopahalf",
	[12] = "koopared",
	[13] = "kooparedhalf",
	[15] = "hammerbros",
	[22] = "lakito",
	[70] = "plant",
	[75] = "beetle",
	[76] = "beetlehalf",
	[77] = "kooparedflying",
	[78] = "koopaflying",
	[94] = "squid",
	[97] = "upfire",
	[98] = "spikey",
	[99] = "spikeyhalf",
}

--[[ Variant descriptors (old_id → kind + static fields).
   kind values consumed by convertentity:
     spawn, cheep, platform, pipe_dest, emance, door, lightbridge,
     platformspawner, faithplate, laser, laserdetector, geldispenser,
     pushbutton, castlefire, seesaw, notgate, gel, checkpoint
   Fields: kind, ce_id?, dir?, vx?, vy?, ccw?, gel_id?, top?, left?, bottom?, right? ]]
global VARIANT_REMAP: {number:{string:any}} = {
	[8] = {kind = "spawn"},
	[14] = {kind = "pipe_dest", ce_id = 14},
	[16] = {kind = "cheep"},
	[17] = {kind = "cheep"},
	[18] = {kind = "platform", dir = "up"},
	[19] = {kind = "platform", dir = "right"},
	[21] = {kind = "pipe_dest", ce_id = 21},
	[26] = {kind = "emance", dir = "hor"},
	[27] = {kind = "emance", dir = "ver"},
	[28] = {kind = "door", dir = "ver"},
	[29] = {kind = "door", dir = "hor"},
	[30] = {kind = "wallindicator"},
	[31] = {kind = "pipespawn"},
	[36] = {kind = "lightbridge", dir = "right"},
	[37] = {kind = "lightbridge", dir = "left"},
	[38] = {kind = "lightbridge", dir = "down"},
	[39] = {kind = "lightbridge", dir = "up"},
	[41] = {kind = "platformspawner", dir = "down"},
	[42] = {kind = "platformspawner", dir = "up"},
	[49] = {kind = "faithplate", vx = 0, vy = 40},
	[50] = {kind = "faithplate", vx = 30, vy = 30},
	[51] = {kind = "faithplate", vx = -30, vy = 30},
	[52] = {kind = "laser", dir = "right"},
	[53] = {kind = "laser", dir = "down"},
	[54] = {kind = "laser", dir = "left"},
	[55] = {kind = "laser", dir = "up"},
	[56] = {kind = "laserdetector", dir = "right"},
	[57] = {kind = "laserdetector", dir = "down"},
	[58] = {kind = "laserdetector", dir = "left"},
	[59] = {kind = "laserdetector", dir = "up"},
	[61] = {kind = "geldispenser", dir = "down", gel_id = 1},
	[62] = {kind = "geldispenser", dir = "right", gel_id = 1},
	[63] = {kind = "geldispenser", dir = "left", gel_id = 1},
	[64] = {kind = "geldispenser", dir = "down", gel_id = 2},
	[65] = {kind = "geldispenser", dir = "right", gel_id = 2},
	[66] = {kind = "geldispenser", dir = "left", gel_id = 2},
	[68] = {kind = "pushbutton", dir = "left"},
	[69] = {kind = "pushbutton", dir = "right"},
	[71] = {kind = "geldispenser", dir = "down", gel_id = 3},
	[72] = {kind = "geldispenser", dir = "right", gel_id = 3},
	[73] = {kind = "geldispenser", dir = "left", gel_id = 3},
	[79] = {kind = "castlefire", ccw = true},
	[80] = {kind = "seesaw"},
	[82] = {kind = "castlefire", ccw = false},
	[84] = {kind = "notgate"},
	[85] = {kind = "gel", top = true, left = false, bottom = false, right = false},
	[86] = {kind = "gel", top = false, left = true, bottom = false, right = false},
	[87] = {kind = "gel", top = false, left = false, bottom = true, right = false},
	[88] = {kind = "gel", top = false, left = false, bottom = false, right = true},
	[100] = {kind = "checkpoint"},
}

-- Old ids that intentionally keep the CE numeric slot (compatible meaning).
global PASS_THROUGH: {number:boolean} = {
	[1] = true, -- remove
	[2] = true, -- mushroom → powerup slot
	[5] = true, -- manycoins
	[11] = true, -- flag
	[20] = true, -- box
	[23] = true, -- mazestart
	[24] = true, -- mazeend
	[25] = true, -- mazegate
	[32] = true, -- platformfall
	[33] = true, -- bulletbillstart
	[34] = true, -- bulletbillend
	[35] = true, -- drain
	[40] = true, -- actionblock (1.6 id 40 was button → emit 41)
	[43] = true, [44] = true, [45] = true, [46] = true, [47] = true, [48] = true, -- groundlights
	[60] = true, -- bulletbill
	[67] = true, -- boxtube
	[74] = true, -- timer → walltimer slot
	[81] = true, -- warppipe
	[83] = true, -- lakitoend
	[89] = true, -- firestart
	[90] = true, -- bowser
	[91] = true, -- axe
	[92] = true, -- platformbonus
	[93] = true, -- spring
	[95] = true, -- flyingfishstart
	[96] = true, -- flyingfishend
}

-- CE entity id → ordered link port names (for CLI / no rightclickmenues).
global ENTITY_LINK_TYPES: {number:{string}} = {
	[26] = {"power"}, -- emance
	[28] = {"open"}, -- door
	[30] = {"power"}, -- wallindicator
	[36] = {"power"}, -- lightbridge
	[44] = {"power"}, [45] = {"power"}, [46] = {"power"},
	[47] = {"power"}, [48] = {"power"}, [49] = {"power"},
	[50] = {"power"}, -- faithplate
	[53] = {"power"}, -- laser
	[62] = {"power"}, -- geldispenser
	[67] = {"drop"}, -- boxtube
	[74] = {"power"}, -- walltimer
	[84] = {"in"}, -- notgate
}

-- Seesaw presets from Mari0 1.6 (index = old param).
global SEESAW_PRESETS: {{number}} = {
	{7, 4, 6, 3}, {4, 2, 6, 3}, {7, 3, 6, 3}, {8, 3, 7, 3}, {5, 3, 7, 3},
	{6, 3, 7, 3}, {4, 3, 7, 1.5}, {3, 3, 7, 1.5}, {3, 4, 7, 1.5},
}

-- CE entitylist index → type name for ids used as remap targets / pass-through.
-- Empty string = unused slot (must not be a remap target).
global CE_ENTITY_TYPES: {number:string} = {
	[1] = "remove", [2] = "powerup", [3] = "cheepcheep", [5] = "manycoins",
	[8] = "spawn", [11] = "flag", [14] = "vine", [18] = "platform",
	[20] = "box", [21] = "pipe", [23] = "mazestart", [24] = "mazeend",
	[25] = "mazegate", [26] = "emance", [28] = "door", [30] = "pedestal",
	[31] = "wallindicator",
	[32] = "pipespawn", [33] = "platformfall", [34] = "bulletbillstart",
	[35] = "bulletbillend", [36] = "drain", [37] = "lightbridge", [40] = "actionblock",
	[41] = "button", [42] = "platformspawner", [43] = "animationtrigger",
	[44] = "groundlightver", [45] = "groundlighthor",
	[46] = "groundlightupright", [47] = "groundlightrightdown",
	[48] = "groundlightdownleft", [49] = "groundlightleftup",
	[50] = "faithplate", [53] = "laser", [57] = "laserdetector",
	[61] = "bulletbill", [62] = "geldispenser",
	[67] = "boxtube", [68] = "pushbutton", [74] = "walltimer", [79] = "castlefire",
	[80] = "seesaw", [81] = "warppipe", [83] = "lakitoend", [84] = "notgate",
	[85] = "gel", [89] = "firestart", [90] = "bowser", [91] = "axe",
	[92] = "platformbonus", [93] = "spring", [95] = "flyingfishstart",
	[96] = "flyingfishend", [100] = "checkpoint",
}

global function remap_kind(old_id: number): string
	if ENEMY_REMAP[old_id] then
		return "enemy"
	elseif VARIANT_REMAP[old_id] then
		return "variant"
	elseif PASS_THROUGH[old_id] then
		return "pass"
	end
	return "unknown"
end

-- 1.6 pass-through ids → current CE entitylist slot (actionblock/animationtrigger shifted +1 from 40).
local PASS_THROUGH_CE_EMIT: {number:number} = {
	[40] = 41, -- button
	[43] = 44, [44] = 45, [45] = 46, [46] = 47, [47] = 48, [48] = 49, -- groundlights
	[60] = 61, -- bulletbill
}

-- Platformspawner dirs are only up/down, and shipped cells always carry size/speed
-- params after dir. Floor buttons also use "down"/"up" — do not treat bare dir as spawner.
local function is_platformspawner_cell(r: {any}): boolean
	local p3 = r[3]
	if tonumber(p3) ~= nil then
		return true
	end
	if (p3 == "up" or p3 == "down") and #r >= 4 then
		return true
	end
	return false
end

local function is_legacy_floor_button_cell(r: {any}): boolean
	local p3 = r[3]
	return p3 == nil or p3 == "down" or p3 == "up" or p3 == "left" or p3 == "right" or p3 == "link"
end

local function is_legacy_laser_dir(p3: any): boolean
	return p3 == "right" or p3 == "left" or p3 == "up" or p3 == "down"
end

-- Mari0 1.6 pipespawn was entity id 31; CE shifted wallindicator to 31 and pipespawn to 32.
-- Portal / early CE mappacks still store platformspawner at 41 (now button) and groundlights at 43–48.
global function normalize_legacy_map_entity(r: {any})
	local ent = r[2]
	if type(ent) ~= "number" then
		return
	end
	local e = ent as number

	if e == 31 and type(r[3]) == "number" then
		r[2] = 32
		return
	end

	if e == 42 and is_platformspawner_cell(r) then
		return
	end
	if e == 41 and not is_platformspawner_cell(r) and is_legacy_floor_button_cell(r) then
		return
	end

	if e == 41 and is_platformspawner_cell(r) then
		r[2] = 42
		return
	end

	if e == 40 and is_legacy_floor_button_cell(r) then
		r[2] = 41
		return
	end

	if e >= 43 and e <= 48 and r[3] == "link" then
		r[2] = e + 1
		return
	end

	-- 1.6 directional lasers lived at 52–55; CE laser slot is 53.
	if e >= 52 and e <= 55 and is_legacy_laser_dir(r[3]) then
		r[2] = 53
		return
	end

	-- 1.6 laserdetectors 56–59 → CE 57
	if e >= 56 and e <= 59 and is_legacy_laser_dir(r[3]) then
		r[2] = 57
		return
	end

	-- Pass-through slots that gained an empty hole (bulletbill 60→61, …)
	local emit = PASS_THROUGH_CE_EMIT[e]
	if emit and (entitylist == nil or entitylist[e] == nil or entitylist[e].t == nil or entitylist[e].t == "") then
		r[2] = emit
		return
	end

	-- Legacy enemy ids still stored numerically when the CE slot is empty
	local enemy_name = ENEMY_REMAP[e]
	if enemy_name and (entitylist == nil or entitylist[e] == nil or entitylist[e].t == nil or entitylist[e].t == "") then
		r[2] = enemy_name
		return
	end
end

global function pass_through_ce_id(old_id: number): number
	local mapped = PASS_THROUGH_CE_EMIT[old_id]
	if mapped then
		return mapped
	end
	return old_id
end

--[[ Validate remaps against enemy JSON files and CE entity slots.
   opts.enemy_json_exists(name) → bool
   Returns list of problem strings (empty = ok). ]]
global function validate_remap(opts: {string:any}|nil): {string}
	local problems: {string} = {}
	local o = (opts or {}) as {string:any}
	local enemy_exists_raw: any = o["enemy_json_exists"]
	local ce_types = (o["ce_entity_types"] or CE_ENTITY_TYPES) as {any:any}

	for id, name in pairs(ENEMY_REMAP) do
		if type(enemy_exists_raw) == "function" and not (enemy_exists_raw as function(string): boolean)(name) then
			table.insert(problems, string.format("ENEMY_REMAP[%s]=%s missing assets/enemies/%s.json", tostring(id), name, name))
		end
	end

	for id, vr in pairs(VARIANT_REMAP) do
		local kind = tostring(vr["kind"] or "")
		local ce: any = vr["ce_id"]
		if kind == "cheep" then
			ce = 3
		elseif kind == "spawn" then
			ce = 8
		elseif kind == "platform" then
			ce = 18
		elseif kind == "emance" then
			ce = 26
		elseif kind == "door" then
			ce = 28
		elseif kind == "lightbridge" then
			ce = 36
		elseif kind == "platformspawner" then
			ce = 42
		elseif kind == "faithplate" then
			ce = 50
		elseif kind == "laser" then
			ce = 53
		elseif kind == "laserdetector" then
			ce = 57
		elseif kind == "geldispenser" then
			ce = 62
		elseif kind == "pushbutton" then
			ce = 68
		elseif kind == "castlefire" then
			ce = 79
		elseif kind == "seesaw" then
			ce = 80
		elseif kind == "notgate" then
			ce = 84
		elseif kind == "gel" then
			ce = 85
		elseif kind == "checkpoint" then
			ce = 100
		elseif kind == "pipe_dest" then
			ce = vr["ce_id"]
		end
		if ce then
			local t = ce_types[ce]
			if not t or t == "" then
				table.insert(problems, string.format("VARIANT_REMAP[%s] kind=%s targets empty CE slot %s", tostring(id), kind, tostring(ce)))
			end
		end
	end

	for id, _ in pairs(PASS_THROUGH) do
		local ce_id = pass_through_ce_id(id)
		local t = ce_types[ce_id]
		if not t or t == "" then
			table.insert(problems, string.format("PASS_THROUGH[%s] emits empty CE slot %s", tostring(id), tostring(ce_id)))
		end
	end

	return problems
end

	return {
	OLD_ENTITY_NAMES = OLD_ENTITY_NAMES,
	ENEMY_REMAP = ENEMY_REMAP,
	VARIANT_REMAP = VARIANT_REMAP,
	PASS_THROUGH = PASS_THROUGH,
	ENTITY_LINK_TYPES = ENTITY_LINK_TYPES,
	SEESAW_PRESETS = SEESAW_PRESETS,
	CE_ENTITY_TYPES = CE_ENTITY_TYPES,
	remap_kind = remap_kind,
	normalize_legacy_map_entity = normalize_legacy_map_entity,
	pass_through_ce_id = pass_through_ce_id,
	validate_remap = validate_remap,
}
