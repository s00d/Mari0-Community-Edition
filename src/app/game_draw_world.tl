--[[ game_draw world/scene phases ]]

global function drawlevel_tiles(...: any): any
	local xtodraw, ytodraw = ...
	--TILES
	local xscrollfrac = math.fmod(xscroll, 1)
	local yscrollfrac = math.fmod(yscroll, 1)
	local batchx, batchy = scroll_batch_offset(xscroll), scroll_batch_offset(yscroll)
	love.graphics.draw(smbspritebatch, batchx, batchy)
	love.graphics.draw(portalspritebatch, batchx, batchy)
	if customtiles then
		love.graphics.draw(customspritebatch, batchx, batchy)
	end
	if modcustomtiles then
		for i = 1, modcustomtiles do
			love.graphics.draw(modcustomspritebatch[i], batchx, batchy)
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
				local bounceyoffset = 0
				local bi = bounce_at[tilekey(flooredxscroll+x, flooredyscroll+y)] as any
				if bi then
					if blockbouncetimer[bi] < blockbouncetime/2 then
						bounceyoffset = blockbouncetimer[bi] / (blockbouncetime/2) * blockbounceheight
					else
						bounceyoffset = (2 - blockbouncetimer[bi] / (blockbouncetime/2)) * blockbounceheight
					end
				end
				
				local cox, coy = flooredxscroll+x, flooredyscroll+y
				local t = lmap[flooredxscroll+x][flooredyscroll+y]
				
				local tilenumber = t[1]
				if tilequads[tilenumber]:getproperty("coinblock", cox, coy) and tilequads[tilenumber]:getproperty("invisible", cox, coy) == false then --coinblock
					love.graphics.draw(coinblockimg, coinblockquads[spriteset][coinframe], math.floor((x-1-xscrollfrac)*16*scale), math.floor(((y-1-yscrollfrac-bounceyoffset)*16-8)*scale), 0, scale, scale)
				elseif coinmap[cox][coy] then --coin
					love.graphics.draw(coinimg, coinquads[spriteset][coinframe], math.floor((x-1-xscrollfrac)*16*scale), math.floor(((y-1-yscrollfrac-bounceyoffset)*16-8)*scale), 0, scale, scale)
				elseif bounceyoffset ~= 0 or tilenumber > 10000 then
					if not tilequads[tilenumber]:getproperty("invisible", cox, coy) then
						love.graphics.draw(tilequads[tilenumber].image, tilequads[tilenumber]:quad(flooredxscroll+x, flooredyscroll+y), math.floor((x-1-xscrollfrac)*16*scale), math.floor(((y-1-yscrollfrac-bounceyoffset)*16-8)*scale), 0, scale, scale)
					end
				end
				
				--Gel overlays!
				if t["gels"] then
					for i = 1, 4 do
						local dir = "top"
						local r: number = 0
						if i == 2 then
							dir = "right"
							r = math.pi/2
						elseif i == 3 then
							dir = "bottom"
							r = math.pi
						elseif i == 4 then
							dir = "left"
							r = math.pi*1.5
						end
						
						for i = 1, 4 do
							if t["gels"][dir] == i then
								local img: Image|nil = nil
								if i == 1 then
									img = gel1groundimg
								elseif i == 2 then
									img = gel2groundimg
								elseif i == 3 then
									img = gel3groundimg
								elseif i == 4 then
									img = gel4groundimg
								end
									
								love.graphics.draw(img, math.floor((x-.5-xscrollfrac)*16*scale), math.floor((y-1-yscrollfrac-bounceyoffset)*16*scale), r, scale, scale, 8, 8)
							end
						end
					end
				end
				
				if editormode then
					if tilequads[t[1]]:getproperty("invisible", cox, coy) and t[1] ~= 1 then
						love.graphics.draw(tilequads[t[1]].image, tilequads[t[1]]:quad(), math.floor((x-1-xscrollfrac)*16*scale), ((y-1-yscrollfrac)*16-8)*scale, 0, scale, scale)
					end
					
					if #t > 1 and t[2] ~= "link" then
						tilenumber = t[2]
						love.graphics.setColor(1, 1, 1, 0.6)
						if tablecontains(enemies, tilenumber) then --ENEMY PREVIEW THING
							local v = enemiesdata[tilenumber]
							local xoff, yoff = (((v.spawnoffsetx or 0)+v.width/2-.5)*16 - v.offsetX + v.quadcenterX)*scale, (((v.spawnoffsety or 0)-v.height+1)*16-v.offsetY - v.quadcenterY)*scale
							
							local mx, my = getMouseTile(mouse.getX(), mouse.getY()+8*scale)
							local alpha = 0.6
							if x == mx and y == my then
								alpha = 1
							end
							
							love.graphics.setColor(1, 0, 0, alpha)
							love.graphics.rectangle("fill", math.floor((x-1-xscrollfrac)*16*scale), math.floor(((y-1-yscrollfrac)*16-8)*scale), 16*scale, 16*scale)
							love.graphics.setColor(1, 1, 1, alpha)
							love.graphics.draw(v.graphic, v.quad, math.floor((x-1-xscrollfrac)*16*scale+xoff), math.floor(((y-1-yscrollfrac)*16)*scale+yoff), 0, scale, scale)
						else
							love.graphics.draw(entityquads[tilenumber].image, entityquads[tilenumber].quad, math.floor((x-1-xscrollfrac)*16*scale), math.floor(((y-1-yscrollfrac)*16-8)*scale), 0, scale, scale)
						end
						love.graphics.setColor(1, 1, 1, 1)
					end
					
					if entitylist[map[x][y][2]] and entitylist[map[x][y][2]].t == "platform" then
						local dir: any
						local dist: any
						if rightclickm and (rightclickm as rightclickmenu).tx == x and (rightclickm as rightclickmenu).ty == y then
							dir = (rightclickm as rightclickmenu).variables[2].value
							dist = tonumber((rightclickm as rightclickmenu).t[6].value as string)
						else
							dir = map[x][y][3]
							dist = tonumber(map[x][y][5])
						end
						
						
						love.graphics.setColor(252 / 255, 152 / 255, 56 / 255, 0.6)
						if dir == "down" then
							love.graphics.line((x-xscroll-.5)*16*scale, (y-yscroll-1.2)*16*scale, (x-xscroll-.5)*16*scale, (y-yscroll-1.2+dist)*16*scale)
						elseif dir == "left" then
							love.graphics.line((x-xscroll-.5)*16*scale, (y-yscroll-1.2)*16*scale, (x-xscroll-.5-dist)*16*scale, (y-yscroll-1.2)*16*scale)
						end
						love.graphics.setColor(1, 1, 1, 1)
					end
				end
			end
		end
	end
	
