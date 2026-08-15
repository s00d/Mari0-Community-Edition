-- Ported from root editorutil.lua (Teal).

-- Low-risk editor helpers (coords, map list, hotkeys, minimap math).
-- Globals used match editor.lua call sites (scale, tilesoffset, objectsguiarea, …).

-- Sort mappack level filenames (world-level / sublevel). Mutates comparison only.
local function mapsort(a: any, b: any): boolean
	local as = a as string
	local bs = b as string
	local aw = string.match(as, "(%d+)-")
	local bw = string.match(bs, "(%d+)-")
	if tonumber(aw) > 9 and tonumber(bw) > 9 then
		if as < bs then
			return true
		end
	elseif tonumber(bw) > 9 then
		return true
	elseif tonumber(aw) > 9 then
		return false
	elseif as < bs then
		return true
	end
	return false
end
_G.mapsort = mapsort


-- Keep only N-M.txt / N-M_S.txt entries (mutates files in place, like getmaps).
local function editor_filter_map_files(files: any): any
	local f = files as {any}
	for i = #f, 1, -1 do
		local fi = f[i] as string|nil
		if fi ~= nil and not (string.match(fi, "(%d+)-(%d+).txt") or string.match(fi, "(%d+)-(%d+)_(%d+).txt")) then
			table.remove(f, i)
		end
	end
	return f
end
_G.editor_filter_map_files = editor_filter_map_files


local function gettilelistpos(x: number, y: number): number|boolean
	local ox = tilelist_ox or 5
	local oy = tilelist_oy or 38
	local cols = tilelist_cols or 22
	local x2 = ox + cols * 17
	local y2 = oy + 165
	local L = EDITOR_LAYOUT
	if L and L.dock_mode and L.palette then
		y2 = L.palette.y + L.palette.h - 8
	end
	if x >= ox*scale and y >= oy*scale and x < x2*scale and y < y2*scale then
		x = (x - ox*scale)/scale
		y = y + tilesoffset
		y = (y - oy*scale)/scale

		local out = math.floor(math.floor(x/17)+1) as integer
		out = math.floor(out + math.floor(y/17)*cols) as integer

		return out
	end

	return false
end
_G.gettilelistpos = gettilelistpos


local function getlistpos(x: any, y: any): number|boolean
	local xx = x as number
	local yy = y as number
	if xx >= objectsguiarea[1]*scale and yy >= objectsguiarea[2]*scale and xx < objectsguiarea[3]*scale and yy < objectsguiarea[4]*scale then
		xx = (xx - objectsguiarea[1]*scale)/scale
		yy = yy + (multitilesoffset as number)
		yy = (yy - objectsguiarea[2]*scale)/scale

		local out = math.floor(yy/17)
		if out <= #(multitileobjects as {any})-1 then
			return out
		end
	end

	return false
end
_G.getlistpos = getlistpos


local function getmtbutton(x: any): number
	local xx = x as number
	local button = 0
	if xx >= (objectsguiarea[3]-15*4)*scale and xx < (objectsguiarea[3]-1-15*3)*scale then
		button = 1
	elseif xx >= (objectsguiarea[3]-15*3)*scale and xx < (objectsguiarea[3]-1-15*2)*scale then
		button = 2
	elseif xx >= (objectsguiarea[3]-15*2)*scale and xx < (objectsguiarea[3]-1-15*1)*scale then
		button = 3
	elseif xx >= (objectsguiarea[3]-15*1)*scale and xx < (objectsguiarea[3]-1-15*0)*scale then
		button = 4
	end

	return button
end
_G.getmtbutton = getmtbutton


local function hasHotkey(tiletype: any, id: any): any
	for i = 1, 9 do
		local hk = hotkeys[tostring(i)]
		if hk and hk[1] == tiletype and hk[2] == id then
			return i
		end
	end
	return false
end
_G.hasHotkey = hasHotkey


local function changeHotKey(key: any, tiletype: any, id: any): any
	if key == 0 then
		for i = 1, 9 do
			local hk = hotkeys[tostring(i)]
			if hk and hk[1] == tiletype and hk[2] == id then
				hotkeys[tostring(i)] = nil
				break
			end
		end
	else
		hotkeys[tostring(key)] = {tiletype, id}
	end
