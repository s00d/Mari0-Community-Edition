--[[ config / save / suspend ]]

-- Keys written by saveconfig / read by loadconfig (keep in sync).
global OPTIONS_SCHEMA_KEYS = {
	"playercontrols", "playercolors", "mariocharacter", "portalhues", "mariohats",
	"scale", "shader1", "shader2", "volume", "musicvolume", "mouseowner", "mappack",
	"vsync", "gamefinished", "fullscreen", "fullscreenmode", "reachedworlds",
}

local OPTION_WRITERS: {string: function(): string} = {}

OPTION_WRITERS["playercontrols"] = function(): string
	local s = ""
	for i = 1, #(controls as {any}) do
		s = s .. "playercontrols:" .. i .. ":"
		local count = 0
		for j, _ in pairs(controls[i]) do
			local c = ""
			for l = 1, #(controls[i][j] as {any}) do
				c = c .. tostring(controls[i][j][l])
				if l ~= #(controls[i][j] as {any}) then
					c = c ..  "-"
				end
			end
			s = s .. j .. "-" .. c
			count = count + 1
			if count == 12 then
				s = s .. ";"
			else
				s = s .. ","
			end
		end
	end
	return s
end

OPTION_WRITERS["playercolors"] = function(): string
	local s = ""
	for i = 1, #mariocolors do
		s = s .. "playercolors:" .. i .. ":"
		if #mariocolors[i] > 0 then
			for j = 1, #mariocolors[i] do
				for k = 1, 3 do
					s = s .. mariocolors[i][j][k] * 255
					if j == #mariocolors[i] and k == 3 then
						s = s .. ";"
					else
						s = s .. ","
					end
				end
			end
		else
			s = s .. ";"
		end
	end
	return s
end

OPTION_WRITERS["mariocharacter"] = function(): string
	local s = ""
	for i = 1, #(mariocharacter as {any}) do
		s = s .. "mariocharacter:" .. i .. ":"
		s = s .. mariocharacter[i]
		s = s .. ";"
	end
	return s
end

OPTION_WRITERS["portalhues"] = function(): string
	local s = ""
	for i = 1, #portalhues do
		s = s .. "portalhues:" .. i .. ":"
		s = s .. round(portalhues[i][1], 4) .. "," .. round(portalhues[i][2], 4) .. ";"
	end
	return s
end

OPTION_WRITERS["mariohats"] = function(): string
	local s = ""
	for i = 1, #(mariohats as {any}) do
		s = s .. "mariohats:" .. i
		if #(mariohats[i] as {any}) > 0 then
			s = s .. ":"
		end
		for j = 1, #(mariohats[i] as {any}) do
			s = s .. tostring(mariohats[i][j])
			if j == #mariohats[i] then
				s = s .. ";"
			else
				s = s .. ","
			end
		end
		if #mariohats[i] == 0 then
			s = s .. ";"
		end
	end
	return s
end

OPTION_WRITERS["scale"] = function(): string
	return "scale:" .. scale .. ";"
end

OPTION_WRITERS["shader1"] = function(): string
	return "shader1:" .. shaderlist[currentshaderi1] .. ";"
end

OPTION_WRITERS["shader2"] = function(): string
	return "shader2:" .. shaderlist[currentshaderi2] .. ";"
end

OPTION_WRITERS["volume"] = function(): string
	return "volume:" .. volumesfx .. ";"
end

OPTION_WRITERS["musicvolume"] = function(): string
	return "musicvolume:" .. volumemusic .. ";"
end

OPTION_WRITERS["mouseowner"] = function(): string
	return "mouseowner:" .. mouseowner .. ";"
end

OPTION_WRITERS["mappack"] = function(): string
	return "mappack:" .. mappack .. ";"
end

OPTION_WRITERS["vsync"] = function(): string
	if vsync then
		return "vsync;"
	end
	return ""
end

OPTION_WRITERS["gamefinished"] = function(): string
	if gamefinished then
		return "gamefinished;"
	end
	return ""
end

OPTION_WRITERS["fullscreen"] = function(): string
	return "fullscreen:" .. tostring(fullscreen) .. ";"
