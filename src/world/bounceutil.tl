-- Block-bounce lookup: tilekey -> bounce index (truthy also usable as skip set).
-- Reuses scratch table; do not retain the returned reference across frames.

local bounce_lookup_scratch: {any:any} = {}

global function build_blockbounce_lookup(blockbouncex: {any:any}, blockbouncey: {any:any}): {any:any}
	local t = bounce_lookup_scratch
	for k in pairs(t) do
		t[k] = nil
	end
	local by = blockbouncey as {any:any}
	for i, x in pairs(blockbouncex as {any:any}) do
		if x and by[i] then
			t[tilekey(x, by[i])] = i
		end
	end
	return t
end
