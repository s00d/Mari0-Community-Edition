--[[ Centralized camera scroll update (xscroll/yscroll globals). ]]

global function scroll_update(dt: number)
	local saved_xscroll = session.xscroll
	local saved_yscroll = session.yscroll

	--HORIZONTAL
	if metroidmode and roomcam_update then
		roomcam_update(dt)
	elseif level_mapmode and session.playerobjs[1] and not session.playerobjs[1].dead then
		mapmode_update_view(session.playerobjs[1])
	-- not minimapdragging: treat nil as false (play-mode editor_load skip used to leave it nil)
	elseif autoscroll and not minimapdragging then
		--scrolling
		local i = 1
		while i <= players and (session.playerobjs[i].dead or session.playerobjs[i].remote) do
			i = i + 1
		end
		
		local fastestplayer = session.playerobjs[i]
		
		-- HORIZONTAL SCROLLING
		if fastestplayer then
			for i = 1, players do
				if not session.playerobjs[i].dead and not session.playerobjs[i].remote and session.playerobjs[i].x > fastestplayer.x then
					fastestplayer = session.playerobjs[i]
				end
			end
			local speedx = converttostandard(fastestplayer, fastestplayer.speedx, fastestplayer.speedy)
			
			if fastestplayer.dead then -- scrolling fix for online multiplayer if all local players suck. I mean, are dead.
				for i = 1, players do
					if not session.playerobjs[i].dead and session.playerobjs[i].x > fastestplayer.x then
						fastestplayer = session.playerobjs[i]
					end
				end
			end
			
			--LEFT
			if fastestplayer.x < session.xscroll + scrollingleftstart and session.xscroll > 0 then
				
				if fastestplayer.x < session.xscroll + scrollingleftstart and speedx < 0 then
					if speedx < -scrollrate then
						session.xscroll = session.xscroll - scrollrate*dt
					else
						session.xscroll = session.xscroll + speedx*dt
					end
				end
				
				if fastestplayer.x < session.xscroll + scrollingleftcomplete then
					if fastestplayer.x > session.xscroll + scrollingleftcomplete - 1/16 then
						session.xscroll = session.xscroll - scrollrate*dt
					else
						session.xscroll = session.xscroll - superscrollrate*dt
					end
				end
			end
			
			--RIGHT
			
			if fastestplayer.x > session.xscroll + width - scrollingstart and session.xscroll < session.mapwidth - width then
				if fastestplayer.x > session.xscroll + width - scrollingstart and speedx > 0.3 then
					if speedx > scrollrate then
						session.xscroll = session.xscroll + scrollrate*dt
					else
						session.xscroll = session.xscroll + speedx*dt
					end
				end
				
				if fastestplayer.x > session.xscroll + width - scrollingcomplete then
					if fastestplayer.x > session.xscroll + width - scrollingcomplete then
						session.xscroll = session.xscroll + scrollrate*dt
						if session.xscroll > fastestplayer.x - (width - scrollingcomplete) then
							session.xscroll = fastestplayer.x - (width - scrollingcomplete)
						end
					else
						session.xscroll = fastestplayer.x - (width - scrollingcomplete)
					end
				end
			end
			
			--just force that shit
			if not levelfinished then
				if fastestplayer.x > session.xscroll + width - scrollingcomplete then
					session.xscroll = session.xscroll + (superscroll as number)*dt
					if fastestplayer.x < session.xscroll + width - scrollingcomplete then
						session.xscroll = fastestplayer.x - width + scrollingcomplete
					end
					--xscroll = fastestplayer.x + width - scrollingcomplete - width
				end
			end
			
			if session.xscroll > session.mapwidth-width then
				session.xscroll = math.max(0, session.mapwidth-width)
				hitrightside()
			end
				
			if session.xscroll < 0 then
				session.xscroll = 0
			end
				
			if (axex and session.xscroll > (axex as number)-width and (axex as number) >= width) then
				session.xscroll = (axex as number)-width
				hitrightside()
			end
		end
	
		--VERTICAL SCROLLING
		for i = 1, players do
			local v = session.playerobjs[i]
			local old = session.ylookmodifier
			if downkey(i) then
				if v.looktimer < userscrolltime then
					v.looktimer = v.looktimer + dt
				else
					if session.ylookmodifier < math.min(userscrollrange, session.mapheight-(height+session.yscroll)) then
						session.ylookmodifier = session.ylookmodifier + dt*userscrollspeed
						if session.ylookmodifier > math.min(userscrollrange, session.mapheight-(height+session.yscroll)) then
							session.ylookmodifier = math.min(userscrollrange, session.mapheight-(height+session.yscroll))
						end
					end
				end
			elseif upkey(i) then
				if v.looktimer < userscrolltime then
					v.looktimer = v.looktimer + dt
				else
					if session.ylookmodifier > -math.min(userscrollrange, session.yscroll) then
						session.ylookmodifier = session.ylookmodifier - dt*userscrollspeed
						if session.ylookmodifier < -math.min(userscrollrange, session.yscroll) then
							session.ylookmodifier = -math.min(userscrollrange, session.yscroll)
						end
					end
				end
			else
				v.looktimer = 0
				if session.ylookmodifier > 0 then
					session.ylookmodifier = math.max(0, session.ylookmodifier - userscrollspeed*dt)
				elseif session.ylookmodifier < 0 then
					session.ylookmodifier = math.min(0, session.ylookmodifier + userscrollspeed*dt)
				end
			end
			
			session.yscroll = session.yscroll + (session.ylookmodifier-old)
		end
		
		local i = 1
		while i <= players and (session.playerobjs[i].dead or session.playerobjs[i].remote) do
			i = i + 1
		end
		local fastestplayer = session.playerobjs[i]
		if fastestplayer then
			for i = 1, players do
				if not session.playerobjs[i].dead and not session.playerobjs[i].remote and session.playerobjs[i].y > fastestplayer.y then
					fastestplayer = session.playerobjs[i]
				end
			end
			local _, speedy = converttostandard(fastestplayer, fastestplayer.speedx, fastestplayer.speedy)
			if fastestplayer.y-session.yscroll < upscrollborder then
				local minspeed = (fastestplayer.y-session.yscroll-upscrollborder)*yscrollingrate
				session.yscroll = session.yscroll+math.min(speedy, minspeed)*dt
			elseif fastestplayer.y-session.yscroll > height-downscrollborder then
				local minspeed = (fastestplayer.y-session.yscroll - (height-downscrollborder))*yscrollingrate
				session.yscroll = session.yscroll+math.max(speedy, minspeed)*dt
			end
		end
			
		if session.yscroll > session.mapheight-height-1 then
			session.yscroll = math.max(0, session.mapheight-height-1)
		end
		
		if session.yscroll < 0 then
			session.yscroll = 0
		end
	end
	
	if not autoscroll or not autoscrollx then
		session.xscroll = saved_xscroll
	end
	
	if not autoscroll or not autoscrolly then
		session.yscroll = saved_yscroll
	end
	
	if firstpersonview then
		session.xscroll = session.playerobjs[1].x-width/2+session.playerobjs[1].width/2
		session.yscroll = session.playerobjs[1].y-height/2+session.playerobjs[1].height/2-.5
	end
	
	if session.mapwidth > width then
		session.xscroll = math.min(session.xscroll, session.mapwidth-width)
	end
	
	--camera pan x
	if xpan then
		xpantimer = xpantimer + dt
		if xpantimer >= xpantime then
			xpan = false
			xpantimer = xpantime
		end
		
		local i = xpantimer/xpantime
		
		session.xscroll = (xpanstart as number) + (xpandiff as number)*i
	end
	
	--camera pan y
	if ypan then
		ypantimer = ypantimer + dt
		if ypantimer >= ypantime then
			ypan = false
			ypantimer = ypantime
		end
		
		local i = ypantimer/ypantime
		
		session.yscroll = (ypanstart as number) + (ypandiff as number)*i
	end
end
