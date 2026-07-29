--[[ Match start: slots, cosmetics, shared level load. ]]

local Schema = require("net.schema")

local Match = {}

local MAX_WORLD_LEVEL = 99
local MAX_SUBLEVEL = 99

local function mappack_name_safe(name: string): boolean
	if name == "" then
		return false
	end
	if name:find("..", 1, true) or name:find("/", 1, true) or name:find("\\", 1, true) then
		return false
	end
	return name:match("^[%w%._%-]+$") ~= nil
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

function Match.validate_mappack(name: any): string|nil
	local s = tostring(name or "")
	if not mappack_name_safe(s) then
		return nil
	end
	if mappack_in_list(s) or mappack_exists_on_disk(s) then
		return s
	end
	local current = tostring(rawget(_G, "mappack") or "")
	if s == "smb" or s == current then
		return s
	end
	return nil
end

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
	if not mariolives then rawset(_G, "mariolives", {}) end
	if not mariosizes then rawset(_G, "mariosizes", {}) end
	if not mariocolors then rawset(_G, "mariocolors", {}) end
	if not mariohats then rawset(_G, "mariohats", {}) end
	if not portalcolor then rawset(_G, "portalcolor", {}) end
	if not mariocharacter then rawset(_G, "mariocharacter", {}) end
	if not controls then rawset(_G, "controls", {}) end
	for i = 1, n do
		if not controls[i] then
			controls[i] = {
				right = {"key:d"},
				left = {"key:a"},
				down = {"key:s"},
				up = {"key:w"},
				run = {"key:lshift"},
				jump = {"key:space"},
				aimx = {},
				aimy = {},
				portal1 = {},
				portal2 = {},
				reload = {"key:r"},
				use = {"key:e"},
				weaponnext = {"key:tab"},
				weaponprev = {},
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

function Match.build_start(
	host_id: string,
	host_nick: string,
	peers: {{string:any}},
	mappack_name: string,
	world: any,
	level: any,
	sub: any
): {string:any}
	local slots: {{string:any}} = {}
	table.insert(slots, {
		slot = 1,
		id = host_id,
		nick = host_nick,
		colors = mariocolors[playerconfig as integer] or mariocolors[1],
		hats = mariohats[playerconfig as integer] or mariohats[1],
	})
	local slot = 2
	for i = 1, #peers do
		if slot > Schema.MAX_PLAYERS then
			break
		end
		local peer = peers[i]
		table.insert(slots, {
			slot = slot,
			id = tostring(peer.id or ""),
			nick = tostring(peer.nick or "player"),
			colors = peer.colors,
			hats = peer.hats,
		})
		slot = slot + 1
	end
	local pack = Match.validate_mappack(mappack_name or mappack or "smb") or "smb"
	return {
		n = #slots,
		m = pack,
		w = sanitize_world(world or marioworld or 1),
		l = sanitize_level(level or mariolevel or 1),
		u = sanitize_sub(sub or mariosublevel or 0),
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

function Match.begin(msg: {string:any}, my_id: string): integer|nil
	local pack = Match.validate_mappack(msg.m or mappack or "smb")
	if not pack then
		if notice and notice.new then
			notice.new("rejected unknown mappack", notice.red)
		end
		return nil
	end

	local n = math.max(1, math.min(Schema.MAX_PLAYERS, (tonumber(msg.n) or 1) as integer))
	local slots = (msg.slots as {{string:any}}) or {}
	local my_slot = find_local_slot(slots, my_id)

	ensure_player_tables(n)
	rawset(_G, "mouseowner", my_slot)

	for i = 1, #slots do
		local s = slots[i]
		local slot = (tonumber(s.slot) or i) as integer
		if type(s.colors) == "table" then
			mariocolors[slot] = s.colors as {{number}}
		end
		if type(s.hats) == "table" then
			mariohats[slot] = s.hats as {any}
		end
	end

	rawset(_G, "mappack", pack)
	rawset(_G, "marioworld", sanitize_world(msg.w))
	rawset(_G, "mariolevel", sanitize_level(msg.l))
	rawset(_G, "mariosublevel", sanitize_sub(msg.u))
	rawset(_G, "guielements", {})

	if love and love.keyboard and love.keyboard.setTextInput then
		pcall(function()
			love.keyboard.setTextInput(false)
		end)
	end

	game_load()
	return my_slot
end

return Match
