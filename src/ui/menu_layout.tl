--[[ Pure menu layout/hit — shared by draw, mouse, and tests (no LÖVE). ]]

global function menu_visible_items(screen: {string:any}): {any}
	local out: {any} = {}
	local items = (screen.items as {any}) or {}
	for i = 1, #items do
		local it = items[i] as {string:any}
		local vis = it.visible
		local ok = true
		if type(vis) == "function" then
			ok = (vis as function(): boolean)()
		elseif vis ~= nil then
			ok = not not vis
		end
		if ok then
			out[#out + 1] = it
		end
	end
	return out
end

-- Main menu layout: one panel, full-width row hitboxes, optional players spinner on newgame row.
-- Returns { panel={x,y,w,h}, rects={...}, spinner={dec,inc,cycle}|nil, footer={x,y,text} }
global function menu_layout_main(screen: {string:any}): {string:any}
	local grid = 8
	local line = 16
	local pad = 8
	local panel_w = 192
	local panel_x = math.floor((400 - panel_w) / 2) -- 104
	local items = menu_visible_items(screen)
	local n = #items
	local panel_h = math.max(24, pad * 2 + n * line)
	-- snap to 8
	panel_h = math.ceil(panel_h / grid) * grid
	local panel_y = 96
	local rects: {any} = {}
	local spinner: {string:any}|nil = nil
	local ox = panel_x
	local oy = panel_y + pad
	for i = 1, n do
		local it = items[i] as {string:any}
		local r: {string:any} = {
			x = ox,
			y = oy + (i - 1) * line,
			w = panel_w,
			h = line,
			item = it,
			label = it.label,
			id = it.id,
			index = i,
		}
		rects[i] = r
		if it.id == "newgame" then
			-- left/right arrow hitboxes around player count (fixed column)
			local cy = r.y
			spinner = {
				dec = { x = ox + pad, y = cy, w = 16, h = line, kind = "dec" },
				inc = { x = ox + pad + 40, y = cy, w = 16, h = line, kind = "inc" },
				cycle = { x = ox + pad + 16, y = cy, w = 24, h = line, kind = "cycle" },
			}
		end
	end
	return {
		panel = { x = panel_x, y = panel_y, w = panel_w, h = panel_h },
		rects = rects,
		spinner = spinner,
		footer = { x = 48, y = 208, text = "_dir4_dir6 select   enter ok   esc quit" },
		items = items,
	}
end

global function menu_hit(rects: {any}, mx: number, my: number): integer|nil
	for i = 1, #rects do
		local r = rects[i] as {string:any}
		local x = r.x as number
		local y = r.y as number
		local w = r.w as number
		local h = r.h as number
		if mx >= x and mx < x + w and my >= y and my < y + h then
			return i
		end
	end
	return nil
end

global function menu_hit_spinner(spinner: {string:any}|nil, mx: number, my: number): string|nil
	if not spinner then
		return nil
	end
	local sp = spinner as {string:any}
	for _, key in ipairs({ "dec", "inc", "cycle" }) do
		local raw = sp[key]
		if raw then
			local r = raw as {string:any}
			local x, y, w, h = r.x as number, r.y as number, r.w as number, r.h as number
			if mx >= x and mx < x + w and my >= y and my < y + h then
				return r.kind as string
			end
		end
	end
	return nil
end

global function menu_rects_on_grid(rects: {any}): boolean
	for i = 1, #rects do
		local r = rects[i] as {string:any}
		for _, k in ipairs({ "x", "y", "w", "h" }) do
			local v = r[k] as number
			if v % 8 ~= 0 then
				return false
			end
		end
	end
	return true
end

global function menu_rects_non_overlap(rects: {any}): boolean
	for i = 1, #rects do
		local a = rects[i] as {string:any}
		for j = i + 1, #rects do
			local b = rects[j] as {string:any}
			local ax, ay, aw, ah = a.x as number, a.y as number, a.w as number, a.h as number
			local bx, by, bw, bh = b.x as number, b.y as number, b.w as number, b.h as number
			if ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by then
				return false
			end
		end
	end
	return true
end

return {
	menu_visible_items = menu_visible_items,
	menu_layout_main = menu_layout_main,
	menu_hit = menu_hit,
	menu_hit_spinner = menu_hit_spinner,
	menu_rects_on_grid = menu_rects_on_grid,
	menu_rects_non_overlap = menu_rects_non_overlap,
}
