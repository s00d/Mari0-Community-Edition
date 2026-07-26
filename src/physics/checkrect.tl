-- AABB object-list query (extracted from physics.lua).
-- Depends at runtime on: objects, aabb.

global function checkrect(...: any): {any}
	local x, y, width, height, list, statics = ...
	local unpack = table.unpack or unpack
	local out = {}
	
	local inobj
	
	local catlist = ""
	
	if type(list) == "table" and list[1] == "exclude" then
		inobj = {unpack(list)}
		table.remove(inobj, 1)
		list = "all"
	end

	for i, v in pairs(objects) do
		local contains = false
		
		if list and list ~= "all" then			
			for j = 1, #list do
				if list[j] == i then
					contains = true
				elseif tonumber(list[j]) and "enemy" == i then
					contains = true
					catlist = tonumber(list[j])
				end
			end
		end
		
		if list == "all" or contains then
			for j, w in pairs(v) do
				if statics or w.static ~= true or list ~= "all" then
					local skip = false
					if inobj then
						for i, v in pairs(inobj) do
							if v == w then
								skip = true
							end
							
							if (v.mask ~= nil and v.mask[w.category] == true) or (w.mask ~= nil and w.mask[v.category] == true) then
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
