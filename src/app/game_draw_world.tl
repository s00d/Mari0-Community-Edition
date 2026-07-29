--[[ game_draw world/scene phases ]]

global function drawlevel_tiles(xtodraw: any, ytodraw: any)
	
	--TILES
	local xscrollfrac = math.fmod(xscroll, 1)
	local yscrollfrac = math.fmod(yscroll, 1)
	local tile_y_off = mapmode_tile_y_off()
	local batchx, batchy = scroll_batch_offset(xscroll), scroll_batch_offset(yscroll)
	love.graphics.draw(smbspritebatch, batchx, batchy)
	love.graphics.draw(portalspritebatch, batchx, batchy)
	if customtiles then
		love.graphics.draw(customspritebatch, batchx, batchy)
	end
	if modcustomtiles then
		for i = 1, modcustomtiles do
			love.graphics.draw(modcustomspritebatch[i as integer], batchx, batchy)
		end
	end
	local lmap = map as {number:{number:MapCell}}
	
	local flooredxscroll: number = 0
	if xscroll >= 0 then
		flooredxscroll = math.floor(xscroll)
	else
		flooredxscroll = math.ceil(xscroll)
	end
	
	local flooredyscroll: number = 0
	if yscroll >= 0 then
		flooredyscroll = math.floor(yscroll)
	else
		flooredyscroll = math.ceil(yscroll)
	end

	-- O(bounces) once per frame instead of O(tiles*bounces)
	local bounce_at = build_blockbounce_lookup(blockbouncex, blockbouncey)
	
	for y = 1, ytodraw do
		for x = 1, xtodraw do
			if inmap(flooredxscroll+x, flooredyscroll+y) then
				local bounceyoffset: number = 0
				local bi = (bounce_at as {any:any})[tilekey(flooredxscroll+x, flooredyscroll+y)]
				if bi then
					if (blockbouncetimer[bi] as number) < blockbouncetime/2 then
						bounceyoffset = (blockbouncetimer[bi] as number) / (blockbouncetime/2) * blockbounceheight
					else
						bounceyoffset = (2 - (blockbouncetimer[bi] as number) / (blockbouncetime/2)) * blockbounceheight
					end
				end
				
				local cox, coy = flooredxscroll+x, flooredyscroll+y
				local col = lmap[flooredxscroll+x]
				local t = col and col[flooredyscroll+y]
				if not t then
					-- incomplete / sparse map cell (bad pack or mid-edit)
				else
				local tilenumber = t[1]
				local tq = (tilenumber ~= nil) and tilequads[tilenumber] or nil
				if not level_mapmode and tq and tq:getproperty("coinblock", cox, coy) and tq:getproperty("invisible", cox, coy) == false then --coinblock
					love.graphics.draw(coinblockimg, coinblockquads[spriteset][coinframe], math.floor((x-1-xscrollfrac)*16*scale), math.floor(((y-1-yscrollfrac-bounceyoffset)*16+tile_y_off)*scale), 0, scale, scale)
				elseif not level_mapmode and coinmap[cox] and coinmap[cox][coy] then --coin
					love.graphics.draw(coinimg, coinquads[spriteset][coinframe], math.floor((x-1-xscrollfrac)*16*scale), math.floor(((y-1-yscrollfrac-bounceyoffset)*16+tile_y_off)*scale), 0, scale, scale)
				elseif tq and (bounceyoffset ~= 0 or (tilenumber as number) > 10000) then
					if not tq:getproperty("invisible", cox, coy) then
						love.graphics.draw(tq.image, tq:quad(flooredxscroll+x, flooredyscroll+y), math.floor((x-1-xscrollfrac)*16*scale), math.floor(((y-1-yscrollfrac-bounceyoffset)*16+tile_y_off)*scale), 0, scale, scale)
					end
				end
				
				if t.gelSides then
					draw_tile_gel_overlays(t.gelSides, math.floor((x - .5 - xscrollfrac) * 16 * scale), math.floor((y - 1 - yscrollfrac - bounceyoffset) * 16 * scale), 8, 8)
				end
				
				if editormode then
					if tq and tq:getproperty("invisible", cox, coy) and t[1] ~= 1 then
						love.graphics.draw(tq.image, tq:quad(), math.floor((x-1-xscrollfrac)*16*scale), ((y-1-yscrollfrac)*16+tile_y_off)*scale, 0, scale, scale)
					end
					
					if #t > 1 and t[2] ~= "link" then
						tilenumber = t[2]
						love.graphics.setColor(1, 1, 1, 0.6)
						if tablecontains(enemies, tilenumber) then --ENEMY PREVIEW THING
							local v = enemiesdata[tilenumber]
							if v and v.graphic and v.quad then
								local xoff, yoff = (((v.spawnoffsetx or 0)+v.width/2-.5)*16 - v.offsetX + v.quadcenterX)*scale, (((v.spawnoffsety or 0)-v.height+1)*16-v.offsetY - v.quadcenterY)*scale
								
								local mx, my = getMouseTile(mouse.getX(), mouse.getY()+8*scale)
								local alpha = 0.6
								if x == mx and y == my then
									alpha = 1
								end
								
								love.graphics.setColor(1, 0, 0, alpha)
								love.graphics.rectangle("fill", math.floor((x-1-xscrollfrac)*16*scale), math.floor(((y-1-yscrollfrac)*16+tile_y_off)*scale), 16*scale, 16*scale)
								love.graphics.setColor(1, 1, 1, alpha)
								love.graphics.draw(v.graphic, v.quad, math.floor((x-1-xscrollfrac)*16*scale+xoff), math.floor(((y-1-yscrollfrac)*16)*scale+yoff), 0, scale, scale)
							end
						else
							local eq = entityquads[tilenumber as number]
							if eq and eq.image and eq.quad then
								love.graphics.draw(eq.image, eq.quad, math.floor((x-1-xscrollfrac)*16*scale), math.floor(((y-1-yscrollfrac)*16+tile_y_off)*scale), 0, scale, scale)
							end
						end
						love.graphics.setColor(1, 1, 1, 1)
					end
					
					local mcell = map[x] and map[x][y]
					if mcell and entitylist[mcell[2]] and entitylist[mcell[2]].t == "platform" then
						local dir: any
						local dist: any
						if rightclickm and (rightclickm as rightclickmenu).tx == x and (rightclickm as rightclickmenu).ty == y then
							dir = (rightclickm as rightclickmenu).variables[2].value
							dist = tonumber(((rightclickm as rightclickmenu).t[6] as guielement).value as string)
						else
							dir = mcell[3]
							dist = tonumber(mcell[5])
						end
						
						
						love.graphics.setColor(252 / 255, 152 / 255, 56 / 255, 0.6)
						if dir == "down" then
							love.graphics.line((x-xscroll-.5)*16*scale, (y-yscroll-1.2)*16*scale, (x-xscroll-.5)*16*scale, (y-yscroll-1.2+(dist as number))*16*scale)
						elseif dir == "left" then
							love.graphics.line((x-xscroll-.5)*16*scale, (y-yscroll-1.2)*16*scale, (x-xscroll-.5-(dist as number))*16*scale, (y-yscroll-1.2)*16*scale)
						end
						love.graphics.setColor(1, 1, 1, 1)
					end
				end
				end
			end
		end
	end
	
