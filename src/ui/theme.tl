--[[ Shared UI theme: 8px grid, color tokens, 9-slice panel. ]]

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
		text = {1.00, 1.00, 1.00, 1},
		text_dim = {0.62, 0.62, 0.66, 1},
		text_accent = {1.00, 0.84, 0.22, 1},
		panel = {0.05, 0.06, 0.10, 0.88},
		panel_edge = {0.35, 0.38, 0.50, 1},
		hover = {1.00, 1.00, 1.00, 0.10},
		sel = {1.00, 0.84, 0.22, 0.18},
		rule = {0.30, 0.32, 0.42, 1},
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
