-- Ported from root updateutil.lua (Teal).

-- Update entity lists and compact removed entries (dense in-place or sparse remove).
-- Uses globals mapwidth / mapheight for autodelete bounds (same as game loop).

require("weapons.punt")

-- Reused across sparse-path calls to avoid per-frame table allocation.
local delete_scratch: {any} = {}

local function update_and_compact(v: Dyn, dt: number)
	-- Dense array path: compact in-place (no sort/remove)
	local n = #(v as {Entity})
	if n > 0 then
		local write = 1
		local arr = v as {Entity}
		for j = 1, n do
			local w = arr[j]
			-- Holes (nil) from despawn/assign-nil: drop and compact. #t past a hole is undefined in Lua.
			local remove = (w == nil)
			if not remove then
				if w.update and w:update(dt) then
					remove = true
				elseif w.autodelete then
					if w.y > mapheight+5 or w.x > mapwidth+5 or w.x < -5 or w.y < -5 then
						if w.autodeleted then
							(w.autodeleted as function(Entity))(w)
						end
						remove = true
					end
				end
			end
			if not remove then
				punt_tick(w as {string:any}, dt)
				if write ~= j then
					arr[write] = w
				end
				write = write + 1
			end
		end
		for j = n, write, -1 do
			arr[j] = nil as Entity
		end
		return
	end

	-- Sparse / hash tables: collect keys then delete (legacy path)
	local delete = delete_scratch
	local n = 0
	local mapv = v as {any:Entity}
	for j, w in pairs(mapv) do
		local remove = false
		if w.update and w:update(dt) then
			remove = true
		elseif w.autodelete then
			if w.y > mapheight+5 or w.x > mapwidth+5 or w.x < -5 or w.y < -5 then
				if w.autodeleted then
					(w.autodeleted as function(Entity))(w)
				end
				remove = true
			end
		end
		if remove then
			n = n + 1
			delete[n] = j
		else
			punt_tick(w as {string:any}, dt)
		end
	end
	for i = n + 1, #delete do
		delete[i] = nil
	end
	if n > 0 then
		remove_indices_desc(v, delete)
	end
end
_G.update_and_compact = update_and_compact

return {
	update_and_compact = update_and_compact,
}
