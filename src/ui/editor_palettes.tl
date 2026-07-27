--[[ Registry-driven editor palettes. Deterministic: keys sorted. ]]

global record EditorPalettes
	tiles: {any}
	entities: {any}
	enemies: {any}
	weapons: {any}
	gels: {any}
	forms: {any}
end

local function sorted_keys(t: {any:any}): {string}
	local keys: {string} = {}
	for k in pairs(t) do
		keys[#keys + 1] = tostring(k)
	end
	table.sort(keys)
	return keys
end

local function list_enemy_json_names(): {string}
	local names: {string} = {}
	local seen: {string:boolean} = {}
	local love_raw = rawget(_G, "love")
	if love_raw then
		local love_t = love_raw as {string:any}
		local fs_raw = love_t.filesystem
		if fs_raw then
			local fs = fs_raw as {string:any}
			local getDir = fs.getDirectoryItems
			if type(getDir) == "function" then
				local ok, fl = pcall(function(): {string}
					return (getDir as function(string): {string})("assets/enemies/")
				end)
				if ok and fl then
					local list = fl as {string}
					for i = 1, #list do
						local f = list[i]
						if string.sub(f, -5) == ".json" then
							local n = string.sub(f, 1, -6):lower()
							if not seen[n] then
								seen[n] = true
								names[#names + 1] = n
							end
						end
					end
				end
			end
		end
	end
	local en_any = rawget(_G, "enemies")
	if en_any then
		local en = en_any as {string}
		for i = 1, #en do
			local n = tostring(en[i]):lower()
			if not seen[n] then
				seen[n] = true
				names[#names + 1] = n
			end
		end
	end
	table.sort(names)
	return names
end

global function build_palettes(overrides: {string:any}|nil): any
	local o = (overrides or {}) as {string:any}
	local tiles: {any} = {}
	local entities: {any} = {}
	local enemies_out: {any} = {}
	local weapons: {any} = {}
	local gels: {any} = {}
	local forms: {any} = {}

	local tq = (o.tilequads or rawget(_G, "tilequads")) as {any:any}|nil
	if tq then
		local ids: {number} = {}
		local tqm = tq as {any:any}
		for k, v in pairs(tqm) do
			local n = tonumber(k)
			if n and v ~= nil and n < 10000 then
				ids[#ids + 1] = n as number
			end
		end
		table.sort(ids)
		for i = 1, #ids do
			tiles[#tiles + 1] = { kind = "tile", id = ids[i] }
		end
	end

	local el = (o.entitylist or rawget(_G, "entitylist")) as {any}|nil
	if el then
		local entries: {any} = {}
		local ell = el as {any}
		for i = 1, #ell do
			local eraw = ell[i]
			if eraw then
				local e = eraw as {string:any}
				local et = e.t
				if et and (et as string) ~= "" and not e.hidden then
					entries[#entries + 1] = { kind = "entity", id = i, t = et, category = e.category }
				end
			end
		end
		table.sort(entries, function(a: any, b: any): boolean
			local aa = a as {string:any}
			local bb = b as {string:any}
			local ta, tb = tostring(aa.t), tostring(bb.t)
			if ta == tb then
				return (aa.id as number) < (bb.id as number)
			end
			return ta < tb
		end)
		entities = entries
	end

	local enames = (o.enemy_names as {string}|nil) or list_enemy_json_names()
	local enames2 = enames as {string}
	for i = 1, #enames2 do
		enemies_out[#enemies_out + 1] = { kind = "enemy", t = enames2[i] }
	end

	local W: {string:any}|nil = nil
	if o.weapons_registry then
		W = o.weapons_registry as {string:any}
	else
		local Wm_raw = rawget(_G, "Weapons")
		if Wm_raw then
			W = (Wm_raw as WeaponsModule).registry
		end
	end
	if W then
		local keys = sorted_keys(W)
		local seen: {string:boolean} = {}
		for i = 1, #keys do
			local id = keys[i]
			if id ~= "gel" and not seen[id] then
				seen[id] = true
				weapons[#weapons + 1] = { kind = "weapon", id = id }
			end
		end
	end

	local gd_raw = o.gel_defs or GEL_DEFS
	if gd_raw then
		local gd = gd_raw as {integer:GelDef}
		local ids: {number} = {}
		for k in pairs(gd as {any:any}) do
			local n = tonumber(k)
			if n then
				ids[#ids + 1] = n as number
			end
		end
		table.sort(ids)
		for i = 1, #ids do
			local d = gd[math.floor(ids[i]) as integer]
			local nm = d and d.name
			gels[#gels + 1] = { kind = "gel", id = ids[i], name = nm or tostring(ids[i]) }
		end
	end

	local mf = (o.mario_forms or MARIO_FORMS) as {string:any}|nil
	if mf then
		local keys = sorted_keys(mf)
		for i = 1, #keys do
			forms[#forms + 1] = { kind = "form", id = keys[i] }
		end
	end

	return {
		tiles = tiles,
		entities = entities,
		enemies = enemies_out,
		weapons = weapons,
		gels = gels,
		forms = forms,
	}
end

global function palette_weapon_ids(p: EditorPalettes): {string}
	local out: {string} = {}
	for i = 1, #p.weapons do
		out[#out + 1] = ((p.weapons[i] as {string:any}).id) as string
	end
	return out
end

global function palette_gel_ids(p: EditorPalettes): {number}
	local out: {number} = {}
	for i = 1, #p.gels do
		out[#out + 1] = ((p.gels[i] as {string:any}).id) as number
	end
	return out
end

global function palette_entity_types(p: EditorPalettes): {string}
	local out: {string} = {}
	for i = 1, #p.entities do
		out[#out + 1] = ((p.entities[i] as {string:any}).t) as string
	end
	return out
end
