-- Deterministic physics group iteration order (matches fresh_objects keys + screenboundary).

require("world.level")

PHYSICS_GROUP_ORDER = {}
for i = 1, #OBJECT_GROUP_KEYS do
	PHYSICS_GROUP_ORDER[i] = OBJECT_GROUP_KEYS[i]
end
PHYSICS_GROUP_ORDER[#PHYSICS_GROUP_ORDER + 1] = "screenboundary"

-- Scratch buffer reused each call (callers must not retain the returned table).
local keys_scratch: {any} = {}

-- Hoisted once: avoid allocating a comparator closure every call.
local function key_less(a: any, b: any): boolean
	local ta = type(a)
	local tb = type(b)
	if ta ~= tb then
		return ta < tb
	end
	if ta == "number" then
		return (a as number) < (b as number)
	end
	return tostring(a) < tostring(b)
end

global function physics_group_keys_sorted(w: {any: any}): {any}
	local keys = keys_scratch
	local n = 0
	for _ in pairs(w) do
		n = n + 1
	end
	-- Dense array: # on array-shaped tables; map type would always be 0 under Teal.
	local len = #(w as {any})
	if n == len then
		-- Dense array: keys are exactly 1..n — nothing to sort.
		for i = 1, len do
			keys[i] = i
		end
		for i = len + 1, #keys do
			keys[i] = nil
		end
		return keys
	end
	n = 0
	for k in pairs(w) do
		n = n + 1
		keys[n] = k
	end
	for i = n + 1, #keys do
		keys[i] = nil
	end
	table.sort(keys, key_less)
	return keys
end
