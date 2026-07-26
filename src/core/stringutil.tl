local function addzeros(s: any, i: integer): string
	local out = tostring(s)
	for _ = string.len(out) + 1, i do
		out = "0" .. out
	end
	return out
end

local function string_split(self: string, delimiter: string): {string}
	local parts: {string} = {}
	local from = 1
	local delim_from, delim_to = string.find(self, delimiter, from)
	while delim_from do
		table.insert(parts, string.sub(self, from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = string.find(self, delimiter, from)
	end
	table.insert(parts, string.sub(self, from))
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
