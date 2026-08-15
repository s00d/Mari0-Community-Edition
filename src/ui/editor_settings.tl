--[[ Editor settings toggles / dropdowns / hotkeys (extracted from editor.tl). ]]

function toggleautoscroll(var: any)
	if var ~= nil then
		autoscroll = var
	else
		autoscroll = not autoscroll
	end
	guielements["autoscrollcheckbox"].var = autoscroll
end

function toggleintermission(var: any)
	if var ~= nil then
		intermission = var
	else
		intermission = not intermission
	end
	guielements["intermissioncheckbox"].var = intermission
end

function togglewarpzone(var: any)
	if var ~= nil then
		haswarpzone = var
	else
		haswarpzone = not haswarpzone
	end
	guielements["warpzonecheckbox"].var = haswarpzone
end

function toggleunderwater(var: any)
	if var ~= nil then
		underwater = var
	else
		underwater = not underwater
	end
	guielements["underwatercheckbox"].var = underwater
end

function togglebonusstage(var: any)
	if var ~= nil then
		bonusstage = var
	else
		bonusstage = not bonusstage
	end
	guielements["bonusstagecheckbox"].var = bonusstage
end

function toggleclipboardenabled(var: any)
	if var ~= nil then
		clipboardenabled = var
	else
		clipboardenabled = not clipboardenabled
	end
	guielements["clipboardcheckbox"].var = clipboardenabled
end

function toggledrawalllinks(var: any)
	if var ~= nil then
		drawalllinks = var
	else
		drawalllinks = not drawalllinks
	end
	guielements["linktoolkindabutnotreally"].var = drawalllinks
end

function togglecustombackground(_: any)
	if custombackground then
		custombackground = false
	else
		custombackground = custombackgrounds[(((guielements["backgrounddropdown"].var as number)-1) as integer)]
		if custombackground == nil then
			custombackground = true
		end
	end
	
	guielements["custombackgroundcheckbox"].var = custombackground ~= false
end

function toggleeditordebug(var: any)
	if var ~= nil then
		editordebug = var
	else
		editordebug = not editordebug
	end
	
	physicsdebug = editordebug
	portalwalldebug = editordebug
	
	guielements["editordebugcheckbox"].var = editordebug
end

function toggleskiplevelscreen(var: any)
	if var ~= nil then
		skiplevelscreen = var
	else
		skiplevelscreen = not skiplevelscreen
	end
	
	guielements["levelscreencheckbox"].var = skiplevelscreen
end

function changepastemode(var: any)
	--	pastemode = var
	--	guielements["pastemodedropdown"].var = var
	if var ~= nil then
		pastemode = var
	else
		pastemode = not pastemode
	end
	guielements["pastemodedropdown"].var = pastemode
end

function togglecustomforeground(_: any)
	if customforeground then
		customforeground = false
	else
		customforeground = custombackgrounds[(((guielements["foregrounddropdown"].var as number)-1) as integer)]
		if customforeground == nil then
			customforeground = true
		end
	end
	
	guielements["customforegroundcheckbox"].var = customforeground ~= false
end

function changebackground(var: any)
	guielements["backgrounddropdown"].var = var
	if custombackground then
		custombackground = custombackgrounds[(((guielements["backgrounddropdown"].var as number)-1) as integer)]
		if custombackground == nil then
			custombackground = true
		end
	end	
end

function changeforeground(var: any)
	guielements["foregrounddropdown"].var = var
	if customforeground then
		customforeground = custombackgrounds[(((var as number)-1) as integer)]
		if customforeground == nil then
			customforeground = true
		end
	end	
end

function changelevelscreen(var: any)
	guielements["levelscreendropdown"].var = var
	levelscreenbackname = levelscreens[(((var as number)-1) as integer)]
end

function changeportalgun(var: any)
	if var == 1 then
		portalsavailable = {true, true}
	elseif var == 2 then
		portalsavailable = {true, false}
	elseif var == 3 then
		portalsavailable = {false, true}
	elseif var == 4 then
		portalsavailable = {false, false}
	end
	guielements["portalgundropdown"].var = var
