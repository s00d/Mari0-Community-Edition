-- AABB object-list query (extracted from physics.lua).
-- Depends at runtime on: objects, aabb.

global function checkrect(...: any): {any}
	local x = (... as number)
	local y = (select(2, ...) as number)
	local width = (select(3, ...) as number)
	local height = (select(4, ...) as number)
	local list: any = select(5, ...)
	local statics = select(6, ...)
	local unpack = table.unpack or unpack
	local out = {} as {any}
	
	local inobj: {Entity}|nil = nil
	
	local catlist: any = ""
	
	if type(list) == "table" and (list as {any})[1] == "exclude" then
		inobj = {unpack(list as {any})} as {Entity}
		table.remove(inobj as {any}, 1)
		list = "all"
	end

	for i, v in pairs(objects) do
		local contains = false
		
		if list and list ~= "all" then
			local lst = list as {any}
			for j = 1, #lst do
				if lst[j] == i then
					contains = true
				elseif tonumber(lst[j] as any) and "enemy" == i then
					contains = true
					catlist = tonumber(lst[j] as any)
				end
			end
		end
		
		if list == "all" or contains then
			for j, w in pairs(v) do
				if statics or w.static ~= true or list ~= "all" then
					local skip = false
					if inobj then
						for ii, vv in pairs(inobj) do
							if vv == w then
								skip = true
							end
							
							if (vv.mask ~= nil and vv.mask[w.category] == true) or (w.mask ~= nil and w.mask[vv.category] == true) then
								skip = true
							end
							
						end
					end
					if not skip then
						if w.active then
							if aabb(x, y, width, height, w.x, w.y, w.width, w.height) then
								if (i=="enemy" and catlist == w.category) or catlist == "" or i ~= "enemy" then
									table.insert(out, i)
									table.insert(out, j)
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
