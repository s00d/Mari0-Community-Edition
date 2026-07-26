-- Integer keys for objects["tile"] lookups (avoids per-frame string GC).
-- Assumes map coordinates fit in 0 .. TILEKEY_STRIDE-1 for y.
TILEKEY_STRIDE = 65536

function tilekey(x, y)
	return x * TILEKEY_STRIDE + y
end

function tilekey_xy(key)
	local x = math.floor(key / TILEKEY_STRIDE)
	local y = key % TILEKEY_STRIDE
	return x, y
end
