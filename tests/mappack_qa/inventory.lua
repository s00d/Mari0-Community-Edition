--[[ List mappacks + N-M(_S) levels. ]]

local Common = require("tests.mappack_qa.common")

local M = {}

function M.run(root, state, pack_filter)
	local packs = Common.list_packs(root)
	Common.check(state, "inventory: packs found", #packs >= 1, "count=" .. #packs)

	local selected = {}
	for _, pack in ipairs(packs) do
		if pack_filter == "all" or pack == pack_filter then
			selected[#selected + 1] = pack
		end
	end
	Common.check(state, "inventory: filter matches", #selected >= 1,
		"filter=" .. tostring(pack_filter) .. " matched=" .. #selected)

	local total_levels = 0
	state.packs = {}
	for _, pack in ipairs(selected) do
		local levels = Common.list_levels(root, pack)
		state.packs[pack] = levels
		total_levels = total_levels + #levels
		Common.check(state, "inventory: " .. pack .. " has levels", #levels >= 1, "levels=" .. #levels)
	end
	Common.check(state, "inventory: total levels > 0", total_levels > 0, "total=" .. total_levels)
	print(string.format("INFO inventory packs=%d levels=%d filter=%s", #selected, total_levels, pack_filter))
	return selected
end

return M
