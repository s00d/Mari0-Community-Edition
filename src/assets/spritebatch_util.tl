--[[ Tile spritebatch factory (Stage 2.3). ]]

global function create_tile_spritebatches()
	smbspritebatch = love.graphics.newSpriteBatch(smbtilesimg, 10000)
	smbspritebatchfront = love.graphics.newSpriteBatch(smbtilesimg, 10000)
	portalspritebatch = love.graphics.newSpriteBatch(portaltilesimg, 10000)
	portalspritebatchfront = love.graphics.newSpriteBatch(portaltilesimg, 10000)
	if customtiles then
		customspritebatch = love.graphics.newSpriteBatch(customtilesimg, 10000)
		customspritebatchfront = love.graphics.newSpriteBatch(customtilesimg, 10000)
	end
	if modcustomtiles then
		modcustomspritebatch = {}
		modcustomspritebatchfront = {}
		for i = 1, modcustomtiles as number do
			modcustomspritebatch[i as integer] = love.graphics.newSpriteBatch(modcustomtilesimg[i as integer], 10000)
			modcustomspritebatchfront[i as integer] = love.graphics.newSpriteBatch(modcustomtilesimg[i as integer], 10000)
		end
	end
	spritebatchX = {}
	spritebatchY = {}
	spritebatch_orphan_slots = 0
	spritebatch_portal_catchup = false
end

return create_tile_spritebatches
