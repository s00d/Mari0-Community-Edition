--[[ Clear-check: must beat level in test mode before "publish". ]]

global editor_cheats_used: boolean = false

global function editor_clearcheck_key(world: any, level: any, sub: any): string
	local s = tostring(world) .. "-" .. tostring(level)
	if sub and tonumber(sub) and (tonumber(sub) as number) > 0 then
		s = s .. "_" .. tostring(sub)
	end
	return "clearcheck_" .. tostring(mappack or "pack") .. "_" .. s
end

global function editor_mark_cheats()
	editor_cheats_used = true
end

global function editor_clear_cheats()
	editor_cheats_used = false
end

global function editor_pass_clearcheck(): boolean
	if not testlevel or editor_cheats_used then return false end
	local key = editor_clearcheck_key(marioworld, mariolevel, mariosublevel)
	if globoolSH then
		globoolSH(key, "true")
	end
	if notice and notice.new then
		notice.new("CLEAR CHECK PASSED", notice.white, 3)
	end
	return true
end

global function editor_has_clearcheck(world: any, level: any, sub: any): boolean
	local key = editor_clearcheck_key(world, level, sub)
	if not globoolSH then return false end
	return globoolSH(key, "check") == true
end

global function editor_clear_check(): boolean, string
	-- Basic validation
	if not session.map then return false, "no map" end
	local has_spawn = false
	local has_finish = false
	for x = 1, session.mapwidth or 0 do
		for y = 1, session.mapheight or 0 do
			local c = session.map[x][y]
			if c and c[2] and entitylist and type(c[2]) == "number" then
				local e = entitylist[c[2] as integer]
				if e then
					if e.t == "spawn" then has_spawn = true end
					if e.t == "flag" or e.t == "castleend" then has_finish = true end
				end
			end
		end
	end
	if not has_spawn then return false, "need spawn" end
	if not has_finish then return false, "need flag/finish" end
	if not editor_has_clearcheck(marioworld, mariolevel, mariosublevel) then
		return false, "beat level in test to publish"
	end
	return true, ""
end
