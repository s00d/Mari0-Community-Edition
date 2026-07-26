-- Block-bounce lookup: tilekey -> bounce index (truthy also usable as skip set).

function build_blockbounce_lookup(blockbouncex, blockbouncey)
	local t = {}
	for i, x in pairs(blockbouncex) do
		if x and blockbouncey[i] then
			t[tilekey(x, blockbouncey[i])] = i
		end
	end
	return t
end
