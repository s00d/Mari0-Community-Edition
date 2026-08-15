--[[ Parse every N-M.txt via level_parse_tiles_only. ]]

local Common = require("tests.mappack_qa.common")

local M = {}

function M.run(root, state, packs)
	state.parsed = state.parsed or {}
	local ok_n, fail_n = 0, 0
	for _, pack in ipairs(packs) do
		state.parsed[pack] = {}
		for _, level in ipairs(state.packs[pack] or {}) do
			local s, path_or_err = Common.read_level(root, pack, level)
			if not s then
				fail_n = fail_n + 1
				Common.check(state, "parse " .. pack .. "/" .. level, false, path_or_err)
			else
				local parsed, err = level_parse_tiles_only(s)
				if not parsed then
					fail_n = fail_n + 1
					Common.check(state, "parse " .. pack .. "/" .. level, false, err)
				else
					ok_n = ok_n + 1
					state.parsed[pack][level] = parsed
				end
			end
		end
	end
	Common.check(state, "parse_smoke: all ok", fail_n == 0, "ok=" .. ok_n .. " fail=" .. fail_n)
	print(string.format("INFO parse_smoke ok=%d fail=%d", ok_n, fail_n))
end

return M
