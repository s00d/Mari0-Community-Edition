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

-- Filter pack names (case-insensitive substring). Returns source indices.
global function menu_mappack_filter_indices(names: {any}, filter: string): {integer}
	local out: {integer} = {}
	local f = (filter or ""):lower()
	for i = 1, #names do
		local n = tostring(names[i] or ""):lower()
		if f == "" or string.find(n, f, 1, true) then
			out[#out + 1] = i
		end
	end
	return out
end

-- Two-panel mappack layout (400×224 UI space).
-- opts: { visible_count, scroll, row_h?, filter_h? }
global function menu_layout_mappack(opts: {string:any}|nil): {string:any}
	local o = (opts or {}) as {string:any}
	local row_h = (o.row_h as number) or 24
	local filter_h = (o.filter_h as number) or 16
	local vis = (o.visible_count as number) or 0
	local scroll = (o.scroll as number) or 0
	local list = { x = 16, y = 24, w = 224, h = 176 }
	local preview = { x = 248, y = 24, w = 136, h = 176 }
	local tabs: {any} = {
		{ id = "local", label = "local", x = 16, y = 8, w = 56, h = 16 },
		{ id = "online", label = "dlc", x = 80, y = 8, w = 40, h = 16 },
		{ id = "toconvert", label = "convert", x = 128, y = 8, w = 64, h = 16 },
	}
	local filter_rect = { x = list.x + 8, y = list.y + 8, w = list.w - 16, h = filter_h }
	local rows: {any} = {}
	local list_top = list.y + 8 + filter_h + 8
	for i = 1, vis do
		table.insert(rows, {
			x = list.x,
			y = list_top + (i - 1) * row_h,
			w = list.w,
			h = row_h,
			slot = i,
			list_i = math.floor(scroll) + i,
		})
	end
	return {
		list = list,
		preview = preview,
		tabs = tabs,
		filter = filter_rect,
		rows = rows,
		row_h = row_h,
		footer = { x = 16, y = 208, text = "_dir4_dir6 list  enter ok  esc back  m folder" },
	} as {string:any}
end

-- Options tab strip (matches menu_draw_options tab positions, snapped to 8).
global function menu_layout_options_tabs(): {any}
	return {
		{ id = 1, label = "controls", x = 24, y = 16, w = 72, h = 16 },
		{ id = 2, label = "skins", x = 96, y = 16, w = 48, h = 16 },
		{ id = 3, label = "misc.", x = 144, y = 16, w = 40, h = 16 },
		{ id = 4, label = "cheat", x = 184, y = 16, w = 48, h = 16 },
	} as {any}
end

-- Options body rows: selection index 1 is tabs; body starts at selection 2.
global function menu_layout_options_rows(count: number): {string:any}
	local rects: {any} = {}
	local panel = { x = 16, y = 16, w = 224, h = 192 }
	local oy = 40
	local line = 16
	-- selection 1 = tabs (no body row)
	for i = 2, count do
		table.insert(rects, {
			x = panel.x,
			y = oy + (i - 2) * line,
			w = panel.w,
			h = line,
			selection = i,
		})
	end
	return { panel = panel, rows = rects } as {string:any}
end

-- Pause menu centered on game width (in unscaled UI units relative to width*16).
global function menu_layout_pause(screen_w: number): {string:any}
	local menuwidth = 120
	local menuheight = 168 -- snap 8
	local px = math.floor((screen_w - menuwidth) / 16) * 8 -- center on 8px grid
	local py = 24
	local line = 24
	local rects: {any} = {}
	for i = 1, 6 do
		table.insert(rects, {
			x = px,
			y = py + 16 + (i - 1) * line,
			w = menuwidth,
			h = line,
			index = i,
		})
	end
	return {
		panel = { x = px, y = py, w = menuwidth, h = menuheight },
		rects = rects,
	} as {string:any}
end

-- Levelscreen info panel (centered).
global function menu_layout_levelscreen(screen_w: number): {string:any}
	local pw, ph = 192, 80
	return {
		panel = {
			x = math.floor((screen_w - pw) / 2),
			y = 64,
			w = pw,
			h = ph,
		},
	} as {string:any}
end

return {
	menu_visible_items = menu_visible_items,
	menu_layout_main = menu_layout_main,
	menu_hit = menu_hit,
	menu_hit_spinner = menu_hit_spinner,
	menu_rects_on_grid = menu_rects_on_grid,
	menu_rects_non_overlap = menu_rects_non_overlap,
	menu_mappack_filter_indices = menu_mappack_filter_indices,
	menu_layout_mappack = menu_layout_mappack,
	menu_layout_options_tabs = menu_layout_options_tabs,
	menu_layout_options_rows = menu_layout_options_rows,
	menu_layout_pause = menu_layout_pause,
	menu_layout_levelscreen = menu_layout_levelscreen,
}
