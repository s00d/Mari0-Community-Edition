--[[ Simulation state hash for desync detection (lockstep F1).

Walks PHYSICS_GROUP_ORDER + sorted entity keys (same order as physics.update).
Quantizes coords/speeds to 1/1024 so hash catches real desync, not float noise.

Works with the current snapshot model too — measures how far host/client diverge.
Reuse idea from golden-replay / rng_checks: same seed + same walk → same hash.

TODO F3-F5: after cross-arch hash validation, use this as the gate before
input-delay lockstep and snapshot removal.
]]

local Q = 1024 -- quantize scale

local function quantize(n: any): integer
	local v = tonumber(n)
	if not v then
		return 0
	end
	return math.floor(v * Q + 0.5) as integer
end

-- djb2-ish mix over 32-bit ints (Lua numbers stay exact for these).
local function mix(h: integer, a: integer, b: integer, c: integer, d: integer): integer
	local x = h
	x = ((x * 33) + a) % 2147483647
	x = ((x * 33) + b) % 2147483647
	x = ((x * 33) + c) % 2147483647
	x = ((x * 33) + d) % 2147483647
	return x as integer
end

local function entity_fields(v: any): integer, integer, integer, integer
	if type(v) ~= "table" then
		return 0, 0, 0, 0
	end
	local e = v as {string:any}
	return quantize(e.x), quantize(e.y), quantize(e.speedx), quantize(e.speedy)
end

local function sim_hash(): integer
	local h: integer = 5381
	local order = PHYSICS_GROUP_ORDER
	local objs = objects
	if type(order) ~= "table" or type(objs) ~= "table" then
		return h
	end
	local groups = order as {string}
	local all = objs as {string:any}
	for gi = 1, #groups do
		local name = groups[gi]
		local w = all[name]
		if type(w) == "table" then
			local group = w as {any:any}
			local keys = physics_group_keys_sorted(group)
			for ki = 1, #keys do
				local key = keys[ki]
				local ent = group[key]
				local x, y, sx, sy = entity_fields(ent)
				h = mix(h, x, y, sx, sy)
			end
		end
	end
	return h
end

local function pack_hash(frame: integer, h: integer, seq?: integer): {string:any}
	return {
		t = "hash",
		frame = frame,
		h = h,
		seq = seq or 0,
	}
end

return {
	sim_hash = sim_hash,
	quantize = quantize,
	pack_hash = pack_hash,
	Q = Q,
}