end

OPTION_WRITERS["fullscreenmode"] = function(): string
	return "fullscreenmode:" .. fullscreenmode .. ";"
end

OPTION_WRITERS["reachedworlds"] = function(): string
	local s = ""
	for i, v in pairs(reachedworlds) do
		s = s .. "reachedworlds:" .. i .. ":"
		for j = 1, 8 do
			if v[j] then
				s = s .. 1
			else
				s = s .. 0
			end
			if j == 8 then
				s = s .. ";"
			else
				s = s .. ","
			end
		end
	end
	return s
end

global function saveconfig()
	if CLIENT or SERVER then
		return
	end
	
	local s = ""
	for _, key in ipairs(OPTIONS_SCHEMA_KEYS) do
		local writer = OPTION_WRITERS[key]
		if writer then
			s = s .. writer()
		end
	end
	
	love.filesystem.write("options.txt", s)
end

local OPTION_READERS: {string: function({string}): boolean} = {}

OPTION_READERS["playercontrols"] = function(s2: {string}): boolean
	if controls[tonumber(s2[2]) as integer] == nil then
		controls[tonumber(s2[2]) as integer] = {}
	end
	s3 = strsplit(s2[3], ",")
	for j = 1, #s3 do
		s4 = strsplit(s3[j], "-")
		controls[tonumber(s2[2]) as integer][s4[1]] = {}
		for k = 2, #s4 do
			if tonumber(s4[k]) ~= nil then
				controls[tonumber(s2[2]) as integer][s4[1]][k-1] = tonumber(s4[k]) as number
			else
				controls[tonumber(s2[2]) as integer][s4[1]][k-1] = s4[k]
			end
		end
	end
	players = math.max(players, tonumber(s2[2]) as integer)
	return true
end

OPTION_READERS["playercolors"] = function(s2: {string}): boolean
	if mariocolors[tonumber(s2[2]) as integer] == nil then
		mariocolors[tonumber(s2[2]) as integer] = {}
	end
	s3 = strsplit(s2[3], ",")
	mariocolors[tonumber(s2[2]) as integer] = {}
	for i = 1, #s3/3 do
		mariocolors[tonumber(s2[2]) as integer][i as integer] = {tonumber(s3[(1+(i-1)*3) as integer]) / 255, tonumber(s3[(2+(i-1)*3) as integer]) / 255, tonumber(s3[(3+(i-1)*3) as integer]) / 255}
	end
	return true
end

OPTION_READERS["portalhues"] = function(s2: {string}): boolean
	if portalhues[tonumber(s2[2]) as integer] == nil then
		portalhues[tonumber(s2[2]) as integer] = {}
	end
	s3 = strsplit(s2[3], ",")
	portalhues[tonumber(s2[2]) as integer] = {tonumber(s3[1]), tonumber(s3[2])}
	return true
end

OPTION_READERS["mariohats"] = function(s2: {string}): boolean
	local playerno = tonumber(s2[2])
	mariohats[playerno as integer] = {}
	if s2[3] == "mariohats" then
	elseif s2[3] then
		s3 = strsplit(s2[3], ",")
		for i = 1, #s3 do
			local hatno = tonumber(s3[i])
			mariohats[playerno as integer][i] = hatno
		end
	end
	return true
end

OPTION_READERS["scale"] = function(s2: {string}): boolean
	scale = tonumber(s2[2])
	return true
end

OPTION_READERS["shader1"] = function(s2: {string}): boolean
	for i = 1, #shaderlist do
		if shaderlist[i] == s2[2] then
			currentshaderi1 = i as integer
		end
	end
	return true
end

OPTION_READERS["shader2"] = function(s2: {string}): boolean
	for i = 1, #shaderlist do
		if shaderlist[i] == s2[2] then
			currentshaderi2 = i as integer
		end
	end
	return true
end

OPTION_READERS["volume"] = function(s2: {string}): boolean
	volumesfx = tonumber(s2[2])
	love.audio.setVolume( volumesfx )
	return true
end

OPTION_READERS["musicvolume"] = function(s2: {string}): boolean
	volumemusic = tonumber(s2[2])
	return true
