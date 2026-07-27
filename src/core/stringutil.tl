local function addzeros(s: any, i: integer): string
	local out = tostring(s)
	for _ = string.len(out) + 1, i do
		out = "0" .. out
	end
	return out
end

local function string_split(self: any, delimiter: any): {string}
	local parts: {string} = {}
	if self == nil then
		return parts
	end
	local src = tostring(self)
	local delim = tostring(delimiter or "/")
	if delim == "" then
		table.insert(parts, src)
		return parts
	end
	local from = 1
	local delim_from, delim_to = string.find(src, delim, from, true)
	while delim_from do
		table.insert(parts, string.sub(src, from, delim_from - 1))
		from = (delim_to as integer) + 1
		delim_from, delim_to = string.find(src, delim, from, true)
	end
	table.insert(parts, string.sub(src, from))
	return parts
end

_G["addzeros"] = addzeros
_G["strsplit"] = string_split
-- Runtime monkey-patch for any leftover :split call sites.
rawset(string, "split", string_split)

return {
	addzeros = addzeros,
	split = string_split,
	strsplit = string_split,
}
