--[[ game_draw FX / seethrough portals ]]

global function game_draw_fx(...: any): any
	love.graphics.setColor(1, 1, 1)

	--bowser
	for j, w in pairs(objects["bowser"]) do
		w:draw()
	end

	--Geldispensers
	for j, w in pairs(objects["geldispenser"]) do
		w:draw()
	end

	--Cubedispensers
	for j, w in pairs(objects["cubedispenser"]) do
		w:draw()
	end

	--Funnels
	for j, w in pairs(objects["funnel"]) do
		w:draw()
	end

	--Emancipationgrills
	for j, w in pairs(emancipationgrills) do
		w:draw()
	end

	--Doors
	for j, w in pairs(objects["door"]) do
		w:draw()
	end

	--Wallindicators
	for j, w in pairs(objects["wallindicator"]) do
		w:draw()
	end

	--Tiletriggers
	for j, w in pairs(objects["animatedtiletrigger"]) do
		w:draw()
	end

	--Delayers
	for j, w in pairs(objects["delayer"]) do
		w:draw()
	end

	--Walltimers
	for j, w in pairs(objects["walltimer"]) do
		w:draw()
	end

	--Notgates
	for j, w in pairs(objects["notgate"]) do
		w:draw()
	end

	--RSFlipflops
	for j, w in pairs(objects["rsflipflop"]) do
		w:draw()
	end

	--Orgates
	for j, w in pairs(objects["orgate"]) do
		w:draw()
	end

	--Andgates
	for j, w in pairs(objects["andgate"]) do
		w:draw()
	end

	--Musicentities
	for j, w in pairs(objects["musicentity"]) do
		w:draw()
	end

	--Squarewaves
	for j, w in pairs(objects["squarewave"]) do
		w:draw()
	end

	--Squarewaves
	for j, w in pairs(objects["actionblock"]) do
		w:draw()
	end

	--particles
	for j, w in pairs(portalparticles) do
		w:draw()
	end

	love.graphics.setColor(1, 1, 1)

	--portals
	for i, v in pairs(portals) do
		v:draw()
	end		

	love.graphics.setColor(1, 1, 1)

	--COINBLOCKanimation
	for i, v in pairs(coinblockanimations) do
		love.graphics.draw(coinblockanimationimg, coinblockanimationquads[coinblockanimations[i].frame as integer], math.floor((coinblockanimations[i].x - xscroll)*16*scale), math.floor(((coinblockanimations[i].y-yscroll)*16-8)*scale), 0, scale, scale, 4, 54)
	end

	--SCROLLING SCORE
	for i, v in pairs(scrollingscores) do
		if type(scrollingscores[i].i) == "number" then
			properprint2(scrollingscores[i].i, math.floor((scrollingscores[i].x-0.4)*16*scale), math.floor((scrollingscores[i].y-1.5-scrollingscoreheight*(scrollingscores[i].timer/scrollingscoretime))*16*scale))
		elseif scrollingscores[i].i == "1up" then
			love.graphics.draw(oneuptextimage, math.floor((scrollingscores[i].x)*16*scale), math.floor((scrollingscores[i].y-1.5-scrollingscoreheight*(scrollingscores[i].timer/scrollingscoretime))*16*scale), 0, scale, scale)
		end
	end

	--SCROLLING TEXT
	for i, v in pairs(scrollingtexts as {any:Entity}) do
		v:draw()
	end

	--BLOCK DEBRIS
	for i, v in pairs(blockdebristable as {any:Entity}) do
		v:draw()
	end

	local minex, miney, minecox, minecoy = nil as any, nil as any, nil as any, nil as any

	--PORTAL UI STUFF
	if levelfinished == false then
		for pl = 1, players do
			if playerobjs[pl].controlsenabled and playerobjs[pl].t == "portal" and playerobjs[pl].vine == false and (playerobjs[pl].portalsavailable[1] or playerobjs[pl].portalsavailable[2]) then
				local sourcex: number = playerobjs[pl].x+6/16
				local sourcey: number = playerobjs[pl].y+6/16
				local an = playerobjs[pl].pointingangle
				local cox: any = false
				local coy: any = nil
				local side: any = nil
				local tend: any = nil
				local x: any = nil
				local y: any = nil
				cox, coy, side, tend, x, y = traceline(sourcex, sourcey, an)
				local mirror = 1

				local portalpossible: any = true
				if cox == false then
					portalpossible = false
				else
					local _, _, m = getportalposition(1, cox, coy, side, tend, true)
					if m == "mirror" then
						portalpossible = false

						sourcex = playerobjs[pl].x+6/16
						sourcey = playerobjs[pl].y+6/16
						an = playerobjs[pl].pointingangle
						cox = false
						coy = nil
						side = nil
						tend = nil
						x = nil
						y = nil
						cox, coy, side, tend, x, y = traceline(sourcex, sourcey, an)

						for a = 1, portalbouncethreshold do
							if cox then
								local _, _, m2 = getportalposition(1, cox, coy, side, tend, true)
								if m2 == "mirror" then
									mirror = mirror+1
									sourcex = x as number
									sourcey = y as number
									if side == "up" or side == "down" then
										an = math.pi-an
										if an >= math.pi then an = an - math.pi*2 end
									else
										an = -an
									end
									cox, coy, side, tend, x, y = traceline(sourcex, sourcey, an)
									if a == portalbouncethreshold or not cox then
										portalpossible = false
										break
									end
								else
									portalpossible = getportalposition(1, cox, coy, side, tend, true)
									break
								end
							else
								portalpossible = false
								break
							end
						end

					elseif getportalposition(1, cox, coy, side, tend) == false then
						portalpossible = false
					end
				end

				love.graphics.setColor(1, 1, 1, 1)

				local xn = x as number
				local yn = y as number
				local dist = math.sqrt(((xn-xscroll)*16*scale - (sourcex-xscroll)*16*scale)^2 + ((yn-.5-yscroll)*16*scale - (sourcey-.5-yscroll)*16*scale)^2)/16/scale

				for a = 1, mirror do
					local pd = portaldotsdistance-- * (.5+.5*a/(mirror))
					for i = 1, dist/pd+1 do
						if ((i-1+portaldotstimer/portaldotstime)/(dist/pd)) < 1 then
							xn = x as number
							yn = y as number
							local xplus = ((xn-xscroll)*16*scale - (sourcex-xscroll)*16*scale)*((i-1+portaldotstimer/portaldotstime)/(dist/pd))
							local yplus = ((yn-.5-yscroll)*16*scale - (sourcey-.5-yscroll)*16*scale)*((i-1+portaldotstimer/portaldotstime)/(dist/pd))

							local dotx = (sourcex-xscroll)*16*scale + xplus
							local doty = (sourcey-.5-yscroll)*16*scale + yplus

							local radius = math.sqrt(xplus^2 + yplus^2)/scale

							local alpha: number = 1
							if radius < portaldotsouter and a == 1 then
								alpha = (radius-portaldotsinner) * (255/(portaldotsouter-portaldotsinner))
								if alpha < 0 then
									alpha = 0
								end
								alpha = alpha/255
							end


							if portalpossible == false then
								love.graphics.setColor(1, 0, 0, alpha)
							else
								love.graphics.setColor(0, 1, 0, alpha)
							end

							love.graphics.draw(portaldotimg, math.floor(dotx-0.25*scale), math.floor(doty-0.25*scale), 0, scale, scale)
						end
					end

					if cox then
						local _, _, m3 = getportalposition(1, cox, coy, side, tend, true)
						if m3 == "mirror" then
							sourcex = x as number
							sourcey = y as number
							if side == "up" or side == "down" then
								an = math.pi-an
								if an >= math.pi then an = an - math.pi*2 end
							else
								an = -an
							end
							cox, coy, side, tend, x, y = traceline(sourcex, sourcey, an)
						end
					end
					xn = x as number
					yn = y as number
					dist = math.sqrt(((xn-xscroll)*16*scale - (sourcex-xscroll)*16*scale)^2 + ((yn-.5-yscroll)*16*scale - (sourcey-.5-yscroll)*16*scale)^2)/16/scale
				end

				love.graphics.setColor(1, 1, 1, 1)

				if cox ~= false then
					if portalpossible == false then
						love.graphics.setColor(1, 0, 0)
					else
						love.graphics.setColor(0, 1, 0)
					end

					local rotation: number = 0
					if side == "right" then
						rotation = math.pi/2
					elseif side == "down" then
						rotation = math.pi
					elseif side == "left" then
						rotation = math.pi/2*3
					end
					love.graphics.draw(portalcrosshairimg, math.floor(((x as number)-xscroll)*16*scale), math.floor(((y as number)-.5-yscroll)*16*scale), rotation, scale, scale, 4, 8)
				end
			end
		end
	end

	--Portal projectile
	for i, v in pairs(portalprojectiles) do
		v:draw()
	end

	love.graphics.setColor(1, 1, 1)

	--nothing to see here
	for i, v in pairs(rainbooms) do
		v:draw()
	end

