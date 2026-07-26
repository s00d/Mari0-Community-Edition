-- Tiny pure table helpers.

function tablecontains(t, entry)
	for i, v in pairs(t) do
		if v == entry then
			return true
		end
	end
	return false
end
