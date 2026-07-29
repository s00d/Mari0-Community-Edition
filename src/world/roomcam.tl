--[[ Room rectangles + camera clamp (F0). openmv MIT — licenses/openmv.MIT ]]

global ROOMS: {MetroidRoom} = {}
global ROOMS_BY_ID: {string:MetroidRoom} = {}
global START_ROOM: string = ""
global currentroom: MetroidRoom|nil = nil
global metroidmode: boolean = false
global roomtransition: number = 0
global metroidmapopen: boolean = false
global metroid_playtime: number = 0

local ROOM_FADE: number = 0.25
local trans_from_x: number = 0
local trans_from_y: number = 0
local cam_blend = { k = 1 }
local cam_blend_tween: FluxTween|nil = nil

local function clamp(v: number, lo: number, hi: number): number
	if hi < lo then return lo end
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function parse_flags(flags: string): boolean, boolean
	return flags ~= nil and string.find(flags, "scroll_h", 1, true) ~= nil, flags ~= nil and string.find(flags, "scroll_v", 1, true) ~= nil
end

local function make_room(id: string, x: number, y: number, w: number, h: number, flags: string): MetroidRoom
	local sh, sv = parse_flags(flags or "")
	return { id = id, x = x, y = y, w = w, h = h, scroll_h = sh, scroll_v = sv, flags = flags or "", doors = {}, items = {}, spawns = {} }
end

local function index_rooms(list: {MetroidRoom})
	ROOMS = list
	ROOMS_BY_ID = {}
	for i = 1, #list do ROOMS_BY_ID[list[i].id] = list[i] end
	if START_ROOM == "" and #list > 0 then START_ROOM = list[1].id end
end

global function rooms_parse_txt(body: string): {MetroidRoom}
	local list: {MetroidRoom} = {}
	if not body then return list end
	for part in string.gmatch(body, "([^¤\r\n]+)") do
		local trimmed = string.match(part, "^%s*(.-)%s*$") or part
		if trimmed ~= "" and not string.match(trimmed, "^%s*#") then
			local x, y, w, h, name, flags = string.match(trimmed, "^%s*([%-]?%d+%.?%d*)%s*,%s*([%-]?%d+%.?%d*)%s*,%s*([%-]?%d+%.?%d*)%s*,%s*([%-]?%d+%.?%d*)%s*,%s*([^,]+)%s*,?(.*)$")
			if x and name then
				table.insert(list, make_room(string.match(name, "^%s*(.-)%s*$") or name, tonumber(x) or 0, tonumber(y) or 0, tonumber(w) or 1, tonumber(h) or 1, string.match(flags or "", "^%s*(.-)%s*$") or ""))
			end
		end
	end
	return list
end

global function rooms_parse_json(data: {string:any}): {MetroidRoom}
	local list: {MetroidRoom} = {}
	if not data then return list end
	if type(data.start) == "string" then START_ROOM = data.start as string end
	local rooms = data.rooms as {{string:any}}
	if not rooms then return list end
	for i = 1, #rooms do
		local raw = rooms[i]
		local r = make_room(tostring(raw.id or raw.name or ("room" .. i)), tonumber(raw.x) or 0, tonumber(raw.y) or 0, tonumber(raw.w) or 1, tonumber(raw.h) or 1, tostring(raw.flags or ""))
		if raw.doors then r.doors = raw.doors as {{string:any}} end
		if raw.items then r.items = raw.items as {{string:any}} end
		if raw.spawns then r.spawns = raw.spawns as {{string:any}} end
		table.insert(list, r)
	end
	return list
end

global function rooms_set(list: {MetroidRoom})
	index_rooms(list or {})
	currentroom = nil
	roomtransition = 0
end

global function rooms_clear()
	ROOMS = {}; ROOMS_BY_ID = {}; START_ROOM = ""; currentroom = nil; roomtransition = 0; metroidmode = false; metroidmapopen = false
end

global function room_at(x: number, y: number): MetroidRoom|nil
	for i = 1, #ROOMS do
		local r = ROOMS[i]
		if x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h then return r end
	end
	return nil
end

global function room_camera_target(r: MetroidRoom, plx: number, ply: number, view_w: number, view_h: number): number, number
	local tx = r.scroll_h and clamp(plx - view_w / 2, r.x, r.x + r.w - view_w) or r.x
	local ty = r.scroll_v and clamp(ply - view_h / 2, r.y, r.y + r.h - view_h) or r.y
	if r.w < view_w then tx = r.x end
	if r.h < view_h then ty = r.y end
	return tx, ty
