local function buildstartendzones(starts: {number}|nil, ends: {number}|nil): {{number|boolean}}
	local zones: {{number|boolean}} = {}
	if not starts or #starts == 0 then
		return zones
	end
	local unpack_fn = table.unpack or (unpack as function)
	local s = { unpack_fn(starts) } as {number}
	local e = { unpack_fn(ends or {}) } as {number}
	table.sort(s)
	table.sort(e)
	local ei = 1
	for i = 1, #s do
		local sx = s[i]
		local ex: number|boolean = false
		while e[ei] and e[ei] <= sx do
			ei = ei + 1
		end
		if e[ei] then
			ex = e[ei]
			ei = ei + 1
		end
		table.insert(zones, { sx, ex } as {number|boolean})
	end
	return zones
end

_G.buildstartendzones = buildstartendzones

return {
	buildstartendzones = buildstartendzones,
}