end

global function drawlevel(...: any): any
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
		love.graphics.draw(castleflagimg, math.floor((flagx+6-xscroll)*16*scale), (flagy-7+10/16)*16*scale+(castleflagy-yscroll)*16*scale, 0, scale, scale)
	end
	
	--itemanimations
	for j, w in pairs(itemanimations) do
		w:draw()
	end
	
	drawlevel_tiles(xtodraw, ytodraw)
	
	love.graphics.setColor(1, 1, 1)
	--textentities
	for j, w in pairs(textentities) do
		w:draw()
	end
end

global function drawforeground(...: any): any
	--TILES FOREGROUND
	local batchx, batchy = scroll_batch_offset(xscroll), scroll_batch_offset(yscroll)
	love.graphics.draw(smbspritebatchfront, batchx, batchy)
	love.graphics.draw(portalspritebatchfront, batchx, batchy)
	if customtiles then
		love.graphics.draw(customspritebatchfront, batchx, batchy)
	end
	if modcustomtiles then
		for i = 1, modcustomtiles do
			love.graphics.draw(modcustomspritebatchfront[i], batchx, batchy)
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
				local t = lmap[cox][coy]
				
				local tilenumber = t[1]
				
				if tilequads[tilenumber]:getproperty("foreground", cox, coy) then
					if tilequads[tilenumber]:getproperty("coinblock", cox, coy) and not tilequads[tilenumber]:getproperty("invisible", cox, coy) then --coinblock
						love.graphics.draw(coinblockimg, coinblockquads[spriteset][coinframe], math.floor((x-1-math.fmod(xscroll, 1))*16*scale), math.floor(((y-1-math.fmod(yscroll, 1))*16-8)*scale), 0, scale, scale)
					elseif coinmap[x][y] then --coin
						love.graphics.draw(coinimg, coinquads[spriteset][coinframe], math.floor((x-1-xscroll)*16*scale), math.floor(((y-1-yscroll)*16-8)*scale), 0, scale, scale)
					elseif tilenumber > 10000 then
						if not tilequads[tilenumber]:getproperty("invisible", cox, coy) then
							love.graphics.draw(tilequads[tilenumber].image, tilequads[tilenumber]:quad(flooredxscroll+x, flooredyscroll+y), math.floor((x-1-math.fmod(xscroll, 1))*16*scale), math.floor(((y-1-math.fmod(yscroll, 1))*16-8)*scale), 0, scale, scale)
						end
					end
					
					--Gel overlays!
					if t["gels"] then
						for i = 1, 4 do
							local dir = "top"
							local r: number = 0
							if i == 2 then
								dir = "right"
								r = math.pi/2
							elseif i == 3 then
								dir = "bottom"
								r = math.pi
							elseif i == 4 then
								dir = "left"
								r = math.pi*1.5
							end
							
							for i = 1, 4 do
								if t["gels"][dir] == i then
									local img: Image|nil = nil
									if i == 1 then
										img = gel1groundimg
									elseif i == 2 then
										img = gel2groundimg
									elseif i == 3 then
										img = gel3groundimg
									elseif i == 4 then
										img = gel4groundimg
									end
										
									love.graphics.draw(img, math.floor((x-.5-math.fmod(xscroll, 1))*16*scale), math.floor((y-1-math.fmod(yscroll, 1))*16*scale), r, scale, scale, 8, 8)
								end
							end
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

