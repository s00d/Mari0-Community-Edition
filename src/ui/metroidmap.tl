--[[ Metroid map overlay (F4). ]]

local MAP_SCALE: number = 2

global function metroidmap_toggle()
	if metroidmode then metroidmapopen = not metroidmapopen end
end

global function metroidmap_close()
	metroidmapopen = false
end

global function metroidmap_draw()
	if not metroidmapopen or not metroidmode or not ROOMS or #ROOMS == 0 then return end
	local sc = scale or 1
	local accent = (UI and UI.COL and UI.COL.text_accent) or {1.0, 0.84, 0.22, 1.0}
	local dim = (UI and UI.COL and UI.COL.text_dim) or {0.62, 0.62, 0.66, 1.0}
	local panel = (UI and UI.COL and UI.COL.panel) or {0.05, 0.06, 0.10, 0.88}
	love.graphics.setColor(panel[1] as number, panel[2] as number, panel[3] as number, (panel[4] or 0.88) as number)
	love.graphics.rectangle("fill", 0, 0, (width or 25) * 16 * sc, (height or 14) * 16 * sc)
	local cur = currentroom
	local cx, cy = 200.0, 112.0
	local cur_id = ""
	if cur then
		local c = cur as MetroidRoom
		cx = 200 - c.x * MAP_SCALE - c.w * MAP_SCALE / 2
		cy = 112 - c.y * MAP_SCALE - c.h * MAP_SCALE / 2
		cur_id = c.id
	end
	for i = 1, #ROOMS do
		local r = ROOMS[i]
		if globoolSH("seen_" .. r.id, "check") then
			local x = cx + r.x * MAP_SCALE
			local y = cy + r.y * MAP_SCALE
			local col = (cur_id ~= "" and r.id == cur_id) and accent or dim
			love.graphics.setColor(col[1] as number, col[2] as number, col[3] as number, (col[4] or 1) as number)
			love.graphics.rectangle("line", x * sc, y * sc, r.w * MAP_SCALE * sc, r.h * MAP_SCALE * sc)
			for j = 1, #(r.doors or {}) do
				local d = r.doors[j]
				local dc = (DOOR_COLOR and DOOR_COLOR[tostring(d.kind or "open")]) or accent
				love.graphics.setColor(dc[1] as number, dc[2] as number, dc[3] as number, (dc[4] or 1) as number)
				local dx = (tonumber(d.dx) or (r.w - 1)) as number
				local dy = (tonumber(d.dy) or (r.h / 2)) as number
				love.graphics.rectangle("fill", (x + dx * MAP_SCALE) * sc, (y + dy * MAP_SCALE) * sc, 2 * sc, 2 * sc)
			end
			for j = 1, #(r.items or {}) do
				local it = r.items[j]
				local uid = tostring(it.uid or it.ability or j)
				if not globoolSH("item_" .. uid, "check") and not globoolSH("ability_" .. tostring(it.ability or ""), "check") then
					love.graphics.setColor(1, 0.9, 0.2, 0.8)
					local ix = (tonumber(it.dx) or (r.w / 2)) as number
					local iy = (tonumber(it.dy) or (r.h / 2)) as number
					love.graphics.circle("fill", (x + ix * MAP_SCALE) * sc, (y + iy * MAP_SCALE) * sc, 1.5 * sc)
				end
			end
		end
	end
	love.graphics.setColor(1, 1, 1, 1)
end

return { metroidmap_toggle = metroidmap_toggle, metroidmap_close = metroidmap_close, metroidmap_draw = metroidmap_draw }