end

OPTION_READERS["mouseowner"] = function(s2: {string}): boolean
	mouseowner = tonumber(s2[2]) as integer
	return true
end

OPTION_READERS["mappack"] = function(s2: {string}): boolean
	if love.filesystem.getInfo(mappack_path(s2[2]) .. "/settings.txt") then
		mappack = s2[2]
	end
	return true
end

OPTION_READERS["gamefinished"] = function(_s2: {string}): boolean
	gamefinished = true
	return true
end

OPTION_READERS["vsync"] = function(_s2: {string}): boolean
	vsync = true
	return true
end

OPTION_READERS["reachedworlds"] = function(s2: {string}): boolean
	reachedworlds[s2[2]] = {}
	local s3 = strsplit(s2[3], ",")
	for i = 1, #s3 do
		if tonumber(s3[i]) == 1 then
			reachedworlds[s2[2]][i as integer] = true
		end
	end
	return true
end

OPTION_READERS["mariocharacter"] = function(s2: {string}): boolean
	mariocharacter[tonumber(s2[2]) as integer] = s2[3]
	return true
end

OPTION_READERS["fullscreen"] = function(s2: {string}): boolean
	fullscreen = s2[2] == "true"
	return true
end

OPTION_READERS["fullscreenmode"] = function(s2: {string}): boolean
	fullscreenmode = s2[2]
	return true
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
		s2 = strsplit(s1[i], ":")
		local reader = OPTION_READERS[s2[1]]
		if reader then
			reader(s2)
		end
	end
	
	for i = 1, math.max(4, players) do
		portalcolor[i] = {getrainbowcolor(portalhues[i][1]), getrainbowcolor(portalhues[i][2])}
	end
	
	players = 1
end

global function defaultconfig()
	--------------
	-- CONTORLS --
	--------------
	
	-- Joystick stuff:
	-- joy, #, hat, #, direction (r, u, ru, etc)
	-- joy, #, axe, #, pos/neg
	-- joy, #, but, #
	-- You cannot set Hats and Axes as the jump button. Bummer.
	
	mouseowner = 1
	
	controls = {}
	
	local i = 1
	controls[i] = {}
	controls[i]["right"] = {"d"}
	controls[i]["left"] = {"a"}
	controls[i]["down"] = {"s"}
	controls[i]["up"] = {"w"}
	controls[i]["run"] = {"lshift"}
	controls[i]["jump"] = {" "}
	controls[i]["aimx"] = {""} --mouse aiming, so no need
	controls[i]["aimy"] = {""}
	controls[i]["portal1"] = {""}
	controls[i]["portal2"] = {""}
	controls[i]["reload"] = {"r"}
	controls[i]["use"] = {"e"}
	
	for i = 2, 4 do
		controls[i] = {}		
		controls[i]["right"] = {"joy", i-1, "hat", 1, "r"}
		controls[i]["left"] = {"joy", i-1, "hat", 1, "l"}
		controls[i]["down"] = {"joy", i-1, "hat", 1, "d"}
		controls[i]["up"] = {"joy", i-1, "hat", 1, "u"}
		controls[i]["run"] = {"joy", i-1, "but", 3}
		controls[i]["jump"] = {"joy", i-1, "but", 1}
		controls[i]["aimx"] = {"joy", i-1, "axe", 5, "neg"}
		controls[i]["aimy"] = {"joy", i-1, "axe", 4, "neg"}
		controls[i]["portal1"] = {"joy", i-1, "but", 5}
		controls[i]["portal2"] = {"joy", i-1, "but", 6}
		controls[i]["reload"] = {"joy", i-1, "but", 4}
		controls[i]["use"] = {"joy", i-1, "but", 2}
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
		if playerobjs[i] then
			s = s .. "g/" .. i .. "/" .. playerobjs[i].size .. "|"
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
				
				if tableexists then
					
				else
					table.insert(nexttablestodo, v)
					table.insert(tableindex, v)
				end
			end
		end
		tablestodo = nexttablestodo
	until #(tablestodo as {any}) == 0
end

mouse = {}

