--[[ config / save / suspend
	options.txt records: `name value;` or flag `name;`
	Slotted names use `/`: `playercontrols/1 left=key:a,right=key:d;`
	No `:` as record delimiter — baton sources keep `key:a` intact.
]]

global function saveconfig()
	if Net and Net.is_online and Net.is_online() then
		return
	end
	
	local s = ""
	for i = 1, #(controls as {any}) do
		s = s .. "playercontrols/" .. i .. " "
		local row = controls[i] as {string:any}
		if row["joy"] then
			s = s .. "joy=" .. tostring(row["joy"]) .. ","
		end
		local keys = {} as {string}
		for j, _ in pairs(row) do
			if j ~= "joy" then
				table.insert(keys, j as string)
			end
		end
		table.sort(keys)
		local parts = {} as {string}
		for ki = 1, #keys do
			local j = keys[ki]
			local binding = row[j] as {string}|nil
			if binding and #binding > 0 then
				table.insert(parts, j .. "=" .. table.concat(binding, "|"))
			end
		end
		if #parts > 0 then
			s = s .. table.concat(parts, ",")
		end
		s = s .. ";"
	end	
	
	for i = 1, #mariocolors do
		s = s .. "playercolors/" .. i .. " "
		if #mariocolors[i] > 0 then
			for j = 1, #mariocolors[i] do
				for k = 1, 3 do
					s = s .. mariocolors[i][j][k] * 255
					if not (j == #mariocolors[i] and k == 3) then
						s = s .. ","
					end
				end
			end
		end
		s = s .. ";"
	end
	
	for i = 1, #(mariocharacter as {any}) do
		s = s .. "mariocharacter/" .. i .. " " .. mariocharacter[i] .. ";"
	end
	
	for i = 1, #portalhues do
		s = s .. "portalhues/" .. i .. " " .. round(portalhues[i][1], 4) .. "," .. round(portalhues[i][2], 4) .. ";"
	end
	
	for i = 1, #(mariohats as {any}) do
		s = s .. "mariohats/" .. i
		if #(mariohats[i] as {any}) > 0 then
			s = s .. " "
			for j = 1, #(mariohats[i] as {any}) do
				s = s .. tostring(mariohats[i][j])
				if j ~= #mariohats[i] then
					s = s .. ","
				end
			end
		end
		s = s .. ";"
	end
	
	s = s .. "scale " .. scale .. ";"
	s = s .. "shader1 " .. shaderlist[currentshaderi1] .. ";"
	s = s .. "shader2 " .. shaderlist[currentshaderi2] .. ";"
	s = s .. "volume " .. volumesfx .. ";"
	s = s .. "musicvolume " .. volumemusic .. ";"
	s = s .. "mouseowner " .. mouseowner .. ";"
	s = s .. "mappack " .. mappack .. ";"
	if vsync then
		s = s .. "vsync;"
	end
	if gamefinished then
		s = s .. "gamefinished;"
	end
	s = s .. "fullscreen " .. tostring(fullscreen) .. ";"
	s = s .. "fullscreenmode " .. fullscreenmode .. ";"
	for i, v in pairs(reachedworlds) do
		s = s .. "reachedworlds/" .. i .. " "
		for j = 1, 8 do
			if v[j] then
				s = s .. 1
			else
				s = s .. 0
			end
			if j ~= 8 then
				s = s .. ","
			end
		end
		s = s .. ";"
	end
	
	love.filesystem.write("options.txt", s)
end

local function config_kind_id(key: string): string, string|nil
	local slash = key:find("/", 1, true)
	if not slash then
		return key, nil
	end
	return key:sub(1, slash - 1), key:sub(slash + 1)
end

local function parse_controls_payload(row: {string:any}, payload: string)
	s3 = strsplit(payload, ",")
	for j = 1, #s3 do
		local eq = (s3[j] as string):find("=", 1, true)
		if eq then
			local name = (s3[j] as string):sub(1, eq - 1)
			local val = (s3[j] as string):sub(eq + 1)
			if name == "joy" then
				row["joy"] = tonumber(val) as integer
			elseif val ~= "" then
				row[name] = strsplit(val, "|")
			else
				row[name] = {}
			end
		end
	end
end

global function loadconfig()
	players = 1
	defaultconfig()
	
	if not love.filesystem.getInfo("options.txt") then
		return
	end
	
	local s = love.filesystem.read("options.txt")
	s1 = strsplit(s, ";")
	
	for i = 1, #s1-1 do
		local line = s1[i] as string
		if line == "" then
			-- skip
		else
			local sp = line:find(" ", 1, true)
			local key: string
			local val: string = ""
			if sp then
				key = line:sub(1, sp - 1)
				val = line:sub(sp + 1)
			else
				key = line
			end
			local kind, id = config_kind_id(key)

			if kind == "playercontrols" and id then
				local slot = tonumber(id) as integer
				if controls[slot] == nil then
					controls[slot] = {}
				end
				parse_controls_payload(controls[slot] as {string:any}, val)
				players = math.max(players, slot)
			elseif kind == "playercolors" and id then
				local slot = tonumber(id) as integer
				if mariocolors[slot] == nil then
					mariocolors[slot] = {}
				end
				s3 = strsplit(val, ",")
				mariocolors[slot] = {}
				for ci = 1, #s3/3 do
					mariocolors[slot][ci as integer] = {
						tonumber(s3[(1+(ci-1)*3) as integer]) / 255,
						tonumber(s3[(2+(ci-1)*3) as integer]) / 255,
						tonumber(s3[(3+(ci-1)*3) as integer]) / 255,
					}
				end
			elseif kind == "portalhues" and id then
				local slot = tonumber(id) as integer
				if portalhues[slot] == nil then
					portalhues[slot] = {}
				end
				s3 = strsplit(val, ",")
				portalhues[slot] = {tonumber(s3[1]), tonumber(s3[2])}
			elseif kind == "mariohats" and id then
				local playerno = tonumber(id) as integer
				mariohats[playerno] = {}
				if val ~= "" then
					s3 = strsplit(val, ",")
					for hi = 1, #s3 do
						mariohats[playerno][hi] = tonumber(s3[hi])
					end
				end
			elseif kind == "mariocharacter" and id then
				mariocharacter[tonumber(id) as integer] = val
			elseif kind == "scale" then
				scale = tonumber(val)
			elseif kind == "shader1" then
				for si = 1, #shaderlist do
					if shaderlist[si] == val then
						currentshaderi1 = si as integer
					end
				end
			elseif kind == "shader2" then
				for si = 1, #shaderlist do
					if shaderlist[si] == val then
						currentshaderi2 = si as integer
					end
				end
			elseif kind == "volume" then
				volumesfx = tonumber(val)
				love.audio.setVolume(volumesfx)
			elseif kind == "musicvolume" then
				volumemusic = tonumber(val)
			elseif kind == "mouseowner" then
				mouseowner = tonumber(val) as integer
			elseif kind == "mappack" then
				-- Inline path: loadconfig runs in LoveLoad before Boot.require_game
				-- defines mappack_path (world.levelio). Calling it here threw every launch.
				if val ~= "" and love.filesystem.getInfo("mappacks/" .. val .. "/settings.txt") then
					mappack = val
				end
			elseif kind == "gamefinished" then
				gamefinished = true
			elseif kind == "vsync" then
				vsync = true
			elseif kind == "reachedworlds" and id then
				reachedworlds[id] = {}
				s3 = strsplit(val, ",")
				for ri = 1, #s3 do
					if tonumber(s3[ri]) == 1 then
						reachedworlds[id][ri as integer] = true
					end
				end
			elseif kind == "fullscreen" then
				fullscreen = val == "true"
			elseif kind == "fullscreenmode" then
				fullscreenmode = val
			end
		end
	end
	
	for i = 1, math.max(4, players) do
		portalcolor[i] = {getrainbowcolor(portalhues[i][1]), getrainbowcolor(portalhues[i][2])}
	end
	
	if input_bindings_init then
		input_bindings_init()
	end
	
	players = 1
end

global function defaultconfig()
	--------------
	-- CONTROLS (baton source strings: key:a, button:1, hat:1l, axis:4-) --
	--------------
	
	mouseowner = 1
	
	controls = {}
	
	local i = 1
	controls[i] = {}
	controls[i]["right"] = {"key:d"}
	controls[i]["left"] = {"key:a"}
	controls[i]["down"] = {"key:s"}
	controls[i]["up"] = {"key:w"}
	controls[i]["run"] = {"key:lshift"}
	controls[i]["jump"] = {"key:space"}
	controls[i]["aimx"] = {}
	controls[i]["aimy"] = {}
	controls[i]["portal1"] = {}
	controls[i]["portal2"] = {}
	controls[i]["reload"] = {"key:r"}
	controls[i]["use"] = {"key:e"}
	controls[i]["weaponnext"] = {"key:tab"}
	controls[i]["weaponprev"] = {}
	
	for i = 2, 4 do
		controls[i] = {}
		controls[i]["joy"] = i - 1
		controls[i]["right"] = {"hat:1r"}
		controls[i]["left"] = {"hat:1l"}
		controls[i]["down"] = {"hat:1d"}
		controls[i]["up"] = {"hat:1u"}
		controls[i]["run"] = {"button:3"}
		controls[i]["jump"] = {"button:1"}
		controls[i]["aimx"] = {"axis:5-"}
		controls[i]["aimy"] = {"axis:4-"}
		controls[i]["portal1"] = {"button:5"}
		controls[i]["portal2"] = {"button:6"}
		controls[i]["reload"] = {"button:4"}
		controls[i]["use"] = {"button:2"}
		controls[i]["weaponnext"] = {"button:8"}
		controls[i]["weaponprev"] = {"button:7"}
	end
	
	if input_bindings_init then
		input_bindings_init()
	end
	-------------------
	-- PORTAL COLORS --
	-------------------
	
	portalhues = {}
	portalcolor = {}
	for i = 1, 4 do
		local players = 4
		portalhues[i] = {(i-1)*(1/players), (i-1)*(1/players)+0.5/players}
		portalcolor[i] = {getrainbowcolor(portalhues[i][1]), getrainbowcolor(portalhues[i][2])}
	end
	
	--hats.
	mariohats = {}
	for i = 1, 4 do
		mariohats[i] = {1}
	end
	
	------------------
	-- MARIO COLORS --
	------------------
	--1: hat, pants (red)
	--2: shirt, shoes (brown-green)
	--3: skin (yellow-orange)
	
	mariocolors = {}
	mariocolors[1] = {{224 / 255,  32 / 255,   0 / 255}, {136 / 255, 112 / 255,   0 / 255}, {252 / 255, 152 / 255,  56 / 255}}
	mariocolors[2] = {{255 / 255, 255 / 255, 255 / 255}, {  0 / 255, 160 / 255,   0 / 255}, {252 / 255, 152 / 255,  56 / 255}}
	mariocolors[3] = {{  0 / 255,   0 / 255,   0 / 255}, {200 / 255,  76 / 255,  12 / 255}, {252 / 255, 188 / 255, 176 / 255}}
	mariocolors[4] = {{ 32 / 255,  56 / 255, 236 / 255}, {  0 / 255, 128 / 255, 136 / 255}, {252 / 255, 152 / 255,  56 / 255}}
	for i = 5, players do
		mariocolors[i] = mariocolors[math.random(4)]
	end
	
	--STARCOLORS
	starcolors = {}
	starcolors[1] = {{  0 / 255,   0 / 255,   0 / 255}, {200 / 255,  76 / 255,  12 / 255}, {252 / 255, 188 / 255, 176 / 255}}
	starcolors[2] = {{  0 / 255, 168 / 255,   0 / 255}, {252 / 255, 152 / 255,  56 / 255}, {252 / 255, 252 / 255, 252 / 255}}
	starcolors[3] = {{252 / 255, 216 / 255, 168 / 255}, {216 / 255,  40 / 255,   0 / 255}, {252 / 255, 152 / 255,  56 / 255}}
	starcolors[4] = {{216 / 255,  40 / 255,   0 / 255}, {252 / 255, 152 / 255,  56 / 255}, {252 / 255, 252 / 255, 252 / 255}}
	
	flowercolor = {{252 / 255, 216 / 255, 168 / 255}, {216 / 255,  40 / 255,   0 / 255}, {252 / 255, 152 / 255,  56 / 255}}
	
	--CHARACTERS
	mariocharacter = {"mario", "mario", "mario", "mario"}
	
	--options
	scale = 2
	volumesfx = 1
	volumemusic = 1
	mappack = "smb"
	vsync = false
	currentshaderi1 = 1
	currentshaderi2 = 1
	firstpersonview = false
	firstpersonrotate = false
	seethroughportals = false
	fullscreen = false
	fullscreenmode = "letterbox"
	
	reachedworlds = {}
end

global function suspendgame()
	local s = ""
	if marioworld == "M" then
		marioworld = 1
		mariolevel = 3
	end
	s = s .. "a/" .. tostring(marioworld) .. "|"
	s = s .. "b/" .. tostring(mariolevel) .. "|"
	s = s .. "c/" .. mariocoincount .. "|"
	s = s .. "d/" .. marioscore .. "|"
	s = s .. "e/" .. players .. "|"
	for i = 1, players do
		if mariolivecount ~= false then
			s = s .. "f/" .. i .. "/" .. mariolives[i] .. "|"
		end
		if session.playerobjs[i] then
			s = s .. "g/" .. i .. "/" .. session.playerobjs[i].size .. "|"
		else
			s = s .. "g/" .. i .."/1|"
		end
	end
	s = s .. "h/" .. mappack
	
	love.filesystem.write("suspend.txt", s)
	
	love.audio.stop()
	menu_load()
end

global function continuegame()
	if not love.filesystem.getInfo("suspend.txt") then
		return
	end
	
	local s = love.filesystem.read("suspend.txt")
	
	mariosizes = {}
	mariolives = {}
	
	local split = strsplit(s, "|")
	for i = 1, #split do
		local split2 = strsplit(split[i], "/")
		if split2[1] == "a" then
			marioworld = tonumber(split2[2])
		elseif split2[1] == "b" then
			mariolevel = tonumber(split2[2])
		elseif split2[1] == "c" then
			mariocoincount = tonumber(split2[2])
		elseif split2[1] == "d" then
			marioscore = tonumber(split2[2])
		elseif split2[1] == "e" then
			players = tonumber(split2[2]) as integer
		elseif split2[1] == "f" and mariolivecount ~= false then
			mariolives[tonumber(split2[2]) as integer] = tonumber(split2[3]) as number
		elseif split2[1] == "g" then
			mariosizes[tonumber(split2[2]) as integer] = tonumber(split2[3]) as number
		elseif split2[1] == "h" then
			mappack = split2[2]
		end
	end
	
	love.filesystem.remove("suspend.txt")
end

global function savestate()
	serializetable(_G)
end

global function serializetable(t: any)
	tablestodo = {t}
	tableindex = {}
	repeat
		nexttablestodo = {}
		for _, v in pairs(tablestodo as {any:any}) do
			if type(v) == "table" then
				local tableexists = false
				for _, k in pairs(tableindex as {any:any}) do
					if k == v then
						tableexists = true
					end
				end
				if not tableexists then
					table.insert(nexttablestodo, v)
					table.insert(tableindex, v)
				end
			end
		end
		tablestodo = nexttablestodo
	until #(tablestodo as {any}) == 0
end

mouse = {}
