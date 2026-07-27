--[[
  SuperTux → mapsdk IR (CC-BY-SA levels only).
  Does NOT copy SuperTux engine code (GPL-3). Format reverse-engineered from
  public .stl/.strf docs + data files.
]]

local function script_dir()
	local src = debug.getinfo(1, "S").source
	if src:sub(1, 1) == "@" then
		return src:sub(2):match("^(.*)/") or "."
	end
	return "."
end

local DIR = script_dir()
local sexpr = dofile(DIR .. "/sexpr.lua")
local irmod = dofile(DIR .. "/../ir.lua")

local M = {}

M.CUSTOM_TILE_BASE = 221
M.TILE_PX = 32

-- Allowlist before any mass convert (F3).
M.ALLOWED_LICENSES = {
	["cc-by-sa 4.0 international"] = true,
	["cc-by-sa 4.0"] = true,
	["cc-by-sa 3.0"] = true,
	["cc-by-sa-3.0"] = true,
	["gpl-2+/cc-by-sa-3.0"] = true,
	["gpl 2+ / cc-by-sa 3.0"] = true,
	["gpl 2+/cc-by-sa 3.0"] = true,
}

-- Histogram-backed top mappings (world1) + user starter table.
M.ST_OBJECTS = {
	spawnpoint = { kind = "spawn" },
	spawn_point = { kind = "spawn" },
	snowball = { kind = "enemy", name = "goomba" },
	smartball = { kind = "enemy", name = "goomba" },
	bouncingsnowball = { kind = "enemy", name = "goomba" },
	mriceblock = { kind = "enemy", name = "koopa" },
	smartblock = { kind = "enemy", name = "koopa" },
	mrbomb = { kind = "enemy", name = "beetle" },
	haywire = { kind = "enemy", name = "beetle" },
	stalactite = { kind = "enemy", name = "thwomp" },
	yeti_stalactite = { kind = "enemy", name = "thwomp" },
	crusher = { kind = "enemy", name = "thwomp" },
	flyingsnowball = { kind = "enemy", name = "koopaflying" },
	fish = { kind = "enemy", name = "cheepcheepred" },
	["fish-swimming"] = { kind = "enemy", name = "cheepcheepred" },
	["fish-harmless"] = { kind = "skip" },
	["dive-mine"] = { kind = "enemy", name = "cheepcheepred" },
	spiky = { kind = "enemy", name = "spikey" },
	jumpy = { kind = "enemy", name = "splitter" },
	zeekling = { kind = "enemy", name = "lakito" },
	dispenser = { kind = "enemy", name = "lakito" },
	firefly = { kind = "enemy", name = "fire" },
	bonusblock = { kind = "enemy", name = "mushroom" }, -- Level-1: powerup stand-in
	coin = { kind = "coin" },  -- emits entity "manycoins"
	trampoline = { kind = "entity", name = "spring" },
	platform = { kind = "entity", name = "platform" },
	weak_block = { kind = "skip" },
	unstable_tile = { kind = "skip" },
	infoblock = { kind = "skip" },
	invisible_wall = { kind = "skip" },
	secretarea = { kind = "skip" },
	ambient_sound = { kind = "skip" },
	["ambient-sound"] = { kind = "skip" },
	scripttrigger = { kind = "skip" },
	decal = { kind = "skip" },
	torch = { kind = "skip" },
	climbable = { kind = "skip" },
	background = { kind = "skip" },
	camera = { kind = "skip" },
	gradient = { kind = "skip" },
	path = { kind = "skip" },
	tilemap = { kind = "skip" },
	music = { kind = "skip" },
	["ambient-light"] = { kind = "skip" },
	sequencetrigger = { kind = "finish" },
	short_fuse = { kind = "enemy", name = "beetle" },
	snowman = { kind = "enemy", name = "goomba" },
	["fish-chasing"] = { kind = "enemy", name = "cheepcheepred" },
	["lit-object"] = { kind = "skip" },
	switch = { kind = "skip" },
	pushbutton = { kind = "skip" },
	["init-script"] = { kind = "skip" },
	["particles-snow"] = { kind = "skip" },
	rublight = { kind = "skip" },
	scriptedobject = { kind = "skip" },
	button = { kind = "skip" },
	sspiky = { kind = "enemy", name = "spikey" },
	captainsnowball = { kind = "enemy", name = "goomba" },
	goldbomb = { kind = "enemy", name = "beetle" },
	powerup = { kind = "enemy", name = "mushroom" },
	flame = { kind = "enemy", name = "fire" },
	yeti = { kind = "enemy", name = "bowser" },
	wind = { kind = "skip" },
	bumper = { kind = "skip" },
	circleplatform = { kind = "entity", name = "platform" },
	["particles-clouds"] = { kind = "skip" },
}

local SKIP_HEADS = {
	["supertux-level"] = true,
	sector = true,
	version = true,
	name = true,
	author = true,
	license = true,
	statistics = true,
	["target-time"] = true,
	["allow-item-pocket"] = true,
	icon = true,
	["icon-locked"] = true,
}

