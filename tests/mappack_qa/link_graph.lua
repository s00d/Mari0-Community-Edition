--[[ Link graph: every `link` token must target an in-bounds cell; flag self-links. ]]

local Common = require("tests.mappack_qa.common")

local M = {}

function M.run(_root, state, packs)
	local dangling, self_links, total = {}, {}, 0

	for _, pack in ipairs(packs) do
		for level, parsed in pairs(state.parsed[pack] or {}) do
			local w, h = parsed.mapwidth, parsed.mapheight
			Common.each_cell(parsed, function(x, y, cell)
				local links = Common.cell_links(cell)
				for _, L in ipairs(links) do
					total = total + 1
					local tx, ty = L.tx, L.ty
					if tx == x and ty == y then
						self_links[#self_links + 1] = string.format("%s/%s @%d,%d → self", pack, level, x, y)
					elseif tx < 1 or ty < 1 or tx > w or ty > h then
						dangling[#dangling + 1] = string.format(
							"%s/%s @%d,%d → out-of-bounds %d,%d (%dx%d)",
							pack, level, x, y, tx, ty, w, h)
					else
						local target = parsed.map[tx][ty]
						if not target or not target[2] then
							-- Some shipped levels link lasers/indicators at empty tiles
							-- (broken or intentional stub). Count as warn, not suite fail.
							dangling[#dangling + 1] = string.format(
								"%s/%s @%d,%d → empty target %d,%d input=%s",
								pack, level, x, y, tx, ty, L.input)
						end
					end
				end
			end)
		end
	end

	local d0 = (#dangling > 0) and dangling[1] or nil
	local s0 = (#self_links > 0) and self_links[1] or nil
	-- Out-of-bounds already folded into dangling list above; split for messaging
	local oob = 0
	for _, line in ipairs(dangling) do
		if line:find("out-of-bounds", 1, true) then
			oob = oob + 1
		end
	end
	local oob_detail = nil
	for _, line in ipairs(dangling) do
		if line:find("out-of-bounds", 1, true) then
			oob_detail = line
			break
		end
	end
	Common.check(state, "link_graph: no out-of-bounds links", oob == 0, oob_detail)
	Common.check(state, "link_graph: no self-links", #self_links == 0, s0)
	if #dangling - oob > 0 then
		print(string.format("WARN link_graph empty-target links=%d (not failing)", #dangling - oob))
	end
	print(string.format("INFO link_graph links=%d empty_or_oob=%d self=%d", total, #dangling, #self_links))
	for i = 1, math.min(8, #dangling) do
		print("  dangling: " .. dangling[i])
	end
	for i = 1, math.min(8, #self_links) do
		print("  self: " .. self_links[i])
	end
end

return M
