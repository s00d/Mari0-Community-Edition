--[[ Gel type registry: ids, flags, clamp, pool cap. ]]

global GEL_BOUNCE: integer = 1
global GEL_SPEED: integer = 2
global GEL_CLEANSE: integer = 3
global GEL_ADHERE: integer = 4

global GEL_MAX_ID: integer = 4
global GEL_POOL_MAX: integer = 24

global record GelDef
	id: integer
	name: string
	bounce: boolean|nil
	speed: boolean|nil
	cleanse: boolean|nil
	adhere: boolean|nil
end

global GEL_DEFS: {integer:GelDef} = {
	[1] = { id = 1, name = "bounce", bounce = true },
	[2] = { id = 2, name = "speed", speed = true },
	[3] = { id = 3, name = "cleanse", cleanse = true },
	[4] = { id = 4, name = "adhere", adhere = true },
}

global function gel_has(gid: number|nil, flag: string): boolean
	if gid == nil then
		return false
	end
	local d = GEL_DEFS[gid as integer]
	if d == nil then
		return false
	end
	return (d as {string:any})[flag] == true
end

global function gel_clamp_id(id: any): integer
	local gid = tonumber(id)
	if gid == nil or gid < 1 or gid > GEL_MAX_ID then
		return 1
	end
	return gid as integer
end

-- Drop oldest living gel blobs so spawn stays under GEL_POOL_MAX.
global function gel_pool_prepare()
	local listn = session.objects and session.objects["gel"]
	if listn == nil then
		return
	end
	local list = listn as {any}
	while #list >= GEL_POOL_MAX do
		table.remove(list, 1)
	end
end

return {
	GEL_BOUNCE = GEL_BOUNCE,
	GEL_SPEED = GEL_SPEED,
	GEL_CLEANSE = GEL_CLEANSE,
	GEL_ADHERE = GEL_ADHERE,
	GEL_MAX_ID = GEL_MAX_ID,
	GEL_POOL_MAX = GEL_POOL_MAX,
	GEL_DEFS = GEL_DEFS,
	gel_has = gel_has,
	gel_clamp_id = gel_clamp_id,
	gel_pool_prepare = gel_pool_prepare,
}