end

global function drawlevel()
	if incognito then
		return
	end
	love.graphics.setColor(love.graphics.getBackgroundColor())
	love.graphics.rectangle("fill", 0, 0, width*16*scale, height*16*scale)
	love.graphics.setColor(1, 1, 1, 1)
	local xtodraw: number
	if mapwidth < width+1 then
		xtodraw = math.ceil(mapwidth)
	else
		if mapwidth > width and xscroll < mapwidth-width then
			xtodraw = math.ceil(width+1)
		else
			xtodraw = math.ceil(width)
		end
	end
	
	local ytodraw: number
	if mapheight < height+1 then
		ytodraw = math.ceil(mapheight)
	else
		if mapheight > height and yscroll < mapheight-height then
			ytodraw = height+2
		else
			ytodraw = height
		end
	end
	
	--custom background
	if custombackground then
		if custombackground == true then
			local xscroll = xscroll / (scrollfactor + 1)
			if reversescrollfactor() == 1 then
				xscroll = 0
			end
			for y = 1, math.ceil(height/14)+1 do
				for x = 1, math.ceil(width)+1 do
					love.graphics.draw(portalbackgroundimg, math.floor((x-1)*16*scale) - math.floor(math.fmod(xscroll, 1)*16*scale), math.floor(((y-1)*14)*16*scale) - math.floor(math.fmod(yscroll, 14)*16*scale), 0, scale, scale)
				end
			end
		else
			if custombackgroundimg[custombackground as string] then
				for i = #custombackgroundimg[custombackground as string], 1, -1  do
					local xscroll = xscroll / (i * scrollfactor + 1)
					if reversescrollfactor() == 1 then
						xscroll = 0
					end
					
					local yscroll = yscroll / (i * scrollfactor + 1)
					if reversescrollfactor() == 1 then
						yscroll = 0
					end
					
					for y = 1, math.ceil(height/custombackgroundheight[custombackground as string][i])+1 do
						for x = 1, math.ceil(width/custombackgroundwidth[custombackground as string][i])+1 do
							love.graphics.draw(custombackgroundimg[custombackground as string][i], math.floor(((x-1)*custombackgroundwidth[custombackground as string][i])*16*scale) - math.floor(math.fmod(xscroll, custombackgroundwidth[custombackground as string][i])*16*scale), math.floor(((y-1)*custombackgroundheight[custombackground as string][i])*16*scale) - math.floor(math.fmod(yscroll, custombackgroundheight[custombackground as string][i])*16*scale), 0, scale, scale)
						end
					end
				end
			end
		end
	end
	
	--castleflag
	if levelfinished and levelfinishtype == "flag" and not custombackground then
		love.graphics.draw(castleflagimg, math.floor(((flagx as number)+6-xscroll)*16*scale), (flagy-7+10/16)*16*scale+(castleflagy-yscroll)*16*scale, 0, scale, scale)
	end
	
	--itemanimations
	for _, w in pairs(itemanimations) do
		w:draw()
	end
	
	drawlevel_tiles(xtodraw, ytodraw)
	
	love.graphics.setColor(1, 1, 1)
	--textentities
	for _, w in pairs(textentities) do
		w:draw()
	end
