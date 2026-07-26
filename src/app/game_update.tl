--[[ Game update orchestration (Teal).
     Loaded via require("app.game_update"); defines global game_update.
]]

global function game_update(dt: number)
	if not objects then return end
	dt = dt * speed
	gdt = dt
	
	--------
	--GAME--
	--------
	
	--animationS
	animationsystem_update(dt)
	
	
	--earthquake reset
	if earthquake > 0 then
		earthquake = math.max(0, earthquake-dt*earthquake*2-0.001)
		sunrot = sunrot + dt
	end
	
	--pausemenu
	if pausemenuopen then
		return
	end
	
	--Animate animated tiles because I say so
	for i = 1, #animatedtiles do
		animatedtiles[i]:update(dt)
	end
	
	for i = 1, #animatedtimerlist do
		animatedtimerlist[i]:update(dt)
	end
	
	for i = 1, #animatedbooltimerlist do
		animatedbooltimerlist[i]:update(dt)
	end
	
	--coinanimation
	coinanimation = coinanimation + dt*6.75
	while coinanimation >= 6 do
		coinanimation = coinanimation - 5
	end	
	
	coinframe = math.max(1, math.floor(coinanimation))
	
	--SCROLLING SCORES
	local delete = {}
	
	for i, v in pairs(scrollingscores) do
		if scrollingscores[i]:update(dt) == true then
			table.insert(delete, i)
		end
	end
	
	remove_indices_desc(scrollingscores, delete)
	
	
	--SCROLLING TEXTS
	local delete = {}
	
	for i, v in pairs(scrollingtexts) do
		if scrollingtexts[i]:update(dt) == true then
			table.insert(delete, i)
		end
	end
	
	remove_indices_desc(scrollingtexts, delete)
	
	if replaysystem then
		for j = 1, #replaydata do
			if replaydata[j].data then
				replaytimer[j] = replaytimer[j] + dt
				local rdata = replaydata[j].data as {any}
				while (rdata[replayi[j]] as {string:any}).time < replaytimer[j] and replayi[j] < #rdata do
					replayi[j] = replayi[j] + 1
				end
			end
		end
	end
	
	--If everyone's dead, just update the players and coinblock timer.
	if everyonedead then
		for i, v in pairs(playerobjs) do
			v:update(dt)
		end
		
		return
	end
	
	--timer	
	if editormode == false then
		--get if any player has their controls disabled
		local notime = false
		for i = 1, players do
			if (playerobjs[i].controlsenabled == false and playerobjs[i].dead == false) then
				notime = true
			end
		end
		
		if notime == false and infinitetime == false and mariotime ~= 0 then
			mariotime = mariotime - 2.5*dt
			
			if mariotime > 0 and mariotime + 2.5*dt >= 99 and mariotime < 99 and firstunder100 then
				love.audio.stop()
				playsound("lowtime")
			end
			
			if mariotime > 0 and mariotime + 2.5*dt >= 99-8 and mariotime < 99-8 and firstunder100 then
				local star = false
				for i = 1, players do
					if playerobjs[i].starred then
						star = true
					end
				end
				
				if not star then
				
					playmusic()
				else
					music:play("starmusic.ogg")
				end
				
				firstunder100 = false
			end
			
			if mariotime <= 0 then
				mariotime = 0
				for i, v in pairs(playerobjs) do
					v:die("time")
				end
			end
		end
	end
	
	--remove userects
	local delete = {}
	for i, v in pairs(userects) do
		if v.delete then
			table.insert(delete, i)
		end
	end
	
	remove_indices_desc(userects, delete)
	
	--Portaldots
	portaldotstimer = portaldotstimer + dt
	while portaldotstimer > portaldotstime do
		portaldotstimer = portaldotstimer - portaldotstime
	end
	
	--portalgundelay
	for i = 1, players do
		if portaldelay[i] > 0 then
			portaldelay[i] = math.max(0, portaldelay[i] - dt/speed)
		end
	end
	
	--check if updates are blocked for whatever reason
	if noupdate then
		for i, v in pairs(playerobjs) do --But update players anyway.
			v:update(dt)
		end
		return
	end
	
	--blockbounce
	local delete = {}
	
	for i, v in pairs(blockbouncetimer) do
		if blockbouncetimer[i] < blockbouncetime then
			blockbouncetimer[i] = blockbouncetimer[i] + dt
			if blockbouncetimer[i] > blockbouncetime then
				blockbouncetimer[i] = blockbouncetime
				if blockbouncecontent then
					item(blockbouncecontent[i], blockbouncex[i], blockbouncey[i], blockbouncecontent2[i])
				end
				table.insert(delete, i)
			end
		end
	end
	
	remove_indices_desc_multi({blockbouncetimer, blockbouncex, blockbouncey, blockbouncecontent, blockbouncecontent2}, delete)
	
	if #delete >= 1 then
		generatespritebatch()
	end
	
	--coinblocktimer things
	for i, v in pairs(coinblocktimers) do
		if v[3] > 0 then
			v[3] = v[3] - dt
		end
	end
	
	--gelcannon
	if playerobjs[mouseowner] and playertype == "gelcannon" and playerobjs[mouseowner].controlsenabled then
		if gelcannontimer > 0 then
			gelcannontimer = gelcannontimer - dt
			if gelcannontimer < 0 then
				gelcannontimer = 0
			end
		else
			if love.mouse.isDown("l") then
				gelcannontimer = gelcannondelay
				playerobjs[mouseowner]:shootgel(1)
			elseif love.mouse.isDown("r") then
				gelcannontimer = gelcannondelay
				playerobjs[mouseowner]:shootgel(2)
			end
		end
	end
	
	
	--UPDATE STUFFFFF
	-- Fixed list of effect tables (re-read globals each frame; level load reassigns them)
	local static_updatelists = {	pedestals, emancipationfizzles, emancipateanimations, dialogboxes, rocketlaunchers, emancipationgrills, fireworks, miniblocks, bubbles, platformspawners, seesaws, blockdebristable,
							userects, rainbooms, coinblockanimations, itemanimations}

	for _, v in ipairs(static_updatelists) do
		update_and_compact(v, dt)
	end
	for i, v in pairs(objects) do
		if i ~= "tile" and i ~= "portalwall" and i ~= "screenboundary" then
			update_and_compact(v, dt)
		end
	end
	
	
	--PHYSICS
	physicsupdate(dt)
	
	
	--SCROLLING
	--HORIZONTAL
	local oldxscroll = xscroll
	local oldyscroll = yscroll
	
	if autoscroll and minimapdragging == false then
		--scrolling
		local i = 1
		while i <= players and (playerobjs[i].dead or playerobjs[i].remote) do
			i = i + 1
		end
		
		local fastestplayer = playerobjs[i]
		
		-- HORIZONTAL SCROLLING
		if fastestplayer then
			for i = 1, players do
				if not playerobjs[i].dead and not playerobjs[i].remote and playerobjs[i].x > fastestplayer.x then
					fastestplayer = playerobjs[i]
				end
			end
			local speedx = converttostandard(fastestplayer, fastestplayer.speedx, fastestplayer.speedy)
			
			if fastestplayer.dead then -- scrolling fix for online multiplayer if all local players suck. I mean, are dead.
				for i = 1, players do
					if not playerobjs[i].dead and playerobjs[i].x > fastestplayer.x then
						fastestplayer = playerobjs[i]
					end
				end
			end
			
			--LEFT
			if fastestplayer.x < xscroll + scrollingleftstart and xscroll > 0 then
				
				if fastestplayer.x < xscroll + scrollingleftstart and speedx < 0 then
					if speedx < -scrollrate then
						xscroll = xscroll - scrollrate*dt
					else
						xscroll = xscroll + speedx*dt
					end
				end
				
				if fastestplayer.x < xscroll + scrollingleftcomplete then
					if fastestplayer.x > xscroll + scrollingleftcomplete - 1/16 then
						xscroll = xscroll - scrollrate*dt
					else
						xscroll = xscroll - superscrollrate*dt
					end
				end
			end
			
			--RIGHT
			
			if fastestplayer.x > xscroll + width - scrollingstart and xscroll < mapwidth - width then
				if fastestplayer.x > xscroll + width - scrollingstart and speedx > 0.3 then
					if speedx > scrollrate then
						xscroll = xscroll + scrollrate*dt
					else
						xscroll = xscroll + speedx*dt
					end
				end
				
				if fastestplayer.x > xscroll + width - scrollingcomplete then
					if fastestplayer.x > xscroll + width - scrollingcomplete then
						xscroll = xscroll + scrollrate*dt
						if xscroll > fastestplayer.x - (width - scrollingcomplete) then
							xscroll = fastestplayer.x - (width - scrollingcomplete)
						end
					else
						xscroll = fastestplayer.x - (width - scrollingcomplete)
					end
				end
			end
			
			--just force that shit
			if not levelfinished then
				if fastestplayer.x > xscroll + width - scrollingcomplete then
					xscroll = xscroll + superscroll*dt
					if fastestplayer.x < xscroll + width - scrollingcomplete then
						xscroll = fastestplayer.x - width + scrollingcomplete
					end
					--xscroll = fastestplayer.x + width - scrollingcomplete - width
				end
			end
			
			if xscroll > mapwidth-width then
				xscroll = math.max(0, mapwidth-width)
				hitrightside()
			end
				
			if xscroll < 0 then
				xscroll = 0
			end
				
			if (axex and xscroll > (axex as number)-width and (axex as number) >= width) then
				xscroll = (axex as number)-width
				hitrightside()
			end
		end
	
		--VERTICAL SCROLLING
		for i = 1, players do
			local v = playerobjs[i]
			local old = ylookmodifier
			if downkey(i) then
				if v.looktimer < userscrolltime then
					v.looktimer = v.looktimer + dt
				else
					if ylookmodifier < math.min(userscrollrange, mapheight-(height+yscroll)) then
						ylookmodifier = ylookmodifier + dt*userscrollspeed
						if ylookmodifier > math.min(userscrollrange, mapheight-(height+yscroll)) then
							ylookmodifier = math.min(userscrollrange, mapheight-(height+yscroll))
						end
					end
				end
			elseif upkey(i) then
				if v.looktimer < userscrolltime then
					v.looktimer = v.looktimer + dt
				else
					if ylookmodifier > -math.min(userscrollrange, yscroll) then
						ylookmodifier = ylookmodifier - dt*userscrollspeed
						if ylookmodifier < -math.min(userscrollrange, yscroll) then
							ylookmodifier = -math.min(userscrollrange, yscroll)
						end
					end
				end
			else
				v.looktimer = 0
				if ylookmodifier > 0 then
					ylookmodifier = math.max(0, ylookmodifier - userscrollspeed*dt)
				elseif ylookmodifier < 0 then
					ylookmodifier = math.min(0, ylookmodifier + userscrollspeed*dt)
				end
			end
			
			yscroll = yscroll + (ylookmodifier-old)
		end
		
		local i = 1
		while i <= players and (playerobjs[i].dead or playerobjs[i].remote) do
			i = i + 1
		end
		local fastestplayer = playerobjs[i]
		if fastestplayer then
			for i = 1, players do
				if not playerobjs[i].dead and not playerobjs[i].remote and playerobjs[i].y > fastestplayer.y then
					fastestplayer = playerobjs[i]
				end
			end
			local dummy, speedy = converttostandard(fastestplayer, fastestplayer.speedx, fastestplayer.speedy)
			if fastestplayer.y-yscroll < upscrollborder then
				local minspeed = (fastestplayer.y-yscroll-upscrollborder)*yscrollingrate
				yscroll = yscroll+math.min(speedy, minspeed)*dt
			elseif fastestplayer.y-yscroll > height-downscrollborder then
				local minspeed = (fastestplayer.y-yscroll - (height-downscrollborder))*yscrollingrate
				yscroll = yscroll+math.max(speedy, minspeed)*dt
			end
		end
			
		if yscroll > mapheight-height-1 then
			yscroll = math.max(0, mapheight-height-1)
		end
		
		if yscroll < 0 then
			yscroll = 0
		end
	end
	
	if not autoscroll or not autoscrollx then
		xscroll = oldxscroll
	end
	
	if not autoscroll or not autoscrolly then
		yscroll = oldyscroll
	end
	
	if firstpersonview then
		xscroll = playerobjs[1].x-width/2+playerobjs[1].width/2
		yscroll = playerobjs[1].y-height/2+playerobjs[1].height/2-.5
	end
	
	if mapwidth > width then
		xscroll = math.min(xscroll, mapwidth-width)
	end
	
	--[[ Code I wrote for testing all levels for crashes.. doesn't properly change the levels anymore..
	for i = 1, 10 do
		mazesolved[i] = true
	end
	xscroll = xscroll + dt*100
	if xscroll >= mapwidth-width then
		while true do
			mariosublevel = mariosublevel + 1
			if mariosublevel > 5 then
				mariosublevel = 0
				mariolevel = mariolevel + 1
				if mariolevel > 4 then
					mariolevel = 1
					marioworld = marioworld + 1
				end
			end
			love.timer.sleep(0.1)
			if mariosublevel == 0 then
				print(marioworld .. "-" .. mariolevel .. ".txt")
				if love.filesystem.getInfo("mappacks/" .. mappack .. "/" .. marioworld .. "-" .. mariolevel .. ".txt", "file") then
					startlevel(marioworld .. "-" .. mariolevel)
					break
				end
			else
				print(marioworld .. "-" .. mariolevel .. "_" .. mariosublevel .. ".txt")
				if love.filesystem.getInfo("mappacks/" .. mappack .. "/" .. marioworld .. "-" .. mariolevel .. "_" .. mariosublevel .. ".txt", "file") then
					startlevel(marioworld .. "-" .. mariolevel .. "_" .. mariosublevel)
					break
				end
			end
		end
	end
	--]]
	
	
	--camera pan x
	if xpan then
		xpantimer = xpantimer + dt
		if xpantimer >= xpantime then
			xpan = false
			xpantimer = xpantime
		end
		
		local i = xpantimer/xpantime
		
		xscroll = xpanstart + xpandiff*i
	end
	
	--camera pan y
	if ypan then
		ypantimer = ypantimer + dt
		if ypantimer >= ypantime then
			ypan = false
			ypantimer = ypantime
		end
		
		local i = ypantimer/ypantime
		
		yscroll = ypanstart + ypandiff*i
	end
	
	--enemy spawning
	if not editormode then
		if round(xscroll) ~= round(oldxscroll) then
			local xstart, xend
			if xscroll > oldxscroll then
				xstart, xend = round(oldxscroll)+1+math.ceil(width), round(xscroll)+math.ceil(width)
			else
				xstart, xend = round(xscroll), round(oldxscroll)-1
			end
			
			for x = xstart, xend do
				for y = round(yscroll)-1, round(yscroll)+height+1 do
					spawnenemy(x, y)
				end
			end
		end
		
		if round(yscroll) ~= round(oldyscroll) then
			local ystart, yend
			if yscroll > oldyscroll then
				ystart, yend = round(oldyscroll)+1+math.ceil(height), round(yscroll)+math.ceil(height)
			else
				ystart, yend = round(yscroll), round(oldyscroll)-1
			end
			
			for y = ystart, yend do
				for x = round(xscroll)-1, round(xscroll)+width+1 do
					spawnenemy(x, y)
				end
			end
		end
	end
	
	--SPRITEBATCH UPDATE and CASTLEREPEATS
	if math.floor(xscroll) ~= spritebatchX[1] then
		if not editormode then
			for currentx = lastrepeat+1+width, math.floor(xscroll)+1+width do
				reachedx(currentx)
			end
		end
		
		generatespritebatch()
		spritebatchX[1] = math.floor(xscroll)
	elseif math.floor(yscroll) ~= spritebatchY[1] then
		generatespritebatch()
		spritebatchY[1] = math.floor(yscroll)
	end
	
	--portal update
	for i, v in pairs(portals) do
		v:update(dt)
	end
	
	--portal particles
	portalparticletimer = portalparticletimer + dt
	while portalparticletimer > portalparticletime do
		portalparticletimer = portalparticletimer - portalparticletime
		
		for i, v in pairs(portals) do
			if v.facing1 and v.x1 and v.y1 then
				local x1, y1
				
				if v.facing1 == "up" then
					x1 = v.x1 + math.random(1, 30)/16-1
					y1 = v.y1-1
				elseif v.facing1 == "down" then
					x1 = v.x1 + math.random(1, 30)/16-2
					y1 = v.y1
				elseif v.facing1 == "left" then
					x1 = v.x1-1
					y1 = v.y1 + math.random(1, 30)/16-2
				elseif v.facing1 == "right" then
					x1 = v.x1
					y1 = v.y1 + math.random(1, 30)/16-1
				end
				
				table.insert(portalparticles, portalparticle:new(x1, y1, v.portal1color, v.facing1))
			end
			
			if v.facing2 ~= nil and v.x2 and v.y2 then
				local x2, y2
				
				if v.facing2 == "up" then
					x2 = v.x2 + math.random(1, 30)/16-1
					y2 = v.y2-1
				elseif v.facing2 == "down" then
					x2 = v.x2 + math.random(1, 30)/16-2
					y2 = v.y2
				elseif v.facing2 == "left" then
					x2 = v.x2-1
					y2 = v.y2 + math.random(1, 30)/16-2
				elseif v.facing2 == "right" then
					x2 = v.x2
					y2 = v.y2 + math.random(1, 30)/16-1
				end
				
				table.insert(portalparticles, portalparticle:new(x2, y2, v.portal2color, v.facing2))
			end
		end
	end
	
	delete = {}
	
	for i, v in pairs(portalparticles) do
		if v:update(dt) == true then
			table.insert(delete, i)
		end
	end
	
	remove_indices_desc(portalparticles, delete)
	
	--PORTAL PROJECTILES
	delete = {}
	
	for i, v in pairs(portalprojectiles) do
		if v:update(dt) == true then
			table.insert(delete, i)
		end
	end
	
	remove_indices_desc(portalprojectiles, delete)
	
	--FIRE SPAWNING
	if not levelfinished and firestarted and (not objects["bowser"][1] or (objects["bowser"][1].backwards == false and objects["bowser"][1].shot == false and objects["bowser"][1].fall == false)) then
		firetimer = firetimer + dt
		while firetimer > firedelay do
			firetimer = firetimer - firedelay
			firedelay = math.random(4)
			local temp = enemy:new(xscroll + width, math.random(3)+7, "fire")
			table.insert(objects["enemy"], temp)
			
			
			if objects["bowser"][1] then --make bowser fire this
				temp.y = objects["bowser"][1].y+0.25
				temp.x = objects["bowser"][1].x-0.750
				
				--get goal Y
				temp.movement = "targety"
				temp.targetyspeed = 2
				temp.targety = objects["bowser"][1].starty-math.random(3)+2/16
			end
		end
	end
	
	--FLYING FISH
	if not levelfinished and flyingfishstarted then
		flyingfishtimer = flyingfishtimer + dt
		while flyingfishtimer > flyingfishdelay do
			flyingfishtimer = flyingfishtimer - flyingfishdelay
			flyingfishdelay = math.random(6, 20)/10
			
			local x, y = math.random(math.floor(xscroll), math.floor(xscroll)+width), mapheight
			local temp = enemy:new(x, y, "flyingfish")
			table.insert(objects["enemy"], temp)
			
			temp.speedx = playerobjs[1].speedx + math.random(10)-5
			
			if temp.speedx == 0 then
				temp.speedx = 1
			end
			
			if temp.speedx > 0 then
				temp.animationdirection = "left"
			else
				temp.animationdirection = "right"
			end
		end
	end
	
	--BULLET BILL
	if not levelfinished and bulletbillstarted then
		bulletbilltimer = bulletbilltimer + dt
		while bulletbilltimer > bulletbilldelay do
			bulletbilltimer = bulletbilltimer - bulletbilldelay
			bulletbilldelay = math.random(5, 40)/10
			table.insert(objects["enemy"], enemy:new(xscroll+width+2, math.random(4, 12), "bulletbill"))
		end
	end
	
	--Editor
	if editormode then
		editor_update(dt)
	end
	
	--Update pointing angle of players
	for i, v in pairs(objects.player) do
		if not v.disableaiming then
			v:updateangle()
		end
	end
end

