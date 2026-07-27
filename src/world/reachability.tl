--[[ World reachability BFS (Metroidvania F3). ]]

global function world_reachability_check(start_id: string|nil): {string}
	local errs: {string} = {}
	if not ROOMS or #ROOMS == 0 then
		errs[#errs + 1] = "no rooms loaded"
		return errs
	end
	local start = start_id or START_ROOM
	if not start or start == "" or not ROOMS_BY_ID[start] then
		start = ROOMS[1].id
	end
	local have: {string:boolean} = {}
	local seen: {string:boolean} = { [start] = true }
	local changed = true
	while changed do
		changed = false
		for id in pairs(seen) do
			local r = ROOMS_BY_ID[id]
			if r then
				for i = 1, #(r.items or {}) do
					local ab = r.items[i].ability as string|nil
					if ab and ab ~= "" and not have[ab] then have[ab] = true; changed = true end
				end
				local pl = fake_player_from_abilities(have)
				for i = 1, #(r.doors or {}) do
					local d = r.doors[i]
					local kind = tostring(d.kind or "open")
					local dest = tostring(d.to or "")
					if dest ~= "" and not seen[dest] then
						local uid = tostring(d.uid or (id .. ">" .. dest))
						if (door_is_open(uid) or door_can_pass(kind, pl, d)) and ROOMS_BY_ID[dest] then
							seen[dest] = true; changed = true
						end
					end
				end
			end
		end
	end
	for i = 1, #ROOMS do
		if not seen[ROOMS[i].id] then errs[#errs + 1] = "unreachable room " .. ROOMS[i].id end
	end
	for i = 1, #ROOMS do
		local r = ROOMS[i]
		for j = 1, #(r.doors or {}) do
			local d = r.doors[j]
			local kind = tostring(d.kind or "open")
			local dest = tostring(d.to or "")
			if dest ~= "" and ROOMS_BY_ID[dest] and kind ~= "open" then
				local kit: {string:boolean} = {}
				for id in pairs(seen) do
					if id ~= dest then
						local rr = ROOMS_BY_ID[id]
						if rr then
							for k = 1, #(rr.items or {}) do
								local ab = rr.items[k].ability as string|nil
								if ab then kit[ab] = true end
							end
						end
					end
				end
				local pl = fake_player_from_abilities(kit)
				if door_can_pass(kind, pl, d) then
					local target = ROOMS_BY_ID[dest]
					for k = 1, #(target.items or {}) do
						local ab = target.items[k].ability as string|nil
						if ab then kit[ab] = true end
					end
					pl = fake_player_from_abilities(kit)
					local can_leave = false
					for k = 1, #(target.doors or {}) do
						local out = target.doors[k]
						if tostring(out.to or "") ~= "" and door_can_pass(tostring(out.kind or "open"), pl, out) then
							can_leave = true; break
						end
					end
					if not can_leave and #(target.doors or {}) > 0 then
						errs[#errs + 1] = "soft dead-end " .. r.id .. "->" .. dest .. " (" .. kind .. ")"
					end
				end
			end
		end
	end
	return errs
end

return { world_reachability_check = world_reachability_check }