end

global function drawforeground()
	--TILES FOREGROUND
	local tile_y_off = mapmode_tile_y_off()
	local batchx, batchy = scroll_batch_offset(xscroll), scroll_batch_offset(yscroll)
	love.graphics.draw(smbspritebatchfront, batchx, batchy)
	love.graphics.draw(portalspritebatchfront, batchx, batchy)
	if customtiles then
		love.graphics.draw(customspritebatchfront, batchx, batchy)
	end
	if modcustomtiles then
		for i = 1, modcustomtiles do
			love.graphics.draw(modcustomspritebatchfront[i as integer], batchx, batchy)
		end
	end
	
	--ANY NON STATIC BLOCKS AND STUFF.
	local lmap = map as {number:{number:MapCell}}
	
	local xtodraw: number
	if mapwidth < width+1 then
		xtodraw = math.ceil(mapwidth)
	else
		if mapwidth > width and xscroll < mapwidth-width then
			xtodraw = math.ceil(width+1)
		else
			xtodraw = math.ceil(width)
		end
	end
	
	local ytodraw: number
	if mapheight < height+1 then
		ytodraw = math.ceil(mapheight)
	else
		if mapheight > height and yscroll < mapheight-height then
			ytodraw = height+1
		else
			ytodraw = height
		end
	end
	
	local flooredxscroll: number = 0
	if xscroll >= 0 then
		flooredxscroll = math.floor(xscroll)
	else
		flooredxscroll = math.ceil(xscroll)
	end
	
	local flooredyscroll: number = 0
	if yscroll >= 0 then
		flooredyscroll = math.floor(yscroll)
	else
		flooredyscroll = math.ceil(yscroll)
	end
	
	for y = 1, ytodraw do
		for x = 1, xtodraw do
			if inmap(flooredxscroll+x, flooredyscroll+y) then
				local cox, coy = flooredxscroll+x, flooredyscroll+y
				local col = lmap[cox]
				local t = col and col[coy]
				if not t then
					-- skip
				else
				local tilenumber = t[1]
				local tq = (tilenumber ~= nil) and tilequads[tilenumber] or nil
				
				if tq and tq:getproperty("foreground", cox, coy) then
					if tq:getproperty("coinblock", cox, coy) and not tq:getproperty("invisible", cox, coy) then --coinblock
						love.graphics.draw(coinblockimg, coinblockquads[spriteset][coinframe], math.floor((x-1-math.fmod(xscroll, 1))*16*scale), math.floor(((y-1-math.fmod(yscroll, 1))*16+tile_y_off)*scale), 0, scale, scale)
					elseif coinmap[x] and coinmap[x][y] then --coin
						love.graphics.draw(coinimg, coinquads[spriteset][coinframe], math.floor((x-1-xscroll)*16*scale), math.floor(((y-1-yscroll)*16+tile_y_off)*scale), 0, scale, scale)
					elseif (tilenumber as number) > 10000 then
						if not tq:getproperty("invisible", cox, coy) then
							love.graphics.draw(tq.image, tq:quad(flooredxscroll+x, flooredyscroll+y), math.floor((x-1-math.fmod(xscroll, 1))*16*scale), math.floor(((y-1-math.fmod(yscroll, 1))*16+tile_y_off)*scale), 0, scale, scale)
						end
					end
					
					if t.gelSides then
						draw_tile_gel_overlays(t.gelSides, math.floor((x - .5 - math.fmod(xscroll, 1)) * 16 * scale), math.floor((y - 1 - math.fmod(yscroll, 1)) * 16 * scale), 8, 8)
					end
				end
				end
			end
		end
	end
	
	--custom foreground
	if customforeground then
		if customforeground == true then
			--None
		else
			if custombackgroundimg[customforeground] then
				for i = 1, #custombackgroundimg[customforeground]  do
				
					local xscroll = xscroll * (i * fscrollfactor + 1)
					if reversefscrollfactor() == 1 then
						xscroll = 0
					end
					
					local yscroll = yscroll / (i * fscrollfactor + 1)
					if reversefscrollfactor() == 1 then
						yscroll = 0
					end
					
					for y = 1, math.ceil(height/custombackgroundheight[customforeground][i])+1 do
						for x = 1, math.ceil(width/custombackgroundwidth[customforeground][i])+1 do
							love.graphics.draw(custombackgroundimg[customforeground][i], math.floor(((x-1)*custombackgroundwidth[customforeground][i])*16*scale) - math.floor(math.fmod(xscroll, custombackgroundwidth[customforeground][i])*16*scale), math.floor(((y-1)*custombackgroundheight[customforeground][i])*16*scale) - math.floor(math.fmod(yscroll, custombackgroundheight[customforeground][i])*16*scale), 0, scale, scale)
						end
					end
				end
			end
		end
	end
