--[[ Mari0 1.6 → CE mappack conversion (text→text + pack copy).
   Pure helpers work without LÖVE; convertmappack uses love.filesystem when present. ]]

require "core.tableutil"
require "world.entity_remap"

local unpack = rawget(_G, "unpack") or table.unpack

local DEFAULT_MUSICLIST: {string} = {
	"none.ogg", "overworld.ogg", "underground.ogg", "castle.ogg", "underwater.ogg", "starmusic.ogg",
}

local DEFAULT_BG: {{number}} = {
	{92 / 255, 148 / 255, 252 / 255},
	{0 / 255, 0 / 255, 0 / 255},
	{32 / 255, 56 / 255, 236 / 255},
	{158 / 255, 219 / 255, 248 / 255},
	{210 / 255, 159 / 255, 229 / 255},
	{237 / 255, 241 / 255, 243 / 255},
	{244 / 255, 178 / 255, 92 / 255},
	{253 / 255, 246 / 255, 175 / 255},
	{249 / 255, 183 / 255, 206 / 255},
}

local function link_types_for(ce_id: any): {string}|nil
	if type(ce_id) ~= "number" then
		return nil
	end
	local static = ENTITY_LINK_TYPES[ce_id as number]
	if static then
		return static
	end
	-- In-game: derive from rightclickmenues when available.
	local el: any = rawget(_G, "entitylist")
	local menus: any = rawget(_G, "rightclickmenues")
	if el and menus and el[ce_id] and el[ce_id].t then
		local rcmenu = menus[el[ce_id].t]
		if rcmenu then
			local out: {string} = {}
			for _, v in pairs(rcmenu as {any:{string:any}}) do
				if v.t == "linkbutton" and type(v.link) == "string" then
					table.insert(out, v.link as string)
				end
			end
			if #out > 0 then
				return out
			end
		end
	end
	return nil
end

local function append_links(newent: {any}, entin: {any})
	local types_opt = link_types_for(newent[1])
	if not types_opt then
		return
	end
	local types = types_opt as {string}
	local linkcount = 0
	for i = 1, #entin do
		if entin[i] == "link" then
			local linktype = types[(linkcount + 1) as integer] or ""
			table.insert(newent, "link")
			table.insert(newent, linktype)
			table.insert(newent, entin[i + 1])
			table.insert(newent, entin[i + 2])
			linkcount = linkcount + 1
		end
	end
end

local function build_variant(vr: {string:any}, entin: {any}): {any}
	local kind = vr.kind as string
	if kind == "spawn" then
		return {8, "true", "false", "false", "false", "false"}
	elseif kind == "cheep" then
		return {3}
	elseif kind == "platform" then
		local entid_up = vr.dir == "up"
		return {18, entin[2], entid_up and 0 or 3.31, (not entid_up) and 0 or 3.31, 4}
	elseif kind == "pipe_dest" then
		return {vr.ce_id, (entin[2] as number) + 1}
	elseif kind == "pipespawn" then
		return {32, entin[2]}
	elseif kind == "wallindicator" then
		return {31, entin[2] or "false"}
	elseif kind == "emance" then
		return {26, vr.dir, "false"}
	elseif kind == "door" then
		return {28, vr.dir, "false", "false"}
	elseif kind == "lightbridge" then
		return {36, vr.dir, tostring(tablecontains(entin, "link"))}
	elseif kind == "platformspawner" then
		return {42, vr.dir, entin[2], 3.5, 2.18}
	elseif kind == "faithplate" then
		return {50, vr.vx, vr.vy, "false"}
	elseif kind == "laser" then
		return {53, vr.dir, tostring(tablecontains(entin, "link"))}
	elseif kind == "laserdetector" then
		return {57, vr.dir, "false"}
	elseif kind == "geldispenser" then
		return {62, vr.dir, vr.gel_id, "false"}
	elseif kind == "pushbutton" then
		return {68, vr.dir, "down"}
	elseif kind == "castlefire" then
		return {79, 6, 0.11, tostring(vr.ccw == true)}
	elseif kind == "seesaw" then
		local seesawtype = SEESAW_PRESETS[entin[2] as integer] or SEESAW_PRESETS[1]
		return {80, seesawtype[1], seesawtype[2], seesawtype[3], seesawtype[4]}
	elseif kind == "notgate" then
		return {84, "true"}
	elseif kind == "gel" then
		return {85, entin[2], vr.left, vr.top, vr.right, vr.bottom}
	elseif kind == "checkpoint" then
		return {100, "true", "false", "false", "false", "false", "false", "false", "region:0:m15:1:30"}
	end
	return {}
