--[[ Host-authoritative input + player snapshots.

Gaffer-style choice for Mari0: full lockstep is a poor fit (Lua physics not
bit-identical); rollback is heavy. Host runs sim, clients send inputs (~30 Hz),
host broadcasts player snaps (~20 Hz) with soft local correction.
]]

local INPUT_HZ = 30
local SNAP_HZ = 20
local SOFT_CORRECT = 0.75

local held: {integer:{string:any}} = {}
local held_prev: {integer:{string:any}} = {}
local last_snap: {{string:any}}|nil = nil
local input_accum = 0.0
local snap_accum = 0.0

local KEYS = {"left", "right", "up", "down", "jump", "run", "use", "reload", "portal1", "portal2"}

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
	if src == nil then
		return h
	end
	local s = src as {string:any}
	for _, k in ipairs(KEYS) do
		h[k] = s[k] == true
	end
	h.ang = tonumber(s.ang) or 0
	return h
end

local function read_local_held(slot: integer): {string:any}
	local h = empty_held()
	if not controls or not controls[slot] then
		return h
	end
	local function down(action: string): boolean
		local c = controls[slot][action]
		if not c then
			return false
		end
		return checkkey(c) == true
	end
	h.left = down("left")
	h.right = down("right")
	h.up = down("up")
	h.down = down("down")
	h.jump = down("jump")
	h.run = down("run")
	h.use = down("use")
	h.reload = down("reload")
	h.portal1 = down("portal1")
	h.portal2 = down("portal2")
	if playerobjs and playerobjs[slot] then
		h.ang = (playerobjs[slot].pointingangle as number) or 0
	end
	return h
end

local function pack_input(slot: integer, h: {string:any}): {string:any}
	return {
		t = "input",
		slot = slot,
		left = h.left == true,
		right = h.right == true,
		up = h.up == true,
		down = h.down == true,
		jump = h.jump == true,
		run = h.run == true,
		use = h.use == true,
		reload = h.reload == true,
		portal1 = h.portal1 == true,
		portal2 = h.portal2 == true,
		ang = tonumber(h.ang) or 0,
	}
end

local function unpack_input(msg: {string:any}): integer, {string:any}
	local slot = (tonumber(msg.slot) or 0) as integer
	local h = empty_held()
	for _, k in ipairs(KEYS) do
		h[k] = msg[k] == true
	end
	h.ang = tonumber(msg.ang) or 0
	return slot, h
end

local function set_held(slot: integer, h: {string:any})
	held[slot] = copy_held(h)
end

local function clear_held()
	for k in pairs(held) do
		held[k] = nil
	end
	for k in pairs(held_prev) do
		held_prev[k] = nil
	end
	last_snap = nil
	input_accum = 0
	snap_accum = 0
	rawset(_G, "net_held", held)
end

local function is_held(slot: integer, action: string): boolean|nil
	local h = held[slot]
	if not h then
		return nil
	end
	return h[action] == true
end

local function round3(n: number): number
	if n >= 0 then
		return math.floor(n * 1000 + 0.5) / 1000
	end
	return math.ceil(n * 1000 - 0.5) / 1000
end

local function pack_player(i: integer): {string:any}|nil
	if not playerobjs or not playerobjs[i] then
		return nil
	end
	local p = playerobjs[i]
	return {
		i = i,
		x = round3((p.x as number) or 0),
		y = round3((p.y as number) or 0),
		sx = round3((p.speedx as number) or 0),
		sy = round3((p.speedy as number) or 0),
		ang = round3((p.pointingangle as number) or 0),
		sz = (p.size as number) or 1,
		dead = p.dead == true,
	}
end

local function pack_snapshot(): {string:any}
	local plist: {{string:any}} = {}
	if playerobjs then
		for i = 1, (players as integer) or 1 do
			local row = pack_player(i)
			if row then
				table.insert(plist, row)
			end
		end
	end
	return {t = "snap", p = plist}
end

local function apply_one(row: {string:any}, soft_local: boolean)
	local i = (tonumber(row.i) or 0) as integer
	if i < 1 or not playerobjs or not playerobjs[i] then
		return
	end
	local p = playerobjs[i]
	local nx = (tonumber(row.x) or p.x) as number
	local ny = (tonumber(row.y) or p.y) as number
	if soft_local and i == (netplayernumber as integer) then
		local dx = nx - ((p.x as number) or 0)
		local dy = ny - ((p.y as number) or 0)
		if (dx * dx + dy * dy) < (SOFT_CORRECT * SOFT_CORRECT) then
			-- small drift: keep local prediction
			p.speedx = tonumber(row.sx) or p.speedx
			p.speedy = tonumber(row.sy) or p.speedy
			if row.ang ~= nil then
				p.pointingangle = tonumber(row.ang) or p.pointingangle
			end
			return
		end
	end
	p.x = nx
	p.y = ny
	p.speedx = tonumber(row.sx) or 0
	p.speedy = tonumber(row.sy) or 0
	if row.ang ~= nil then
		p.pointingangle = tonumber(row.ang) or 0
	end
	if row.sz ~= nil and p.size ~= row.sz then
		-- size changes are rare; leave growth anim to host authority later
	end
	if row.dead ~= nil then
		p.dead = row.dead == true
	end
