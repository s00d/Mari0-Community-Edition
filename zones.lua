-- Pair start/end x lists into spawn zones (flying fish, bullet bills, etc).

function buildstartendzones(starts, ends)
	local zones = {}
	if not starts or #starts == 0 then
		return zones
	end
	local unpack = table.unpack or unpack
	local s = {unpack(starts)}
	local e = {unpack(ends or {})}
	table.sort(s)
	table.sort(e)
	local ei = 1
	for i = 1, #s do
		local sx = s[i]
		local ex = false
		while e[ei] and e[ei] <= sx do
			ei = ei + 1
		end
		if e[ei] then
			ex = e[ei]
			ei = ei + 1
		end
		table.insert(zones, {sx, ex})
	end
	return zones
end
