-- Pure-ish enemy JSON / visibility helpers (from enemies.lua / enemy.lua).

local ENEMY_NAME_BAD = {",", ";", "-", "*"}

function enemy_name_ok(s)
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

-- Mutates t in place: case-fold keys + special camelCase offsets (legacy).
function normalize_enemy_props(t)
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

function apply_enemy_defaults(t, defaults)
	for i, v in pairs(defaults) do
		if t[i] == nil then
			t[i] = v
		end
	end
	return t
end

-- Shallow copy of base enemy table, skipping description / nobasevalues.
-- Uses global nobasevalues when present (legacy enemies.lua contract).
function usebase(t)
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

-- AABB vs camera view (globals xscroll/yscroll/width/height).
function enemy_onscreen(x, y, w, h)
	return x > xscroll - w and x < xscroll + width + w and y > yscroll - h and y < yscroll + height + h
end
