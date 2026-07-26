-- Low-risk editor helpers (coords, map list, hotkeys, minimap math).
-- Globals used match editor.lua call sites (scale, tilesoffset, objectsguiarea, …).

-- Sort mappack level filenames (world-level / sublevel). Mutates comparison only.
function mapsort(a, b)
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

-- Keep only N-M.txt / N-M_S.txt entries (mutates files in place, like getmaps).
function editor_filter_map_files(files)
	for i = #files, 1, -1 do
		if files[i] ~= nil and not (string.match(files[i], "(%d+)-(%d+).txt") or string.match(files[i], "(%d+)-(%d+)_(%d+).txt")) then
			table.remove(files, i)
		end
	end
	return files
end

function gettilelistpos(x, y)
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

function getlistpos(x, y)
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

function getmtbutton(x)
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

function hasHotkey(tiletype, id)
	for i = 1, 9 do
		if hotkeys[tostring(i)] and hotkeys[tostring(i)][1] == tiletype and hotkeys[tostring(i)][2] == id then
			return i
		end
	end
	return false
end

function changeHotKey(key, tiletype, id)
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

-- Pure hotkeys.txt ↔ table (loadHotKeys / saveHotKeys stay thin FS wrappers).
function editor_hotkeys_parse(data)
	local out = {}
	if not data or #data == 0 then
		return out
	end
	local split1 = data:split("\n")
	for i = 1, #split1 do
		local split2 = split1[i]:split("=")
		if split2[1] and split2[2] then
			local split3 = split2[2]:split(",")
			out[tostring(split2[1])] = {tonumber(split3[1]), tonumber(split3[2])}
		end
	end
	return out
end

function editor_hotkeys_serialize(hk)
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

-- Minimap: mouse X → camera xscroll (or splitxscroll), clamped to window.
function editor_minimap_xscroll_from_mouse(mousex, sc, viewwidth, mscroll)
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

-- Minimap click → map tile coords (player warp on main tab).
function editor_minimap_tile_from_click(mx, my, sc, mx0, my0, mscroll, ysc)
	sc = sc or scale
	local tx = math.floor((mx-mx0*sc+math.floor(mscroll*sc*2))/sc/2)
	local ty = math.floor((my-my0*sc)/sc/2+math.floor(ysc))
	return tx, ty
end

function formatscrollnumber(i)
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

-- Normalize drag rect so width/height are non-negative (selection overlay).
function editor_normalize_rect(x, y, width, height)
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

-- HUD labels for closed-menu editor status strip.
function editor_mode_labels(state, enemies, entities, advtool)
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

-- Map tile → screen pixel for link-line endpoints (uses xscroll/yscroll/scale).
function editor_link_screen_pos(tx, ty)
	return math.floor((tx-xscroll-.5)*16*scale), math.floor((ty-yscroll-1)*16*scale)
end
