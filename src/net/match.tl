--[[ Match start: assign slots, apply cosmetics, load shared level. ]]

local MAX_PLAYERS = 4
local MAX_WORLD_LEVEL = 99
local MAX_SUBLEVEL = 99

local function mappack_name_safe(name: string): boolean
	if name == "" then
		return false
	end
	-- Path traversal / separators — never allow into mappack_path().
	if name:find("..", 1, true) or name:find("/", 1, true) or name:find("\\", 1, true) then
		return false
	end
	-- Allowlist characters used by shipped / custom pack folder names.
	if not name:match("^[%w%._%-]+$") then
		return false
	end
	return true
end

local function mappack_in_list(name: string): boolean
	local list = rawget(_G, "mappacklist") as {string}|nil
	if type(list) == "table" and #list > 0 then
		return tablecontains(list, name)
	end
	local online = rawget(_G, "onlinemappacklist") as {string}|nil
	if type(online) == "table" and #online > 0 then
		return tablecontains(online, name)
	end
	return false
end

local function mappack_exists_on_disk(name: string): boolean
	local fs = love and love.filesystem
	if not fs or not fs.getInfo then
		return false
	end
	local path_fn = rawget(_G, "mappack_path")
	local base: string
	if type(path_fn) == "function" then
		base = (path_fn as function(string): string)(name)
	else
		base = "mappacks/" .. name
	end
	return fs.getInfo(base .. "/settings.txt") ~= nil
end

-- True if name is a known/installed pack and not a path traversal attempt.
local function validate_mappack(name: any): string|nil
	local s = tostring(name or "")
	if not mappack_name_safe(s) then
		return nil
	end
	if mappack_in_list(s) then
		return s
	end
	-- List may be empty early (tests / pre-menu); fall back to on-disk settings.
	if mappack_exists_on_disk(s) then
		return s
	end
	-- Offline unit tests without filesystem: allow current / default smb only.
	local current = tostring(rawget(_G, "mappack") or "")
	if s == "smb" or s == current then
		return s
	end
	return nil
end

-- Sanitize world/level/sub for level_filename (N-M / N-M_S / M-N).
local function sanitize_world(v: any): number|string
	if tostring(v) == "M" then
		return "M"
	end
	local n = tonumber(v)
	if not n or n ~= math.floor(n) or n < 1 or n > MAX_WORLD_LEVEL then
		return 1
	end
	return n as integer
end

local function sanitize_level(v: any): number
	local n = tonumber(v)
	if not n or n ~= math.floor(n) or n < 1 or n > MAX_WORLD_LEVEL then
		return 1
	end
	return n as integer
end

local function sanitize_sub(v: any): number
	local n = tonumber(v)
	if not n or n ~= math.floor(n) or n < 0 or n > MAX_SUBLEVEL then
		return 0
	end
	return n as integer
end

local function ensure_player_tables(n: integer)
	rawset(_G, "players", n)
	if not mariolives then
		rawset(_G, "mariolives", {})
	end
	if not mariosizes then
		rawset(_G, "mariosizes", {})
	end
	if not mariocolors then
		rawset(_G, "mariocolors", {})
	end
	if not mariohats then
		rawset(_G, "mariohats", {})
	end
	if not portalcolor then
		rawset(_G, "portalcolor", {})
	end
	if not mariocharacter then
		rawset(_G, "mariocharacter", {})
	end
	if not controls then
		rawset(_G, "controls", {})
	end
	for i = 1, n do
		if not controls[i] then
			-- Clone player-1 keyboard defaults if missing.
			controls[i] = {
				right = {"d"},
				left = {"a"},
				down = {"s"},
				up = {"w"},
				run = {"lshift"},
				jump = {" "},
				aimx = {""},
				aimy = {""},
				portal1 = {""},
				portal2 = {""},
				reload = {"r"},
				use = {"e"},
				weaponnext = {"tab"},
				weaponprev = {""},
			}
		end
		if not mariocolors[i] then
			mariocolors[i] = {{1, 0, 0}, {1, 1, 1}, {1, 0.6, 0.2}}
		end
		if not mariohats[i] then
			mariohats[i] = {1}
		end
		if not portalcolor[i] then
			portalcolor[i] = {{0.2, 0.6, 1}, {1, 0.4, 0.1}}
		end
		if not mariocharacter[i] then
			mariocharacter[i] = mariocharacter[1] or "mario"
		end
	end
