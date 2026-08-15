--[[ Editor tab builders (extracted from editor.tl). ]]

function maintab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "main"
	for _, v in pairs(guielements) do
		v.active = false
	end
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0, 0, 0}
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	guielements["colorsliderr"].active = true
	guielements["colorsliderg"].active = true
	guielements["colorsliderb"].active = true
	for i = 1, #backgroundcolor do
		guielements["defaultcolor" .. i].active = true
	end
	
	guielements["autoscrollcheckbox"].active = true
	guielements["musicdropdown"].active = true
	guielements["spritesetdropdown"].active = true
	guielements["timelimitdecrease"].active = true
	guielements["timelimitincrease"].active = true
	guielements["portalgundropdown"].active = true
	guielements["savebutton"].active = true
	guielements["menubutton"].active = true
	guielements["testbutton"].active = true
	if guielements["testcursorbutton"] then
		guielements["testcursorbutton"].active = true
	end
	if guielements["clearcheckbutton"] then
		guielements["clearcheckbutton"].active = true
	end
	guielements["widthbutton"].active = true
	guielements["intermissioncheckbox"].active = true
	guielements["warpzonecheckbox"].active = true
	guielements["underwatercheckbox"].active = true
	guielements["bonusstagecheckbox"].active = true
	guielements["custombackgroundcheckbox"].active = true
	guielements["customforegroundcheckbox"].active = true
	guielements["scrollfactorscrollbar"].active = true
	guielements["fscrollfactorscrollbar"].active = true
	guielements["backgrounddropdown"].active = true
	guielements["foregrounddropdown"].active = true
	guielements["levelscreendropdown"].active = true
end

function tilestab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "tiles"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"].fillcolor = {0, 0, 0}
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	guielements["tilesscrollbar"].active = true
	
	guielements["tilesall"].active = true
	guielements["tilessmb"].active = true
	guielements["tilesportal"].active = true
	guielements["tilescustom"].active = true
	guielements["tilesanimated"].active = true
	guielements["tilesentities"].active = true
	guielements["tilesenemies"].active = true
	
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function toolstab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "tools"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"].fillcolor = {0, 0, 0}
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	guielements["selectionbutton"].active = true
	guielements["lightdrawbutton"].active = true
	guielements["edittitle"].active = true
	guielements["editauthor"].active = true
	guielements["editdescription"].active = true
	guielements["savesettings"].active = true
	
	guielements["livesdecrease"].active = true
	guielements["livesincrease"].active = true
	
	guielements["pastemodedropdown"].active = true
	guielements["clipboardcheckbox"].active = true
	guielements["linktoolkindabutnotreally"].active = true
	guielements["editordebugcheckbox"].active = true
	guielements["levelscreencheckbox"].active = true
	
	if guielements["editauthor"].value == "willware" or guielements["editauthor"].value == "turretbot" then
		guielements["secretcheckbox"].active = true
	end
	
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function mapstab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "maps"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"].fillcolor = {0, 0, 0}
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	guielements["mapsnewlevel"].active = true
	guielements["mapsnewlevel"].textcolor = {0, 1, 0}
	guielements["mapsworldbox"].active = true
	guielements["mapslevelbox"].active = true
	
	guielements["mapscrollbar"].active = true
	
	for _, v in pairs(mapbuttons) do
		v.active = true
	end
end

function animationstab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "animations"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"].fillcolor = {0, 0, 0}
	guielements["tabobjects"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	guielements["animationsscrollbarver"].active = true
	guielements["animationsscrollbarhor"].active = true
	guielements["animationsavebutton"].active = true
	guielements["animationselectdrop"].active = true
	guielements["animationnewbutton"].active = true
	
	generateanimationgui()
	
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function objectstab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "objects"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	guielements["tabmain"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtiles"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabtools"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabmaps"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabanimations"].fillcolor = {0.25, 0.25, 0.25}
	guielements["tabobjects"].fillcolor = {0, 0, 0}
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	guielements["objectscrollbar"].active = true	
	objectscrollbarheight = math.max(0, math.ceil((#multitileobjects-1))*17 - 1 - (17*9) - 12)
	
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function powerlinestab()
	do
		local fromtab = (_G as {string:any})["from" .. editorstate .. "tab"]
		if fromtab then
			(fromtab as function())()
		end
	end

	editorstate = "lightdrawcustomize"
	for _, v in pairs(guielements) do
		v.active = false
	end
	
	-- guielements["tabtools"].text = "party"
	guielements["tabmain"].active = true
	guielements["tabtiles"].active = true
	guielements["tabtools"].active = true
	guielements["tabmaps"].active = true
	guielements["tabanimations"].active = true
	guielements["tabobjects"].active = true
	
	for i = 1, drawtools do
		guielements["drawtool" .. i].active = true
	end
	
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function fromanimationstab()
	saveanimation()
end

function frommapstab()
	for _, v in pairs(mapbuttons) do
		v.active = false
	end
end

function fromlightdrawcustomizetab() --the name for this tab is all over the place
	guielements["tabtools"].text = "tools"
	guielements["tabtools"].textcolor = {1, 1, 1}
	guielements["tabtools"].bordercolor = {0.5, 0.5, 0.5}
	for i = 1, drawtools do
		guielements["drawtool" .. i].active = false
	end
end
