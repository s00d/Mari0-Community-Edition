--[[ Teal port of root enemies.lua ]]

global function enemies_load()
	defaultvalues = {quadcount=1, quadno=1}
	
	nobasevalues = {"description"} --values that aren't loaded from base
	
	enemiesdata = {}
	enemies = {}
	
	--ENEMIIIIEEES
	loaddelayed = {}
	
	local fl = love.filesystem.getDirectoryItems("assets/enemies/")
	local fl2 = love.filesystem.getDirectoryItems("mappacks/" .. mappack .. "/enemies/")
	
	local realfl = {}
	
	for i = 1, #fl do
		table.insert(realfl, "assets/enemies/" .. fl[i]) --STANDARD ENEMIES
	end
	
	for i = 1, #fl2 do
		table.insert(realfl, "mappacks/" .. mappack .. "/enemies/" .. fl2[i]) --MAPPACK ENEMIES
	end
	
	for i = 1, #realfl do
		if string.sub(realfl[i], -4) == "json" then
			loadenemy(realfl[i])
		end
	end
end

global function loadenemy(filename: string)
	
	local ss = strsplit(filename, "/")
	local folder = ""
	for i = 1, #ss-1 do
		folder = folder .. (ss[i] as string) .. "/"
	end
	
	local s = string.sub(ss[#ss] as string, 1, -6):lower()
	
	--CHECK FOR - , ; * AND WHATEVER ELSE WOULD BREAK MAPS
	local skip = not enemy_name_ok(s)
	
	if not skip then --bad letter
		local data = love.filesystem.read(filename)
		if not data then return end
		local datastr = (data as string):gsub("\r", "")
		
		if string.sub(datastr, 1, 4) == "base" then
			local split = strsplit(datastr, "\n")
			local base = string.sub(split[1] as string, 6)
			if enemiesdata[base] then
				local newdata = ""
				for i = 2, #split do
					newdata = newdata .. (split[i] as string)
					if i ~= #split then
						newdata = newdata .. "\n"
					end
				end
				
				enemiesdata[s] = usebase(enemiesdata[base]) as EnemyDef
				
				local temp = JSON.decode(newdata) as Dyn
				
				for i, v in pairs(temp) do
					(enemiesdata[s] as Dyn)[i] = v
				end
			else
				--Put enemy for later loading because base hasn't been loaded yet
				if not success then
					if not loaddelayed[base] then
						loaddelayed[base] = {}
					end
					table.insert(loaddelayed[base], filename)
				end
				print("DON'T HAVE BASE " .. base .. " FOR " .. s)
				return
			end
		else
			enemiesdata[s] = JSON.decode(datastr) as EnemyDef
		end
		
		--CASE INSENSITVE THING
		normalize_enemy_props(enemiesdata[s])
		
		apply_enemy_defaults(enemiesdata[s], defaultvalues)
		
		--Load graphics if it exists
		if love.filesystem.getInfo(folder .. s .. ".png") then
			enemiesdata[s].graphic = AssetStore.load_image(folder .. s .. ".png")
		end
		
		--Set up quads if given
		if enemiesdata[s].graphic and enemiesdata[s].quadcount then
			local imgwidth, imgheight = (enemiesdata[s].graphic as Image):getWidth(), (enemiesdata[s].graphic as Image):getHeight()
			local quadwidth = imgwidth/enemiesdata[s].quadcount
			local quadheight = imgheight/4
			
			if math.floor(quadwidth) == quadwidth and math.floor(quadheight) == quadheight then
				if enemiesdata[s].nospritesets then
					quadheight = quadheight*4
				end
				
				local qb: Dyn = {}
				enemiesdata[s].quadbase = qb
				
				for y = 1, 4 do
					qb[y] = {}
					for x = 1, enemiesdata[s].quadcount do
						local realy = (y-1)*quadheight
						if enemiesdata[s].nospritesets then
							realy = 0
						end
						(qb[y] as {any:any})[x] = love.graphics.newQuad((x-1)*quadwidth, realy, quadwidth, quadheight, imgwidth, imgheight)
					end
				end
			end
		end
		
		--check if graphic for enemy exists
		if enemiesdata[s].quadbase and enemiesdata[s].graphic then
			enemiesdata[s].drawable = true
			local qb = enemiesdata[s].quadbase as Dyn
			enemiesdata[s].quadgroup = qb[spriteset as integer]
			if enemiesdata[s].animationtype == "frames" then
				enemiesdata[s].quad = (qb[spriteset as integer] as Dyn)[enemiesdata[s].animationstart]
			else
				enemiesdata[s].quad = (qb[spriteset as integer] as Dyn)[enemiesdata[s].quadno]
			end
		end
		
		table.insert(enemies, s)
		
		
		if loaddelayed[s] and #loaddelayed[s] > 0 then
			for j = #loaddelayed[s], 1, -1 do
				loadenemy(loaddelayed[s][j]) --RECURSIVE PROGRAMMING AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH
				table.remove(loaddelayed[s], j)
			end
		end
	else
		--Bad.
	end
end

