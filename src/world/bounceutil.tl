-- Block-bounce lookup: tilekey -> bounce index (truthy also usable as skip set).

global function build_blockbounce_lookup(...: any): any
	local blockbouncex, blockbouncey = ...
	local t = {}
	for i, x in pairs(blockbouncex as {any:any}) do
		if x and blockbouncey[i] then
			t[tilekey(x, blockbouncey[i])] = i
		end
	end
	return t
end