end

-- Converts an entity from the 1.6 system to the CE one.
-- opts.strict: unknown ids error (string return via second value) instead of pass-through.
-- opts.on_unknown(id): optional callback; return false to leave empty.
global function convertentity(entin_in: any, opts: {string:any}|nil): {any}, string|nil
	local entin: {any} = (entin_in as {any}) or {}
	local o = (opts or {}) as {string:any}
	local newent: {any} = {}
	if #entin < 1 then
		return newent, nil
	end

	local entid = entin[1] as number
	local enemy = ENEMY_REMAP[entid]
	local variant = VARIANT_REMAP[entid]

	if enemy then
		newent = {enemy}
	elseif variant then
		newent = build_variant(variant, entin)
	elseif PASS_THROUGH[entid] then
		local i = 1
		while entin[i] ~= "link" and i <= #entin do
			if i == 1 and pass_through_ce_id then
				newent[i] = pass_through_ce_id(entid)
			else
				newent[i] = entin[i]
			end
			i = i + 1
		end
	else
		local on_unknown: any = o.on_unknown
		if o.strict then
			return {}, string.format("unknown 1.6 entity id %s", tostring(entid))
		end
		if type(on_unknown) == "function" then
			local cb = on_unknown as function(number): any
			if cb(entid) == false then
				return {}, nil
			end
		end
		local i = 1
		while entin[i] ~= "link" and i <= #entin do
			newent[i] = entin[i]
			i = i + 1
		end
	end

	append_links(newent, entin)
	return newent, nil
end

local function parse_cell_entities(spl2: {any}, opts: {string:any}): {any}, string|nil
	local entextra: {any} = {}
	if #spl2 < 2 then
		return entextra, nil
	end
	for subent = 2, #spl2 do
		local n = tonumber(spl2[subent] as string)
		if n ~= nil then
			table.insert(entextra, n)
		else
			table.insert(entextra, spl2[subent])
		end
	end
	return convertentity(entextra, opts)
end

--[[ Convert full 1.6 level text → CE v1 level text.
   Returns text, nil on success; nil, err on hard failure (height not ×15, strict unknown, …).
   opts:
     strict (bool), is_coin(tileid)->bool, musiclist, backgroundcolor,
     mapheight_multiple (default 15), on_unknown(id) ]]
