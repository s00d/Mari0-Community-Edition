-- AABB object-list query (extracted from physics.lua).
-- Depends at runtime on: objects, aabb.

global function checkrect(x: number, y: number, width: number, height: number, list: any, statics?: any): {any}
	local unpack = table.unpack or unpack
	local out = {} as {any}
	
	local inobj: {Body}|nil = nil
	
	local catlist: any = ""
	
	if type(list) == "table" and (list as {any})[1] == "exclude" then
		inobj = {unpack(list as {any})} as {Body}
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
			for j, w in pairs(v as {any:Body}) do
				if statics or w.static ~= true or list ~= "all" then
					local skip = false
					if inobj then
						for _, vv in pairs(inobj as {any:Body}) do
							if vv == w then
								skip = true
							end
							
							local vvmask = vv.mask
							local wmask = w.mask
							if (vvmask ~= nil and (vvmask as {number:boolean})[w.category] == true)
								or (wmask ~= nil and (wmask as {number:boolean})[vv.category] == true) then
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