end

global function map_reveal(room_id: string)
	if room_id and room_id ~= "" then globoolSH("seen_" .. room_id, "true") end
end

local function point_in_room(r: MetroidRoom, x: number, y: number): boolean
	return x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h
end

local function despawn_group_in_room(group: {any:Entity}|nil, r: MetroidRoom)
	if not group then return end
	local g = group as {any:Entity}
	local remove: {integer} = {}
	for k, e in pairs(g) do
		local ent = e as Dyn
		local wx: number
		local wy: number
		if ent.cox and ent.coy then
			wx = (ent.cox as number) - 1 + 0.5
			wy = (ent.coy as number) - 1 + 0.5
		else
			wx = (ent.x as number) or -999
			wy = (ent.y as number) or -999
		end
		if point_in_room(r, wx, wy) then
			-- Dense lists (enemy/abilitypickup via table.insert): nil holes crash update_and_compact.
			if type(k) == "number" then
				table.insert(remove, k as integer)
			else
				g[k] = nil
			end
		end
	end
	if #remove > 0 then
		remove_indices_desc(g as {any}, remove)
	end
end

global function despawn_room(r: MetroidRoom)
	if not r or not objects then return end
	despawn_group_in_room(objects["enemy"] as {any:Entity}|nil, r)
	despawn_group_in_room(objects["abilitypickup"] as {any:Entity}|nil, r)
end

local function spawn_room_items(r: MetroidRoom)
	if not r.items or #r.items == 0 or not abilitypickup or not objects then return end
	if not objects["abilitypickup"] then objects["abilitypickup"] = {} end
	for i = 1, #r.items do
		local it = r.items[i]
		local ab = tostring(it.ability or "")
		local uid = tostring(it.uid or ab)
		if ab ~= "" and not globoolSH("item_" .. uid, "check") and not globoolSH("ability_" .. ab, "check") then
			local mx = math.floor(r.x + (tonumber(it.dx) or (r.w / 2)) + 1)
			local my = math.floor(r.y + (tonumber(it.dy) or (r.h / 2)) + 1)
			local fake = {1, "abilitypickup", ab, uid} as {any}
			table.insert(objects["abilitypickup"], abilitypickup:new(mx, my, fake) as Entity)
		end
	end
end

global function spawn_room(r: MetroidRoom)
	if not r then return end
	spawn_room_items(r)
	if r.spawns and #r.spawns > 0 and enemy and objects and objects["enemy"] then
		for i = 1, #r.spawns do
			local e = r.spawns[i]
			local uid = tostring(e.uid or door_uid(tonumber(e.x) or 0, tonumber(e.y) or 0))
			if not globoolSH("killed_" .. uid, "check") then
				table.insert(objects["enemy"], enemy:new(tonumber(e.x) or 0, tonumber(e.y) or 0, tostring(e.t or e.type or "goomba"), e) as Entity)
			end
		end
		return
	end
	if not map or not spawnenemy or not enemiesspawned then return end
	for x = math.floor(r.x) + 1, math.ceil(r.x + r.w) do
		for y = math.floor(r.y) + 1, math.ceil(r.y + r.h) do
			if not globoolSH("killed_" .. tostring(tilekey(x, y)), "check") then
				enemiesspawned[tilekey(x, y)] = nil
				spawnenemy(x, y)
			else
				enemiesspawned[tilekey(x, y)] = true
			end
		end
	end
end

global function room_enter(r: MetroidRoom, prev: MetroidRoom|nil)
	if not r then return end
	trans_from_x = xscroll or 0
	trans_from_y = yscroll or 0
	roomtransition = ROOM_FADE
	cam_blend.k = 0
	local prev_tween = cam_blend_tween
	if prev_tween ~= nil then
		(prev_tween as FluxTween):stop()
	end
	cam_blend_tween = Flux.to(cam_blend, ROOM_FADE, { k = 1 }):ease("quadout")
	map_reveal(r.id)
	if prev then despawn_room(prev) end
	spawn_room(r)
	if r.flags and string.find(r.flags, "save", 1, true) and metroid_autosave then metroid_autosave() end
