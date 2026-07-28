--[[ Metroid save slots (F5). openmv MIT — licenses/openmv.MIT ]]

global function metroid_save(slot: integer): boolean
	if not JSON or not JSON.encode then return false end
	local pl = playerobjs and playerobjs[1]
	local payload: {string:any} = {
		room = (currentroom and (currentroom as MetroidRoom).id) or START_ROOM or "",
		x = pl and (pl as {string:any}).x or 0,
		y = pl and (pl as {string:any}).y or 0,
		globools = globools or {},
		globints = globints or {},
		playtime = metroid_playtime or 0,
		mappack = mappack,
		level = currentlevel,
	}
	if love and love.filesystem and love.filesystem.write then
		love.filesystem.write("save_metroid_" .. tostring(slot) .. ".json", JSON.encode(payload))
		return true
	end
	return false
end

global function metroid_autosave()
	metroid_save(0)
end

global function metroid_load(slot: integer): {string:any}|nil
	if not JSON or not JSON.decode then return nil end
	local path = "save_metroid_" .. tostring(slot) .. ".json"
	if not (love and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(path)) then return nil end
	local raw = love.filesystem.read(path)
	if not raw then return nil end
	local data = JSON.decode(raw) as {string:any}
	if data.globools then globools = data.globools as {string:boolean} end
	if data.globints then globints = data.globints as {string:number} end
	metroid_playtime = tonumber(data.playtime) or 0
	return data
end

global function metroid_use_hp(): boolean
	return (tonumber((globints and globints["maxhp"]) or 0) or 0) > 0
end

global function metroid_hurt(pl_any: any, n: number): boolean
	-- Returns true if HP model absorbed the hit (caller should not classic-shrink).
	-- Does NOT call die — caller finishes death when hp<=0.
	if not metroid_use_hp() then return false end
	local pl = pl_any as {string:any}
	if not pl then return false end
	if (pl.invultimer as number or 0) > 0 then return true end
	local hp = (pl.hp as number) or (globints["maxhp"] as number) or 1
	hp = hp - (n or 1)
	pl.hp = hp
	pl.invultimer = 1.0
	return true
end

global function metroid_apply_hp_to_player(pl_any: any)
	if not metroid_use_hp() then return end
	local pl = pl_any as {string:any}
	if not pl then return end
	local maxhp = globints["maxhp"] or 1
	pl.maxhp = maxhp
	if not pl.hp or (pl.hp as number) > maxhp then pl.hp = maxhp end
end

return {
	metroid_save = metroid_save, metroid_load = metroid_load, metroid_autosave = metroid_autosave,
	metroid_use_hp = metroid_use_hp, metroid_hurt = metroid_hurt, metroid_apply_hp_to_player = metroid_apply_hp_to_player,
}
