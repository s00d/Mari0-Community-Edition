--[[ Editor dock layout: toolbar / palette / canvas / props / minimap / hint.
     All rects multiples of 8. Pure calc used by draw + mouse hit. ]]

local GRID = 8
local SCREEN_W = 400
local SCREEN_H = 224
local TOOLBAR_H = 16
local HINT_H = 16
local MINIMAP_H = 16
local CANVAS_H = 176
local PALETTE_W = 136
local PROPS_W = 80

global EDITOR_LAYOUT: EditorLayoutState = {
	toolbar = { x = 0, y = 0, w = SCREEN_W, h = TOOLBAR_H },
	palette = { x = 0, y = TOOLBAR_H, w = PALETTE_W, h = CANVAS_H },
	canvas = { x = PALETTE_W, y = TOOLBAR_H, w = SCREEN_W - PALETTE_W - PROPS_W, h = CANVAS_H },
	props = { x = SCREEN_W - PROPS_W, y = TOOLBAR_H, w = PROPS_W, h = CANVAS_H },
	minimap = { x = 0, y = TOOLBAR_H + CANVAS_H, w = SCREEN_W, h = MINIMAP_H },
	hint = { x = 0, y = SCREEN_H - HINT_H, w = SCREEN_W, h = HINT_H },
	palette_collapsed = false,
	props_collapsed = true,
	palette_w = PALETTE_W,
	props_w = PROPS_W,
	tile_ox = 8,
	tile_oy = 40,
	tile_cols = 7,
	dock_mode = true,
}

tilelist_ox = 5
tilelist_oy = 38
tilelist_cols = 22

local function snap8(n: number): number
	return math.floor(n / GRID + 0.5) * GRID
end

local function rect(x: number, y: number, w: number, h: number): EditorRect
	return { x = snap8(x), y = snap8(y), w = snap8(w), h = snap8(h) }
end

-- Recompute dock rects from collapse flags. Call before draw/hit.
global function layout_recalc(editorstate: string|nil, menu_open: boolean|nil)
	local L = EDITOR_LAYOUT
	local est = editorstate or (rawget(_G, "editorstate") as string|nil) or "tiles"
	local open = menu_open
	if open == nil then
		open = rawget(_G, "editormenuopen") == true
	end

	-- Docks for tiles/main/tools; animations/maps/objects keep denser overlay.
	L.dock_mode = open and (est == "tiles" or est == "main" or est == "tools")

	local pw = L.palette_collapsed and 0 or PALETTE_W
	local rw = L.props_collapsed and 0 or PROPS_W
	local cw = SCREEN_W - pw - rw
	if cw < 128 then
		cw = 128
	end
	cw = math.floor(snap8(cw))

	L.palette_w = pw
	L.props_w = rw
	L.toolbar = rect(0, 0, SCREEN_W, TOOLBAR_H)
	local pal_w = 0
	if pw > 0 then pal_w = pw end
	local pr_w = 0
	if rw > 0 then pr_w = rw end
	L.palette = rect(0, TOOLBAR_H, pal_w, CANVAS_H)
	L.canvas = rect(pw, TOOLBAR_H, cw, CANVAS_H)
	L.props = rect(pw + cw, TOOLBAR_H, pr_w, CANVAS_H)
	L.minimap = rect(pw, TOOLBAR_H + CANVAS_H, cw, MINIMAP_H)
	L.hint = rect(0, SCREEN_H - HINT_H, SCREEN_W, HINT_H)

	if pw > 0 and L.dock_mode then
		L.tile_ox = L.palette.x + 8
		L.tile_oy = L.palette.y + 24
		L.tile_cols = math.max(1, math.floor((pw - 16) / 17))
	else
		-- Classic fullscreen tile browser coords
		L.tile_ox = 5
		L.tile_oy = 38
		L.tile_cols = 22
	end
	-- Publish for editorutil / draw loops (avoid circular requires).
	tilelist_ox = L.tile_ox
	tilelist_oy = L.tile_oy
	tilelist_cols = L.tile_cols
end

global function layout_toggle_palette()
	EDITOR_LAYOUT.palette_collapsed = not EDITOR_LAYOUT.palette_collapsed
	layout_recalc(nil, nil)
end

global function layout_toggle_props()
	EDITOR_LAYOUT.props_collapsed = not EDITOR_LAYOUT.props_collapsed
	layout_recalc(nil, nil)
end

global function layout_hit(r: EditorRect, ux: number, uy: number): boolean
	if r.w <= 0 or r.h <= 0 then
		return false
	end
	return ux >= r.x and ux < r.x + r.w and uy >= r.y and uy < r.y + r.h
end

global function layout_over_canvas(ux: number, uy: number): boolean
	return layout_hit(EDITOR_LAYOUT.canvas, ux, uy)
end

global function layout_rects_on_grid(): boolean
	local L = EDITOR_LAYOUT
	local list: {any} = { L.toolbar, L.canvas, L.minimap, L.hint }
	if not L.palette_collapsed then
		list[#list + 1] = L.palette
	end
	if not L.props_collapsed then
		list[#list + 1] = L.props
	end
	for i = 1, #list do
		local r = list[i] as EditorRect
		if r.x % GRID ~= 0 or r.y % GRID ~= 0 or r.w % GRID ~= 0 or r.h % GRID ~= 0 then
			return false
		end
	end
	return true
end
