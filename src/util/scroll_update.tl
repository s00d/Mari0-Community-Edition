--[[ Centralized camera scroll update (xscroll/yscroll globals). ]]

global function scroll_update(dt: number)
	local saved_xscroll = xscroll
	local saved_yscroll = yscroll

	--HORIZONTAL
	if metroidmode and roomcam_update then
		roomcam_update(dt)
	elseif level_mapmode and playerobjs[1] and not playerobjs[1].dead then
		mapmode_update_view(playerobjs[1])
	-- not minimapdragging: treat nil as false (play-mode editor_load skip used to leave it nil)
	elseif autoscroll and not minimapdragging then
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
					xscroll = xscroll + (superscroll as number)*dt
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
			local _, speedy = converttostandard(fastestplayer, fastestplayer.speedx, fastestplayer.speedy)
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
		xscroll = saved_xscroll
	end
	
	if not autoscroll or not autoscrolly then
		yscroll = saved_yscroll
	end
	
	if firstpersonview then
		xscroll = playerobjs[1].x-width/2+playerobjs[1].width/2
		yscroll = playerobjs[1].y-height/2+playerobjs[1].height/2-.5
	end
	
	if mapwidth > width then
		xscroll = math.min(xscroll, mapwidth-width)
	end
	
	--camera pan x
	if xpan then
		xpantimer = xpantimer + dt
		if xpantimer >= xpantime then
			xpan = false
			xpantimer = xpantime
		end
		
		local i = xpantimer/xpantime
		
		xscroll = (xpanstart as number) + (xpandiff as number)*i
	end
	
	--camera pan y
	if ypan then
		ypantimer = ypantimer + dt
		if ypantimer >= ypantime then
			ypan = false
			ypantimer = ypantime
		end
		
		local i = ypantimer/ypantime
		
		yscroll = (ypanstart as number) + (ypandiff as number)*i
	end
end
