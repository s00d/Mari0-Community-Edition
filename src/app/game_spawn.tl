--[[ Teal extract from root game.lua: spawn helpers ]]

global function add_spawn_restriction(sx: number, sy: number)
	-- Precompute exclusive ±6 zone cells (same predicate as legacy list scan).
	for x = math.floor(sx) - 5, math.floor(sx) + 5 do
		for y = math.floor(sy) - 5, math.floor(sy) + 5 do
			spawnrestrictions[tilekey(x, y)] = true
		end
	end
end

global function spawnenemy(x: number, y: number)
	if not inmap(x, y) then
		return
	end

	local key = tilekey(x, y)

	--don't spawn when on a coinblock or breakable block
	if tilequads[map[x][y][1] ]:getproperty("breakable", x, y) or tilequads[map[x][y][1] ]:getproperty("coinblock", x, y) then
		enemiesspawned[key] = true
		return
	end

	if enemiesspawned[key] then
		return
	end

	--spawnrestriction (tilekey set, precomputed on add)
	allowenemy = not spawnrestrictions[key]

	local r = map[x][y]
	if #r > 1 then
		local wasenemy = false
		if allowenemy and tablecontains(enemies, r[2]) and enemiesdata[r[2] as string] and enemiesdata[r[2] as string].width and not editormode then
			if not tilequads[map[x][y][1] ]:getproperty("breakable", x, y) and not tilequads[map[x][y][1] ]:getproperty("coinblock", x, y) then
				table.insert(objects["enemy"], enemy:new(x, y, r[2] as string, r))
				wasenemy = true
			end
		elseif entitylist[r[2]] then
			local t = entitylist[r[2]].t
			wasenemy = dispatch_enemy_entity_spawn(t, x, y, r, allowenemy)
		end

		enemiesspawned[key] = true

		if wasenemy then
			--spawn enemies in 5x1 line so they spawn as a unit and not alone.
			spawnenemy(x-2, y)
			spawnenemy(x-1, y)
			spawnenemy(x+1, y)
			spawnenemy(x+2, y)
		end
	end
	if session then session:sync_session_from_globals() end
end

global function givelive(_: any, t: Entity)
	
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

global function addpoints(i: any, x?: any, y?: any)
	
	if (i as number) > 0 then
		marioscore = marioscore + (i as number)
		if x and y then
			table.insert(scrollingscores, scrollingscore:new(i, x, y))
		end
	else
		table.insert(scrollingscores, scrollingscore:new(-(i as number), x, y))
	end
end

