local function tablecontains(t: {any}, entry: any): boolean
	for _, v in pairs(t) do
		if v == entry then
			return true
		end
	end
	return false
end

_G.tablecontains = tablecontains

return {
	tablecontains = tablecontains,
}
