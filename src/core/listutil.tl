local function remove_indices_desc(t: {any}, indices: {integer})
	if not indices or #indices == 0 then
		return
	end
	table.sort(indices, function(a: integer, b: integer): boolean
		return a > b
	end)
	for _, idx in ipairs(indices) do
		table.remove(t, idx)
	end
end

local function remove_indices_desc_multi(lists: {{any}}, indices: {integer})
	if not indices or #indices == 0 then
		return
	end
	table.sort(indices, function(a: integer, b: integer): boolean
		return a > b
	end)
	for _, idx in ipairs(indices) do
		for i = 1, #lists do
			table.remove(lists[i], idx)
		end
	end
end

_G.remove_indices_desc = remove_indices_desc
_G.remove_indices_desc_multi = remove_indices_desc_multi

return {
	remove_indices_desc = remove_indices_desc,
	remove_indices_desc_multi = remove_indices_desc_multi,
}
