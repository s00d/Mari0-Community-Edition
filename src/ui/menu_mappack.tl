--[[ Mappack picker: two-panel layout, filtered scroll, mouse + wheel. ]]

local ROW_H = 24
local VISIBLE = 6
local FILTER_H = 16
local CHAR_W = 8

local function filter_text(): string
	local el = guielements and guielements["mappackfilter"]
	if el and el.value then
		return tostring(el.value)
	end
	return ""
end

local function current_lists(): {string:any}
	if mappacktype == "online" then
		return {
			list = onlinemappacklist or {},
			name = onlinemappackname or onlinemappacklist or {},
			author = onlinemappackauthor or {},
			desc = onlinemappackdescription or {},
			icon = onlinemappackicon or {},
			sel = onlinemappackselection or 1,
			scroll = onlinemappackscroll or 0,
		}
	elseif mappacktype == "toconvert" then
		return {
			list = toconvertmappacklist or {},
			name = toconvertmappackname or toconvertmappacklist or {},
			author = toconvertmappackauthor or {},
			desc = toconvertmappackdescription or {},
			icon = toconvertmappackicon or {},
			sel = toconvertmappackselection or 1,
			scroll = toconvertmappackscroll or 0,
		}
	end
	return {
		list = mappacklist or {},
		name = mappackname or mappacklist or {},
		author = mappackauthor or {},
		desc = mappackdescription or {},
		icon = mappackicon or {},
		sel = mappackselection or 1,
		scroll = mappackscroll or 0,
	}
end

local function write_scroll(n: number)
	n = math.max(0, n)
	if mappacktype == "online" then
		onlinemappackscroll = n
		onlinemappackscrollsmooth = n
	elseif mappacktype == "toconvert" then
		toconvertmappackscroll = n
		toconvertmappackscrollsmooth = n
	else
		mappackscroll = n
		mappackscrollsmooth = n
	end
end

local function filt_index_of(filt: {integer}, src: integer): integer
	for i = 1, #filt do
		if filt[i] == src then
			return i
		end
	end
	return 1
end

