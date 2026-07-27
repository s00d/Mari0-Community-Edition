-- Block-bounce lookup: tilekey -> bounce index (truthy also usable as skip set).

global function build_blockbounce_lookup(blockbouncex: {any:any}, blockbouncey: {any:any}): {any:any}
	local t = {}
	local by = blockbouncey as {any:any}
	for i, x in pairs(blockbouncex as {any:any}) do
		if x and by[i] then
			t[tilekey(x, by[i])] = i
		end
	end
	return t
end
