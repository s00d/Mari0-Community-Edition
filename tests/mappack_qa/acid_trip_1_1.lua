--[[ Acid Trip 1-1 diagnostics + activator remap regression.

   Root cause of “wrong activator / lift” on Acid Trip 1-1: entitylist had a
   spare empty slot before boxtube that shifted warppipe from id 81 → seesaw.
   Maps still store warppipe as 81; players got a seesaw (tilting platform)
   instead of warp pipes. Fixed by restoring CE_ENTITY_TYPES indices.

   Data shape: tiny warp-zone room — two warppipes @28–29,14 → world 5; no
   floor button / pushbutton / scaffold / platformspawner / link graph.
   Classic button@40 vs platformspawner@41 remap covered by fixtures + untitled 1-1.
]]

local Common = require("tests.mappack_qa.common")

local M = {}

function M.run(root, state)
	require("world.entity_remap")
	Common.ensure_entitylist()

	local s, err = Common.read_level(root, "dlc_acid_trip", "1-1")
	Common.check(state, "acid 1-1 readable", s ~= nil, err)
	if not s then
		return
	end

	local parsed, perr = level_parse_tiles_only(s)
	Common.check(state, "acid 1-1 parse", parsed ~= nil, perr)
	if not parsed then
		return
	end

	Common.check(state, "acid 1-1 size 40x15",
		parsed.mapwidth == 40 and parsed.mapheight == 15,
		tostring(parsed.mapwidth) .. "x" .. tostring(parsed.mapheight))

	local warps, buttons, lifts, links, other = {}, {}, {}, 0, {}
	Common.each_cell(parsed, function(x, y, cell)
		if not cell[2] then
			return
		end
		local copy = {}
		for i = 1, #cell do
			copy[i] = cell[i]
		end
		if type(copy[2]) == "number" then
			normalize_legacy_map_entity(copy)
		end
		local id = copy[2]
		local t = (type(id) == "number" and entitylist[id] and entitylist[id].t) or tostring(id)
		if t == "warppipe" or id == 81 then
			warps[#warps + 1] = { x = x, y = y, world = tonumber(copy[3]), cell = copy }
		elseif t == "button" or t == "pushbutton" or t == "actionblock" then
			buttons[#buttons + 1] = { x = x, y = y, t = t }
		elseif t == "platformspawner" or t == "scaffold" or t == "platform" or t == "seesaw" or t == "platformfall" then
			lifts[#lifts + 1] = { x = x, y = y, t = t }
		elseif type(id) == "number" or type(id) == "string" then
			if t ~= "warppipe" then
				other[#other + 1] = { x = x, y = y, t = t, id = id }
			end
		end
		links = links + #Common.cell_links(cell)
	end)

	Common.check(state, "acid 1-1: exactly 2 warppipes", #warps == 2, "count=" .. #warps)
	if #warps == 2 then
		table.sort(warps, function(a, b)
			return a.x < b.x
		end)
		Common.check(state, "acid 1-1: warppipe @28,14", warps[1].x == 28 and warps[1].y == 14)
		Common.check(state, "acid 1-1: warppipe @29,14", warps[2].x == 29 and warps[2].y == 14)
		Common.check(state, "acid 1-1: warppipe dest world 5",
			warps[1].world == 5 and warps[2].world == 5,
			tostring(warps[1].world) .. "," .. tostring(warps[2].world))
		-- Remap must not turn warppipe into vine/button
		for _, w in ipairs(warps) do
			normalize_legacy_map_entity(w.cell)
			Common.check(state, "acid 1-1: warppipe id stable under remap",
				w.cell[2] == 81 and entitylist[81].t == "warppipe",
				tostring(w.cell[2]))
		end
	end

	Common.check(state, "acid 1-1: no I/O buttons", #buttons == 0, "n=" .. #buttons)
	Common.check(state, "acid 1-1: no lift entities", #lifts == 0, "n=" .. #lifts)
	Common.check(state, "acid 1-1: no link tokens", links == 0, "n=" .. links)
	Common.check(state, "acid 1-1: no other entities", #other == 0,
		(#other > 0) and (other[1].t .. "@" .. other[1].x .. "," .. other[1].y) or nil)

	-- Classic remap fixtures (the bug class users report as “wrong activator”)
	do
		local btn = { 1, 40 }
		normalize_legacy_map_entity(btn)
		Common.check(state, "remap: legacy floor button 40→41", btn[2] == 41)

		local psp = { 1, 41, "down", 3, 3.5, 2.18 }
		normalize_legacy_map_entity(psp)
		Common.check(state, "remap: legacy platformspawner 41→42", psp[2] == 42)

		local cur_btn = { 1, 41, "down" }
		normalize_legacy_map_entity(cur_btn)
		Common.check(state, "remap: CE button 41 unchanged", cur_btn[2] == 41)

		local cur_psp = { 1, 42, "up", 5 }
		normalize_legacy_map_entity(cur_psp)
		Common.check(state, "remap: CE platformspawner 42 unchanged", cur_psp[2] == 42)
	end

	-- Live sample: untitled_game 1-1 is the real button+lift level in-tree
	do
		local us, uerr = Common.read_level(root, "dlc_the_untitled_game", "1-1")
		if us then
			local up = level_parse_tiles_only(us)
			if up then
				local b = up.map[26][13]
				local L = up.map[36][2]
				local bc, lc = {}, {}
				for i = 1, #b do
					bc[i] = b[i]
				end
				for i = 1, #L do
					lc[i] = L[i]
				end
				Common.check(state, "untitled 1-1: raw button id 40", bc[2] == 40)
				Common.check(state, "untitled 1-1: raw lift id 41", lc[2] == 41 and lc[3] == "down")
				normalize_legacy_map_entity(bc)
				normalize_legacy_map_entity(lc)
				Common.check(state, "untitled 1-1: button→41 after remap", bc[2] == 41)
				Common.check(state, "untitled 1-1: lift→42 after remap", lc[2] == 42)
			else
				Common.check(state, "untitled 1-1 parse", false, "parse failed")
			end
		else
			Common.check(state, "untitled 1-1 readable", false, uerr)
		end
	end

	-- qa_activators smoke room
	do
		local qs, qerr = Common.read_level(root, "qa_activators", "1-1")
		Common.check(state, "qa_activators readable", qs ~= nil, qerr)
		if qs then
			local qp = level_parse_tiles_only(qs)
			Common.check(state, "qa_activators parse", qp ~= nil)
			if qp then
				Common.check(state, "qa_activators spawn", qp.map[3][13][2] == 8)
				Common.check(state, "qa_activators button", qp.map[6][13][2] == 41)
				Common.check(state, "qa_activators scaffold", qp.map[10][11][2] == 27)
				Common.check(state, "qa_activators pushbutton", qp.map[14][13][2] == 68)
				Common.check(state, "qa_activators door", qp.map[18][12][2] == 28)
				Common.check(state, "qa_activators flag", qp.map[22][13][2] == 11)
				local links = Common.cell_links(qp.map[10][11])
				Common.check(state, "qa_activators scaffold→button link",
					#links == 1 and links[1].tx == 6 and links[1].ty == 13)
			end
		end
	end
end

return M
