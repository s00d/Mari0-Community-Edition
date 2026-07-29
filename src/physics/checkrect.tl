-- AABB object-list query via bump spatial index.

require("physics.world")

global function checkrect(x: number, y: number, width: number, height: number, list: any, statics?: any): {integer:any}
	local unpack = table.unpack or unpack
	local out = {} as {integer:any}

	local inobj: {Body}|nil = nil

	local catlist: any = ""

	if type(list) == "table" and (list as {any})[1] == "exclude" then
		inobj = {unpack(list as {any})} as {Body}
		table.remove(inobj as {any}, 1)
		list = "all"
	end

	local allow_all = (list == nil) or (list == "all")
	local allow: {string: boolean}|nil = nil
	if not allow_all and type(list) == "table" then
		allow = {} as {string: boolean}
		local lst = list as {any}
		for j = 1, #lst do
			local entry = lst[j]
			if tonumber(entry as string) then
				(allow as {string: boolean})["enemy"] = true
				catlist = tonumber(entry as string)
			else
				(allow as {string: boolean})[entry as string] = true
			end
		end
	end

	local items: {integer: any}
	local len: number
	items, len = physics_world_query(x, y, width, height, nil)

	for ii = 1, len do
		local w = items[ii as integer] as Body
		if w and w.active then
			local group_name: string|nil
			local key: any
			group_name, key = physics_world_meta(w)
			if group_name and key ~= nil and objects[group_name] and (objects[group_name] as {any: Body})[key] == w then
				local contains = allow_all
				if not contains and allow then
					contains = (allow as {string: boolean})[group_name] == true
				end

				if contains then
					if statics or w.static ~= true or not allow_all then
						local skip = false
						if inobj then
							for _, vv in pairs(inobj as {any: Body}) do
								if vv == w then
									skip = true
								end

								local vvmask = vv.mask
								local wmask = w.mask
								if (vvmask ~= nil and (vvmask as {number: boolean})[w.category] == true)
									or (wmask ~= nil and (wmask as {number: boolean})[vv.category] == true) then
									skip = true
								end
							end
						end
						if not skip then
							-- Real rect for zero-size bodies (index uses epsilon expansion).
							if aabb(x, y, width, height, w.x, w.y, w.width, w.height) then
								if (group_name == "enemy" and catlist == w.category) or catlist == "" or group_name ~= "enemy" then
									table.insert(out, group_name)
									table.insert(out, key)
								end
							end
						end
					end
				end
			end
		end
	end

	return out
end
