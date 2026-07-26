-- Ported from root enemyutil.lua (Teal).

-- Pure-ish enemy JSON / visibility helpers (from enemies.lua / enemy.lua).

local ENEMY_NAME_BAD = {",", ";", "-", "*"}

local function enemy_name_ok(s: any): any
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
local function normalize_enemy_props(t: any): any
	for i, v in pairs(t) do
		local a = i:lower()
		if a == "offsetx" then
			t["offsetX"] = v
		elseif a == "offsety" then
			t["offsetY"] = v
		elseif a == "quadcenterx" then
			t["quadcenterX"] = v
		elseif a == "quadcentery" then
			t["quadcenterY"] = v
		else
			if type(v) == "string" then
				t[a] = v:lower()
			else
				t[a] = v
			end
		end
	end
	return t
end
_G.normalize_enemy_props = normalize_enemy_props


local function apply_enemy_defaults(t: any, defaults: any): any
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
local function usebase(t: any): any
	local r = {}
	local skip = nobasevalues or {"description"}

	for i, v in pairs(t) do
		local check = true
		for j in pairs(skip) do
			if i == v then
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


-- AABB vs camera view (globals xscroll/yscroll/width/height).
local function enemy_onscreen(x: any, y: any, w: any, h: any): any
	return x > xscroll - w and x < xscroll + width + w and y > yscroll - h and y < yscroll + height + h
end
_G.enemy_onscreen = enemy_onscreen

return {
	enemy_name_ok = enemy_name_ok,
	normalize_enemy_props = normalize_enemy_props,
	apply_enemy_defaults = apply_enemy_defaults,
	usebase = usebase,
	enemy_onscreen = enemy_onscreen,
}
