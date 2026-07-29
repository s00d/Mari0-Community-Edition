--[[ bump spatial index for Mari0 AABB broadphase / checkrect.
     Resolve stays in checkcollision; bump.move responses are unused. ]]

local bump = require("bump")

local CELL_SIZE = 2
local EPS = 1 / 32
local EPS_SIZE = 1 / 16

local world: BumpWorld|nil = nil

-- item → { group = string, key = any }
local item_meta: {any: {string: any}} = {}

local function ensure_world(): BumpWorld
	if not world then
		world = bump.newWorld(CELL_SIZE)
	end
	return world as BumpWorld
end

-- Expand zero-size rects for bump (requires w,h > 0). Body sizes unchanged.
local function index_rect(x: number, y: number, w: number, h: number): number, number, number, number
	if w == 0 then
		x = x - EPS
		w = EPS_SIZE
	end
	if h == 0 then
		y = y - EPS
		h = EPS_SIZE
	end
	if w <= 0 then
		w = EPS_SIZE
	end
	if h <= 0 then
		h = EPS_SIZE
	end
	return x, y, w, h
end

local function item_still_valid(item: any, group: string, key: any): boolean
	if not objects then
		return false
	end
	local grp = objects[group]
	if not grp then
		return false
	end
	return (grp as {any: Body})[key] == item
end

global function physics_world_reset()
	world = bump.newWorld(CELL_SIZE)
	item_meta = {}
end

global function physics_world_remove(item: any)
	if not world or not item then
		return
	end
	local w = world as BumpWorld
	if w:hasItem(item) then
		w:remove(item)
	end
	item_meta[item] = nil
end

-- Register / update a body in the spatial index. group+key used by handlegroup/checkrect.
global function physics_world_upsert(item: any, group: string, key: any)
	if not item then
		return
	end
	local body = item as Body
	if body.active == false then
		physics_world_remove(item)
		return
	end
	if body.width == nil or body.height == nil or body.x == nil or body.y == nil then
		return
	end

	local w = ensure_world()
	local ix, iy, iw, ih = index_rect(body.x, body.y, body.width, body.height)
	item_meta[item] = { group = group, key = key }
	if w:hasItem(item) then
		w:update(item, ix, iy, iw, ih)
	else
		w:add(item, ix, iy, iw, ih)
	end
end

global function physics_world_meta(item: any): string|nil, any
	local m = item_meta[item]
	if not m then
		return nil, nil
	end
	return m.group as string, m.key
end

global function physics_world_query(x: number, y: number, w: number, h: number, filter: any): {integer: any}, number
	local bw = ensure_world()
	local qx, qy, qw, qh = index_rect(x, y, w, h)
	if filter then
		return bw:queryRect(qx, qy, qw, qh, filter as function)
	end
	return bw:queryRect(qx, qy, qw, qh)
end

-- Remove stale bump entries (despawn without explicit remove).
global function physics_world_prune()
	if not world then
		return
	end
	local bw = world as BumpWorld
	local items, len = bw:getItems()
	for i = 1, len do
		local item = items[i as integer]
		local group, key = physics_world_meta(item)
		if not group or not item_still_valid(item, group, key) then
			physics_world_remove(item)
		end
	end
end

-- Full sync from global `objects` (level load + unit tests only).
global function physics_world_refresh()
	if not objects then
		return
	end
	ensure_world()

	local seen: {any: boolean} = {}

	local function sync_group(group_name: string, grp: {any: Body})
		for key, body in pairs(grp) do
			if body and (body as Body).active ~= false then
				physics_world_upsert(body, group_name, key)
				seen[body] = true
			end
		end
	end

	local order = PHYSICS_GROUP_ORDER
	local order_seen: {string: boolean} = {}
	if order then
		for gi = 1, #order do
			local group_name = order[gi]
			order_seen[group_name] = true
			local grp = objects[group_name]
			if grp then
				sync_group(group_name, grp as {any: Body})
			end
		end
	end

	-- Groups not in PHYSICS_GROUP_ORDER (test stubs, dynamic groups).
	for group_name, grp in pairs(objects) do
		if type(grp) == "table" and not order_seen[group_name as string] then
			sync_group(group_name as string, grp as {any: Body})
		end
	end

	local bw = world as BumpWorld
	local items, len = bw:getItems()
	for i = 1, len do
		local item = items[i as integer]
		if not seen[item] then
			physics_world_remove(item)
		end
	end
end

-- Generic objects[group][key] slot: set body and sync bump.
global function physics_world_upsert_slot(group: string, key: any, body: any)
	if objects then
		if not objects[group] then
			objects[group] = {}
		end
		(objects[group] as {any: any})[key] = body
	end
	if body then
		physics_world_upsert(body, group, key)
	end
end

-- Generic despawn: remove from bump and clear objects[group][key].
global function physics_world_remove_slot(group: string, key: any)
	if objects and objects[group] then
		local old = (objects[group] as {any: Body})[key]
		if old then
			physics_world_remove(old)
		end
		(objects[group] as {any: any})[key] = nil
	end
end

-- Tile slot helper: objects["tile"][key] + bump sync.
global function physics_world_set_tile(key: any, body: any|nil)
	if objects then
		if not objects["tile"] then
			objects["tile"] = {}
		end
		local old = (objects["tile"] as {any: Body})[key]
		if old and old ~= body then
			physics_world_remove(old)
		end
		(objects["tile"] as {any: any})[key] = body
	end
	if body then
		physics_world_upsert(body, "tile", key)
	end
end

-- Portalwall slot helper.
global function physics_world_set_portalwall(key: string, body: any|nil)
	if objects then
		if not objects["portalwall"] then
			objects["portalwall"] = {}
		end
		local old = (objects["portalwall"] as {any: Body})[key]
		if old and old ~= body then
			physics_world_remove(old)
		end
		(objects["portalwall"] as {any: any})[key] = body
	end
	if body then
		physics_world_upsert(body, "portalwall", key)
	end
end

-- Platform array append + immediate bump sync (runtime spawn).
global function physics_world_insert_platform(body: any)
	if objects then
		if not objects["platform"] then
			objects["platform"] = {}
		end
		local grp = objects["platform"] as {integer: Body}
		table.insert(grp, body as Body)
		physics_world_upsert_slot("platform", #grp, body)
	end
end
