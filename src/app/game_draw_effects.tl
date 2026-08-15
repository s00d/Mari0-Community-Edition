--[[ game_draw FX / seethrough portals ]]

local DRAW_FX_GROUPS = {
	"bowser",
	"geldispenser",
	"cubedispenser",
	"funnel",
	"gatedoor",
	"abilitypickup",
	"door",
	"wallindicator",
	"animatedtiletrigger",
	"delayer",
	"walltimer",
	"notgate",
	"rsflipflop",
	"orgate",
	"andgate",
	"musicentity",
	"squarewave",
	"actionblock",
} as {string}

global function game_draw_fx()
	love.graphics.setColor(1, 1, 1)
	for i = 1, #DRAW_FX_GROUPS do
		obj_draw_group(DRAW_FX_GROUPS[i])
	end

	--Emancipationgrills
	for _, w in pairs(emancipationgrills) do
		w:draw()
	end

	--particles
	for _, w in pairs(portalparticles) do
		if onscreen(w.x, w.y, 0.5, 0.5) then
			w:draw()
		end
	end

	love.graphics.setColor(1, 1, 1)

	--portals
	for _, v in pairs(session.portals) do
		v:draw()
	end		

	love.graphics.setColor(1, 1, 1)

	--COINBLOCKanimation
	for i, _ in pairs(coinblockanimations) do
		local cba = coinblockanimations[i]
		local q = coinblockanimationquads[cba.frame as integer]
		if q then
			love.graphics.draw(
				coinblockanimationimg,
				q,
				tile_draw_x(cba.x as number),
				tile_draw_y(cba.y as number, -8),
				0,
				world_draw_scale(),
				world_draw_scale(),
				4,
				54
			)
		end
	end

	--SCROLLING SCORE
	for i, _ in pairs(scrollingscores) do
		local ss = scrollingscores[i]
		local sy = (ss.y as number) - 1.5 - scrollingscoreheight * ((ss.timer as number) / scrollingscoretime)
		if type(ss.i) == "number" then
			properprint2(ss.i, tile_draw_x((ss.x as number) - 0.4), tile_draw_y(sy, 0))
		elseif ss.i == "1up" then
			love.graphics.draw(oneuptextimage, tile_draw_x(ss.x as number), tile_draw_y(sy, 0), 0, world_draw_scale(), world_draw_scale())
		end
	end

	--SCROLLING TEXT
	for _, v in pairs(scrollingtexts as {any:Entity}) do
		v:draw()
	end

	--BLOCK DEBRIS
	for _, v in pairs(blockdebristable as {any:Entity}) do
		if onscreen(v.x, v.y, 0.5, 0.5) then
			v:draw()
		end
	end

	local _: number|nil
	local _: number|nil
	local _: number|nil
	local _: number|nil = nil, nil, nil, nil

	--PORTAL UI STUFF
	if levelfinished == false then
		for pl = 1, players do
			local curw = Weapons and Weapons.current(session.playerobjs[pl])
			local portal_equipped = (not Weapons) or (curw and curw.id == "portal")
			if session.playerobjs[pl].controlsenabled and portal_equipped and session.playerobjs[pl].vine == false and session.playerobjs[pl].grapple == false and (session.playerobjs[pl].portalsavailable[1] or session.playerobjs[pl].portalsavailable[2]) then
				local sourcex: number = session.playerobjs[pl].x+6/16
				local sourcey: number = session.playerobjs[pl].y+6/16
				local an = session.playerobjs[pl].pointingangle
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

						sourcex = session.playerobjs[pl].x+6/16
						sourcey = session.playerobjs[pl].y+6/16
						an = session.playerobjs[pl].pointingangle
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

				local draw_scale = world_draw_scale()
				local xn = x as number
				local yn = y as number
				local dist = math.sqrt((xn - sourcex)^2 + (yn - sourcey)^2)

				for a = 1, mirror do
					local pd = portaldotsdistance-- * (.5+.5*a/(mirror))
					for i = 1, dist/pd+1 do
						if ((i-1+portaldotstimer/portaldotstime)/(dist/pd)) < 1 then
							xn = x as number
							yn = y as number
							local t = (i-1+portaldotstimer/portaldotstime)/(dist/pd)
							local sx = entity_draw_x(sourcex, 0)
							local sy = entity_draw_y(sourcey, 8)
							local ex = entity_draw_x(xn, 0)
							local ey = entity_draw_y(yn, 8)
							local dotx = sx + (ex - sx) * t
							local doty = sy + (ey - sy) * t

							local radius = math.sqrt((dotx - sx)^2 + (doty - sy)^2) / draw_scale

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

							love.graphics.draw(portaldotimg, math.floor(dotx-0.25*draw_scale), math.floor(doty-0.25*draw_scale), 0, draw_scale, draw_scale)
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
					dist = math.sqrt((xn - sourcex)^2 + (yn - sourcey)^2)
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
					love.graphics.draw(portalcrosshairimg, entity_draw_x(x as number, 0), entity_draw_y(y as number, 8), rotation, draw_scale, draw_scale, 4, 8)
				end
			end
		end
	end

	--Portal projectile
	for _, v in pairs(portalprojectiles) do
		v:draw()
	end

	love.graphics.setColor(1, 1, 1)

	-- Gravity-gun beam (and any weapon overlays)
	if Weapons then
		for pl = 1, players do
			if session.playerobjs[pl] and not session.playerobjs[pl].dead then
				Weapons.draw(session.playerobjs[pl])
			end
		end
	end

	--nothing to see here
	for _, v in pairs(rainbooms) do
		v:draw()
	end

