--[[ Persistent spatial hash for object↔object broadphase (skeleton + usable API).

Rebuild once per physics frame; query by swept mover AABB.
Cell size = 1 world unit. Zero-size (portalwall) bodies get epsilon thickness on insert.
Does not replace tile collision. Keep handlegroup swept+epsilon portalwall fix when wiring.
]]

local CELL: number = 1
local EPS: number = 1 / 16

local buckets: {string:{any}} = {}
local inserted: integer = 0

local function cell_key(cx: integer, cy: integer): string
	return tostring(cx) .. ":" .. tostring(cy)
end

global function spatialhash_clear()
	for k in pairs(buckets) do
		buckets[k] = nil as {any}
	end
	inserted = 0
end

global function spatialhash_count(): integer
	return inserted
end

local function thick(x: number, y: number, w: number, h: number): number, number, number, number
	local tx, ty, tw, th = x, y, w, h
	if tw == 0 then
		tx = tx - EPS / 2
		tw = EPS
	end
	if th == 0 then
		ty = ty - EPS / 2
		th = EPS
	end
	return tx, ty, tw, th
end

global function spatialhash_insert(obj: any, x: number, y: number, w: number, h: number)
	local tx, ty, tw, th = thick(x, y, w, h)
	local x0 = math.floor(tx / CELL)
	local y0 = math.floor(ty / CELL)
	local x1 = math.floor((tx + tw) / CELL)
	local y1 = math.floor((ty + th) / CELL)
	for cy = y0, y1 do
		for cx = x0, x1 do
			local k = cell_key(cx, cy)
			local bucket = buckets[k]
			if bucket == nil then
				bucket = {}
				buckets[k] = bucket
			end
			bucket[#bucket + 1] = obj
		end
	end
	inserted = inserted + 1
end

-- Rebuild from a group table {id: Body}. Skips inactive.
global function spatialhash_rebuild_group(group: {any:Body})
	spatialhash_clear()
	for _, t in pairs(group) do
		if t.active then
			spatialhash_insert(t, t.x, t.y, t.width, t.height)
		end
	end
end

-- Collect unique active objects overlapping AABB into out (cleared first).
-- Returns count written.
global function spatialhash_query(
	x: number,
	y: number,
	w: number,
	h: number,
	out: {any},
	seen: {any:boolean}
): integer
	for i = #out, 1, -1 do
		out[i] = nil
	end
	for k in pairs(seen) do
		seen[k] = nil as boolean
	end
	local tx, ty, tw, th = thick(x, y, w, h)
	local x0 = math.floor(tx / CELL)
	local y0 = math.floor(ty / CELL)
	local x1 = math.floor((tx + tw) / CELL)
	local y1 = math.floor((ty + th) / CELL)
	local n = 0
	for cy = y0, y1 do
		for cx = x0, x1 do
			local bucket = buckets[cell_key(cx, cy)]
			if bucket then
				for i = 1, #bucket do
					local obj = bucket[i]
					if not seen[obj] then
						seen[obj] = true
						n = n + 1
						out[n] = obj
					end
				end
			end
		end
	end
	return n
end

return {
	spatialhash_clear = spatialhash_clear,
	spatialhash_count = spatialhash_count,
	spatialhash_insert = spatialhash_insert,
	spatialhash_rebuild_group = spatialhash_rebuild_group,
	spatialhash_query = spatialhash_query,
	CELL = CELL,
}
