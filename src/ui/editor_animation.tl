--[[ Editor animation-tab GUI glue (extracted from editor.tl). ]]

function generateanimationgui()
	if not animations[currentanimation] then
		createnewanimation()
	end

	animationguilines = {}
	animationguilines.triggers = {}
	for _, v in pairs(animations[currentanimation].triggers as {any:any}) do
		table.insert(animationguilines.triggers, animationguiline:new(v, "trigger"))
	end
	animationguilines.conditions = {}
	for _, v in pairs(animations[currentanimation].conditions as {any:any}) do
		table.insert(animationguilines.conditions, animationguiline:new(v, "condition"))
	end
	animationguilines.actions = {}
	for _, v in pairs(animations[currentanimation].actions as {any:any}) do
		table.insert(animationguilines.actions, animationguiline:new(v, "action"))
	end
end

function createnewanimation()
	local s = {}
	s.triggers = {}
	s.conditions = {}
	s.actions = {}
	
	local i = 1
	while love.filesystem.getInfo(mappack_path(mappack) .. "/animations/animation" .. i .. ".json") do
		i = i + 1
	end
	love.filesystem.createDirectory(mappack_path(mappack) .. "/animations/")
	love.filesystem.write(mappack_path(mappack) .. "/animations/animation" .. i .. ".json", JSON.encode(s, { indent = true }))
	
	table.insert(animations as {any}, animation:new(mappack_path(mappack) .. "/animations/animation" .. i .. ".json", "animation" .. i .. ".json"))
	
	currentanimation = #animations
	
	updateanimationdropdown()
end

function updateanimationdropdown()	
	local args = {}
	for _, v in ipairs(animations) do
		table.insert(args, string.sub(v.name as string, 1, -6))
	end
	
	guielements["animationselectdrop"] = guielement:new("dropdown", 15, 20, 15, selectanimation, currentanimation, unpack(args))
end
	
function deleteanimationguiline(t: string, tabl: animationguiline)
	for i, v in ipairs((animationguilines[t .. "s"]) as {animationguiline}) do
		if v == tabl then
			table.remove(animationguilines[t .. "s"], i)
		end
	end
end

function movedownanimationguiline(t: string, tabl: animationguiline)
	for i, v in ipairs((animationguilines[t .. "s"]) as {animationguiline}) do
		if v == tabl then
			if i ~= #animationguilines[t .. "s"] then
				animationguilines[t .. "s"][i], animationguilines[t .. "s"][i+1] = animationguilines[t .. "s"][i+1], animationguilines[t .. "s"][i]
				break
			end
		end
	end
end

function moveupanimationguiline(t: string, tabl: animationguiline)
	for i, v in ipairs((animationguilines[t .. "s"]) as {animationguiline}) do
		if v == tabl then
			if i ~= 1 then
				animationguilines[t .. "s"][i], animationguilines[t .. "s"][i-1] = animationguilines[t .. "s"][i-1], animationguilines[t .. "s"][i]
				break
			end
		end
	end
end

function selectanimation(i: number)
	guielements["animationselectdrop"].var = i
	saveanimation()
	currentanimation = i as integer
	generateanimationgui()
end

function saveanimation()
	local out: {string:{{any}}} = {}
	
	local typelist = {"triggers", "conditions", "actions"}
	for _, w in ipairs(typelist) do
		out[w] = {}
		for i, v in ipairs((animationguilines[w]) as {animationguiline}) do
			out[w][i] = {}
			for j, k in ipairs(v.elements as {animationguielement}) do
				if k.gui then
					local val: any = ""
					if k.gui.type == "dropdown" then
						if j == 1 then
							--find normal name
							for l, m in pairs(animationlist as {any:any}) do
								if (m as guielement).nicename == (k.gui.entries as {any:any})[k.gui.var] then
									val = l
									break
								end
							end
						else
							val = (k.gui.entries as {any:any})[k.gui.var]
						end
					elseif k.gui.type == "input" then
						val = k.gui.value
					end
					
					table.insert(out[w][i], val)
				end
			end
		end
	end
	
	animations[currentanimation].triggers = out.triggers as {{any}}
	animations[currentanimation].conditions = out.conditions as {{any}}
	animations[currentanimation].actions = out.actions as {{any}}
	
	local json = JSON.encode(out, { indent = true })
	
	local ok, err = pcall(love.filesystem.write, animations[currentanimation].filepath as string, json as string)
	if not ok then
		print(tostring(err) .. " - File: " .. (animations[currentanimation].filepath as string))
	end
end

function addanimationtrigger()
	table.insert(animationguilines.triggers, animationguiline:new({}, "trigger"))
end

function addanimationcondition()
	table.insert(animationguilines.conditions, animationguiline:new({}, "condition"))
end

function addanimationaction()
	table.insert(animationguilines.actions, animationguiline:new({}, "action"))
end