end

local function apply_snapshot(msg: {string:any}, soft_local: boolean)
	local plist = msg.p
	if type(plist) ~= "table" then
		return
	end
	last_snap = plist as {{string:any}}
	for j = 1, #(plist as {any}) do
		local row = (plist as {{string:any}})[j]
		if row then
			local i = (tonumber(row.i) or 0) as integer
			local soft = soft_local and i == (netplayernumber as integer)
			apply_one(row, soft)
		end
	end
end

local function reapply_last_snap(soft_local: boolean)
	local snap = last_snap
	if snap == nil then
		return
	end
	local rows = snap as {{string:any}}
	for j = 1, #rows do
		local row = rows[j]
		if row then
			local i = (tonumber(row.i) or 0) as integer
			-- Always hard-correct remotes; soft for local if requested.
			local soft = soft_local and i == (netplayernumber as integer)
			if i ~= (netplayernumber as integer) or soft_local then
				apply_one(row, soft)
			end
		end
	end
end

local function fire_edges(slot: integer, prev: {string:any}, cur: {string:any})
	if not playerobjs or not playerobjs[slot] then
		return
	end
	local p = playerobjs[slot]
	if cur.jump and not prev.jump then
		p:jump()
	elseif not cur.jump and prev.jump then
		p:stopjump()
	end
	if cur.run and not prev.run then
		p:fire()
	end
	if cur.use and not prev.use then
		p:use()
	end
	if cur.reload and not prev.reload then
		p:removeportals()
	end
	if cur.left and not prev.left then
		p:leftkey()
	end
	if cur.right and not prev.right then
		p:rightkey()
	end
	if cur.portal1 and not prev.portal1 then
		shootportal(slot, 1, (p.x as number) + 6 / 16, (p.y as number) + 6 / 16, (p.pointingangle as number) or 0)
	end
	if cur.portal2 and not prev.portal2 then
		shootportal(slot, 2, (p.x as number) + 6 / 16, (p.y as number) + 6 / 16, (p.pointingangle as number) or 0)
	end
	if cur.ang ~= nil then
		p.pointingangle = tonumber(cur.ang) or p.pointingangle
	end
end

local function host_process_edges()
	local any = false
	for _ in pairs(held) do
		any = true
		break
	end
	if not any then
		return
	end
	for slot, cur in pairs(held) do
		local s = slot as integer
		if s ~= (netplayernumber as integer) then
			local prev = held_prev[s]
			if not prev then
				prev = empty_held()
			end
			fire_edges(s, prev, cur as {string:any})
		end
	end
	for k in pairs(held_prev) do
		held_prev[k] = nil
	end
	for slot, cur in pairs(held) do
		held_prev[slot as integer] = copy_held(cur as {string:any})
	end
end

local function should_send_input(dt: number): boolean
	input_accum = input_accum + dt
	if input_accum >= 1 / INPUT_HZ then
		input_accum = input_accum - 1 / INPUT_HZ
		return true
	end
	return false
end

local function should_send_snap(dt: number): boolean
	snap_accum = snap_accum + dt
	if snap_accum >= 1 / SNAP_HZ then
		snap_accum = snap_accum - 1 / SNAP_HZ
		return true
	end
	return false
end

-- Export for checkkey overrides
rawset(_G, "net_held", held)

local function refresh_net_held_global()
	rawset(_G, "net_held", held)
end

return {
	INPUT_HZ = INPUT_HZ,
	SNAP_HZ = SNAP_HZ,
	read_local_held = read_local_held,
	pack_input = pack_input,
	unpack_input = unpack_input,
	set_held = set_held,
	clear_held = clear_held,
	is_held = is_held,
	pack_snapshot = pack_snapshot,
	apply_snapshot = apply_snapshot,
	reapply_last_snap = reapply_last_snap,
	host_process_edges = host_process_edges,
	should_send_input = should_send_input,
	should_send_snap = should_send_snap,
	refresh_net_held_global = refresh_net_held_global,
	empty_held = empty_held,
}
