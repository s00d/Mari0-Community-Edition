-- Deterministic physics group iteration order (matches fresh_objects keys + screenboundary).

require("world.level")

PHYSICS_GROUP_ORDER = {}
for i = 1, #OBJECT_GROUP_KEYS do
	PHYSICS_GROUP_ORDER[i] = OBJECT_GROUP_KEYS[i]
end
PHYSICS_GROUP_ORDER[#PHYSICS_GROUP_ORDER + 1] = "screenboundary"

global function physics_group_keys_sorted(w: {any: any}): {any}
	local keys: {any} = {}
	for k in pairs(w) do
		keys[#keys + 1] = k
	end
	table.sort(keys, function(a, b): boolean
		local ta = type(a)
		local tb = type(b)
		if ta ~= tb then
			return ta < tb
		end
		if ta == "number" then
			return (a as number) < (b as number)
		end
		return tostring(a) < tostring(b)
	end)
	return keys
end