function M.normalize_license(s)
	if not s then
		return nil
	end
	s = tostring(s):lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	return s
end

function M.license_ok(root)
	local lic = sexpr.as_string(sexpr.field(root, "license"))
	local key = M.normalize_license(lic)
	return key and M.ALLOWED_LICENSES[key] == true, lic
end

--- Attribute bitmask → Mari0 props (wiki Tile Attributes).
function M.attr_to_props(attr, data)
	attr = tonumber(attr) or 0
	data = tonumber(data) or 0
	local p = {}
	local solid = attr % 2 == 1
	local unisolid = math.floor(attr / 2) % 2 == 1
	local brick = math.floor(attr / 4) % 2 == 1
	local slope = math.floor(attr / 16) % 2 == 1
	local water = math.floor(attr / 512) % 2 == 1
	local hurts = math.floor(attr / 1024) % 2 == 1
	if solid or unisolid then
		p.collision = true
	end
	if unisolid then
		p.platform = true
	end
	if brick then
		p.breakable = true
		p.collision = true
	end
	if water then
		p.water = true
	end
	if hurts then
		p.spikestop = true
	end
	if slope then
		p.collision = true
		-- form 0/2 ≈ rising to the right; 1/3 ≈ rising to the left (ST slope forms)
		local form = data % 4
		if form == 1 or form == 3 then
			p.slantupleft = true
		else
			p.slantupright = true
		end
	end
	return p
end

local function merge_props(dst, src)
	for k, v in pairs(src) do
		if v then
			dst[k] = true
		end
	end
end

local function tile_flags_from_node(t)
	local p = {}
	if sexpr.is_true(sexpr.field(t, "solid")) then
		p.collision = true
	end
	if sexpr.is_true(sexpr.field(t, "unisolid")) then
		p.platform = true
		p.collision = true
	end
	if sexpr.is_true(sexpr.field(t, "hurts")) then
		p.spikestop = true
	end
	if sexpr.is_true(sexpr.field(t, "water")) then
		p.water = true
	end
	if sexpr.is_true(sexpr.field(t, "brick")) then
		p.breakable = true
		p.collision = true
	end
	local st = sexpr.field(t, "slope-type")
	if type(st) == "number" then
		p.collision = true
		if st % 2 == 1 then
			p.slantupleft = true
		else
			p.slantupright = true
		end
	end
	return p
end

--- Parse tiles.strf → { [id] = { collision=?, ... }, images = { [id] = path } }
function M.parse_strf(text)
	local root = sexpr.parse_sexpr(text)
	local props, images = {}, {}
	if type(root) ~= "table" then
		return props, images
	end

	local function first_image(node)
		local _, imglist = sexpr.field(node, "images")
		if not imglist then
			return nil
		end
		for i = 2, #imglist do
			if type(imglist[i]) == "string" then
				return imglist[i]
			end
		end
		return nil
	end

	for i = 2, #root do
		local t = root[i]
		if type(t) ~= "table" then
			-- skip
		elseif t[1] == "tile" then
			local id = sexpr.field(t, "id")
			if type(id) == "number" and id > 0 then
				props[id] = tile_flags_from_node(t)
				local img = first_image(t)
				if img then
					images[id] = img
				end
			end
		elseif t[1] == "tiles" then
			local w = sexpr.field(t, "width") or 1
			local h = sexpr.field(t, "height") or 1
			local _, ids_node = sexpr.field(t, "ids")
			local _, attrs_node = sexpr.field(t, "attributes")
			local _, datas_node = sexpr.field(t, "datas")
			local img = first_image(t)
			if ids_node then
				local idx = 0
				for j = 2, #ids_node do
					local id = ids_node[j]
					if type(id) == "number" then
						idx = idx + 1
						if id > 0 then
							local attr = 0
							local data = 0
							if attrs_node and type(attrs_node[j]) == "number" then
								attr = attrs_node[j]
							end
							if datas_node and type(datas_node[j]) == "number" then
								data = datas_node[j]
							end
							props[id] = M.attr_to_props(attr, data)
							if img and w >= 1 then
								-- sheet cell index → crop later in Python; store sheet + cell
								images[id] = { sheet = img, cell = idx - 1, cols = w, rows = h }
							end
						end
					end
				end
			end
		end
	end
	return props, images
end

local function place_spawn(ir, base)
	for x = 2, math.min(12, ir.width) do
		for y = ir.height - 1, 2, -1 do
			local below = ir.tiles[x][y + 1]
			local here = ir.tiles[x][y]
			if below and below > base and here == base then
				return { x = x, y = y }
			end
		end
	end
	return { x = 3, y = math.max(2, ir.height - 3) }
end