end
_G.changeHotKey = changeHotKey


-- Pure hotkeys.txt ↔ table (loadHotKeys / saveHotKeys stay thin FS wrappers).
local function editor_hotkeys_parse(data: any): any
	local out = {}
	local ds = data as string|nil
	if not ds or #ds == 0 then
		return out
	end
	local split1 = strsplit(ds, "\n")
	for i = 1, #split1 do
		local split2 = strsplit(split1[i] as string, "=")
		if split2[1] and split2[2] then
			local split3 = strsplit(split2[2] as string, ",")
			out[tostring(split2[1])] = {tonumber(split3[1] as string), tonumber(split3[2] as string)}
		end
	end
	return out
end
_G.editor_hotkeys_parse = editor_hotkeys_parse


local function editor_hotkeys_serialize(hk: any): any
	local h = hk as {string:{any}}
	local data = ""
	for i = 1, 9 do
		local entry = h[tostring(i)]
		if entry then
			data = data .. i .. "=" .. tostring(entry[1]) .. "," .. tostring(entry[2]) .. "\n"
		end
	end
	if #data > 0 then
		data = string.sub(data, 0, -2)
	end
	return data
end
_G.editor_hotkeys_serialize = editor_hotkeys_serialize


-- Minimap: mouse X → camera xscroll (or splitxscroll), clamped to window.
local function editor_minimap_xscroll_from_mouse(mousex: number, sc: number, viewwidth: number, mscroll: number): number
	sc = sc or scale
	local xs = (mousex/sc-3-viewwidth) / 2 + mscroll
	if xs < mscroll then
		return mscroll
	end
	if xs > 170 + mscroll then
		return 170 + mscroll
	end
	return xs
end
_G.editor_minimap_xscroll_from_mouse = editor_minimap_xscroll_from_mouse


-- Minimap click → map tile coords (player warp on main tab).
local function editor_minimap_tile_from_click(mx: number, my: number, sc: number, mx0: number, my0: number, mscroll: number, ysc: number): number, number
	sc = sc or scale
	local tx = math.floor((mx-mx0*sc+math.floor(mscroll*sc*2))/sc/2)
	local ty = math.floor((my-my0*sc)/sc/2+math.floor(ysc))
	return tx, ty
end
_G.editor_minimap_tile_from_click = editor_minimap_tile_from_click


local function formatscrollnumber(i: any): string
	local n = i as number
	if n < 0 then
		n = round(n, 1)
	else
		n = round(n, 2)
	end

	local s = tostring(n)
	if string.len(s) == 1 then
		s = s .. ".00"
	elseif string.len(s) == 3 and math.abs(n) < 10 then
		s = s .. "0"
	end

	if string.sub(s, 4, 4) == "." then
		return string.sub(s, 1, 3)
	else
		return string.sub(s, 1, 4)
	end
end
_G.formatscrollnumber = formatscrollnumber


-- Normalize drag rect so width/height are non-negative (selection overlay).
local function editor_normalize_rect(x: number, y: number, width: number, height: number): number, number, number, number
	if width < 0 then
		x = x + width
		width = -width
	end
	if height < 0 then
		y = y + height
		height = -height
	end
	return x, y, width, height
end
_G.editor_normalize_rect = editor_normalize_rect


-- HUD labels for closed-menu editor status strip.
local function editor_mode_labels(state: any, enemies: any, entities: any, advtool: any): string, string|boolean
	if state == "selection" then
		return "selection", false
	end
	if state == "lightdraw" then
		local sub = "power line draw"
		if advtool == "mushroom" then
			sub = "mushroom platforms"
		end
		return "advanced draw tool", sub
	end
	local sub = "tiles"
	if enemies then
		sub = "enemies"
	elseif entities then
		sub = "entities"
	end
	return "tiles", sub
end
_G.editor_mode_labels = editor_mode_labels


-- Map tile → screen pixel for link-line endpoints (uses xscroll/yscroll/scale).
local function editor_link_screen_pos(tx: any, ty: any): number, number
	return math.floor(((tx as number)-session.xscroll-.5)*16*scale), math.floor(((ty as number)-session.yscroll-1)*16*scale)
end
_G.editor_link_screen_pos = editor_link_screen_pos