end

global function game_draw_props()
	love.graphics.setColor(1, 1, 1)
	--vines
	for _, w in pairs(objects["vine"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--warpzonetext
	if displaywarpzonetext then
		properprint("welcome to warp zone!", (mapwidth-14-1/16-xscroll)*16*scale, (5.5-yscroll)*16*scale)
		for _, v in ipairs(warpzonenumbers as {any}) do
			properprint((v as {any})[3], math.floor(((v as {any})[1] as number)-xscroll-1-9/16)*16*scale, (((v as {any})[2] as number)-3-yscroll)*16*scale)
		end
	end

	love.graphics.setColor(1, 1, 1)
	--platforms
	for _, w in pairs(objects["platform"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--scaffolds
	for _, w in pairs(objects["scaffold"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--seesawplatforms
	for _, w in pairs(objects["seesawplatform"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--seesaws
	for _, w in pairs(seesaws) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--springs
	for _, w in pairs(objects["spring"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--AE belts (tiled)
	if objects["belt"] then
		for _, w in pairs(objects["belt"]) do
			(w as belt):draw()
		end
	end

	love.graphics.setColor(1, 1, 1)
	--flag
	if flagx then
		local flag_y_off = mapmode_tile_y_off()
		love.graphics.draw(flagimg, math.floor((flagimgx-1-xscroll)*16*scale), ((flagimgy-yscroll)*16+flag_y_off)*scale, 0, scale, scale)
		if levelfinishtype == "flag" then
			properprint2(flagscore, math.floor((flagimgx+4/16-xscroll)*16*scale), ((14-flagimgy-yscroll+(flagy-13)*2)*16+flag_y_off)*scale, 0, scale, scale)
		end
	end

	love.graphics.setColor(1, 1, 1)
	--axe
	if axex then
		local axe_x = axex as number
		local axe_y = axey as number
		love.graphics.draw(axeimg, axequads[coinframe], math.floor((axe_x-1-xscroll)*16*scale), (axe_y-1.5-yscroll)*16*scale, 0, scale, scale)
	end

	love.graphics.setColor(1, 1, 1)
	--levelfinish text and toad
	if levelfinished and levelfinishtype == "castle" then
		local axe_y = axey as number
		if marioworld ~= 8 then
			love.graphics.draw(toadimg, math.floor((mapwidth-7-xscroll)*16*scale), (axe_y+2.0625-yscroll)*16*scale, 0, scale, scale)
		else
			print(math.floor((mapwidth-7-xscroll)*16*scale), (axe_y+2.0625-yscroll)*16*scale)
			love.graphics.draw(peachimg, math.floor((mapwidth-7-xscroll)*16*scale), (axe_y+2.0625-yscroll)*16*scale, 0, scale, scale)
		end

		if levelfinishedmisc2 == 1 then
			if levelfinishedmisc >= 1 then
				properprint("thank you " .. characters[mariocharacter[1]].name .. "!", math.floor(((mapwidth-12-xscroll)*16-1)*scale), (axe_y-4.5-yscroll)*16*scale)
			end
			if levelfinishedmisc == 2 then
				properprint("but our princess is in", math.floor(((mapwidth-13.5-xscroll)*16-1)*scale), (axe_y-2.5-yscroll)*16*scale) --say what
				properprint("another castle!", math.floor(((mapwidth-13.5-xscroll)*16-1)*scale), (axe_y-1.5-yscroll)*16*scale) --bummer.
			end
		else
			if levelfinishedmisc >= 1 then	
				properprint("thank you mario!", math.floor(((mapwidth-12-xscroll)*16-1)*scale), (axe_y-4.5-yscroll)*16*scale)
			end
			if levelfinishedmisc >= 2 then
				properprint("your quest is over.", math.floor(((mapwidth-12.5-xscroll)*16-1)*scale), (axe_y-3-yscroll)*16*scale)
			end

			--todo
			if levelfinishedmisc >= 3 then
				properprint("we present you a new quest.", math.floor(((mapwidth-14.5-xscroll)*16-1)*scale), (axe_y-2-yscroll)*16*scale)
			end
			if levelfinishedmisc >= 4 then
				properprint("push button b", math.floor(((mapwidth-11-xscroll)*16-1)*scale), (axe_y-.5-yscroll)*16*scale)
			end
			if levelfinishedmisc == 5 then
				properprint("to play as steve", math.floor(((mapwidth-12-xscroll)*16-1)*scale), (axe_y+.5-yscroll)*16*scale)
			end
		end
	end
	love.graphics.setColor(1, 1, 1)
	--Panels
	for _, w in pairs(objects["panel"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Fireworks
	for _, w in pairs(fireworks) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Buttons
	for _, w in pairs(objects["button"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Pushbuttons
	for _, w in pairs(objects["pushbutton"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)

	--hardlight bridges
	for _, w in pairs(objects["lightbridgebody"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)

	--lightbridge
	for _, w in pairs(objects["lightbridge"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--laser
	for _, w in pairs(objects["laser"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--laserdetector
	for _, w in pairs(objects["laserdetector"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Groundlights
	for _, w in pairs(objects["groundlight"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Faithplates
	for _, w in pairs(objects["faithplate"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Black holes (procedural VFX)
	if objects["blackhole"] then
		for _, w in pairs(objects["blackhole"]) do
			(w as blackhole):draw()
		end
	end

	love.graphics.setColor(1, 1, 1)
	--Bubbles
	for _, w in pairs(bubbles) do
		if onscreen(w.x, w.y, 0.5, 0.5) then
			w:draw()
		end
	end

	love.graphics.setColor(1, 1, 1)
	--miniblocks
	for _, v in pairs(miniblocks) do
		if onscreen(v.x, v.y, 0.5, 0.5) then
			v:draw()
		end
	end

	--emancipateanimations
	for _, v in pairs(emancipateanimations) do
		v:draw()
	end

	--emancipationfizzles
	for _, v in pairs(emancipationfizzles) do
		v:draw()
	end

	--pedestals
	for _, v in pairs(pedestals) do
		v:draw()
	end

end

global function game_draw_objects()
	love.graphics.setColor(1, 1, 1)

	--OBJECTS
	for j, w in pairs(objects) do	
		if j ~= "tile" then
			for _, v in pairs(w) do
				if v.drawable and v.graphic and v.quad then
					love.graphics.setScissor()
					love.graphics.setColor(1, 1, 1)
					local dirscale: number

					if j == "player" then
						if (v.portalsavailable[1] or v.portalsavailable[2]) then
							if (v.pointingangle+math.pi*2 > -v.rotation+math.pi*2 and (not (v.pointingangle > -v.rotation+math.pi))) or v.pointingangle < -v.rotation-math.pi then
								dirscale = -scale
							else
								dirscale = scale
							end
						else
							if v.animationdirection == "right" then
								dirscale = scale
							else
								dirscale = -scale
							end
						end

						if bigmario then
							dirscale = dirscale * scalefactor
						end
					else
						if v.animationdirection == "left" then
							dirscale = -scale
						else
							dirscale = scale
						end
					end

					if v.mirror then
						dirscale = -dirscale
					end

					local horscale = scale
					if v.shot or v.upsidedown then
						horscale = -scale
					end

					if j == "player" and bigmario then
						horscale = horscale * scalefactor
					end

					if v.customscale then
						horscale = horscale * v.customscale
						dirscale = dirscale * v.customscale
					end

					local portal_raw, portaly = insideportal(v.x, v.y, v.width, v.height)
					local portal = portal_raw as portal
					local entryX: number
					local entryY: number
					local entryfacing: any
					local exitX: number
					local exitY: number
					local exitfacing: any

					--SCISSOR FOR ENTRY
					if v.customscissor and v.portalable ~= false then
						local cs = v.customscissor as {any}
						begin_mask(function() love.graphics.rectangle("fill", math.floor((((cs as {number})[1] as number)-xscroll)*16*scale), math.floor((((cs as {number})[2] as number)-.5-yscroll)*16*scale), (cs[3] as number)*16*scale, (cs[4] as number)*16*scale) end, v.invertedscissor as boolean)
					end

					if v.static == false and v.portalable ~= false then
						if not v.customscissor and portal_raw ~= false and (v.active or v.portaloverride) then
							if portaly == 1 then
								entryX, entryY, entryfacing = portal.x1 as number, portal.y1 as number, portal.facing1
								exitX, exitY, exitfacing = portal.x2 as number, portal.y2 as number, portal.facing2
							else
								entryX, entryY, entryfacing = portal.x2 as number, portal.y2 as number, portal.facing2
								exitX, exitY, exitfacing = portal.x1 as number, portal.y1 as number, portal.facing1
							end

							if entryfacing == "right" then
								love.graphics.setScissor(math.floor((entryX-xscroll)*16*scale), math.floor(((entryY-3.5-yscroll)*16)*scale), 64*scale, 96*scale)
							elseif entryfacing == "left" then
								love.graphics.setScissor(math.floor((entryX-xscroll-5)*16*scale), math.floor(((entryY-4.5-yscroll)*16)*scale), 64*scale, 96*scale)
							elseif entryfacing == "up" then
								love.graphics.setScissor(math.floor((entryX-xscroll-3)*16*scale), math.floor(((entryY-5.5-yscroll)*16)*scale), 96*scale, 64*scale)
							elseif entryfacing == "down" then
								love.graphics.setScissor(math.floor((entryX-xscroll-4)*16*scale), math.floor(((entryY-0.5-yscroll)*16)*scale), 96*scale, 64*scale)
							end
						end
					end

					if type(v.graphic) == "table" then
						local g = v.graphic as {any}
						local cols = v.colors or {}
						for k = 1, #g do
							if cols[k] then
								love.graphics.setColor(cols[k])
							else
								love.graphics.setColor(1, 1, 1)
							end
							love.graphics.draw(g[k], v.quad, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end
					else
						if v.graphic and v.quad then
							love.graphics.draw(v.graphic, v.quad, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end
					end

					--HATS
					if v.drawhat then
						local offsets = (gethatoffset(v.char, v.graphic, v.animationstate, v.runframe, v.jumpframe, v.climbframe, v.swimframe, v.underwater, v.infunnel, v.fireanimationtimer, v.ducking) or {0, 0}) as {number}
						local hats = v.hats as {any}
						local cols = v.colors as {any}

						if offsets and #hats > 0 then
							local yadd: number = 0
							for i = 1, #hats do
								if hats[i] ~= 0 then
									if hats[i] == 1 then
										love.graphics.setColor(cols[1])
									else
										love.graphics.setColor(1, 1, 1)
									end
									if v.graphic == v.biggraphic or v.animationstate == "grow" then
										love.graphics.draw(bighat[hats[i]].graphic, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX - bighat[hats[i]].x + offsets[1], v.quadcenterY - bighat[hats[i]].y + offsets[2] + yadd)
										yadd = yadd + bighat[hats[i]].height
									else
										love.graphics.draw(hat[hats[i]].graphic, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX - hat[hats[i]].x + offsets[1], v.quadcenterY - hat[hats[i]].y + offsets[2] + yadd)
										yadd = yadd + hat[hats[i]].height
									end
								end
							end
						end
						love.graphics.setColor(1, 1, 1)
					end

					if type(v.graphic) == "table" then
						local gdot = v.graphic as {any:any}
						if gdot[0] then
							love.graphics.setColor(1, 1, 1)
							love.graphics.draw(gdot[0], v.quad, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end
						if gdot.dot then
							love.graphics.setColor(unpack((v as {string:any})["portal" .. (v.lastportal or 1) .. "color"] as {any}))
							love.graphics.draw(gdot["dot"], v.quad, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end	
					end

					--portal duplication
					if v.customscissor and v.portalable ~= false then
						begin_mask(function() love.graphics.rectangle("fill", math.floor(((v.customscissor as {number})[1]-xscroll)*16*scale), math.floor(((v.customscissor as {number})[2]-.5-yscroll)*16*scale), (v.customscissor as {number})[3]*16*scale, (v.customscissor as {number})[4]*16*scale) end, v.invertedscissor as boolean)
					end

					if v.static == false and (v.active or v.portaloverride) and v.portalable ~= false then
						if not v.customscissor and portal_raw ~= false then
							love.graphics.setScissor((currentscissor as {number})[1], (currentscissor as {number})[2], (currentscissor as {number})[3], (currentscissor as {number})[4])
							local px, py, pw, ph, pr, pad = v.x, v.y, v.width, v.height, v.rotation, v.animationdirection
							local _d1: any
							local _d2: any
							px, py, _d1, _d2, pr, pad = portalcoords(px, py, 0, 0, pw, ph, pr, pad, entryX, entryY, entryfacing, exitX, exitY, exitfacing)

							if pad ~= v.animationdirection then
								dirscale = -dirscale
							end

							horscale = scale
							if v.shot or v.upsidedown then
								horscale = -scale
							end

							if exitfacing == "right" then
								love.graphics.setScissor(math.floor((exitX-xscroll)*16*scale), math.floor(((exitY-yscroll-3.5)*16)*scale), 64*scale, 96*scale)
							elseif exitfacing == "left" then
								love.graphics.setScissor(math.floor((exitX-xscroll-5)*16*scale), math.floor(((exitY-yscroll-4.5)*16)*scale), 64*scale, 96*scale)
							elseif exitfacing == "up" then
								love.graphics.setScissor(math.floor((exitX-xscroll-3)*16*scale), math.floor(((exitY-yscroll-5.5)*16)*scale), 96*scale, 64*scale)
							elseif exitfacing == "down" then
								love.graphics.setScissor(math.floor((exitX-xscroll-4)*16*scale), math.floor(((exitY-yscroll-0.5)*16)*scale), 96*scale, 64*scale)
							end

							if type(v.graphic) == "table" then
								for k = 1, #(v.graphic as {any}) do
									if (v.colors as {any})[k] then
										love.graphics.setColor(unpack((v.colors as {any})[k] as {any}))
									else
										love.graphics.setColor(1, 1, 1)
									end
									love.graphics.draw((v.graphic as {any})[k], v.quad, math.floor(((px-xscroll)*16+v.offsetX)*scale), math.floor(((py-yscroll)*16-v.offsetY)*scale), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
								end
							else
								love.graphics.draw(v.graphic, v.quad, math.ceil(((px-xscroll)*16+v.offsetX)*scale), math.ceil(((py-yscroll)*16-v.offsetY)*scale), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
							end

							--HAAAATS
							if v.drawhat then
								local offsets = (gethatoffset(v.char, v.graphic, v.animationstate, v.runframe, v.jumpframe, v.climbframe, v.swimframe, v.underwater, v.infunnel, v.fireanimationtimer, v.ducking) or {0, 0}) as {number}

								if offsets and #v.hats > 0 then
									local yadd: number = 0
									for i = 1, #v.hats do
										if v.hats[i] ~= 0 then
											if v.hats[i] == 1 then
												love.graphics.setColor(v.colors[1])
											else
												love.graphics.setColor(1, 1, 1)
											end
											if v.graphic == v.biggraphic or v.animationstate == "grow" then
												love.graphics.draw(bighat[v.hats[i]].graphic, math.floor(((px-xscroll)*16+v.offsetX)*scale), math.floor(((py-yscroll)*16-v.offsetY)*scale), pr, dirscale, horscale, v.quadcenterX - bighat[v.hats[i]].x + offsets[1], v.quadcenterY - bighat[v.hats[i]].y + offsets[2] + yadd)
												yadd = yadd + bighat[v.hats[i]].height
											else
												love.graphics.draw(hat[v.hats[i]].graphic, math.floor(((px-xscroll)*16+v.offsetX)*scale), math.floor(((py-yscroll)*16-v.offsetY)*scale), pr, dirscale, horscale, v.quadcenterX - hat[v.hats[i]].x + offsets[1], v.quadcenterY - hat[v.hats[i]].y + offsets[2] + yadd)
												yadd = yadd + hat[v.hats[i]].height
											end
										end
									end
								end
							end

							if type(v.graphic) == "table" then
								if (v.graphic as {any})[0] then
									love.graphics.setColor(1, 1, 1)
									love.graphics.draw((v.graphic as {any})[0], v.quad, math.floor(((px-xscroll)*16+v.offsetX)*scale), math.floor(((py-yscroll)*16-v.offsetY)*scale), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
								end
								if (v.graphic as {string:any}).dot and v.lastportal then
									love.graphics.setColor(unpack((v as {string:any})["portal" .. v.lastportal .. "color"] as {any}))
									love.graphics.draw((v.graphic as {string:any})["dot"], v.quad, math.floor(((px-xscroll)*16+v.offsetX)*scale), math.floor(((py-yscroll)*16-v.offsetY)*scale), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
								end
							end
						end
					end
					love.graphics.setScissor((currentscissor as {number})[1], (currentscissor as {number})[2], (currentscissor as {number})[3], (currentscissor as {number})[4])
					end_mask()
				end
			end
		end
	end

end

global function scenedraw()
	if level_mapmode then
		love.graphics.push()
		love.graphics.translate(mapmode_pad_x, mapmode_pad_y)
		if mapmode_zoom > 1 then
			love.graphics.scale(mapmode_zoom, mapmode_zoom)
		end
	end

	drawlevel()
	game_draw_props()
	game_draw_objects()
	game_draw_fx()
	drawforeground()

	if level_mapmode then
		love.graphics.pop()
	end

	if bdrawui then
		game_draw_hud()
	end
end

