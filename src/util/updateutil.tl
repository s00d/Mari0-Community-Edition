-- Ported from root updateutil.lua (Teal).

-- Update entity lists and compact removed entries (dense in-place or sparse remove).
-- Uses globals mapwidth / mapheight for autodelete bounds (same as game loop).

local function update_and_compact(v: any, dt: any)
	-- Dense array path: compact in-place (no sort/remove)
	local n = #v
	if n > 0 then
		local write = 1
		for j = 1, n do
			local w = v[j]
			local remove = false
			if w.update and w:update(dt) then
				remove = true
			elseif w.autodelete then
				if w.y > mapheight+5 or w.x > mapwidth+5 or w.x < -5 or w.y < -5 then
					if w.autodeleted then
						w:autodeleted()
					end
					remove = true
				end
			end
			if not remove then
				if write ~= j then
					v[write] = w
				end
				write = write + 1
			end
		end
		for j = n, write, -1 do
			v[j] = nil
		end
		return
	end

	-- Sparse / hash tables: collect keys then delete (legacy path)
	local delete = {}
	for j, w in pairs(v) do
		if w.update and w:update(dt) then
			table.insert(delete, j)
		elseif w.autodelete then
			if w.y > mapheight+5 or w.x > mapwidth+5 or w.x < -5 or w.y < -5 then
				if w.autodeleted then
					w:autodeleted()
				end
				table.insert(delete, j)
			end
		end
	end
	if #delete > 0 then
		remove_indices_desc(v, delete)
	end
end
_G.update_and_compact = update_and_compact

return {
	update_and_compact = update_and_compact,
}