end

global function game_draw_seethrough_portals()
	if not scenecanvas then
		scenecanvas = love.graphics.newCanvas()
	end
	
	local pl = session.playerobjs[1]
	(scenecanvas as Canvas):clear()
	love.graphics.setCanvas{scenecanvas as Canvas, depthstencil=true}
	scenedraw()
	love.graphics.setCanvas{completecanvas as Canvas, depthstencil=true}
	love.graphics.draw(scenecanvas as Canvas, 0, 0)
	
	if firstpersonview and firstpersonrotate then
		local xtranslate = width/2*16*scale
		local ytranslate = height/2*16*scale
		love.graphics.translate(xtranslate, ytranslate)
		love.graphics.rotate(-session.playerobjs[1].rotation/2)
		love.graphics.translate(-xtranslate, -ytranslate)
	end
	
	currentscissor = {0, 0,width*16*scale, height*16*scale}
	
	for _, v in pairs(session.portals) do
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
						p1x, p1y = (x-session.xscroll), (y-session.yscroll-1.5)
						p2x, p2y = p1x, p1y+2
					elseif facing == "down" then
						p1x, p1y = (x-session.xscroll-2), (y-session.yscroll-.5)
						p2x, p2y = p1x+2, p1y
					elseif facing == "left" then
						p1x, p1y = (x-session.xscroll-1), (y-session.yscroll-2.5)
						p2x, p2y = p1x, p1y+2
					elseif facing == "up" then
						p1x, p1y = (x-session.xscroll-1), (y-session.yscroll-1.5)
						p2x, p2y = p1x+2, p1y
					end
					
					local r1 = math.atan2((pl.x+pl.width/2-session.xscroll)-p1x, (pl.y+pl.height/2-session.yscroll-.5)-p1y)
					local r2 = math.atan2((pl.x+pl.width/2-session.xscroll)-p2x, (pl.y+pl.height/2-session.yscroll-.5)-p2y)
					
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
						tx, ty = (x-session.xscroll), (y-session.yscroll-.5)
						r1b = math.pi/2
					elseif facing == "down" then
						tx, ty = (x-session.xscroll-1), (y-session.yscroll-.5)
						r1b = math.pi
					elseif facing == "left" then
						tx, ty = (x-session.xscroll-1), (y-session.yscroll-1.5)
						r1b = math.pi*1.5
					elseif facing == "up" then
						tx, ty = (x-session.xscroll), (y-session.yscroll-1.5)
						r1b = 0
					end
					
					local ox: number = 0
					local oy: number = 0
					if facing2 == "right" then
						ox, oy = (x2-session.xscroll), (y2-session.yscroll-.5)
						r2 = math.pi/2
					elseif facing2 == "down" then
						ox, oy = (x2-session.xscroll-1), (y2-session.yscroll-.5)
						r2 = math.pi
					elseif facing2 == "left" then
						ox, oy = (x2-session.xscroll-1), (y2-session.yscroll-1.5)
						r2 = math.pi*1.5
					elseif facing2 == "up" then
						ox, oy = (x2-session.xscroll), (y2-session.yscroll-1.5)
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
					
					local r, g, b = unpack(pv["portal" .. i .. "color"] as {number})
					with_mask(function()
						love.graphics.polygon("fill", p1x*16*scale, p1y*16*scale, p2x*16*scale, p2y*16*scale, p4x*16*scale, p4y*16*scale, p3x*16*scale, p3y*16*scale)
					end, function()
						love.graphics.setColor(unpack(background as {number}))
						love.graphics.rectangle("fill", 0, 0, width*16*scale, height*16*scale)

						love.graphics.setColor(1, 1, 1)
						love.graphics.draw(scenecanvas as Canvas, (offx+ox)*16*scale, (offy+oy)*16*scale, a, xscale, yscale, ox*16*scale, oy*16*scale)
					end)

					love.graphics.setColor(r, g, b)
					love.graphics.line(p1x*16*scale, p1y*16*scale, p3x*16*scale, p3y*16*scale)
					love.graphics.line(p2x*16*scale, p2y*16*scale, p4x*16*scale, p4y*16*scale)
				end
			end
		end
	end
end

