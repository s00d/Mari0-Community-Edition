--[[ Shared UI theme: 8px grid, color tokens, 9-slice panel, menu draw helpers. ]]

global record UITheme
	GRID: number
	PAD: number
	GAP: number
	LINE: number
	SCREEN_W: number
	SCREEN_H: number
	COL: {string:{number}}
	panel_img: Image|nil
	panel_inset_img: Image|nil
	panel_quads: {Quad}|nil
	panel_inset_quads: {Quad}|nil
	debug_assert: boolean
end

global UI: UITheme = {
	GRID = 8,
	PAD = 8,
	GAP = 8,
	LINE = 16,
	SCREEN_W = 400,
	SCREEN_H = 224,
	COL = {
		-- CE brand: cool slate panels + amber accent (not purple SaaS)
		text = {1.00, 1.00, 1.00, 1},
		text_dim = {0.58, 0.60, 0.66, 1},
		text_accent = {1.00, 0.84, 0.22, 1},
		panel = {0.04, 0.05, 0.09, 0.90},
		panel_edge = {0.32, 0.36, 0.48, 1},
		hover = {1.00, 1.00, 1.00, 0.08},
		sel = {1.00, 0.84, 0.22, 0.16},
		rule = {0.28, 0.30, 0.40, 1},
		overlay = {0.00, 0.00, 0.00, 0.48},
		tab_on = {1.00, 0.84, 0.22, 0.20},
		status = {0.45, 0.90, 0.95, 1},
	},
	panel_img = nil,
	panel_inset_img = nil,
	panel_quads = nil,
	panel_inset_quads = nil,
	debug_assert = false,
}

local function panel_quads(img: Image): {Quad}
	local q: {Quad} = {}
	local iw, ih = img:getWidth(), img:getHeight()
	for r = 0, 2 do
		for c = 0, 2 do
			q[r * 3 + c + 1] = love.graphics.newQuad(c * 8, r * 8, 8, 8, iw, ih)
		end
	end
	return q
end

-- Loads panels via AssetStore (no love.graphics.newImage here — static_api_lint).
global function theme_init()
	if assets then
		if love.filesystem.getInfo("assets/ui/panel.png") then
			assets:register_image("ui_panel", "assets/ui/panel.png")
			UI.panel_img = assets:get_image("ui_panel")
		end
		if love.filesystem.getInfo("assets/ui/panel_inset.png") then
			assets:register_image("ui_panel_inset", "assets/ui/panel_inset.png")
			UI.panel_inset_img = assets:get_image("ui_panel_inset")
		end
	end
	if UI.panel_img then
		(UI.panel_img as Image):setFilter("nearest", "nearest")
		UI.panel_quads = panel_quads(UI.panel_img as Image)
	end
	if UI.panel_inset_img then
		(UI.panel_inset_img as Image):setFilter("nearest", "nearest")
		UI.panel_inset_quads = panel_quads(UI.panel_inset_img as Image)
	end

	UI.debug_assert = false
	local dbg = (_G as {string:any}).MARI0_DEBUG
	if dbg == true or dbg == 1 or dbg == "1" then
		UI.debug_assert = true
	end
end

local function draw_panel_img(img: Image, quads: {Quad}, x: number, y: number, w: number, h: number)
	if UI.debug_assert then
		assert(w >= 24 and h >= 24, "draw_panel: min 24x24")
		assert(w % 8 == 0 and h % 8 == 0, "draw_panel: size must be multiple of 8")
	end
	local s = scale
	local iw, ih = w - 16, h - 16
	local sx, sy = iw / 8, ih / 8
	local q = quads
	love.graphics.setColor(1, 1, 1, 1)
	-- corners
	love.graphics.draw(img, q[1], x * s, y * s, 0, s, s)
	love.graphics.draw(img, q[3], (x + w - 8) * s, y * s, 0, s, s)
	love.graphics.draw(img, q[7], x * s, (y + h - 8) * s, 0, s, s)
	love.graphics.draw(img, q[9], (x + w - 8) * s, (y + h - 8) * s, 0, s, s)
	-- edges
	love.graphics.draw(img, q[2], (x + 8) * s, y * s, 0, s * sx, s)
	love.graphics.draw(img, q[8], (x + 8) * s, (y + h - 8) * s, 0, s * sx, s)
	love.graphics.draw(img, q[4], x * s, (y + 8) * s, 0, s, s * sy)
	love.graphics.draw(img, q[6], (x + w - 8) * s, (y + 8) * s, 0, s, s * sy)
	-- center
	love.graphics.draw(img, q[5], (x + 8) * s, (y + 8) * s, 0, s * sx, s * sy)
end

global function draw_panel(x: number, y: number, w: number, h: number)
	if not UI.panel_img or not UI.panel_quads then
		-- fallback solid rects until theme_init
		local c = UI.COL.panel
		love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
		love.graphics.rectangle("fill", x * scale, y * scale, w * scale, h * scale)
		local e = UI.COL.panel_edge
		love.graphics.setColor(e[1], e[2], e[3], e[4] or 1)
		love.graphics.rectangle("line", x * scale, y * scale, w * scale, h * scale)
		love.graphics.setColor(1, 1, 1, 1)
		return
	end
	draw_panel_img(UI.panel_img as Image, UI.panel_quads as {Quad}, x, y, w, h)
end

global function draw_panel_inset(x: number, y: number, w: number, h: number)
	if UI.panel_inset_img and UI.panel_inset_quads then
		draw_panel_img(UI.panel_inset_img as Image, UI.panel_inset_quads as {Quad}, x, y, w, h)
	else
		draw_panel(x, y, w, h)
	end
