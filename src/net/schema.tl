--[[ Wire event names + compact bitser payloads. No legacy opcodes. ]]

local MAX_PLAYERS = 4
local DEFAULT_PORT = 7331
local INPUT_HZ = 30
local SNAP_HZ = 20
local SOFT_CORRECT = 0.75

local EV = {
	WELCOME = "welcome",
	REJECT = "reject",
	PEER = "peer",
	LEAVE = "leave",
	CHAT = "chat",
	START = "start",
	INPUT = "input",
	SNAP = "snap",
}

local KEYS = {
	"left", "right", "up", "down",
	"jump", "run", "use", "reload",
	"portal1", "portal2",
}

local function empty_held(): {string:any}
	local h: {string:any} = {}
	for _, k in ipairs(KEYS) do
		h[k] = false
	end
	h.ang = 0
	return h
end

local function copy_held(src: {string:any}|nil): {string:any}
	local h = empty_held()
	if not src then
		return h
	end
	local s = src as {string:any}
	for _, k in ipairs(KEYS) do
		h[k] = s[k] == true
	end
	h.ang = tonumber(s.ang) or 0
	return h
end

local function pack_input(seq: integer, h: {string:any}): {string:any}
	local bits: {integer} = {}
	for i = 1, #KEYS do
		bits[i] = h[KEYS[i]] == true and 1 or 0
	end
	return {
		s = seq,
		a = tonumber(h.ang) or 0,
		b = bits,
	}
end

local function unpack_input(msg: {string:any}): {string:any}
	local h = empty_held()
	local bits = msg.b as {integer}|nil
	if type(bits) == "table" then
		local b = bits as {integer}
		for i = 1, #KEYS do
			h[KEYS[i]] = b[i] == 1
		end
	end
	h.ang = tonumber(msg.a) or 0
	return h
end

local function round3(n: number): number
	if n >= 0 then
		return math.floor(n * 1000 + 0.5) / 1000
	end
	return math.ceil(n * 1000 - 0.5) / 1000
end

local function pack_player_row(i: integer, p: {string:any}): {any}
	return {
		i,
		round3((p.x as number) or 0),
		round3((p.y as number) or 0),
		round3((p.speedx as number) or 0),
		round3((p.speedy as number) or 0),
		round3((p.pointingangle as number) or 0),
		p.dead == true and 1 or 0,
	} as {any}
end

local function unpack_player_row(row: {any}): {string:any}|nil
	if type(row) ~= "table" or not row[1] then
		return nil
	end
	return {
		i = (tonumber(row[1]) or 0) as integer,
		x = tonumber(row[2]) or 0,
		y = tonumber(row[3]) or 0,
		sx = tonumber(row[4]) or 0,
		sy = tonumber(row[5]) or 0,
		ang = tonumber(row[6]) or 0,
		dead = row[7] == 1,
	}
end

local function pack_snap(seq: integer, rows: {{any}}): {string:any}
	return {s = seq, p = rows}
end

local function unpack_snap_rows(msg: {string:any}): {{string:any}}
	local out: {{string:any}} = {}
	local plist = msg.p as {{any}}|nil
	if type(plist) ~= "table" then
		return out
	end
	local list = plist as {{any}}
	for j = 1, #list do
		local row = unpack_player_row(list[j])
		if row then
			table.insert(out, row)
		end
	end
	return out
end

return {
	MAX_PLAYERS = MAX_PLAYERS,
	DEFAULT_PORT = DEFAULT_PORT,
	INPUT_HZ = INPUT_HZ,
	SNAP_HZ = SNAP_HZ,
	SOFT_CORRECT = SOFT_CORRECT,
	EV = EV,
	KEYS = KEYS,
	empty_held = empty_held,
	copy_held = copy_held,
	pack_input = pack_input,
	unpack_input = unpack_input,
	pack_player_row = pack_player_row,
	unpack_player_row = unpack_player_row,
	pack_snap = pack_snap,
	unpack_snap_rows = unpack_snap_rows,
}