-- Keep filtered selection row inside the visible window.
local function ensure_visible(filt: {integer}, src_i: integer)
	if #filt == 0 then
		write_scroll(0)
		return
	end
	local pos = filt_index_of(filt, src_i)
	local maxscroll = math.max(0, #filt - VISIBLE)
	local scroll: number = 0
	if mappacktype == "online" then
		scroll = (onlinemappackscroll as number) or 0
	elseif mappacktype == "toconvert" then
		scroll = (toconvertmappackscroll as number) or 0
	else
		scroll = (mappackscroll as number) or 0
	end
	scroll = math.floor(scroll)
	if pos < scroll + 1 then
		scroll = pos - 1
	elseif pos > scroll + VISIBLE then
		scroll = pos - VISIBLE
	end
	scroll = math.max(0, math.min(maxscroll, scroll))
	write_scroll(scroll)
end

global function menu_mappack_filtered(): {integer}
	local L = current_lists()
	local f = filter_text()
	if mappacktype ~= "local" then
		local out: {integer} = {}
		for i = 1, #(L.list as {any}) do
			out[i] = i
		end
		return out
	end
	return menu_mappack_filter_indices(L.name as {any}, f)
end

global function menu_mappack_layout(): {string:any}
	local filt = menu_mappack_filtered()
	local L = current_lists()
	local scroll = math.floor(L.scroll as number)
	local maxscroll = math.max(0, #filt - VISIBLE)
	if scroll > maxscroll then
		scroll = maxscroll
		write_scroll(scroll)
	end
	return menu_layout_mappack({
		visible_count = math.min(VISIBLE, math.max(0, #filt)),
		scroll = scroll,
		row_h = ROW_H,
		filter_h = FILTER_H,
	})
end

global function menu_mappack_setup_filter()
	if not guielements then
		return
	end
	local lay = menu_layout_mappack({ visible_count = VISIBLE, scroll = 0, row_h = ROW_H, filter_h = FILTER_H })
	local fr = lay.filter as {string:any}
	local existing = guielements["mappackfilter"]
	if existing then
		existing.active = (mappacktype == "local")
		existing.x = fr.x as number
		existing.y = fr.y as number
		return
	end
	guielements["mappackfilter"] = guielement:new(
		"input",
		fr.x as number,
		fr.y as number,
		20,
		function() end,
		"",
		32,
		1
	)
	guielements["mappackfilter"].active = (mappacktype == "local")
end

global function menu_mappack_teardown_filter()
	if guielements and guielements["mappackfilter"] then
		guielements["mappackfilter"].active = false
		guielements["mappackfilter"].inputting = false
	end
end

local function set_selection(src_i: integer)
	if mappacktype == "online" then
		onlinemappackselection = src_i
		if onlinemappacklist and onlinemappacklist[src_i] then
			mappack = onlinemappacklist[src_i]
		end
	elseif mappacktype == "toconvert" then
		toconvertmappackselection = src_i
	else
		mappackselection = src_i
		if mappacklist and mappacklist[src_i] then
			mappack = mappacklist[src_i]
		end
	end
	ensure_visible(menu_mappack_filtered(), src_i)
end

local function confirm_selection(src: integer)
	if mappacktype == "toconvert" then
		local toconvert = toconvertmappacklist[src]
		convertmappack(toconvert)
		mappack = toconvert
		gamestate = "menu"
		menu_mappack_teardown_filter()
		saveconfig()
		loadbackgroundsafe("1-1.txt")
	else
		set_selection(src)
		gamestate = "menu"
		menu_mappack_teardown_filter()
		saveconfig()
		if mappack == "custom_mappack" then
			createmappack()
		end
		loadbackgroundsafe("1-1.txt")
	end
end

local function clip_print(s: string, x: number, y: number, max_chars: integer)
	if max_chars < 1 then
		return
	end
	properprint(string.sub(s, 1, max_chars), x * scale, y * scale)
end

local function draw_tabs(lay: {string:any})
	local tabs = lay.tabs as {any}
	-- Normalize tab ids to 0/1/2 to match mappackhorscroll
	local normalized: {any} = {}
	for i = 1, #tabs do
		local t = tabs[i] as {string:any}
		normalized[i] = {
			id = i - 1,
			label = t.label,
			x = t.x, y = t.y, w = t.w, h = t.h,
		}
	end
	menu_draw_tabs(normalized, mappackhorscroll or 0, false)
end

local function draw_preview(lay: {string:any}, src_i: integer)
	local p = lay.preview as {string:any}
	local px, py, pw, ph = p.x as number, p.y as number, p.w as number, p.h as number
	draw_panel(px, py, pw, ph)
	local L = current_lists()
	local pad = 8
	local x = px + pad
	local y = py + pad
	local maxc = math.floor((pw - pad * 2) / CHAR_W)

	love.graphics.setScissor(px * scale, py * scale, pw * scale, ph * scale)

	if src_i < 1 or src_i > #(L.list as {any}) then
		ui_set_color("text_dim")
		clip_print("no pack", x, y + 40, maxc)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setScissor()
		return
	end
	local icon = (L.icon as {any})[src_i]
	if icon then
		local img = icon as Image
		local scale2w = scale * 50 / math.max(1, img:getWidth())
		local scale2h = scale * 50 / math.max(1, img:getHeight())
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(img, (x + 20) * scale, y * scale, 0, scale2w, scale2h)
	elseif mappacknoicon then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(mappacknoicon, (x + 20) * scale, y * scale, 0, scale, scale)
	end
	ui_set_color("text")
	clip_print(menu_mappack_title((L.name as {any})[src_i], maxc), x, y + 56, maxc)
	ui_set_color("text_dim")
	if (L.author as {any})[src_i] then
		clip_print(menu_mappack_author_line((L.author as {any})[src_i], maxc), x, y + 68, maxc)
	end
	if (L.desc as {any})[src_i] then
		local d1, d2, d3, d4 = menu_mappack_desc_lines((L.desc as {any})[src_i], maxc)
		clip_print(d1, x, y + 88, maxc)
		clip_print(d2, x, y + 100, maxc)
		clip_print(d3, x, y + 112, maxc)
		clip_print(d4, x, y + 124, maxc)
	end
	if mappacktype == "local" and mappack_skipped_count and mappack_skipped_count > 0 then
		ui_set_color("text_dim")
		clip_print(tostring(mappack_skipped_count) .. " packs skipped", x, y + 148, maxc)
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setScissor()
end

local function scrollbar_rect(lay: {string:any}, filt_n: integer, scroll: number): {string:any}|nil
	if filt_n <= VISIBLE then
		return nil
	end
	local list = lay.list as {string:any}
	local track_x = (list.x as number) + (list.w as number) - 10
	local track_y = (list.y as number) + 8 + FILTER_H + 8
	local track_h = VISIBLE * ROW_H
	local maxscroll = math.max(1, filt_n - VISIBLE)
	local thumb_h = math.max(12, math.floor(track_h * VISIBLE / filt_n))
	local t = math.min(1, math.max(0, scroll / maxscroll))
	local thumb_y = track_y + t * (track_h - thumb_h)
	return {
		x = track_x, y = thumb_y, w = 8, h = thumb_h,
		track_x = track_x, track_y = track_y, track_h = track_h,
	}
end

local function draw_list(lay: {string:any})
	local list = lay.list as {string:any}
	local lx, ly, lw, lh = list.x as number, list.y as number, list.w as number, list.h as number
	draw_panel(lx, ly, lw, lh)
	local L = current_lists()
	local filt = menu_mappack_filtered()
	local scroll = math.floor(L.scroll as number)
	local sel = L.sel as integer
	local text_x0 = lx + 28
	local maxc = math.floor((lw - 28 - 14) / CHAR_W)

	if mappacktype == "local" then
		ui_set_color("text_dim")
		properprint("filter", (lx + 8) * scale, (ly + 4) * scale)
	end

	if #filt == 0 then
		ui_set_color("text_dim")
		local msg = "no mappacks"
		if mappacktype == "toconvert" then
			msg = "toconvert empty||put 1.6 packs in|toconvert/"
		elseif mappacktype == "online" then
			msg = "dlc unavailable"
		elseif filter_text() ~= "" then
			msg = "no match"
		end
		properprint(msg, (lx + 16) * scale, (ly + 64) * scale)
		love.graphics.setColor(1, 1, 1, 1)
		return
	end

	local rows = lay.rows as {any}
	local list_top = ly + 8 + FILTER_H + 8
	love.graphics.setScissor(lx * scale, list_top * scale, lw * scale, VISIBLE * ROW_H * scale)

	for slot = 1, #rows do
		local fi = scroll + slot
		if fi > #filt then
			break
		end
		local src_i = filt[fi]
		local r = rows[slot] as {string:any}
		local hovered = false
		if ui_input_mode == "mouse" then
			local mx, my = mouseui_x / scale, mouseui_y / scale
			if mx >= (r.x as number) and mx < (r.x as number) + (r.w as number)
				and my >= (r.y as number) and my < (r.y as number) + (r.h as number) then
				hovered = true
			end
		end
		if src_i == sel then
			menu_draw_row_bg(r.x as number, r.y as number, r.w as number, r.h as number, "sel", 1)
			menu_draw_cursor((r.x as number) + 2, (r.y as number) + 8)
		elseif hovered then
			menu_draw_row_bg(r.x as number, r.y as number, r.w as number, r.h as number, "hover", 1)
		end
		if src_i == sel then
			ui_set_color("text_accent")
		else
			ui_set_color("text")
		end
		local icon = (L.icon as {any})[src_i]
		if icon then
			local img = icon as Image
			local s2 = (ROW_H - 4) * scale / math.max(1, math.max(img:getWidth(), img:getHeight()))
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(img, ((r.x as number) + 4) * scale, ((r.y as number) + 2) * scale, 0, s2, s2)
		end
		if src_i == sel then
			ui_set_color("text_accent")
		else
			ui_set_color("text")
		end
		clip_print(menu_mappack_title((L.name as {any})[src_i], maxc), text_x0, (r.y as number) + 4, maxc)
		ui_set_color("text_dim")
		if (L.author as {any})[src_i] then
			clip_print(menu_mappack_author_line((L.author as {any})[src_i], maxc), text_x0, (r.y as number) + 14, maxc)
		end
	end
	love.graphics.setScissor()
	love.graphics.setColor(1, 1, 1, 1)

	local sb = scrollbar_rect(lay, #filt, scroll)
	if sb ~= nil then
		local s = sb as {string:any}
		local stx = s["track_x"] as number
		local sty = s["track_y"] as number
		local sth = s["track_h"] as number
		local sx = s["x"] as number
		local sy = s["y"] as number
		local sw = s["w"] as number
		local sh = s["h"] as number
		ui_set_color("panel_edge")
		love.graphics.rectangle("fill", stx * scale, sty * scale, 8 * scale, sth * scale)
		ui_set_color("text_accent")
		love.graphics.rectangle("fill", sx * scale, sy * scale, sw * scale, sh * scale)
		love.graphics.setColor(1, 1, 1, 1)
	end
end

global function menu_mappack_draw()
	if loadingonlinemappacks then
		draw_panel(16, 24, 368, 176)
		ui_set_color("text")
		properprint("a little patience..|downloading " .. tostring(currentdownload) .. " of " .. tostring(downloadcount), 40 * scale, 80 * scale)
		love.graphics.setColor(1, 1, 1, 1)
		return
	end

	local lay = menu_mappack_layout()
	draw_tabs(lay)
	draw_list(lay)
	local L = current_lists()
	draw_preview(lay, L.sel as integer)

	local footer = lay.footer as {string:any}
	menu_draw_footer(footer.x as number, footer.y as number, footer.text as string)

	if mappacktype == "local" and guielements and guielements["mappackfilter"] and guielements["mappackfilter"].active then
		guielements["mappackfilter"]:draw()
	end
end

global function menu_mappack_wheel(delta: integer)
	local filt = menu_mappack_filtered()
	if #filt == 0 then
		return
	end
	local L = current_lists()
	local maxscroll = math.max(0, #filt - VISIBLE)
	local scroll = math.floor(L.scroll as number) + delta
	scroll = math.max(0, math.min(maxscroll, scroll))
	write_scroll(scroll)
	-- keep selection inside newly visible window
	local pos = filt_index_of(filt, L.sel as integer)
	if pos < scroll + 1 then
		set_selection(filt[scroll + 1])
	elseif pos > scroll + VISIBLE then
		set_selection(filt[math.min(#filt, scroll + VISIBLE)])
	end
end

global function menu_mappack_mousepressed(ux: number, uy: number, button: any): boolean
	if button == "wu" then
		menu_mappack_wheel(-1)
		return true
	elseif button == "wd" then
		menu_mappack_wheel(1)
		return true
	end
	if button ~= "l" then
		return false
	end
	local lay = menu_mappack_layout()
	-- tabs
	local tabs = lay.tabs as {any}
	for i = 1, #tabs do
		local t = tabs[i] as {string:any}
		if ux >= (t.x as number) and ux < (t.x as number) + (t.w as number)
			and uy >= (t.y as number) and uy < (t.y as number) + (t.h as number) then
			local target = i - 1
			if target ~= (mappackhorscroll or 0) then
				if target == 0 then
					loadmappacks()
					mappackhorscroll = 0
				elseif target == 1 then
					loadonlinemappacks()
					mappackhorscroll = 1
				else
					loadtoconvertmappacks()
					mappackhorscroll = 2
				end
				menu_mappack_setup_filter()
			end
			return true
		end
	end

	local filt = menu_mappack_filtered()
	local L = current_lists()
	local scroll = math.floor(L.scroll as number)

	-- scrollbar track click → jump
	local sb = scrollbar_rect(lay, #filt, scroll)
	if sb ~= nil then
		local s = sb as {string:any}
		local stx = s["track_x"] as number
		local sty = s["track_y"] as number
		local sth = s["track_h"] as number
		if ux >= stx and ux < stx + 8 and uy >= sty and uy < sty + sth then
			local rel = (uy - sty) / math.max(1, sth)
			local maxscroll = math.max(0, #filt - VISIBLE)
			write_scroll(math.floor(rel * maxscroll + 0.5))
			return true
		end
	end

	local rows = lay.rows as {any}
	local i = menu_hit(rows, ux, uy)
	if i then
		local fi = scroll + i
		if fi >= 1 and fi <= #filt then
			local src = filt[fi]
			if src == (L.sel as integer) then
				confirm_selection(src)
			else
				set_selection(src)
			end
			return true
		end
	end
	return false
end

global function menu_mappack_mousemoved(ux: number, uy: number)
	local lay = menu_mappack_layout()
	local filt = menu_mappack_filtered()
	local L = current_lists()
	local scroll = math.floor(L.scroll as number)
	local i = menu_hit(lay.rows as {any}, ux, uy)
	if i then
		local fi = scroll + i
		if fi >= 1 and fi <= #filt then
			local src = filt[fi]
			-- hover selects but does not force-scroll away from mouse window
			if mappacktype == "online" then
				onlinemappackselection = src
				if onlinemappacklist and onlinemappacklist[src] then
					mappack = onlinemappacklist[src]
				end
			elseif mappacktype == "toconvert" then
				toconvertmappackselection = src
			else
				mappackselection = src
				if mappacklist and mappacklist[src] then
					mappack = mappacklist[src]
				end
			end
		end
	end
end

global function menu_mappack_move(delta: integer)
	local filt = menu_mappack_filtered()
	if #filt == 0 then
		return
	end
	local L = current_lists()
	local pos = filt_index_of(filt, L.sel as integer)
	pos = math.max(1, math.min(#filt, pos + delta))
	set_selection(filt[pos])
end
