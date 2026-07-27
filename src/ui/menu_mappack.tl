--[[ Mappack picker: two-panel layout + name filter (guielement input). ]]

local ROW_H = 24
local VISIBLE = 6
local FILTER_H = 16

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
			scroll = onlinemappackscrollsmooth or onlinemappackscroll or 0,
		}
	elseif mappacktype == "toconvert" then
		return {
			list = toconvertmappacklist or {},
			name = toconvertmappackname or toconvertmappacklist or {},
			author = toconvertmappackauthor or {},
			desc = toconvertmappackdescription or {},
			icon = toconvertmappackicon or {},
			sel = toconvertmappackselection or 1,
			scroll = toconvertmappackscrollsmooth or toconvertmappackscroll or 0,
		}
	end
	return {
		list = mappacklist or {},
		name = mappackname or mappacklist or {},
		author = mappackauthor or {},
		desc = mappackdescription or {},
		icon = mappackicon or {},
		sel = mappackselection or 1,
		scroll = mappackscrollsmooth or mappackscroll or 0,
	}
end

global function menu_mappack_filtered(): {integer}
	local L = current_lists()
	local f = filter_text()
	-- filter only on local packs (DLC/convert keep full list)
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
	local scroll = L.scroll as number
	return menu_layout_mappack({
		visible_count = math.min(VISIBLE, #filt),
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
		24,
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
	local L = current_lists()
	if mappacktype == "online" then
		onlinemappackselection = src_i
		if onlinemappacklist and onlinemappacklist[src_i] then
			mappack = onlinemappacklist[src_i]
		end
		onlineupdatescroll()
	elseif mappacktype == "toconvert" then
		toconvertmappackselection = src_i
		toconvertupdatescroll()
	else
		mappackselection = src_i
		if mappacklist and mappacklist[src_i] then
			mappack = mappacklist[src_i]
		end
		updatescroll()
	end
end

local function draw_tabs(lay: {string:any})
	local tabs = lay.tabs as {any}
	local active = mappackhorscroll or 0
	for i = 1, #tabs do
		local t = tabs[i] as {string:any}
		local on = (i - 1) == active
		if on then
			ui_set_color("sel")
			love.graphics.rectangle("fill", (t.x as number) * scale, (t.y as number) * scale, (t.w as number) * scale, (t.h as number) * scale)
			ui_set_color("text_accent")
		else
			ui_set_color("text_dim")
		end
		properprint(t.label as string, ((t.x as number) + 4) * scale, ((t.y as number) + 4) * scale)
	end
	love.graphics.setColor(1, 1, 1, 1)
end

local function draw_preview(lay: {string:any}, src_i: integer)
	local p = lay.preview as {string:any}
	draw_panel(p.x as number, p.y as number, p.w as number, p.h as number)
	local L = current_lists()
	local pad = 8
	local x = (p.x as number) + pad
	local y = (p.y as number) + pad
	if src_i < 1 or src_i > #(L.list as {any}) then
		ui_set_color("text_dim")
		properprint("no pack", x * scale, (y + 40) * scale)
		love.graphics.setColor(1, 1, 1, 1)
		return
	end
	local icon = (L.icon as {any})[src_i]
	if icon then
		local img = icon as Image
		local scale2w = scale * 50 / math.max(1, img:getWidth())
		local scale2h = scale * 50 / math.max(1, img:getHeight())
		love.graphics.draw(img, (x + 20) * scale, y * scale, 0, scale2w, scale2h)
	elseif mappacknoicon then
		love.graphics.draw(mappacknoicon, (x + 20) * scale, y * scale, 0, scale, scale)
	end
	ui_set_color("text")
	properprint(menu_mappack_title((L.name as {any})[src_i]), x * scale, (y + 56) * scale)
	ui_set_color("text_dim")
	if (L.author as {any})[src_i] then
		properprint(menu_mappack_author_line((L.author as {any})[src_i]), x * scale, (y + 68) * scale)
	end
	if (L.desc as {any})[src_i] then
		local d1, d2, d3 = menu_mappack_desc_lines((L.desc as {any})[src_i])
		properprint(d1, x * scale, (y + 88) * scale)
		properprint(d2, x * scale, (y + 100) * scale)
		properprint(d3, x * scale, (y + 112) * scale)
	end
	if mappacktype == "local" and mappack_skipped_count and mappack_skipped_count > 0 then
		ui_set_color("text_dim")
		properprint(tostring(mappack_skipped_count) .. " packs skipped", x * scale, (y + 140) * scale)
	end
	love.graphics.setColor(1, 1, 1, 1)
end

local function draw_list(lay: {string:any})
	local list = lay.list as {string:any}
	draw_panel(list.x as number, list.y as number, list.w as number, list.h as number)
	local L = current_lists()
	local filt = menu_mappack_filtered()
	local scroll = math.floor(L.scroll as number)
	local sel = L.sel as integer

	if mappacktype == "local" then
		ui_set_color("text_dim")
		properprint("filter", ((list.x as number) + 8) * scale, ((list.y as number) + 8 + FILTER_H + 2) * scale - 10 * scale)
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
		properprint(msg, ((list.x as number) + 16) * scale, ((list.y as number) + 64) * scale)
		love.graphics.setColor(1, 1, 1, 1)
		return
	end

	local rows = lay.rows as {any}
	for slot = 1, #rows do
		local fi = scroll + slot
		if fi > #filt then
			break
		end
		local src_i = filt[fi]
		local r = rows[slot] as {string:any}
		local state = "normal"
		if src_i == sel then
			state = "selected"
		elseif ui_input_mode == "mouse" then
			-- hover filled by mouse path via selection
		end
		if state == "selected" then
			ui_set_color("sel")
			love.graphics.rectangle("fill", (r.x as number) * scale, (r.y as number) * scale, (r.w as number) * scale, (r.h as number) * scale)
			ui_set_color("text_accent")
			properprint("_dir5", ((r.x as number) + 2) * scale, ((r.y as number) + 8) * scale)
		else
			ui_set_color("text")
		end
		local icon = (L.icon as {any})[src_i]
		local tx = (r.x as number) + 28
		if icon then
			local img = icon as Image
			local s2 = (ROW_H - 4) * scale / math.max(1, math.max(img:getWidth(), img:getHeight()))
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(img, ((r.x as number) + 4) * scale, ((r.y as number) + 2) * scale, 0, s2, s2)
		end
		if state == "selected" then
			ui_set_color("text_accent")
		else
			ui_set_color("text")
		end
		properprint(menu_mappack_title((L.name as {any})[src_i]), tx * scale, ((r.y as number) + 4) * scale)
		ui_set_color("text_dim")
		if (L.author as {any})[src_i] then
			properprint(menu_mappack_author_line((L.author as {any})[src_i]), tx * scale, ((r.y as number) + 14) * scale)
		end
	end
	love.graphics.setColor(1, 1, 1, 1)

	-- scrollbar when needed
	if #filt > VISIBLE and mappackscrollbar then
		local maxscroll = math.max(1, #filt - VISIBLE)
		local t = math.min(1, math.max(0, scroll / maxscroll))
		love.graphics.draw(mappackscrollbar, ((list.x as number) + (list.w as number) - 10) * scale, ((list.y as number) + 32 + t * 120) * scale, 0, scale, scale)
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
	ui_set_color("text_dim")
	properprint(footer.text as string, (footer.x as number) * scale, (footer.y as number) * scale)
	love.graphics.setColor(1, 1, 1, 1)

	-- draw filter input via guielement (already in guielements draw loop? menu doesn't draw guielements by default)
	if mappacktype == "local" and guielements and guielements["mappackfilter"] and guielements["mappackfilter"].active then
		guielements["mappackfilter"]:draw()
	end
end

global function menu_mappack_mousepressed(ux: number, uy: number, button: any): boolean
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
	local rows = lay.rows as {any}
	local i = menu_hit(rows, ux, uy)
	if i then
		local fi = scroll + i
		if fi >= 1 and fi <= #filt then
			local src = filt[fi]
			if src == (L.sel as integer) then
				-- confirm (same as enter)
				if mappacktype == "toconvert" then
					local toconvert = toconvertmappacklist[src]
					convertmappack(toconvert)
					mappack = toconvert
					gamestate = "menu"
					menu_mappack_teardown_filter()
					saveconfig()
					loadbackgroundsafe("1-1.txt")
				else
					gamestate = "menu"
					menu_mappack_teardown_filter()
					saveconfig()
					if mappack == "custom_mappack" then
						createmappack()
					end
					loadbackgroundsafe("1-1.txt")
				end
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
			set_selection(filt[fi])
		end
	end
end

-- Keyboard nav among filtered indices
global function menu_mappack_move(delta: integer)
	local filt = menu_mappack_filtered()
	if #filt == 0 then
		return
	end
	local L = current_lists()
	local cur = L.sel as integer
	local pos = 1
	for i = 1, #filt do
		if filt[i] == cur then
			pos = i
			break
		end
	end
	pos = math.max(1, math.min(#filt, pos + delta))
	set_selection(filt[pos])
end