global function game_draw_props(...: any): any
	love.graphics.setColor(1, 1, 1)
	--vines
	for j, w in pairs(objects["vine"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--warpzonetext
	if displaywarpzonetext then
		properprint("welcome to warp zone!", (mapwidth-14-1/16-xscroll)*16*scale, (5.5-yscroll)*16*scale)
		for i, v in pairs(warpzonenumbers) do
			properprint(v[3], math.floor((v[1]-xscroll-1-9/16)*16*scale), (v[2]-3-yscroll)*16*scale)
		end
	end

	love.graphics.setColor(1, 1, 1)
	--platforms
	for j, w in pairs(objects["platform"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--scaffolds
	for j, w in pairs(objects["scaffold"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--seesawplatforms
	for j, w in pairs(objects["seesawplatform"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--seesaws
	for j, w in pairs(seesaws) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--springs
	for j, w in pairs(objects["spring"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--flag
	if flagx then
		love.graphics.draw(flagimg, math.floor((flagimgx-1-xscroll)*16*scale), ((flagimgy-yscroll)*16-8)*scale, 0, scale, scale)
		if levelfinishtype == "flag" then
			properprint2(flagscore, math.floor((flagimgx+4/16-xscroll)*16*scale), ((14-flagimgy-yscroll+(flagy-13)*2)*16-8)*scale, 0, scale, scale)
		end
	end

	love.graphics.setColor(1, 1, 1)
	--axe
	if axex then
		love.graphics.draw(axeimg, axequads[coinframe], math.floor((axex-1-xscroll)*16*scale), (axey-1.5-yscroll)*16*scale, 0, scale, scale)
	end

	love.graphics.setColor(1, 1, 1)
	--levelfinish text and toad
	if levelfinished and levelfinishtype == "castle" then
		if marioworld ~= 8 then
			love.graphics.draw(toadimg, math.floor((mapwidth-7-xscroll)*16*scale), (axey+2.0625-yscroll)*16*scale, 0, scale, scale)
		else
			print(math.floor((mapwidth-7-xscroll)*16*scale), (axey+2.0625-yscroll)*16*scale)
			love.graphics.draw(peachimg, math.floor((mapwidth-7-xscroll)*16*scale), (axey+2.0625-yscroll)*16*scale, 0, scale, scale)
		end

		if levelfinishedmisc2 == 1 then
			if levelfinishedmisc >= 1 then
				properprint("thank you " .. characters[mariocharacter[1]].name .. "!", math.floor(((mapwidth-12-xscroll)*16-1)*scale), (axey-4.5-yscroll)*16*scale)
			end
			if levelfinishedmisc == 2 then
				properprint("but our princess is in", math.floor(((mapwidth-13.5-xscroll)*16-1)*scale), (axey-2.5-yscroll)*16*scale) --say what
				properprint("another castle!", math.floor(((mapwidth-13.5-xscroll)*16-1)*scale), (axey-1.5-yscroll)*16*scale) --bummer.
			end
		else
			if levelfinishedmisc >= 1 then	
				properprint("thank you mario!", math.floor(((mapwidth-12-xscroll)*16-1)*scale), (axey-4.5-yscroll)*16*scale)
			end
			if levelfinishedmisc >= 2 then
				properprint("your quest is over.", math.floor(((mapwidth-12.5-xscroll)*16-1)*scale), (axey-3-yscroll)*16*scale)
			end

			--todo
			if levelfinishedmisc >= 3 then
				properprint("we present you a new quest.", math.floor(((mapwidth-14.5-xscroll)*16-1)*scale), (axey-2-yscroll)*16*scale)
			end
			if levelfinishedmisc >= 4 then
				properprint("push button b", math.floor(((mapwidth-11-xscroll)*16-1)*scale), (axey-.5-yscroll)*16*scale)
			end
			if levelfinishedmisc == 5 then
				properprint("to play as steve", math.floor(((mapwidth-12-xscroll)*16-1)*scale), (axey+.5-yscroll)*16*scale)
			end
		end
	end
	love.graphics.setColor(1, 1, 1)
	--Panels
	for j, w in pairs(objects["panel"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Fireworks
	for j, w in pairs(fireworks) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Buttons
	for j, w in pairs(objects["button"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Pushbuttons
	for j, w in pairs(objects["pushbutton"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)

	--hardlight bridges
	for j, w in pairs(objects["lightbridgebody"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)

	--lightbridge
	for j, w in pairs(objects["lightbridge"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--laser
	for j, w in pairs(objects["laser"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--laserdetector
	for j, w in pairs(objects["laserdetector"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Groundlights
	for j, w in pairs(objects["groundlight"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Faithplates
	for j, w in pairs(objects["faithplate"]) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--Bubbles
	for j, w in pairs(bubbles) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--miniblocks
	for i, v in pairs(miniblocks) do
		v:draw()
	end

	--emancipateanimations
	for i, v in pairs(emancipateanimations) do
		v:draw()
	end

	--emancipationfizzles
	for i, v in pairs(emancipationfizzles) do
		v:draw()
	end

	--pedestals
	for i, v in pairs(pedestals) do
		v:draw()
	end

end

global function game_draw_objects(...: any): any
	love.graphics.setColor(1, 1, 1)

	--OBJECTS
	for j, w in pairs(objects) do	
		if j ~= "tile" then
			for i, v in pairs(w) do
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

					local portal, portaly = insideportal(v.x, v.y, v.width, v.height)
					local entryX: number
					local entryY: number
					local entryfacing: any
					local exitX: number
					local exitY: number
					local exitfacing: any

					--SCISSOR FOR ENTRY
					if v.customscissor and v.portalable ~= false then
						love.graphics.stencil(function() love.graphics.rectangle("fill", math.floor((v.customscissor[1]-xscroll)*16*scale), math.floor((v.customscissor[2]-.5-yscroll)*16*scale), v.customscissor[3]*16*scale, v.customscissor[4]*16*scale) end, "replace", 1)
						love.graphics.setStencilTest((v.invertedscissor and "equal" or "greater"), 0)
					end

					if v.static == false and v.portalable ~= false then
						if not v.customscissor and portal ~= false and (v.active or v.portaloverride) then
							if portaly == 1 then
								entryX, entryY, entryfacing = portal.x1, portal.y1, portal.facing1
								exitX, exitY, exitfacing = portal.x2, portal.y2, portal.facing2
							else
								entryX, entryY, entryfacing = portal.x2, portal.y2, portal.facing2
								exitX, exitY, exitfacing = portal.x1, portal.y1, portal.facing1
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
						for k = 1, #v.graphic do
							if v.colors[k] then
								love.graphics.setColor(v.colors[k])
							else
								love.graphics.setColor(1, 1, 1)
							end
							love.graphics.draw(v.graphic[k], v.quad, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end
					else
						if v.graphic and v.quad then
							love.graphics.draw(v.graphic, v.quad, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end
					end

					--HATS
					if v.drawhat then
						local offsets = gethatoffset(v.char, v.graphic, v.animationstate, v.runframe, v.jumpframe, v.climbframe, v.swimframe, v.underwater, v.infunnel, v.fireanimationtimer, v.ducking)

						if offsets and #v.hats > 0 then
							local yadd = 0
							for i = 1, #v.hats do
								if v.hats[i] ~= 0 then
									if v.hats[i] == 1 then
										love.graphics.setColor(v.colors[1])
									else
										love.graphics.setColor(1, 1, 1)
									end
									if v.graphic == v.biggraphic or v.animationstate == "grow" then
										love.graphics.draw(bighat[v.hats[i]].graphic, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX - bighat[v.hats[i]].x + offsets[1], v.quadcenterY - bighat[v.hats[i]].y + offsets[2] + yadd)
										yadd = yadd + bighat[v.hats[i]].height
									else
										love.graphics.draw(hat[v.hats[i]].graphic, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX - hat[v.hats[i]].x + offsets[1], v.quadcenterY - hat[v.hats[i]].y + offsets[2] + yadd)
										yadd = yadd + hat[v.hats[i]].height
									end
								end
							end
						end
						love.graphics.setColor(1, 1, 1)
					end

					if type(v.graphic) == "table" then
						if v.graphic[0] then
							love.graphics.setColor(1, 1, 1)
							love.graphics.draw(v.graphic[0], v.quad, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end
						if v.graphic.dot then
							love.graphics.setColor(unpack(v["portal" .. (v.lastportal or 1) .. "color"]))
							love.graphics.draw(v.graphic["dot"], v.quad, math.floor(((v.x-xscroll)*16+v.offsetX)*scale), math.floor(((v.y-yscroll)*16-v.offsetY)*scale), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end	
					end

					--portal duplication
					if v.customscissor and v.portalable ~= false then
						love.graphics.stencil(function() love.graphics.rectangle("fill", math.floor((v.customscissor[1]-xscroll)*16*scale), math.floor((v.customscissor[2]-.5-yscroll)*16*scale), v.customscissor[3]*16*scale, v.customscissor[4]*16*scale) end, "replace", 1)
						love.graphics.setStencilTest((v.invertedscissor and "equal" or "greater"), 0)
					end

					if v.static == false and (v.active or v.portaloverride) and v.portalable ~= false then
						if not v.customscissor and portal ~= false then
							love.graphics.setScissor(unpack(currentscissor))
							local px, py, pw, ph, pr, pad = v.x, v.y, v.width, v.height, v.rotation, v.animationdirection
							px, py, d, d, pr, pad = portalcoords(px, py, 0, 0, pw, ph, pr, pad, entryX, entryY, entryfacing, exitX, exitY, exitfacing)

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
								for k = 1, #v.graphic do
									if v.colors[k] then
										love.graphics.setColor(v.colors[k])
									else
										love.graphics.setColor(1, 1, 1)
									end
									love.graphics.draw(v.graphic[k], v.quad, math.floor(((px-xscroll)*16+v.offsetX)*scale), math.floor(((py-yscroll)*16-v.offsetY)*scale), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
								end
							else
								love.graphics.draw(v.graphic, v.quad, math.ceil(((px-xscroll)*16+v.offsetX)*scale), math.ceil(((py-yscroll)*16-v.offsetY)*scale), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
							end

							--HAAAATS
							if v.drawhat then
								local offsets = gethatoffset(v.char, v.graphic, v.animationstate, v.runframe, v.jumpframe, v.climbframe, v.swimframe, v.underwater, v.infunnel, v.fireanimationtimer, v.ducking)

								if offsets and #v.hats > 0 then
									local yadd = 0
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
								if v.graphic[0] then
									love.graphics.setColor(1, 1, 1)
									love.graphics.draw(v.graphic[0], v.quad, math.floor(((px-xscroll)*16+v.offsetX)*scale), math.floor(((py-yscroll)*16-v.offsetY)*scale), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
								end
								if v.graphic.dot and v.lastportal then
									love.graphics.setColor(unpack(v["portal" .. v.lastportal .. "color"]))
									love.graphics.draw(v.graphic["dot"], v.quad, math.floor(((px-xscroll)*16+v.offsetX)*scale), math.floor(((py-yscroll)*16-v.offsetY)*scale), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
								end
							end
						end
					end
					love.graphics.setScissor(unpack(currentscissor))
						love.graphics.setStencilTest()
				end
			end
		end
	end

end

global function scenedraw(...: any): any
	drawlevel()

	if bdrawui then
		game_draw_hud()
	end

	game_draw_props()
	game_draw_objects()
	game_draw_fx()

	drawforeground()
end

