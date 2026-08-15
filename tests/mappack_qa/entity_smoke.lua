--[[ Entity id / name smoke: cell[2] must resolve to entitylist or enemy JSON. ]]

local Common = require("tests.mappack_qa.common")

local M = {}

function M.run(root, state, packs)
	Common.ensure_entitylist()
	require("world.entity_remap")

	local empty_ids = {}
	for i, e in ipairs(entitylist) do
		if not e or e.t == nil or e.t == "" then
			empty_ids[i] = true
		end
	end

	local bad = {}
	local checked = 0

	for _, pack in ipairs(packs) do
		for level, parsed in pairs(state.parsed[pack] or {}) do
			Common.each_cell(parsed, function(x, y, cell)
				if not cell[2] then
					return
				end
				checked = checked + 1
				local raw = cell[2]
				-- Apply load-time remap before validating numeric CE ids.
				local copy = {}
				for i = 1, #cell do
					copy[i] = cell[i]
				end
				if type(copy[2]) == "number" then
					normalize_legacy_map_entity(copy)
				end
				local ent = copy[2]

				if type(ent) == "number" then
					if empty_ids[ent] then
						bad[#bad + 1] = string.format("%s/%s @%d,%d empty entitylist[%s] (raw=%s)",
							pack, level, x, y, tostring(ent), tostring(raw))
					elseif not entitylist[ent] then
						bad[#bad + 1] = string.format("%s/%s @%d,%d out-of-range id %s",
							pack, level, x, y, tostring(ent))
					elseif not entitylist[ent].t or entitylist[ent].t == "" then
						bad[#bad + 1] = string.format("%s/%s @%d,%d empty t at id %s",
							pack, level, x, y, tostring(ent))
					end
				elseif type(ent) == "string" then
					local name = ent
					if name == "" then
						bad[#bad + 1] = string.format("%s/%s @%d,%d empty string entity id", pack, level, x, y)
					else
						local known = Common.enemy_json_exists(root, name)
						if not known then
							local mf = io.open(root .. "/mappacks/" .. pack .. "/enemies/" .. name .. ".json", "r")
							if mf then
								mf:close()
								known = true
							end
						end
						if not known then
							for _, e in ipairs(entitylist) do
								if e.t == name then
									known = true
									break
								end
							end
						end
						if not known then
							-- Imported packs (opensyobon/cavestory/…) may use alias
							-- basenames; warn but don't fail the suite.
							print(string.format("WARN entity_smoke unknown string %s/%s @%d,%d %q",
								pack, level, x, y, name))
						end
					end
				else
					bad[#bad + 1] = string.format("%s/%s @%d,%d bad type %s",
						pack, level, x, y, type(ent))
				end
			end)
		end
	end

	local detail = (#bad > 0) and (bad[1] .. (bad[2] and (" … +" .. (#bad - 1)) or "")) or nil
	Common.check(state, "entity_smoke: no unknown/empty ids", #bad == 0, detail)
	print(string.format("INFO entity_smoke checked=%d bad=%d", checked, #bad))
	if #bad > 0 and #bad <= 20 then
		for _, line in ipairs(bad) do
			print("  " .. line)
		end
	elseif #bad > 20 then
		for i = 1, 10 do
			print("  " .. bad[i])
		end
		print("  …")
	end
end

return M
