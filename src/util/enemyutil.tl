-- Ported from root enemyutil.lua (Teal).

-- Pure-ish enemy JSON / visibility helpers (from enemies.lua / enemy.lua).

local ENEMY_NAME_BAD = {",", ";", "-", "*"}

local function enemy_name_ok(s: string): boolean
	if not s or s == "" then
		return false
	end
	for i = 1, #ENEMY_NAME_BAD do
		if s:find(ENEMY_NAME_BAD[i], 1, true) then
			return false
		end
	end
	return true
end
_G.enemy_name_ok = enemy_name_ok


-- Mutates t in place: case-fold keys + special camelCase offsets (legacy).
local function normalize_enemy_props(t: Dyn): Dyn
	for i, v in pairs(t) do
		local a = (i as string):lower()
		if a == "offsetx" then
			t["offsetX"] = v
		elseif a == "offsety" then
			t["offsetY"] = v
		elseif a == "quadcenterx" then
			t["quadcenterX"] = v
		elseif a == "quadcentery" then
			t["quadcenterY"] = v
		else
			local bag = t as {string:any}
			if type(v) == "string" then
				bag[a] = (v as string):lower()
			else
				bag[a] = v
			end
		end
	end
	return t
end
_G.normalize_enemy_props = normalize_enemy_props


local function apply_enemy_defaults(t: Dyn, defaults: Dyn): Dyn
	for i, v in pairs(defaults) do
		if t[i] == nil then
			t[i] = v
		end
	end
	return t
end
_G.apply_enemy_defaults = apply_enemy_defaults


-- Shallow copy of base enemy table, skipping description / nobasevalues.
-- Uses global nobasevalues when present (legacy enemies.lua contract).
local function usebase(t: Dyn): Dyn
	local r: Dyn = {}
	local skip = (nobasevalues as {string}) or {"description"}

	for i, v in pairs(t) do
		local check = true
		for j in ipairs(skip) do
			if i == skip[j] then
				check = false
				break
			end
		end
		if check then
			if i ~= "description" then
				r[i] = v
			end
		end
	end

	return r
end
_G.usebase = usebase


-- AABB vs camera view (globals xscroll/yscroll/width/height). World units.
local function onscreen(x: number, y: number, w: number|nil, h: number|nil): boolean
	if w and h then
		return x + w >= xscroll and y + h - 0.5 >= yscroll
			and x <= xscroll + width and y - 0.5 <= yscroll + height
	end
	return x >= xscroll and y - 0.5 >= yscroll
		and x <= xscroll + width and y - 0.5 <= yscroll + height
end
_G.onscreen = onscreen

-- Enemy cull with size padding (not an onscreen alias — looser bounds for spawn/AI).
local function enemy_onscreen(x: number, y: number, w: number, h: number): boolean
	return x > xscroll - w and x < xscroll + width + w and y > yscroll - h and y < yscroll + height + h
end
_G.enemy_onscreen = enemy_onscreen

return {
	enemy_name_ok = enemy_name_ok,
	normalize_enemy_props = normalize_enemy_props,
	apply_enemy_defaults = apply_enemy_defaults,
	usebase = usebase,
	onscreen = onscreen,
	enemy_onscreen = enemy_onscreen,
}