end

global function game_draw_seethrough_portals(...: any): any
	if not scenecanvas then
		scenecanvas = love.graphics.newCanvas()
	end
	
	local pl = playerobjs[1]
	(scenecanvas as Canvas):clear()
	love.graphics.setCanvas{scenecanvas as Canvas, stencil=true}
	scenedraw()
	love.graphics.setCanvas{completecanvas as Canvas, stencil=true}
	love.graphics.draw(scenecanvas as Canvas, 0, 0)
	
	if firstpersonview and firstpersonrotate then
		local xtranslate = width/2*16*scale
		local ytranslate = height/2*16*scale
		love.graphics.translate(xtranslate, ytranslate)
		love.graphics.rotate(-playerobjs[1].rotation/2)
		love.graphics.translate(-xtranslate, -ytranslate)
	end
	
	currentscissor = {0, 0,width*16*scale, height*16*scale}
	
	for k, v in pairs(portals) do
		local pv = v as Dyn
		if v.x1 and v.x2 then
			for i = 1, 2 do
				local otheri = 1
				if i == 1 then
					otheri = 2
				end
			
				local x = pv["x" .. i] as number
				local y = pv["y" .. i] as number
				local facing = pv["facing" .. i] as string
				local x2 = pv["x" .. otheri] as number
				local y2 = pv["y" .. otheri] as number
				local facing2 = pv["facing" .. otheri] as string
				local pass = false
				
				if facing == "up" then
					pass = pl.y+pl.height/2 < y-1
				elseif facing == "right" then
					pass = pl.x+pl.width/2 > x
				elseif facing == "down" then
					pass = pl.y+pl.height/2 > y
				elseif facing == "left" then
					pass = pl.x+pl.width/2 < x-1
				end
				
				if pass then
					local p1x: number = 0
					local p1y: number = 0
					local p2x: number = 0
					local p2y: number = 0
					local p3x: number = 0
					local p3y: number = 0
					local p4x: number = 0
					local p4y: number = 0
					if facing == "right" then
						p1x, p1y = (x-xscroll), (y-yscroll-1.5)
						p2x, p2y = p1x, p1y+2
					elseif facing == "down" then
						p1x, p1y = (x-xscroll-2), (y-yscroll-.5)
						p2x, p2y = p1x+2, p1y
					elseif facing == "left" then
						p1x, p1y = (x-xscroll-1), (y-yscroll-2.5)
						p2x, p2y = p1x, p1y+2
					elseif facing == "up" then
						p1x, p1y = (x-xscroll-1), (y-yscroll-1.5)
						p2x, p2y = p1x+2, p1y
					end
					
					local r1 = math.atan2((pl.x+pl.width/2-xscroll)-p1x, (pl.y+pl.height/2-yscroll-.5)-p1y)
					local r2 = math.atan2((pl.x+pl.width/2-xscroll)-p2x, (pl.y+pl.height/2-yscroll-.5)-p2y)
					
					local limit = (width+height)*100
					
					p3x = -math.sin(r1)*limit+p1x
					p3y = -math.cos(r1)*limit+p1y
					
					p4x = -math.sin(r2)*limit+p2x
					p4y = -math.cos(r2)*limit+p2y
					
					
					--Calculate the middle of the portals
					local tx: number = 0
					local ty: number = 0
					local r1b: number = 0
					if facing == "right" then
						tx, ty = (x-xscroll), (y-yscroll-.5)
						r1b = math.pi/2
					elseif facing == "down" then
						tx, ty = (x-xscroll-1), (y-yscroll-.5)
						r1b = math.pi
					elseif facing == "left" then
						tx, ty = (x-xscroll-1), (y-yscroll-1.5)
						r1b = math.pi*1.5
					elseif facing == "up" then
						tx, ty = (x-xscroll), (y-yscroll-1.5)
						r1b = 0
					end
					
					local ox: number = 0
					local oy: number = 0
					if facing2 == "right" then
						ox, oy = (x2-xscroll), (y2-yscroll-.5)
						r2 = math.pi/2
					elseif facing2 == "down" then
						ox, oy = (x2-xscroll-1), (y2-yscroll-.5)
						r2 = math.pi
					elseif facing2 == "left" then
						ox, oy = (x2-xscroll-1), (y2-yscroll-1.5)
						r2 = math.pi*1.5
					elseif facing2 == "up" then
						ox, oy = (x2-xscroll), (y2-yscroll-1.5)
						r2 = 0
					end
					
					local offx, offy = tx-ox, ty-oy
					
					local a = r2-r1b
					
					local xscale, yscale = 1, 1
					
					if facing == facing2 then
						if facing == "left" or facing == "right" then
							xscale = -xscale
						else
							yscale = -yscale
						end
					end
					
					if (facing == "left" and facing2 == "right") or (facing == "right" and facing2 == "left") or (facing == "up" and facing2 == "down") or (facing == "down" and facing2 == "up") then
						a = a - math.pi
					end
					
					love.graphics.stencil(function()
						love.graphics.polygon("fill", p1x*16*scale, p1y*16*scale, p2x*16*scale, p2y*16*scale, p4x*16*scale, p4y*16*scale, p3x*16*scale, p3y*16*scale)
					end, "replace", 1) --feels like javascript
					love.graphics.setStencilTest("greater", 0)
					
					love.graphics.setColor(unpack(background as {number}))
					love.graphics.rectangle("fill", 0, 0, width*16*scale, height*16*scale)
					
					
					love.graphics.setColor(1, 1, 1)
					love.graphics.draw(scenecanvas as Canvas, (offx+ox)*16*scale, (offy+oy)*16*scale, a, xscale, yscale, ox*16*scale, oy*16*scale)
					
					local r, g, b = unpack(pv["portal" .. i .. "color"] as {number})
					--love.graphics.setColor(r, g, b, 0.6)
					--love.graphics.rectangle("fill", 0, 0, width*16*scale, height*16*scale)
				
						love.graphics.setStencilTest()

					love.graphics.setColor(r, g, b)
					love.graphics.line(p1x*16*scale, p1y*16*scale, p3x*16*scale, p3y*16*scale)
					love.graphics.line(p2x*16*scale, p2y*16*scale, p4x*16*scale, p4y*16*scale)
				end
			end
		end
	end
end