global function convert_level_text(raw: string, opts: {string:any}|nil): string|nil, string|nil
	local o = (opts or {}) as {string:any}
	local height_mod = tonumber(o.mapheight_multiple) or 15
	local musiclist = (o.musiclist or rawget(_G, "musiclist") or DEFAULT_MUSICLIST) as {any}
	local bgcolors = (o.backgroundcolor or rawget(_G, "backgroundcolor") or DEFAULT_BG) as {{number}}
	local is_coin: any = o.is_coin

	local mariotimelimit: number = 400
	local bg0 = bgcolors[1]
	local background: {number} = { bg0[1], bg0[2], bg0[3], bg0[4] or 1 }
	local musicname: string = "overworld.ogg"
	local spriteset: integer = 1
	local custombackground: any = false
	local intermission = false
	local bonusstage = false
	local haswarpzone = false
	local underwater = false
	local scrollfactor: number = 0
	local fscroll_factor: number = 0
	local mapwidth = 25
	local mapheight = height_mod
	local map: {number:{number:MapCell}} = {}
	local coinmap: {number:{number:boolean}} = {}

	local data = strsplit(raw, ";")
	for i, v in ipairs(data as {any}) do
		local spl = strsplit(v, "=")
		if spl[1] == "timelimit" then
			mariotimelimit = tonumber(spl[2]) or mariotimelimit
		elseif spl[1] == "background" then
			local bi = tonumber(spl[2]) as integer
			local bg = bgcolors[bi]
			if bg then
				background = { bg[1], bg[2], bg[3], bg[4] or 1 }
			end
		elseif spl[1] == "music" then
			local musici = tonumber(spl[2])
			if musici == 7 then
				musicname = "custom.ext"
			elseif musici and musiclist[musici as integer] then
				musicname = tostring(musiclist[musici as integer])
			end
		elseif spl[1] == "spriteset" then
			spriteset = (tonumber(spl[2]) or 1) as integer
		elseif spl[1] == "scrollfactor" then
			scrollfactor = tonumber(spl[2]) or 0
		elseif v == "portalbackground" or v == "custombackground" then
			custombackground = true
		elseif v == "intermission" then
			intermission = true
		elseif v == "bonusstage" then
			bonusstage = true
		elseif v == "haswarpzone" then
			haswarpzone = true
		elseif v == "underwater" then
			underwater = true
		elseif i == 1 then
			local mapsplit = strsplit(v, ",")
			if #mapsplit % height_mod ~= 0 then
				return nil, string.format("Level height not multiple of %d (cells=%d)", height_mod as integer, (#mapsplit) as integer)
			end
			mapwidth = math.floor(#mapsplit / height_mod)
			mapheight = height_mod
			local x = 0
			local y = 1
			for _, w in ipairs(mapsplit as {any}) do
				local spl2 = strsplit(w, "-")
				x = x + 1
				if x == mapwidth + 1 then
					x = 1
					y = y + 1
				end
				if not map[x] then
					map[x] = {}
					coinmap[x] = {}
				end

				local tileid = tonumber(spl2[1]) or 1
				local entextra, err = parse_cell_entities(spl2 as {any}, o)
				if err then
					return nil, err
				end

				local shouldbecoin = false
				if type(is_coin) == "function" and (is_coin as function(number): boolean)(tileid) then
					shouldbecoin = true
					tileid = 1
				end

				map[x][y] = {tileid} as MapCell
				for subent = 1, #entextra do
					table.insert(map[x][y] as {any}, entextra[subent])
				end
				coinmap[x][y] = shouldbecoin
			end
		end
	end

	-- Prefer levelio serializer when loaded; else minimal inline.
	local v = 1
	local body: string
	local serialize: any = rawget(_G, "level_serialize_maptiles")
	if type(serialize) == "function" then
		body = serialize(map, coinmap, mapwidth, mapheight, v)
	else
		local parts: {string} = {}
		for y = 1, mapheight do
			for x = 1, mapwidth do
				local cell = map[x][y]
				local bits: {string} = {}
				for li = 1, #cell do
					table.insert(bits, tostring(cell[li]))
				end
				if coinmap[x][y] then
					bits[1] = bits[1] .. "c"
				end
				table.insert(parts, table.concat(bits, LAYERDELIMITER[v]))
			end
		end
		body = table.concat(parts, BLOCKDELIMITER[v])
	end

	local cd = CATEGORYDELIMITER[v]
	local eq = EQUALSIGN[v]
	local s = tostring(mapheight) .. cd .. body
	s = s .. cd .. "backgroundr" .. eq .. tostring(background[1] * 255)
	s = s .. cd .. "backgroundg" .. eq .. tostring(background[2] * 255)
	s = s .. cd .. "backgroundb" .. eq .. tostring(background[3] * 255)
	s = s .. cd .. "spriteset" .. eq .. tostring(spriteset)
	s = s .. cd .. "music" .. eq .. musicname
	if intermission then s = s .. cd .. "intermission" end
	if bonusstage then s = s .. cd .. "bonusstage" end
	if haswarpzone then s = s .. cd .. "haswarpzone" end
	if underwater then s = s .. cd .. "underwater" end
	if custombackground == true then
		s = s .. cd .. "custombackground"
	elseif type(custombackground) == "string" then
		s = s .. cd .. "custombackground" .. eq .. (custombackground as string)
	end
	s = s .. cd .. "timelimit" .. eq .. tostring(mariotimelimit)
	s = s .. cd .. "scrollfactor" .. eq .. tostring(scrollfactor)
	s = s .. cd .. "fscrollfactor" .. eq .. tostring(fscroll_factor)
	return s, nil
end

local function is_level_filename(name: string): boolean
	return string.find(name, "^%d+%-%d+%.txt$") ~= nil
		or string.find(name, "^%d+%-%d+_%d+%.txt$") ~= nil
end

--[[ Copy a 1.6 pack from source_dir → dest_dir without version.txt.
   fs: { list, read, write, mkdir, exists, is_file?, copy? }
   Returns stats table or nil, err. ]]
global function convert_mappack_fs(source_dir: string, dest_dir: string, fs: {string:any}, opts: {string:any}|nil): {string:any}|nil, string|nil
	local o = (opts or {}) as {string:any}
	local list = fs.list as function(string): {string}
	local read = fs.read as function(string): string|nil
	local write = fs.write as function(string, string)
	local mkdir = fs.mkdir as function(string)
	local exists = fs.exists as function(string): boolean

	mkdir(dest_dir)
	for _, sub in ipairs({"animated/", "animations/", "backgrounds/", "assets/enemies/", "assets/graphics/", "levelscreens/", "music/"} as {string}) do
		mkdir(dest_dir .. "/" .. sub)
	end

	local function copy_file(from: string, to: string): boolean
		if not exists(from) then
			return false
		end
		local data = read(from)
		if data == nil then
			return false
		end
		-- ensure parent
		local parent = to:match("^(.*)/[^/]+$")
		if parent and parent ~= "" then
			mkdir(parent)
		end
		write(to, data)
		return true
	end

	copy_file(source_dir .. "/settings.txt", dest_dir .. "/settings.txt")
	copy_file(source_dir .. "/icon.png", dest_dir .. "/icon.png")
	-- NEVER copy version.txt — hides pack from menu (menu.tl ~1360)
	local custommusicname = ""
	for _, ext in ipairs({"mp3", "ogg"} as {string}) do
		if copy_file(source_dir .. "/music." .. ext, dest_dir .. "/music/custom." .. ext) then
			custommusicname = "custom." .. ext
		end
	end

	local defbg = false
	local bgi = 1
	while exists(source_dir .. "/background" .. bgi .. ".png") do
		copy_file(source_dir .. "/background" .. bgi .. ".png", dest_dir .. "/backgrounds/default" .. bgi .. ".png")
		bgi = bgi + 1
		defbg = true
	end
	copy_file(source_dir .. "/tiles.png", dest_dir .. "/tiles.png")

	local levels = 0
	local errors: {string} = {}
	local unknowns: {number:number} = {}
	local convert_opts: {string:any} = {
		strict = o.strict,
		is_coin = o.is_coin,
		musiclist = o.musiclist,
		backgroundcolor = o.backgroundcolor,
		on_unknown = function(id: number): boolean
			unknowns[id] = (unknowns[id] or 0) + 1
			local cb: any = o.on_unknown
			if type(cb) == "function" then
				return (cb as function(number): boolean)(id)
			end
			return true
		end,
	}

	for _, v in ipairs(list(source_dir)) do
		if is_level_filename(v) then
			local raw = read(source_dir .. "/" .. v)
			if raw then
				local out, err = convert_level_text(raw, convert_opts)
				if not out then
					table.insert(errors, v .. ": " .. tostring(err))
					if o.strict then
						return nil, errors[1]
					end
				else
					local text = out as string
					if custommusicname ~= "" then
						text = text:gsub("music¨custom%.ext", "music¨" .. custommusicname)
						text = text:gsub("music=custom%.ext", "music=" .. custommusicname)
					end
					-- custombackground name from per-level backgrounds
					local base = v:sub(1, -5)
					bgi = 1
					local had_bg = false
					while exists(source_dir .. "/" .. base .. "background" .. bgi .. ".png") do
						copy_file(source_dir .. "/" .. base .. "background" .. bgi .. ".png",
							dest_dir .. "/backgrounds/" .. base .. bgi .. ".png")
						had_bg = true
						bgi = bgi + 1
					end
					if had_bg and text:find("custombackground", 1, true) and not text:find("custombackground¨", 1, true) and not text:find("custombackground=", 1, true) then
						text = text:gsub("custombackground", "custombackground¨" .. base, 1)
					elseif defbg and text:find("custombackground", 1, true) and not text:find("custombackground¨", 1, true) then
						text = text:gsub("custombackground", "custombackground¨default", 1)
					end
					write(dest_dir .. "/" .. v, text)
					levels = levels + 1
					if o.after_level then
						(o.after_level as function(string, string))(v, text)
					end
				end
			end
		end
	end

	if exists(dest_dir .. "/version.txt") then
		-- Safety: never leave version.txt in converted output
		if fs.remove then
			(fs.remove as function(string))(dest_dir .. "/version.txt")
		end
	end

	return {
		levels = levels,
		errors = errors,
		unknowns = unknowns,
		dest = dest_dir,
	}, nil
end

-- In-game entry: convert toconvert/<name> → mappacks/<name>
global function convertmappack(name: any)
	local pack = name as string
	local oldmappackpath = "toconvert/" .. pack
	local newmappackpath = mappack_path(pack)

	local function love_fs(): {string:any}
		return {
			list = function(dir: string): {string}
				return love.filesystem.getDirectoryItems(dir) as {string}
			end,
			read = function(path: string): string|nil
				return love.filesystem.read(path) as string|nil
			end,
			write = function(path: string, data: string): boolean|nil, string|nil
				love.filesystem.write(path, data)
				return true, nil
			end,
			mkdir = function(path: string)
				love.filesystem.createDirectory(path)
			end,
			exists = function(path: string): boolean
				return love.filesystem.getInfo(path) ~= nil
			end,
			remove = function(path: string)
				love.filesystem.remove(path)
			end,
		}
	end

	-- Load custom tiles into tilequads (coin detection) — same as legacy path.
	local customstart = smbtilecount + portaltilecount + 1
	for i = customstart, #(tilequads as {any}) do
		tilequads[i] = nil
		rgblist[i] = nil
	end
	mappack = pack
	if love.filesystem.getInfo(oldmappackpath .. "/tiles.png", "file") then
		-- Dest tiles written by convert_mappack_fs; preload after copy via is_coin on source path
	end

	local is_coin = function(tileid: number): boolean
		local tq = tilequads[tileid]
		return tq ~= nil and tq:getproperty("coin") == true
	end

	-- Copy tiles first so we can rebuild tilequads before level convert
	love.filesystem.createDirectory(newmappackpath)
	if love.filesystem.getInfo(oldmappackpath .. "/tiles.png", "file") then
		love.filesystem.write(newmappackpath .. "/tiles.png", (love.filesystem.read(oldmappackpath .. "/tiles.png") or "") as string)
		customtiles = true
		customtilesimg = AssetStore.load_image(newmappackpath .. "/tiles.png")
		local imgwidth, imgheight = customtilesimg:getWidth(), customtilesimg:getHeight()
		local width = math.floor(imgwidth / 17)
		local height = math.floor(imgheight / 17)
		local imgdata = love.image.newImageData(newmappackpath .. "/tiles.png")
		for y = 1, height do
			for x = 1, width do
				table.insert(tilequads as {any}, quad:new(customtilesimg, imgdata, x, y, imgwidth, imgheight))
				local r, g, b = getaveragecolor(imgdata, x, y)
				table.insert(rgblist, {r / LOVE_COLOR_MAX, g / LOVE_COLOR_MAX, b / LOVE_COLOR_MAX})
			end
		end
		customtilecount = width * height
		create_tile_spritebatches()
	else
		customtiles = false
		customtilesimg = nil
	end

	local stats, err = convert_mappack_fs(oldmappackpath, newmappackpath, love_fs(), {
		is_coin = is_coin,
		strict = false,
		after_level = function(filename: string, _out: string)
			-- Optional preview: load converted map into globals and encode
			local base = filename:sub(1, -5)
			if loadmap(base, false) then
				local ok, previewimg = pcall(function(): any
					return renderpreview()
				end)
				if ok and previewimg then
					(previewimg as ImageData):encode("png", newmappackpath .. "/" .. base .. ".png")
				end
			end
		end,
	})

	if err then
		notice.new("convert failed: " .. tostring(err), notice.red)
		return
	end
	if stats then
		local st = stats as {string:any}
		local errs = (st.errors or {}) as {string}
		if #errs > 0 then
			notice.new("converted with " .. tostring(#errs) .. " level errors", notice.red)
		else
			notice.new("mappack converted successfully")
		end
	else
		notice.new("mappack converted successfully")
	end
end

-- Legacy: load 1.6 level into globals (uses convertentity). Prefer convert_level_text for new code.
global function loadmapold(path: any): any
	if not love.filesystem.getInfo(path as string, "file") then
		return false
	end
	local raw = (love.filesystem.read(path as string) or "") as string
	local out, err = convert_level_text(raw, {
		is_coin = function(tileid: number): boolean
			local tq = tilequads[tileid]
			return tq ~= nil and tq:getproperty("coin") == true
		end,
	})
	if not out then
		print(err or "convert_level_text failed")
		return false
	end
	-- Decode into globals via level_parse + assign (mirror loadmapold side effects)
	local parsed, perr = level_parse_tiles_only(out)
	if not parsed then
		print(perr or "parse failed")
		return false
	end
	local ptiles = parsed as LevelTilesParse
	map = ptiles.map
	coinmap = ptiles.coinmap
	mapwidth = ptiles.mapwidth
	mapheight = ptiles.mapheight
	mariotimelimit = 400
	background = {unpack(backgroundcolor[1])} as {any:number}
	musicname = "overworld.ogg"
	spriteset = 1
	custombackground = false
	customforeground = false
	intermission = false
	bonusstage = false
	haswarpzone = false
	underwater = false
	scrollfactor = 0
	fscrollfactor = 0
	portalsavailable = {true, true}
	levelscreenbackname = false
	-- Re-apply options from converted text
	level_detect_format_version(out)
	local _, _, _, sections, _, _, _, _, equalsign = level_split_file_contents(out)
	for i = 2, #sections do
		local spl = strsplit(sections[i], equalsign)
		if spl[1] == "timelimit" then
			mariotimelimit = tonumber(spl[2])
		elseif spl[1] == "backgroundr" then
			background[1] = (tonumber(spl[2]) or 0) / 255
		elseif spl[1] == "backgroundg" then
			background[2] = (tonumber(spl[2]) or 0) / 255
		elseif spl[1] == "backgroundb" then
			background[3] = (tonumber(spl[2]) or 0) / 255
		elseif spl[1] == "music" then
			musicname = spl[2] as string
		elseif spl[1] == "spriteset" then
			spriteset = tonumber(spl[2]) as integer
		elseif spl[1] == "scrollfactor" then
			scrollfactor = tonumber(spl[2])
		elseif spl[1] == "fscrollfactor" then
			fscrollfactor = tonumber(spl[2])
		elseif sections[i] == "intermission" then
			intermission = true
		elseif sections[i] == "bonusstage" then
			bonusstage = true
		elseif sections[i] == "haswarpzone" then
			haswarpzone = true
		elseif sections[i] == "underwater" then
			underwater = true
		elseif spl[1] == "custombackground" then
			custombackground = spl[2] or true
		end
	end
	return true
end

return {
	convertentity = convertentity,
	convert_level_text = convert_level_text,
	convert_mappack_fs = convert_mappack_fs,
	convertmappack = convertmappack,
	loadmapold = loadmapold,
}