end

global function ui_set_color(name: string)
	local c = UI.COL[name]
	if c then
		love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
	end
end

-- Exponential ease toward target (tau ≈ time constant). Snaps when close.
global function menu_ease(cur: number, target: number, dt: number, tau: number): number
	local d = target - cur
	if math.abs(d) < 0.35 then
		return target
	end
	local t = math.max(0.001, tau)
	local k = 1 - math.exp(-dt / t)
	return cur + d * k
end

global function menu_draw_overlay()
	local c = UI.COL.overlay
	love.graphics.setColor(c[1], c[2], c[3], c[4] or 0.48)
	love.graphics.rectangle("fill", 0, 0, UI.SCREEN_W * scale * 2, UI.SCREEN_H * scale * 2)
	love.graphics.setColor(1, 1, 1, 1)
end

-- Selection / hover fill for a list row (unscaled UI coords). alpha usually 1.
global function menu_draw_row_bg(x: number, y: number, w: number, h: number, kind: string, alpha: number)
	local a = alpha
	if kind == "sel" then
		local c = UI.COL.sel
		love.graphics.setColor(c[1], c[2], c[3], (c[4] or 0.16) * a)
		love.graphics.rectangle("fill", x * scale, y * scale, w * scale, h * scale)
		-- left accent bar
		local ac = UI.COL.text_accent
		love.graphics.setColor(ac[1], ac[2], ac[3], a)
		love.graphics.rectangle("fill", x * scale, y * scale, 2 * scale, h * scale)
	elseif kind == "hover" then
		local c = UI.COL.hover
		love.graphics.setColor(c[1], c[2], c[3], (c[4] or 0.08) * a)
		love.graphics.rectangle("fill", x * scale, y * scale, w * scale, h * scale)
	end
	love.graphics.setColor(1, 1, 1, 1)
end

global function menu_draw_cursor(x: number, y: number)
	ui_set_color("text_accent")
	properprint("_dir5", x * scale, y * scale)
	love.graphics.setColor(1, 1, 1, 1)
end

global function menu_draw_footer(x: number, y: number, text: string)
	ui_set_color("text_dim")
	properprint(text, x * scale, y * scale)
	love.graphics.setColor(1, 1, 1, 1)
end

global function menu_draw_rule(x: number, y: number, w: number)
	ui_set_color("rule")
	love.graphics.rectangle("fill", x * scale, y * scale, w * scale, 1 * scale)
	love.graphics.setColor(1, 1, 1, 1)
end

-- Tab strip: tabs = {{id, label, x, y, w, h}, ...}; active_id compared with ==
global function menu_draw_tabs(tabs: {any}, active_id: any, focus_tabs: boolean)
	for i = 1, #tabs do
		local t = tabs[i] as {string:any}
		local on = t.id == active_id
		local x, y, w, h = t.x as number, t.y as number, t.w as number, t.h as number
		if on then
			local c = UI.COL.tab_on
			love.graphics.setColor(c[1], c[2], c[3], c[4] or 0.2)
			love.graphics.rectangle("fill", x * scale, y * scale, w * scale, h * scale)
			ui_set_color("text_accent")
			-- underline
			love.graphics.rectangle("fill", x * scale, (y + h - 2) * scale, w * scale, 2 * scale)
		elseif focus_tabs then
			ui_set_color("text")
		else
			ui_set_color("text_dim")
		end
		properprint(t.label as string, (x + 4) * scale, (y + 4) * scale)
	end
	love.graphics.setColor(1, 1, 1, 1)
end

-- Options row text: selected = full white, else dim.
global function menu_opt_color(selected: boolean)
	if selected then
		ui_set_color("text")
	else
		ui_set_color("text_dim")
	end
end

-- Centered yes/no confirm dialog.
-- center_x: unscaled X center (defaults to UI.SCREEN_W/2). Use width*8 in-game.
global function menu_draw_yesno(title: string, yes_selected: boolean, subtitle: string|nil, center_x: number|nil)
	local cx = center_x or (UI.SCREEN_W / 2)
	local pw, ph = 200, 56
	if subtitle then
		ph = 64
	end
	local px = math.floor((cx - pw / 2) / 8) * 8
	local py = math.floor((UI.SCREEN_H - ph) / 2 / 8) * 8
	love.graphics.setColor(0, 0, 0, 0.35)
	love.graphics.rectangle("fill", 0, 0, (cx * 2 + 64) * scale, UI.SCREEN_H * scale * 2)
	draw_panel(px, py, pw, ph)
	ui_set_color("text")
	properprint(title, (px + math.floor((pw - #title * 8) / 2)) * scale, (py + 10) * scale)
	if subtitle then
		ui_set_color("text_dim")
		properprint(subtitle, (px + math.floor((pw - #subtitle * 8) / 2)) * scale, (py + 22) * scale)
	end
	local by = subtitle and (py + 40) or (py + 32)
	local yes_x = px + 40
	local no_x = px + 120
	if yes_selected then
		menu_draw_row_bg(yes_x - 12, by - 2, 48, 16, "sel", 1)
		ui_set_color("text_accent")
		properprint("yes", yes_x * scale, by * scale)
		ui_set_color("text_dim")
		properprint("no", no_x * scale, by * scale)
	else
		menu_draw_row_bg(no_x - 12, by - 2, 40, 16, "sel", 1)
		ui_set_color("text_dim")
		properprint("yes", yes_x * scale, by * scale)
		ui_set_color("text_accent")
		properprint("no", no_x * scale, by * scale)
	end
	love.graphics.setColor(1, 1, 1, 1)
end
