--[[ Tile spritebatch factory — capacity for full-map fill. ]]

global function create_tile_spritebatches(capacity: number|nil)
	local cap: integer = 10000
	if capacity ~= nil and capacity > (cap as number) then
		cap = math.floor(capacity) as integer
	end
	if session and session.mapwidth and session.mapheight then
		local need = math.floor((session.mapwidth as number) * (session.mapheight as number)) as integer
		if need > cap then
			cap = need
		end
	end
	smbspritebatch = love.graphics.newSpriteBatch(smbtilesimg, cap)
	smbspritebatchfront = love.graphics.newSpriteBatch(smbtilesimg, cap)
	portalspritebatch = love.graphics.newSpriteBatch(portaltilesimg, cap)
	portalspritebatchfront = love.graphics.newSpriteBatch(portaltilesimg, cap)
	if customtiles then
		customspritebatch = love.graphics.newSpriteBatch(customtilesimg, cap)
		customspritebatchfront = love.graphics.newSpriteBatch(customtilesimg, cap)
	end
	if modcustomtiles then
		modcustomspritebatch = {}
		modcustomspritebatchfront = {}
		for i = 1, modcustomtiles as number do
			modcustomspritebatch[i as integer] = love.graphics.newSpriteBatch(modcustomtilesimg[i as integer], cap)
			modcustomspritebatchfront[i as integer] = love.graphics.newSpriteBatch(modcustomtilesimg[i as integer], cap)
		end
	end
	spritebatchX = {}
	spritebatchY = {}
	spritebatch_orphan_slots = 0
	spritebatch_portal_catchup = false
	spritebatch_dirty = true
end

return create_tile_spritebatches