end

global function roomcam_update(dt: number)
	if not metroidmode or #ROOMS == 0 then return end
	metroid_playtime = (metroid_playtime or 0) + (dt or 0)
	if metroidmapopen then return end
	local pl = playerobjs and ((playerobjs[mouseowner or 1] or playerobjs[1]) as Dyn)
	if not pl then return end
	local cx = (pl.x as number) + ((pl.width as number) or 0.75) / 2
	local cy = (pl.y as number) + ((pl.height as number) or 1) / 2
	local r = room_at(cx, cy)
	if r == nil then return end
	if r ~= currentroom then room_enter(r, currentroom); currentroom = r end
	local tx, ty = room_camera_target(r, cx, cy, width or 25, height or 14)
	if cam_blend.k < 1 then
		roomtransition = ROOM_FADE * (1 - cam_blend.k)
		xscroll = lerp(trans_from_x, tx, cam_blend.k)
		yscroll = lerp(trans_from_y, ty, cam_blend.k)
	else
		roomtransition = 0
		xscroll = tx; yscroll = ty
	end
end

global function metroid_mark_killed(cox: number, coy: number)
	if metroidmode then globoolSH("killed_" .. door_uid(cox, coy), "true") end
end

global function metroid_bootstrap_from_player()
	if not metroidmode or #ROOMS == 0 then return end
	local pl = playerobjs and (playerobjs[1] as Dyn)
	local r: MetroidRoom|nil = pl and room_at((pl.x as number) + 0.5, (pl.y as number) + 0.5) or nil
	if not r and START_ROOM ~= "" then r = ROOMS_BY_ID[START_ROOM] end
	if not r and #ROOMS > 0 then r = ROOMS[1] end
	if r then
		local room = r as MetroidRoom
		currentroom = nil; room_enter(room, nil); currentroom = room
		local tx, ty = room_camera_target(room, room.x + room.w / 2, room.y + room.h / 2, width or 25, height or 14)
		xscroll = tx; yscroll = ty; roomtransition = 0
	end
end

local function rooms_load_json_path(path: string): boolean
	if not (love and love.filesystem and love.filesystem.getInfo(path)) then return false end
	local raw = love.filesystem.read(path)
	if not raw or not JSON or not JSON.decode then return false end
	rooms_set(rooms_parse_json(JSON.decode(raw) as {string:any}))
	return #ROOMS > 0
end

-- Prefer rooms/<level>.json; fall back to pack rooms.json / rooms.txt.
global function metroid_try_load_level(pack: string, level: string|nil): boolean
	rooms_clear()
	local base = mappack_path and mappack_path(pack) or ("mappacks/" .. pack)
	local loaded = false
	local lvl = level and tostring(level) or ""
	if lvl ~= "" and rooms_load_json_path(base .. "/rooms/" .. lvl .. ".json") then
		loaded = true
	elseif rooms_load_json_path(base .. "/rooms.json") then
		loaded = true
	elseif love and love.filesystem and love.filesystem.getInfo(base .. "/rooms.txt") then
		rooms_set(rooms_parse_txt(love.filesystem.read(base .. "/rooms.txt") or ""))
		loaded = #ROOMS > 0
	end
	metroidmode = loaded
	return metroidmode
end

global function metroid_try_load_mappack(pack: string): boolean
	return metroid_try_load_level(pack, nil)
end

global function metroid_load_rooms_from_strings(txt: string|nil, json_str: string|nil): boolean
	rooms_clear()
	if json_str and JSON and JSON.decode then
		rooms_set(rooms_parse_json(JSON.decode(json_str) as {string:any}))
	elseif txt then
		rooms_set(rooms_parse_txt(txt))
	end
	metroidmode = #ROOMS > 0
	return metroidmode
end

return {
	rooms_parse_txt = rooms_parse_txt, rooms_parse_json = rooms_parse_json, rooms_set = rooms_set, rooms_clear = rooms_clear,
	room_at = room_at, room_camera_target = room_camera_target, roomcam_update = roomcam_update, room_enter = room_enter,
	map_reveal = map_reveal, spawn_room = spawn_room, despawn_room = despawn_room,
	metroid_try_load_mappack = metroid_try_load_mappack, metroid_try_load_level = metroid_try_load_level,
	metroid_bootstrap_from_player = metroid_bootstrap_from_player,
}
