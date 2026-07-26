-- Ported from root editorutil.lua (Teal).

-- Low-risk editor helpers (coords, map list, hotkeys, minimap math).
-- Globals used match editor.lua call sites (scale, tilesoffset, objectsguiarea, …).

-- Sort mappack level filenames (world-level / sublevel). Mutates comparison only.
local function mapsort(a: any, b: any): boolean
	local aw = string.match(a, "(%d+)-")
	local bw = string.match(b, "(%d+)-")
	if tonumber(aw) > 9 and tonumber(bw) > 9 then
		if a < b then
			return true
		end
	elseif tonumber(bw) > 9 then
		return true
	elseif tonumber(aw) > 9 then
		return false
	elseif a < b then
		return true
	end
end
_G.mapsort = mapsort


-- Keep only N-M.txt / N-M_S.txt entries (mutates files in place, like getmaps).
local function editor_filter_map_files(files: any): any
	for i = #files, 1, -1 do
		if files[i] ~= nil and not (string.match(files[i], "(%d+)-(%d+).txt") or string.match(files[i], "(%d+)-(%d+)_(%d+).txt")) then
			table.remove(files, i)
		end
	end
	return files
end
_G.editor_filter_map_files = editor_filter_map_files


local function gettilelistpos(x: any, y: any): number|boolean
	if x >= 5*scale and y >= 38*scale and x < 378*scale and y < 203*scale then
		x = (x - 5*scale)/scale
		y = y + tilesoffset
		y = (y - 38*scale)/scale

		local out = math.floor(x/17)+1
		out = out + math.floor(y/17)*22

		return out
	end

	return false
end
_G.gettilelistpos = gettilelistpos


local function getlistpos(x: any, y: any): number|boolean
	if x >= objectsguiarea[1]*scale and y >= objectsguiarea[2]*scale and x < objectsguiarea[3]*scale and y < objectsguiarea[4]*scale then
		x = (x - objectsguiarea[1]*scale)/scale
		y = y + multitilesoffset
		y = (y - objectsguiarea[2]*scale)/scale

		local out = math.floor(y/17)
		if out <= #multitileobjects-1 then
			return out
		end
	end

	return false
end
_G.getlistpos = getlistpos


local function getmtbutton(x: any): number
	local button = 0
	if x >= (objectsguiarea[3]-15*4)*scale and x < (objectsguiarea[3]-1-15*3)*scale then
		button = 1
	elseif x >= (objectsguiarea[3]-15*3)*scale and x < (objectsguiarea[3]-1-15*2)*scale then
		button = 2
	elseif x >= (objectsguiarea[3]-15*2)*scale and x < (objectsguiarea[3]-1-15*1)*scale then
		button = 3
	elseif x >= (objectsguiarea[3]-15*1)*scale and x < (objectsguiarea[3]-1-15*0)*scale then
		button = 4
	end

	return button
end
_G.getmtbutton = getmtbutton


local function hasHotkey(tiletype: any, id: any): boolean
	for i = 1, 9 do
		if hotkeys[tostring(i)] and hotkeys[tostring(i)][1] == tiletype and hotkeys[tostring(i)][2] == id then
			return i
		end
	end
	return false
end
_G.hasHotkey = hasHotkey


local function changeHotKey(key: any, tiletype: any, id: any): any
	if key == 0 then
		for i = 1, 9 do
			if hotkeys[tostring(i)] and hotkeys[tostring(i)][1] == tiletype and hotkeys[tostring(i)][2] == id then
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
	if not data or #data == 0 then
		return out
	end
	local split1 = strsplit(data, "\n")
	for i = 1, #split1 do
		local split2 = strsplit(split1[i], "=")
		if split2[1] and split2[2] then
			local split3 = strsplit(split2[2], ",")
			out[tostring(split2[1])] = {tonumber(split3[1]), tonumber(split3[2])}
		end
	end
	return out
end
_G.editor_hotkeys_parse = editor_hotkeys_parse


local function editor_hotkeys_serialize(hk: any): any
	local data = ""
	for i = 1, 9 do
		if hk[tostring(i)] then
			data = data .. i .. "=" .. tostring(hk[tostring(i)][1]) .. "," .. tostring(hk[tostring(i)][2]) .. "\n"
		end
	end
	if #data > 0 then
		data = string.sub(data, 0, -2)
	end
	return data
end
_G.editor_hotkeys_serialize = editor_hotkeys_serialize


-- Minimap: mouse X → camera xscroll (or splitxscroll), clamped to window.
local function editor_minimap_xscroll_from_mouse(mousex: any, sc: any, viewwidth: any, mscroll: any): number
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
local function editor_minimap_tile_from_click(mx: any, my: any, sc: any, mx0: any, my0: any, mscroll: any, ysc: any): any
	sc = sc or scale
	local tx = math.floor((mx-mx0*sc+math.floor(mscroll*sc*2))/sc/2)
	local ty = math.floor((my-my0*sc)/sc/2+math.floor(ysc))
	return tx, ty
end
_G.editor_minimap_tile_from_click = editor_minimap_tile_from_click


local function formatscrollnumber(i: any): string
	if i < 0 then
		i = round(i, 1)
	else
		i = round(i, 2)
	end

	if string.len(i) == 1 then
		i = i .. ".00"
	elseif string.len(i) == 3 and math.abs(i) < 10 then
		i = i .. "0"
	end

	if string.sub(i, 4, 4) == "." then
		return string.sub(i, 1, 3)
	else
		return string.sub(i, 1, 4)
	end
end
_G.formatscrollnumber = formatscrollnumber


-- Normalize drag rect so width/height are non-negative (selection overlay).
local function editor_normalize_rect(x: any, y: any, width: any, height: any): number, number, number, number
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
local function editor_mode_labels(state: any, enemies: any, entities: any, advtool: any): any
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
	return math.floor((tx-xscroll-.5)*16*scale), math.floor((ty-yscroll-1)*16*scale)
end
_G.editor_link_screen_pos = editor_link_screen_pos

return {
	mapsort = mapsort,
	editor_filter_map_files = editor_filter_map_files,
	gettilelistpos = gettilelistpos,
	getlistpos = getlistpos,
	getmtbutton = getmtbutton,
	hasHotkey = hasHotkey,
	changeHotKey = changeHotKey,
	editor_hotkeys_parse = editor_hotkeys_parse,
	editor_hotkeys_serialize = editor_hotkeys_serialize,
	editor_minimap_xscroll_from_mouse = editor_minimap_xscroll_from_mouse,
	editor_minimap_tile_from_click = editor_minimap_tile_from_click,
	formatscrollnumber = formatscrollnumber,
	editor_normalize_rect = editor_normalize_rect,
	editor_mode_labels = editor_mode_labels,
	editor_link_screen_pos = editor_link_screen_pos,
}
