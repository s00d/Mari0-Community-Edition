--[[ Editor tile/entity palette filters (extracted from editor.tl). ]]

function generateentitylist()
	entitylistitems = {}
	for i, v in ipairs(entitylist as {EntityListEntry}) do
		if v.t ~= "" and not v.hidden then
			local cat = v.category or "misc"
			
			local cati = 0
			for j = 1, #entitylistitems do
				if entitylistitems[j].t == cat then
					cati = j
					break
				end
			end
			
			if cati == 0 then
				table.insert(entitylistitems, {t=cat, entries={}}) --cat??
				cati = #entitylistitems
			end
			
			table.insert(entitylistitems[cati].entries, entitylistitem:new(v.t, i))
		end
	end
	
	--sort categories
	table.sort(entitylistitems, function(a: entitylistcategory, b: entitylistcategory): boolean return a.t > b.t end)
	
	--calculate X and Y positions..
	local yadd = -3
	for _, v in ipairs(entitylistitems) do
		table.sort(v.entries, function(a: entitylistitem, b: entitylistitem): boolean return a.t < b.t end)
		
		--Category name space
		yadd = yadd + 14
		
		for j, k in ipairs(v.entries) do
			local x, y = math.fmod(j-1, 22)+1, math.ceil(j/22)
			k.x = (x-1)*17
			k.y = (y-1)*17+yadd
		end
		
		yadd = yadd + math.ceil(#v.entries/22)*17
	end
	
	yadd = yadd + 2
	
	tilescrollbarheight = math.max(0, yadd - 1 - (17*9) - 12)
end


function tilesall()
	guielements["tilesall"].textcolor = {1, 1, 1}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = false
	tileliststart = 1
	tilelistcount = smbtilecount + portaltilecount + customtilecount + (modcustomtilecount[modcustomtiles as integer] or 0)  -1
	
	if editentities or editenemies then
		currenttile = 1
	end
	
	tilescrollbarheight = math.max(0, math.ceil((smbtilecount + portaltilecount + customtilecount + (modcustomtilecount[modcustomtiles as integer] or 0))/22)*17 - 1 - (17*9) - 12)
	editentities = false
	editenemies = false
end

function tilessmb()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {1, 1, 1}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = false
	tileliststart = 1
	tilelistcount = smbtilecount-1
	
	if editentities or editenemies then
		currenttile = 1
	end
	
	tilescrollbarheight = math.max(0, math.ceil((smbtilecount)/22)*17 - 1 - (17*9) - 12)
	editentities = false
	editenemies = false
end

function tilesportal()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {1, 1, 1}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = false
	tileliststart = smbtilecount + 1
	tilelistcount = portaltilecount - 1
	
	if editentities or editenemies then
		currenttile = 1
	end
	
	tilescrollbarheight = math.max(0, math.ceil((portaltilecount)/22)*17 - 1 - (17*9) - 12)
	editentities = false
	editenemies = false
end

function tilescustom()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {1, 1, 1}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = false
	tileliststart = smbtilecount + portaltilecount + 1
	tilelistcount = customtilecount + (modcustomtilecount[modcustomtiles as integer] or 0) - 1
	
	if editentities or editenemies then
		currenttile = 1
	end
	
	tilescrollbarheight = math.max(0,  math.ceil((customtilecount + (modcustomtilecount[modcustomtiles as integer] or 0))/22)*17 - 1 - (17*9) - 12)
	editentities = false
	editenemies = false
end

function tilesanimated()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {1, 1, 1}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = true
	tileliststart = 1
	tilelistcount = animatedtilecount - 1
	
	if editentities or editenemies then
		currenttile = 1
	end
	
	tilescrollbarheight = math.max(0, math.ceil((customtilecount)/22)*17 - 1 - (17*9) - 12)
	editentities = false
	editenemies = false
end

function tilesentities()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {1, 1, 1}
	guielements["tilesenemies"].textcolor = {0.5, 0.5, 0.5}
	
	animatedtilelist = false
	editentities = true
	editenemies = false
	
	currenttile = 1
	
	generateentitylist()
end

function tilesenemies()
	guielements["tilesall"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilessmb"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesportal"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilescustom"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesanimated"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesentities"].textcolor = {0.5, 0.5, 0.5}
	guielements["tilesenemies"].textcolor = {1, 1, 1}
	
	animatedtilelist = false
	tilescrollbarheight = math.max(0, math.ceil((#enemies)/22)*17 - 1 - (17*9) - 12)
	editentities = true
	editenemies = true
	
	currenttile = enemies[1]
end

