-- Dense-array index removal helpers (sort high→low then table.remove).

-- Mutates indices (sorts descending). Removes each index from t.
function remove_indices_desc(t, indices)
	if not indices or #indices == 0 then
		return
	end
	table.sort(indices, function(a, b) return a > b end)
	for _, idx in ipairs(indices) do
		table.remove(t, idx)
	end
end

-- Same indices removed from every parallel list (e.g. blockbounce columns).
function remove_indices_desc_multi(lists, indices)
	if not indices or #indices == 0 then
		return
	end
	table.sort(indices, function(a, b) return a > b end)
	for _, idx in ipairs(indices) do
		for i = 1, #lists do
			table.remove(lists[i], idx)
		end
	end
end
