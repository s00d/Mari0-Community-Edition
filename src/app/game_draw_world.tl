--[[ game_draw world/scene phases ]]

local DRAW_PROPS_GROUPS = {
	"vine",
	"platform",
	"scaffold",
	"seesawplatform",
	"spring",
	"belt",
	"panel",
	"button",
	"pushbutton",
	"lightbridgebody",
	"lightbridge",
	"laser",
	"laserdetector",
	"groundlight",
	"faithplate",
	"blackhole",
} as {string}

local function level_dims(y_edge_extra: number): number, number
	local xtodraw: number
	if session.mapwidth < width+1 then
		xtodraw = math.ceil(session.mapwidth)
	else
		if session.mapwidth > width and session.xscroll < session.mapwidth-width then
			xtodraw = math.ceil(width+1)
		else
			xtodraw = math.ceil(width)
		end
	end

	local ytodraw: number
	if session.mapheight < height+1 then
		ytodraw = math.ceil(session.mapheight)
	else
		if session.mapheight > height and session.yscroll < session.mapheight-height then
			ytodraw = height + y_edge_extra
		else
			ytodraw = height
		end
	end
	return xtodraw, ytodraw
end

global function level_view_dims(): number, number
	return level_dims(2)
end

global function level_foreground_dims(): number, number
	return level_dims(1)
end

global function draw_castle_flag()
	if levelfinished and levelfinishtype == "flag" and not custombackground then
		love.graphics.draw(castleflagimg, wpx((flagx as number) + 6), wpy(flagy - 7 + 10/16) + (castleflagy - flagy) * 16, 0, 1, 1)
	end
end

-- Full-map tile spritebatches: world coords + scroll offset (see world.tile_spritebatch).
global function draw_tile_spritebatches()
	tile_spritebatch_draw_bg()
end

global function draw_tile_spritebatches_foreground()
	tile_spritebatch_draw_fg()
end

