--[[ Statehash / desync detector checks (F1). ]]

local root = ... or "."
local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	package.path,
}, ";")

_G.JSON = require("dkjson")

-- Minimal physics order stubs (same API as physics.order).
_G.PHYSICS_GROUP_ORDER = { "player", "enemy", "tile" }
_G.physics_group_keys_sorted = function(w)
	local keys = {}
	for k in pairs(w) do
		keys[#keys + 1] = k
	end
	table.sort(keys, function(a, b)
		local ta, tb = type(a), type(b)
		if ta ~= tb then return ta < tb end
		if ta == "number" then return a < b end
		return tostring(a) < tostring(b)
	end)
	return keys
end

local SH = require("net.statehash")

check("quantize 1/1024", SH.quantize(1) == 1024)
check("quantize 0.5", SH.quantize(0.5) == 512)
check("quantize negative", SH.quantize(-0.25) == -256)

_G.objects = {
	player = {
		[1] = { x = 1.0, y = 2.0, speedx = 0.5, speedy = -0.25 },
		[2] = { x = 3.0, y = 4.0, speedx = 0, speedy = 0 },
	},
	enemy = {
		a = { x = 10, y = 20, speedx = 1, speedy = 2 },
	},
	tile = {},
}

local h1 = SH.sim_hash()
local h2 = SH.sim_hash()
check("sim_hash bit-identical repeat", h1 == h2 and h1 ~= 5381)
check("sim_hash nonzero", h1 > 5381 or h1 ~= 5381)

-- Perturb one entity → hash must change
objects.player[1].x = 1.0 + 2 / 1024
local h3 = SH.sim_hash()
check("sim_hash detects position change", h3 ~= h1)

-- Restore; change order of insertion must not matter (sorted keys)
objects.player[1].x = 1.0
local h4 = SH.sim_hash()
check("sim_hash restored", h4 == h1)

local packed = SH.pack_hash(60, h1, 9)
check("pack_hash opcode", packed.t == "hash" and packed.frame == 60 and packed.h == h1 and packed.seq == 9)

local Protocol = require("net.protocol")
check("protocol is_op hash", Protocol.is_op("hash") == true)
check("protocol validate hash", Protocol.validate({t = "hash", v = Protocol.VERSION}) == true)
local enc = Protocol.encode(packed)
local dec = Protocol.decode(enc)
check("hash roundtrip", dec and dec.t == "hash" and dec.frame == 60 and dec.h == h1)

-- Empty / missing world
_G.objects = nil
check("sim_hash nil objects", SH.sim_hash() == 5381)

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
