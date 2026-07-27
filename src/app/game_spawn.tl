--[[ Teal extract from root game.lua: spawn helpers ]]

global function spawnenemy(...: any): any
	local args = {...}
	local x = args[1] as number
	local y = args[2] as number
	if not inmap(x, y) then
		return
	end
	
	--don't spawn when on a coinblock or breakable block
	if tilequads[map[x][y][1] ]:getproperty("breakable", x, y) or tilequads[map[x][y][1] ]:getproperty("coinblock", x, y) then
		table.insert(enemiesspawned, {x, y})
		return
	end

	for i = 1, #enemiesspawned do
		if x == enemiesspawned[i][1] and y == enemiesspawned[i][2] then
			return
		end
	end
	
	--spawnrestriction
	allowenemy = true
	for i = 1, #spawnrestrictions do
		if x > spawnrestrictions[i][1]-6 and x < spawnrestrictions[i][1]+6 and y > spawnrestrictions[i][2]-6 and y < spawnrestrictions[i][2]+6 then
			allowenemy = false
		end
	end
	
	local r = map[x][y]
	if #r > 1 then 
		local wasenemy = false
		if allowenemy and tablecontains(enemies, r[2]) and not editormode then
			if not tilequads[map[x][y][1] ]:getproperty("breakable", x, y) and not tilequads[map[x][y][1] ]:getproperty("coinblock", x, y) then
				table.insert(objects["enemy"], enemy:new(x, y, r[2] as string, r))
				wasenemy = true
			end
		elseif entitylist[r[2]] then
			local t = entitylist[r[2]].t
			wasenemy = dispatch_enemy_entity_spawn(t, x, y, r, allowenemy) as boolean
		end
		
		table.insert(enemiesspawned, {x, y})
		
		if wasenemy then
			--spawn enemies in 5x1 line so they spawn as a unit and not alone.
			spawnenemy(x-2, y)
			spawnenemy(x-1, y)
			spawnenemy(x+1, y)
			spawnenemy(x+2, y)
		end
	end
	if session then session:bind_globals() end
end

global function givelive(...: any): any
	local args = {...}
	local id = args[1]
	local t = args[2] as Entity
	if mariolivecount ~= false then
		for i = 1, players do
			mariolives[i] = mariolives[i]+1
			respawnplayers()
		end
	end
	t.destroy = true
	t.active = false
	table.insert(scrollingscores, scrollingscore:new("1up", t.x, t.y))
	playsound("oneup")
end	

global function addpoints(...: any): any
	local args = {...}
	local i = args[1] as number
	local x = args[2]
	local y = args[3]
	if i > 0 then
		marioscore = marioscore + i
		if x and y then
			table.insert(scrollingscores, scrollingscore:new(i, x, y))
		end
	else
		table.insert(scrollingscores, scrollingscore:new(-i, x, y))
	end
end