global function drawlevel_tiles(xtodraw: any, ytodraw: any)
	
	-- Dynamic / non-batched tiles (world_camera attached by scenedraw)
	local tile_y_off = mapmode_tile_y_off()
	local lmap = session.map as {number:{number:MapCell}}
	
	local flooredxscroll: number = 0
	if session.xscroll >= 0 then
		flooredxscroll = math.floor(session.xscroll)
	else
		flooredxscroll = math.ceil(session.xscroll)
	end
	
	local flooredyscroll: number = 0
	if session.yscroll >= 0 then
		flooredyscroll = math.floor(session.yscroll)
	else
		flooredyscroll = math.ceil(session.yscroll)
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
				local draw_x = tile_draw_x(cox - 1)
				local draw_y = tile_draw_y(coy - 1 - bounceyoffset, tile_y_off)
				if not level_mapmode and tq and tq:getproperty("coinblock", cox, coy) and tq:getproperty("invisible", cox, coy) == false then --coinblock
					love.graphics.draw(coinblockimg, coinblockquads[spriteset][coinframe], draw_x, draw_y, 0, 1, 1)
				elseif not level_mapmode and session.coinmap[cox] and session.coinmap[cox][coy] then --coin
					love.graphics.draw(coinimg, coinquads[spriteset][coinframe], draw_x, draw_y, 0, 1, 1)
				elseif tq and (bounceyoffset ~= 0 or (tilenumber as number) > 10000) then
					if not tq:getproperty("invisible", cox, coy) then
						love.graphics.draw(tq.image, tq:quad(flooredxscroll+x, flooredyscroll+y), draw_x, draw_y, 0, 1, 1)
					end
				end
				
				if t.gelSides then
					draw_tile_gel_overlays(t.gelSides, tile_draw_x(cox - .5), tile_draw_y(coy - 1 - bounceyoffset, tile_y_off), 8, 8)
				end
				
				if editormode then
					if tq and tq:getproperty("invisible", cox, coy) and t[1] ~= 1 then
						love.graphics.draw(tq.image, tq:quad(), draw_x, tile_draw_y(coy - 1, tile_y_off), 0, 1, 1)
					end
					
					if #t > 1 and t[2] ~= "link" then
						tilenumber = t[2]
						love.graphics.setColor(1, 1, 1, 0.6)
						if tablecontains(enemies, tilenumber) then --ENEMY PREVIEW THING
							local v = enemiesdata[tilenumber]
							if v and v.graphic and v.quad then
								local xoff, yoff = (((v.spawnoffsetx or 0)+v.width/2-.5)*16 - v.offsetX + v.quadcenterX), (((v.spawnoffsety or 0)-v.height+1)*16-v.offsetY - v.quadcenterY)
								
								local mx, my = getMouseTile(mouse.getX(), mouse.getY()+8*scale)
								local alpha = 0.6
								if x == mx and y == my then
									alpha = 1
								end
								
								love.graphics.setColor(1, 0, 0, alpha)
								love.graphics.rectangle("fill", draw_x, tile_draw_y(coy - 1, tile_y_off), 16, 16)
								love.graphics.setColor(1, 1, 1, alpha)
								love.graphics.draw(v.graphic, v.quad, draw_x + xoff, tile_draw_y(coy - 1, yoff), 0, 1, 1)
							end
						else
							local eq = entityquads[tilenumber as number]
							if eq and eq.image and eq.quad then
								love.graphics.draw(eq.image, eq.quad, draw_x, tile_draw_y(coy - 1, tile_y_off), 0, 1, 1)
							end
						end
						love.graphics.setColor(1, 1, 1, 1)
					end
					
					local mcell = session.map[x] and session.map[x][y]
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
						local wx = flooredxscroll + x - .5
						local wy = flooredyscroll + y - 1.2
						if dir == "down" then
							love.graphics.line(tile_draw_x(wx), tile_draw_y(wy, 0), tile_draw_x(wx), tile_draw_y(wy + (dist as number), 0))
						elseif dir == "left" then
							love.graphics.line(tile_draw_x(wx), tile_draw_y(wy, 0), tile_draw_x(wx - (dist as number)), tile_draw_y(wy, 0))
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

	--custom background
	if custombackground then
		if custombackground == true then
			local xscroll = session.xscroll / (scrollfactor + 1)
			if reversescrollfactor() == 1 then
				xscroll = 0
			end
			for y = 1, math.ceil(height/14)+1 do
				for x = 1, math.ceil(width)+1 do
					love.graphics.draw(portalbackgroundimg, math.floor((x-1)*16*scale) - math.floor(math.fmod(xscroll, 1)*16*scale), math.floor(((y-1)*14)*16*scale) - math.floor(math.fmod(session.yscroll, 14)*16*scale), 0, scale, scale)
				end
			end
		else
			if custombackgroundimg[custombackground as string] then
				for i = #custombackgroundimg[custombackground as string], 1, -1  do
					local xscroll = session.xscroll / (i * scrollfactor + 1)
					if reversescrollfactor() == 1 then
						xscroll = 0
					end
					
					local yscroll = session.yscroll / (i * scrollfactor + 1)
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
end

