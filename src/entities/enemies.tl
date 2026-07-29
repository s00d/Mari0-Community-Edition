--[[ Teal port of root enemies.lua ]]

local Anim8Enemy = require("assets.anim8_enemy")

local enemies_loaded_mappack: string|nil = nil

local function enemies_refresh_spriteset()
	for i = 1, #enemies do
		local s = enemies[i] as string
		local ed = enemiesdata[s]
		if ed and ed.quadbase and ed.graphic then
			local qb = ed.quadbase as Dyn
			ed.quadgroup = qb[spriteset as integer]
			ed.drawable = true
			if ed.animationtype == "frames" then
				ed.quad = (qb[spriteset as integer] as Dyn)[ed.animationstart]
			else
				ed.quad = (qb[spriteset as integer] as Dyn)[ed.quadno]
			end
			ed.anim8_cycle = Anim8Enemy.build_cycle(ed as {string:any})
		end
	end
end

global function enemies_load()
	-- Same mappack: reuse JSON/graphics; only refresh spriteset-dependent quads.
	-- Full reload every level re-decoded PNGs via newImage → transition hang.
	if enemies_loaded_mappack == mappack and enemiesdata and next(enemiesdata) then
		enemies_refresh_spriteset()
		return
	end

	defaultvalues = {quadcount=1, quadno=1}
	
	nobasevalues = {"description"} --values that aren't loaded from base
	
	enemiesdata = {}
	enemies = {}
	
	--ENEMIIIIEEES
	loaddelayed = {}
	
	local fl = love.filesystem.getDirectoryItems("assets/enemies/")
	local fl2 = love.filesystem.getDirectoryItems(mappack_path(mappack) .. "/enemies/")
	
	local realfl = {}
	
	for i = 1, #fl do
		table.insert(realfl, "assets/enemies/" .. fl[i]) --STANDARD ENEMIES
	end
	
	for i = 1, #fl2 do
		table.insert(realfl, mappack_path(mappack) .. "/enemies/" .. fl2[i]) --MAPPACK ENEMIES
	end
	
	for i = 1, #realfl do
		if string.sub(realfl[i], -4) == "json" then
			loadenemy(realfl[i])
		end
	end

	enemies_loaded_mappack = mappack as string
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
		if enemiesdata[s].width == nil or enemiesdata[s].height == nil then
			print("enemy JSON missing size: " .. s)
			enemiesdata[s] = nil
			return
		end
		
		--Load graphics if it exists (mappack folder first; else keep base copy from usebase)
		if love.filesystem.getInfo(folder .. s .. ".png") then
			enemiesdata[s].graphic = AssetStore.load_image(folder .. s .. ".png")
		elseif not enemiesdata[s].graphic then
			-- Base-only mappack enemies (json overlay, no png): try assets/enemies/<name>.png
			local assetpng = "assets/enemies/" .. s .. ".png"
			if love.filesystem.getInfo(assetpng) then
				enemiesdata[s].graphic = AssetStore.load_image(assetpng)
			end
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
			enemiesdata[s].anim8_cycle = Anim8Enemy.build_cycle(enemiesdata[s] as {string:any})
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