local function place_flag(ir, base)
	local x = ir.width
	local y = math.max(1, ir.height - 2)
	for yy = ir.height, 1, -1 do
		local t = ir.tiles[x] and ir.tiles[x][yy]
		if t and t > base then
			y = math.max(1, yy - 1)
			break
		end
	end
	return { x = x, y = y }
end

local function px_to_tile(v)
	return math.floor((tonumber(v) or 0) / M.TILE_PX) + 1
end

--- Convert one .stl text → IR or nil if license skipped.
-- opts.tile_remap: ST id → Mari0 id (optional; default base+id clamped)
-- opts.unmapped: Counter table name→count
-- opts.attribution: append {file,name,author,license}
function M.convert_stl(text, opts)
	opts = opts or {}
	local root = sexpr.parse_sexpr(text)
	if type(root) ~= "table" or root[1] ~= "supertux-level" then
		return nil, "not a supertux-level"
	end
	local ok_lic, lic = M.license_ok(root)
	if not ok_lic then
		return nil, "license: " .. tostring(lic)
	end

	local base = opts.base_tile or M.CUSTOM_TILE_BASE
	local sector = nil
	for _, c in ipairs(sexpr.children(root, "sector")) do
		local sn = sexpr.as_string(sexpr.field(c, "name"))
		if sn == "main" or sector == nil then
			sector = c
			if sn == "main" then
				break
			end
		end
	end
	if not sector then
		return nil, "no sector"
	end

	local solid = nil
	for _, tm in ipairs(sexpr.children(sector, "tilemap")) do
		if sexpr.is_true(sexpr.field(tm, "solid")) then
			solid = tm
			break
		end
	end
	if not solid then
		return nil, "no solid tilemap"
	end

	local w = sexpr.field(solid, "width")
	local h = sexpr.field(solid, "height")
	local _, tiles_node = sexpr.field(solid, "tiles")
	if type(w) ~= "number" or type(h) ~= "number" or not tiles_node then
		return nil, "bad tilemap size"
	end
	local tiles = sexpr.decode_tiles(tiles_node, w, h)

	local ir = irmod.new({
		source = "supertux",
		name = sexpr.as_string(sexpr.field(root, "name")),
		author = sexpr.as_string(sexpr.field(root, "author")),
		license = lic,
	})
	irmod.set_size(ir, w, h, base)

	local remap = opts.tile_remap
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local tid = tiles[y * w + x + 1] or 0
			local mid
			if tid == 0 then
				mid = base
			elseif remap and remap[tid] then
				mid = remap[tid]
			else
				mid = base + tid
			end
			ir.tiles[x + 1][y + 1] = mid
		end
	end

	local unmapped = opts.unmapped
	for _, obj in ipairs(sexpr.children(sector)) do
		local head = obj[1]
		if type(head) == "string" and not SKIP_HEADS[head] then
			local m = M.ST_OBJECTS[head]
			if m == nil then
				if unmapped then
					unmapped[head] = (unmapped[head] or 0) + 1
				end
			elseif m.kind ~= "skip" then
				local tx = px_to_tile(sexpr.field(obj, "x"))
				local ty = px_to_tile(sexpr.field(obj, "y"))
				if tx < 1 then
					tx = 1
				end
				if ty < 1 then
					ty = 1
				end
				if tx > w then
					tx = w
				end
				if ty > h then
					ty = h
				end
				if m.kind == "spawn" then
					ir.spawn = { x = tx, y = ty }
				elseif m.kind == "finish" then
					ir.finish = { x = tx, y = ty }
					ir.entities[#ir.entities + 1] = { x = tx, y = ty, name = "flag" }
				elseif m.kind == "coin" then
					ir.entities[#ir.entities + 1] = { x = tx, y = ty, name = "manycoins" }
				elseif m.kind == "enemy" or m.kind == "entity" then
					ir.entities[#ir.entities + 1] = { x = tx, y = ty, name = m.name }
				end
			end
		end
	end

	if not ir.spawn then
		ir.spawn = place_spawn(ir, base)
	end
	ir.entities[#ir.entities + 1] = { x = ir.spawn.x, y = ir.spawn.y, name = "spawn" }
	if not ir.finish then
		ir.finish = place_flag(ir, base)
		ir.entities[#ir.entities + 1] = { x = ir.finish.x, y = ir.finish.y, name = "flag" }
	end

	if opts.attribution then
		opts.attribution[#opts.attribution + 1] = {
			file = opts.filename or "?",
			name = ir.meta.name,
			author = ir.meta.author,
			license = lic,
		}
	end

	return ir
end

function M.object_histogram(texts)
	local hist = {}
	for _, text in ipairs(texts) do
		local root = sexpr.parse_sexpr(text)
		if type(root) == "table" then
			for _, sector in ipairs(sexpr.children(root, "sector")) do
				for _, obj in ipairs(sexpr.children(sector)) do
					local head = obj[1]
					if type(head) == "string" then
						hist[head] = (hist[head] or 0) + 1
					end
				end
			end
		end
	end
	return hist
end

M.sexpr = sexpr
return M