global function drawforeground()
	-- Dynamic foreground tiles (batched tiles: draw_tile_spritebatches_foreground)
	local tile_y_off = mapmode_tile_y_off()
	
	--ANY NON STATIC BLOCKS AND STUFF.
	local lmap = session.map as {number:{number:MapCell}}
	
	local xtodraw, ytodraw = level_foreground_dims()
	
	local flooredxscroll: number = 0
	if session.xscroll >= 0 then
		flooredxscroll = math.floor(session.xscroll)
	else
		flooredxscroll = math.ceil(session.xscroll)
	end
	
	local flooredyscroll: number = 0
	if session.yscroll >= 0 then
		flooredyscroll = math.floor(session.yscroll)
	else
		flooredyscroll = math.ceil(session.yscroll)
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
				local draw_x = tile_draw_x(cox - 1)
				local draw_y = tile_draw_y(coy - 1, tile_y_off)
				
				if tq and tq:getproperty("foreground", cox, coy) then
					if tq:getproperty("coinblock", cox, coy) and not tq:getproperty("invisible", cox, coy) then --coinblock
						love.graphics.draw(coinblockimg, coinblockquads[spriteset][coinframe], draw_x, draw_y, 0, 1, 1)
					elseif session.coinmap[x] and session.coinmap[x][y] then --coin
						love.graphics.draw(coinimg, coinquads[spriteset][coinframe], draw_x, draw_y, 0, 1, 1)
					elseif (tilenumber as number) > 10000 then
						if not tq:getproperty("invisible", cox, coy) then
							love.graphics.draw(tq.image, tq:quad(flooredxscroll+x, flooredyscroll+y), draw_x, draw_y, 0, 1, 1)
						end
					end
					
					if t.gelSides then
						draw_tile_gel_overlays(t.gelSides, tile_draw_x(cox - .5), tile_draw_y(coy - 1, tile_y_off), 8, 8)
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
				
					local xscroll = session.xscroll * (i * fscrollfactor + 1)
					if reversefscrollfactor() == 1 then
						xscroll = 0
					end
					
					local yscroll = session.yscroll / (i * fscrollfactor + 1)
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
	for i = 1, #DRAW_PROPS_GROUPS do
		obj_draw_group(DRAW_PROPS_GROUPS[i])
	end

	--warpzonetext
	if displaywarpzonetext then
		properprint("welcome to warp zone!", tile_draw_x(session.mapwidth - 14 - 1/16), tile_draw_y(5.5, 0), world_draw_scale())
		for _, v in ipairs(warpzonenumbers as {any}) do
			properprint((v as {any})[3], tile_draw_x((v as {any})[1] as number - 1 - 9/16), tile_draw_y((v as {any})[2] as number - 3, 0), world_draw_scale())
		end
	end

	love.graphics.setColor(1, 1, 1)
	--seesaws
	for _, w in pairs(seesaws) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)
	--flag
	if flagx then
		local flag_y_off = mapmode_tile_y_off()
		love.graphics.draw(flagimg, tile_draw_x(flagimgx - 1), tile_draw_y(flagimgy, flag_y_off), 0, world_draw_scale(), world_draw_scale())
		if levelfinishtype == "flag" then
			properprint2(flagscore, tile_draw_x(flagimgx + 4/16), tile_draw_y(14 - flagimgy + (flagy - 13) * 2, flag_y_off), 0)
		end
	end

	love.graphics.setColor(1, 1, 1)
	--axe
	if axex then
		local axe_x = axex as number
		local axe_y = axey as number
		love.graphics.draw(axeimg, axequads[coinframe], tile_draw_x(axe_x - 1), tile_draw_y(axe_y - 1.5, 0), 0, world_draw_scale(), world_draw_scale())
	end

	love.graphics.setColor(1, 1, 1)
	--levelfinish text and toad
	if levelfinished and levelfinishtype == "castle" then
		local axe_y = axey as number
		if marioworld ~= 8 then
			love.graphics.draw(toadimg, tile_draw_x(session.mapwidth - 7), tile_draw_y(axe_y + 2.0625, 0), 0, world_draw_scale(), world_draw_scale())
		else
			love.graphics.draw(peachimg, tile_draw_x(session.mapwidth - 7), tile_draw_y(axe_y + 2.0625, 0), 0, world_draw_scale(), world_draw_scale())
		end

		if levelfinishedmisc2 == 1 then
			if levelfinishedmisc >= 1 then
				properprint("thank you " .. characters[mariocharacter[1]].name .. "!", tile_draw_x(session.mapwidth - 12) - world_draw_scale(), tile_draw_y(axe_y - 4.5, 0), world_draw_scale())
			end
			if levelfinishedmisc == 2 then
				properprint("but our princess is in", tile_draw_x(session.mapwidth - 13.5) - world_draw_scale(), tile_draw_y(axe_y - 2.5, 0), world_draw_scale())
				properprint("another castle!", tile_draw_x(session.mapwidth - 13.5) - world_draw_scale(), tile_draw_y(axe_y - 1.5, 0), world_draw_scale())
			end
		else
			if levelfinishedmisc >= 1 then	
				properprint("thank you mario!", tile_draw_x(session.mapwidth - 12) - world_draw_scale(), tile_draw_y(axe_y - 4.5, 0), world_draw_scale())
			end
			if levelfinishedmisc >= 2 then
				properprint("your quest is over.", tile_draw_x(session.mapwidth - 12.5) - world_draw_scale(), tile_draw_y(axe_y - 3, 0), world_draw_scale())
			end

			if levelfinishedmisc >= 3 then
				properprint("we present you a new quest.", tile_draw_x(session.mapwidth - 14.5) - world_draw_scale(), tile_draw_y(axe_y - 2, 0), world_draw_scale())
			end
			if levelfinishedmisc >= 4 then
				properprint("push button b", tile_draw_x(session.mapwidth - 11) - world_draw_scale(), tile_draw_y(axe_y - .5, 0), world_draw_scale())
			end
			if levelfinishedmisc == 5 then
				properprint("to play as steve", tile_draw_x(session.mapwidth - 12) - world_draw_scale(), tile_draw_y(axe_y + .5, 0), world_draw_scale())
			end
		end
	end
	love.graphics.setColor(1, 1, 1)
	--Fireworks
	for _, w in pairs(fireworks) do
		w:draw()
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