end

local function apply_cosmetics(slot: integer, colors: any, hats: any)
	if type(colors) == "table" then
		mariocolors[slot] = colors as {{number}}
	end
	if type(hats) == "table" then
		mariohats[slot] = hats as {any}
	end
end

local function build_start_msg(local_id: string, peers_by_key: {string:any}, mappack_name: string, world: any, level: any, sub: any): {string:any}
	local slots: {{string:any}} = {}
	table.insert(slots, {
		slot = 1,
		id = local_id,
		nick = localnick or "host",
		colors = mariocolors[playerconfig as integer] or mariocolors[1],
		hats = mariohats[playerconfig as integer] or mariohats[1],
		host = true,
	})
	local slot = 2
	for _, p in pairs(peers_by_key) do
		if slot > MAX_PLAYERS then
			break
		end
		local peer = p as {string:any}
		peer.slot = slot
		table.insert(slots, {
			slot = slot,
			id = tostring(peer.id or ""),
			nick = tostring(peer.nick or "player"),
			colors = peer.colors,
			hats = peer.hats,
			host = false,
		})
		slot = slot + 1
	end
	local pack = validate_mappack(mappack_name or mappack or "smb") or "smb"
	return {
		t = "start",
		players = #slots,
		mappack = pack,
		world = sanitize_world(world or marioworld or 1),
		level = sanitize_level(level or mariolevel or 1),
		sub = sanitize_sub(sub or mariosublevel or 0),
		slots = slots,
	}
end

local function find_local_slot(slots: {{string:any}}, my_id: string): integer
	for i = 1, #slots do
		if tostring(slots[i].id or "") == my_id then
			return (tonumber(slots[i].slot) or i) as integer
		end
	end
	return 1
end

-- Returns local slot, or nil if start payload is rejected (bad mappack).
local function begin_match(msg: {string:any}, my_id: string): integer|nil
	local pack = validate_mappack(msg.mappack or mappack or "smb")
	if not pack then
		notice.new("rejected unknown mappack", notice.red)
		return nil
	end

	local n = math.max(1, math.min(MAX_PLAYERS, (tonumber(msg.players) or 1) as integer))
	local slots = (msg.slots as {{string:any}}) or {}
	local my_slot = find_local_slot(slots, my_id)

	ensure_player_tables(n)
	rawset(_G, "netplayernumber", my_slot)
	rawset(_G, "mouseowner", my_slot)

	for i = 1, #slots do
		local s = slots[i]
		local slot = (tonumber(s.slot) or i) as integer
		apply_cosmetics(slot, s.colors, s.hats)
	end

	rawset(_G, "mappack", pack)
	rawset(_G, "marioworld", sanitize_world(msg.world))
	rawset(_G, "mariolevel", sanitize_level(msg.level))
	rawset(_G, "mariosublevel", sanitize_sub(msg.sub))

	-- Clear lobby UI elements before level screen.
	rawset(_G, "guielements", {})

	if love.keyboard and love.keyboard.setTextInput then
		pcall(function()
			love.keyboard.setTextInput(false)
		end)
	end

	game_load()
	return my_slot
end

return {
	MAX_PLAYERS = MAX_PLAYERS,
	ensure_player_tables = ensure_player_tables,
	build_start_msg = build_start_msg,
	begin_match = begin_match,
	find_local_slot = find_local_slot,
	apply_cosmetics = apply_cosmetics,
	validate_mappack = validate_mappack,
	mappack_name_safe = mappack_name_safe,
	sanitize_world = sanitize_world,
	sanitize_level = sanitize_level,
	sanitize_sub = sanitize_sub,
}
