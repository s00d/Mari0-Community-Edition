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
			for j, w in pairs(v) do
				local wb = w as Body
				if statics or wb.static ~= true or list ~= "all" then
					local skip = false
					if inobj then
						for ii, vv in pairs(inobj as {any:Body}) do
							if vv == wb then
								skip = true
							end
							
							local vvmask = vv.mask
							local wmask = wb.mask
							if (vvmask ~= nil and (vvmask as {number:boolean})[wb.category] == true)
								or (wmask ~= nil and (wmask as {number:boolean})[vv.category] == true) then
								skip = true
							end
							
						end
					end
					if not skip then
						if wb.active then
							if aabb(x, y, width, height, wb.x, wb.y, wb.width, wb.height) then
								if (i=="enemy" and catlist == wb.category) or catlist == "" or i ~= "enemy" then
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