global function draw_world_tiles()
	local xtodraw, ytodraw = level_view_dims()
	draw_tile_spritebatches()
	world_camera_attach()
	drawlevel_tiles(xtodraw, ytodraw)
	world_camera_detach()
end

global function draw_world_foreground()
	world_camera_attach()
	drawforeground()
	world_camera_detach()
	draw_tile_spritebatches_foreground()
end

global function game_draw_objects()
	love.graphics.setColor(1, 1, 1)

	--OBJECTS
	for j, w in pairs(session.objects) do	
		if j ~= "tile" then
			for _, v in pairs(w) do
				if v.drawable and v.graphic and v.quad then
					love.graphics.setStencilMode()
					love.graphics.setScissor()
					love.graphics.setColor(1, 1, 1)
					local dirscale: number
					local masked = false

					if j == "player" then
						if (v.portalsavailable[1] or v.portalsavailable[2]) then
							if (v.pointingangle+math.pi*2 > -v.rotation+math.pi*2 and (not (v.pointingangle > -v.rotation+math.pi))) or v.pointingangle < -v.rotation-math.pi then
								dirscale = world_flip_scale(-1)
							else
								dirscale = world_flip_scale(1)
							end
						else
							if v.animationdirection == "right" then
								dirscale = world_flip_scale(1)
							else
								dirscale = world_flip_scale(-1)
							end
						end

						if bigmario then
							dirscale = dirscale * scalefactor
						end
					else
						if v.animationdirection == "left" then
							dirscale = world_flip_scale(-1)
						else
							dirscale = world_flip_scale(1)
						end
					end

					if v.mirror then
						dirscale = -dirscale
					end

					local horscale = world_flip_scale(1)
					if v.shot or v.upsidedown then
						horscale = world_flip_scale(-1)
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
						begin_mask(function() love.graphics.rectangle("fill", tile_draw_x((cs as {number})[1] as number), tile_draw_y((cs as {number})[2] as number - 0.5, 0), (cs[3] as number)*16, (cs[4] as number)*16) end, v.invertedscissor as boolean)
						masked = true
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
								love.graphics.setScissor(world_screen_x(entryX), world_screen_y(entryY - 3.5), 64*scale, 96*scale)
							elseif entryfacing == "left" then
								love.graphics.setScissor(world_screen_x(entryX - 5), world_screen_y(entryY - 4.5), 64*scale, 96*scale)
							elseif entryfacing == "up" then
								love.graphics.setScissor(world_screen_x(entryX - 3), world_screen_y(entryY - 5.5), 96*scale, 64*scale)
							elseif entryfacing == "down" then
								love.graphics.setScissor(world_screen_x(entryX - 4), world_screen_y(entryY - 0.5), 96*scale, 64*scale)
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
							love.graphics.draw(g[k], v.quad, entity_draw_x(v.x, v.offsetX), entity_draw_y(v.y, v.offsetY), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end
					else
						if v.graphic and v.quad then
							love.graphics.draw(v.graphic, v.quad, entity_draw_x(v.x, v.offsetX), entity_draw_y(v.y, v.offsetY), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
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
										love.graphics.draw(bighat[hats[i]].graphic, entity_draw_x(v.x, v.offsetX), entity_draw_y(v.y, v.offsetY), v.rotation, dirscale, horscale, v.quadcenterX - bighat[hats[i]].x + offsets[1], v.quadcenterY - bighat[hats[i]].y + offsets[2] + yadd)
										yadd = yadd + bighat[hats[i]].height
									else
										love.graphics.draw(hat[hats[i]].graphic, entity_draw_x(v.x, v.offsetX), entity_draw_y(v.y, v.offsetY), v.rotation, dirscale, horscale, v.quadcenterX - hat[hats[i]].x + offsets[1], v.quadcenterY - hat[hats[i]].y + offsets[2] + yadd)
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
							love.graphics.draw(gdot[0], v.quad, entity_draw_x(v.x, v.offsetX), entity_draw_y(v.y, v.offsetY), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end
						if gdot.dot then
							love.graphics.setColor(unpack((v as {string:any})["portal" .. (v.lastportal or 1) .. "color"] as {any}))
							love.graphics.draw(gdot["dot"], v.quad, entity_draw_x(v.x, v.offsetX), entity_draw_y(v.y, v.offsetY), v.rotation, dirscale, horscale, v.quadcenterX, v.quadcenterY)
						end	
					end

					--portal duplication
					if v.customscissor and v.portalable ~= false then
						if masked then
							end_mask()
						end
						begin_mask(function() love.graphics.rectangle("fill", tile_draw_x((v.customscissor as {number})[1]), tile_draw_y((v.customscissor as {number})[2] - 0.5, 0), (v.customscissor as {number})[3]*16, (v.customscissor as {number})[4]*16) end, v.invertedscissor as boolean)
						masked = true
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

							horscale = world_flip_scale(1)
							if v.shot or v.upsidedown then
								horscale = world_flip_scale(-1)
							end

							if exitfacing == "right" then
								love.graphics.setScissor(world_screen_x(exitX), world_screen_y(exitY - 3.5), 64*scale, 96*scale)
							elseif exitfacing == "left" then
								love.graphics.setScissor(world_screen_x(exitX - 5), world_screen_y(exitY - 4.5), 64*scale, 96*scale)
							elseif exitfacing == "up" then
								love.graphics.setScissor(world_screen_x(exitX - 3), world_screen_y(exitY - 5.5), 96*scale, 64*scale)
							elseif exitfacing == "down" then
								love.graphics.setScissor(world_screen_x(exitX - 4), world_screen_y(exitY - 0.5), 96*scale, 64*scale)
							end

							if type(v.graphic) == "table" then
								for k = 1, #(v.graphic as {any}) do
									if (v.colors as {any})[k] then
										love.graphics.setColor(unpack((v.colors as {any})[k] as {any}))
									else
										love.graphics.setColor(1, 1, 1)
									end
									love.graphics.draw((v.graphic as {any})[k], v.quad, entity_draw_x(px, v.offsetX), entity_draw_y(py, v.offsetY), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
								end
							else
								love.graphics.draw(v.graphic, v.quad, entity_draw_x(px, v.offsetX), entity_draw_y(py, v.offsetY), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
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
												love.graphics.draw(bighat[v.hats[i]].graphic, entity_draw_x(px, v.offsetX), entity_draw_y(py, v.offsetY), pr, dirscale, horscale, v.quadcenterX - bighat[v.hats[i]].x + offsets[1], v.quadcenterY - bighat[v.hats[i]].y + offsets[2] + yadd)
												yadd = yadd + bighat[v.hats[i]].height
											else
												love.graphics.draw(hat[v.hats[i]].graphic, entity_draw_x(px, v.offsetX), entity_draw_y(py, v.offsetY), pr, dirscale, horscale, v.quadcenterX - hat[v.hats[i]].x + offsets[1], v.quadcenterY - hat[v.hats[i]].y + offsets[2] + yadd)
												yadd = yadd + hat[v.hats[i]].height
											end
										end
									end
								end
							end

							if type(v.graphic) == "table" then
								if (v.graphic as {any})[0] then
									love.graphics.setColor(1, 1, 1)
									love.graphics.draw((v.graphic as {any})[0], v.quad, entity_draw_x(px, v.offsetX), entity_draw_y(py, v.offsetY), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
								end
								if (v.graphic as {string:any}).dot and v.lastportal then
									love.graphics.setColor(unpack((v as {string:any})["portal" .. v.lastportal .. "color"] as {any}))
									love.graphics.draw((v.graphic as {string:any})["dot"], v.quad, entity_draw_x(px, v.offsetX), entity_draw_y(py, v.offsetY), pr, dirscale, horscale, v.quadcenterX, v.quadcenterY)
								end
							end
						end
					end
					love.graphics.setScissor((currentscissor as {number})[1], (currentscissor as {number})[2], (currentscissor as {number})[3], (currentscissor as {number})[4])
					if masked then
						end_mask()
					end
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

	local xtodraw, ytodraw = level_view_dims()
	drawlevel()
	draw_tile_spritebatches()
	world_camera_attach()
	draw_castle_flag()
	drawlevel_tiles(xtodraw, ytodraw)
	game_draw_props()
	game_draw_objects()
	game_draw_fx()
	drawforeground()
	world_camera_detach()
	draw_tile_spritebatches_foreground()
	world_camera_attach()
	love.graphics.setColor(1, 1, 1)
	for _, w in pairs(itemanimations) do
		w:draw()
	end
	for _, w in pairs(textentities) do
		w:draw()
	end
	world_camera_detach()

	if level_mapmode then
		love.graphics.pop()
	end

	if bdrawui then
		game_draw_hud()
	end
end

