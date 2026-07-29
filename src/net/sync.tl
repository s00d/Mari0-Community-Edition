--[[ Host-auth input edges + player snapshot apply. Pure Lua (no sock). ]]

local Schema = require("net.schema")

local Sync = {}

local held: {integer:{string:any}} = {}
local held_prev: {integer:{string:any}} = {}
local last_snap: {{string:any}}|nil = nil
local input_accum = 0.0
local snap_accum = 0.0
local local_slot = 1

function Sync.set_local_slot(slot: integer)
	local_slot = slot
end

function Sync.local_slot(): integer
	return local_slot
end

function Sync.clear()
	for k in pairs(held) do
		held[k] = nil
	end
	for k in pairs(held_prev) do
		held_prev[k] = nil
	end
	last_snap = nil
	input_accum = 0
	snap_accum = 0
end

function Sync.set_held(slot: integer, h: {string:any})
	held[slot] = Schema.copy_held(h)
end

function Sync.held_for(slot: integer, action: string): boolean|nil
	local h = held[slot]
	if not h then
		return nil
	end
	return h[action] == true
end

function Sync.read_local_held(slot: integer): {string:any}
	local h = Schema.empty_held()
	if not controls or not controls[slot] then
		return h
	end
	for _, action in ipairs(Schema.KEYS) do
		h[action] = ui_action_down(slot, action)
	end
	if playerobjs and playerobjs[slot] then
		h.ang = (playerobjs[slot].pointingangle as number) or 0
	end
	return h
end

function Sync.should_send_input(dt: number): boolean
	input_accum = input_accum + dt
	if input_accum >= 1 / Schema.INPUT_HZ then
		input_accum = input_accum - 1 / Schema.INPUT_HZ
		return true
	end
	return false
end

function Sync.should_send_snap(dt: number): boolean
	snap_accum = snap_accum + dt
	if snap_accum >= 1 / Schema.SNAP_HZ then
		snap_accum = snap_accum - 1 / Schema.SNAP_HZ
		return true
	end
	return false
end

function Sync.pack_snapshot(seq: integer): {string:any}
	local rows: {{any}} = {}
	if playerobjs then
		for i = 1, (players as integer) or 1 do
			if playerobjs[i] then
				table.insert(rows, Schema.pack_player_row(i, playerobjs[i] as {string:any}))
			end
		end
	end
	return Schema.pack_snap(seq, rows)
end

local function apply_one(row: {string:any}, soft_local: boolean)
	local i = (tonumber(row.i) or 0) as integer
	if i < 1 or not playerobjs or not playerobjs[i] then
		return
	end
	local p = playerobjs[i]
	local nx = (tonumber(row.x) or p.x) as number
	local ny = (tonumber(row.y) or p.y) as number
	if soft_local and i == local_slot then
		local dx = nx - ((p.x as number) or 0)
		local dy = ny - ((p.y as number) or 0)
		if (dx * dx + dy * dy) < (Schema.SOFT_CORRECT * Schema.SOFT_CORRECT) then
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
	if row.dead ~= nil then
		p.dead = row.dead == true
	end
end

function Sync.apply_snapshot(msg: {string:any}, soft_local: boolean)
	local rows = Schema.unpack_snap_rows(msg)
	last_snap = rows
	for j = 1, #rows do
		local row = rows[j]
		local soft = soft_local and (tonumber(row.i) or 0) == local_slot
		apply_one(row, soft)
	end
end

function Sync.reapply_last_snap(soft_local: boolean)
	if not last_snap then
		return
	end
	local snap = last_snap as {{string:any}}
	for j = 1, #snap do
		local row = snap[j]
		local i = (tonumber(row.i) or 0) as integer
		local soft = soft_local and i == local_slot
		if i ~= local_slot or soft_local then
			apply_one(row, soft)
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

function Sync.host_process_edges()
	for slot, cur in pairs(held) do
		local s = slot as integer
		if s ~= local_slot then
			local prev = held_prev[s] or Schema.empty_held()
			fire_edges(s, prev, cur as {string:any})
		end
	end
	for k in pairs(held_prev) do
		held_prev[k] = nil
	end
	for slot, cur in pairs(held) do
		held_prev[slot as integer] = Schema.copy_held(cur as {string:any})
	end
end

return Sync