end

function changemusic(var: any)
	stopmusic()
	musicname = musiclist[var as integer] as string
	
	if var == 1 then
		musicname = nil
	end
	
	playmusic()
	guielements["musicdropdown"].var = var
end

function changespriteset(var: any)
	spriteset = var as integer
	guielements["spritesetdropdown"].var = var
end

function decreasetimelimit()
	mariotimelimit = mariotimelimit - 10
	if mariotimelimit < 0 then
		mariotimelimit = 0
	end
	mariotime = mariotimelimit
	guielements["timelimitincrease"].x = 31 + string.len(tostring(mariotimelimit))*8
end

function increasetimelimit()
	mariotimelimit = mariotimelimit + 10
	mariotime = mariotimelimit
	guielements["timelimitincrease"].x = 31 + string.len(tostring(mariotimelimit))*8
end


function loadHotKeys()
	hotkeys = {}
	if love.filesystem.getInfo(mappack_path(mappack) .. "/hotkeys.txt") then
		local data = (love.filesystem.read(mappack_path(mappack) .. "/hotkeys.txt") or "") as string
		hotkeys = editor_hotkeys_parse(data)
	end
end

function saveHotKeys()
	love.filesystem.write(mappack_path(mappack) .. "/hotkeys.txt", editor_hotkeys_serialize(hotkeys) as string)
end

function savesettings()
	local s = ""
	s = s .. "name=" .. (guielements["edittitle"].value as string) .. "\n"
	s = s .. "author=" .. (guielements["editauthor"].value as string) .. "\n"
	s = s .. "description=" .. (guielements["editdescription"].value as string) .. "\n"
	if mariolivecount == false then
		s = s .. "lives=0\n"
	else
		s = s .. "lives=" .. (mariolivecount as integer) .. "\n"
	end
	
	love.filesystem.createDirectory("mappacks")
	love.filesystem.createDirectory( mappack_path(mappack) )
	
	love.filesystem.write(mappack_path(mappack) .. "/settings.txt", s)
	notice.new("Saved settings!", notice.white, 2)
end

--DELIMITERS old: ,-;*=   new: ¤×¸·¨
--BLOCKDELIMITER = "¤"
--LAYERDELIMITER = "×"
--CATEGORYDELIMITER = "¸"
--MULTIPLYDELIMITER = "·"
--EQUALSIGN = "¨"

function livesdecrease()
	if mariolivecount == false then
		return
	end
	
	mariolivecount = (mariolivecount as integer) - 1
	if mariolivecount == 0 then
		mariolivecount = false
		guielements["livesincrease"].x = 212 + 24
	else
		guielements["livesincrease"].x = 212 + string.len(tostring(mariolivecount))*8
	end
end

function livesincrease()
	if mariolivecount == false then
		mariolivecount = 1
	else
		mariolivecount = (mariolivecount as number) + 1
	end
	guielements["livesincrease"].x = 212 + string.len(tostring(mariolivecount))*8
end

function defaultbackground(i: number)
	background = {unpack(backgroundcolor[i as integer] as {any})} as {number}
	love.graphics.setBackgroundColor(unpack(background))
	
	guielements["colorsliderr"].internvalue = background[1] as number
	guielements["colorsliderg"].internvalue = background[2] as number
	guielements["colorsliderb"].internvalue = background[3] as number
end

function updatebackground()
	background[1] = guielements["colorsliderr"].internvalue
	background[2] = guielements["colorsliderg"].internvalue
	background[3] = guielements["colorsliderb"].internvalue
	love.graphics.setBackgroundColor(unpack(background))
end

function updatescrollfactor()
	scrollfactor = round(((guielements["scrollfactorscrollbar"].value as number)*3)^2, 2)
end

function updatefscrollfactor()
	fscrollfactor = round(((guielements["fscrollfactorscrollbar"].value as number)*3)^2, 2)
end

function reversescrollfactor(): number
	return math.sqrt(scrollfactor)/3
end

function reversefscrollfactor(): number
	return math.sqrt(fscrollfactor)/3
end

