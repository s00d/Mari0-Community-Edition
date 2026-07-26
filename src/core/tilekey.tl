-- Integer keys for objects["tile"] lookups (avoids per-frame string GC).
-- Assumes map coordinates fit in 0 .. TILEKEY_STRIDE-1 for y.

local TILEKEY_STRIDE: integer = 65536

local function tilekey(x: number, y: number): integer
	return math.floor(x) * TILEKEY_STRIDE + math.floor(y)
end

local function tilekey_xy(key: integer): integer, integer
	local x = math.floor(key / TILEKEY_STRIDE)
	local y = key % TILEKEY_STRIDE
	return x, y
end

-- Export as globals for legacy callers during migration.
_G.TILEKEY_STRIDE = TILEKEY_STRIDE
_G.tilekey = tilekey
_G.tilekey_xy = tilekey_xy

return {
	TILEKEY_STRIDE = TILEKEY_STRIDE,
	tilekey = tilekey,
	tilekey_xy = tilekey_xy,
}
