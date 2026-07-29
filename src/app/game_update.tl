--[[ Game update orchestration (Teal).
     Loaded via require("app.game_update"); defines global game_update.
]]

local blockbounce_delete_scratch: {any} = {}
local scores_delete_scratch: {any} = {}
local texts_delete_scratch: {any} = {}
local portal_delete_scratch: {any} = {}
-- Reused list of entity tables (refs refreshed each frame; no new array alloc).
local static_updatelists: {any} = {}
local blackhole_fx = require("weapons.blackhole_fx") as {string:any}

local function flush_spritebatch()
	updatespritebatch()
end

local function clear_scratch(t: {any})
	for i = #t, 1, -1 do
		t[i] = nil
	end
end

global function game_update(dt: number)
	if not objects then return end
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
		flush_spritebatch()
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
	local delete = scores_delete_scratch
	clear_scratch(delete)
	
	for i, _ in pairs(scrollingscores) do
		if scrollingscores[i]:update(dt) == true then
			table.insert(delete, i)
		end
	end
	
	remove_indices_desc(scrollingscores, delete)
	
	
	--SCROLLING TEXTS
	delete = texts_delete_scratch
	clear_scratch(delete)
	
	for i, _ in pairs(scrollingtexts as {any:Entity}) do
		if scrollingtexts[i]:update(dt) == true then
			table.insert(delete, i)
		end
	end
	
	remove_indices_desc(scrollingtexts, delete)
	
	if replaysystem then
		for j = 1, #replaydata do
			local rep = replaydata[j] as {string: any}
			local rdata = rep.data as {integer: any}
			if rdata then
				replaytimer[j] = replaytimer[j] + dt
				local idx = replayi[j] as integer
				while idx < #rdata and ((rdata[idx] as {string: any}).time as number) < replaytimer[j] do
					idx = idx + 1
					replayi[j] = idx
				end
			end
		end
	end
	
	--If everyone's dead, just update the players and coinblock timer.
	if everyonedead then
		for _, v in pairs(playerobjs) do
			v:update(dt)
		end
		flush_spritebatch()
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
				for _, v in pairs(playerobjs) do
					v:die("time")
				end
			end
		end
	end
	
	--remove userects
	local delete = scores_delete_scratch
	clear_scratch(delete)
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
	
	--portalgundelay (legacy global + per-player weapondelay)
	for i = 1, players do
		if portaldelay[i] > 0 then
			portaldelay[i] = math.max(0, portaldelay[i] - dt/speed)
		end
	end

	-- weapon dispatcher (cooldowns, gravity-gun spring, gel hold)
	if Weapons then
		Weapons.update_all(dt)
	end
	
	--check if updates are blocked for whatever reason
	if noupdate then
		for _, v in pairs(playerobjs) do --But update players anyway.
			v:update(dt)
		end
		flush_spritebatch()
		return
	end
	
	--blockbounce
	local delete = blockbounce_delete_scratch
	local ndelete = 0
	
	for i, _ in pairs(blockbouncetimer) do
		if blockbouncetimer[i] < blockbouncetime then
			blockbouncetimer[i] = blockbouncetimer[i] + dt
			if blockbouncetimer[i] > blockbouncetime then
				blockbouncetimer[i] = blockbouncetime
				if blockbouncecontent then
					item(blockbouncecontent[i], blockbouncex[i], blockbouncey[i], blockbouncecontent2[i])
				end
				ndelete = ndelete + 1
				delete[ndelete] = i
			end
		end
	end
	
	for i = ndelete + 1, #delete do
		delete[i] = nil
	end
	
	remove_indices_desc_multi({blockbouncetimer, blockbouncex, blockbouncey, blockbouncecontent, blockbouncecontent2}, delete)
	
	if ndelete >= 1 then
		generatespritebatch(0, 0)
	end
	
	--coinblocktimer things
	for _, v in pairs(coinblocktimers as {any:{any}}) do
		if (v[3] as number) > 0 then
			v[3] = (v[3] as number) - dt
		end
	end
	
	
	--UPDATE STUFFFFF
	-- Fixed list of effect tables (re-read globals each frame; level load reassigns them).
	-- Mutate module-local array — do not allocate a fresh table every step (GC hitch).
	static_updatelists[1] = pedestals
	static_updatelists[2] = emancipationfizzles
	static_updatelists[3] = emancipateanimations
	static_updatelists[4] = dialogboxes
	static_updatelists[5] = rocketlaunchers
	static_updatelists[6] = emancipationgrills
	static_updatelists[7] = fireworks
	static_updatelists[8] = miniblocks
	static_updatelists[9] = bubbles
	static_updatelists[10] = platformspawners
	static_updatelists[11] = seesaws
	static_updatelists[12] = blockdebristable
	static_updatelists[13] = userects
	static_updatelists[14] = rainbooms
	static_updatelists[15] = coinblockanimations
	static_updatelists[16] = itemanimations

	for _, v in ipairs(static_updatelists as {any}) do
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
	local oldxscroll = xscroll
	local oldyscroll = yscroll
	scroll_update(dt)
	--enemy spawning
	if not editormode and not metroidmode then
		if round(xscroll) ~= round(oldxscroll) then
			local xstart: number = 0
			local xend: number = 0
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
			local ystart: number = 0
			local yend: number = 0
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
	local new_sbx = math.floor(xscroll)
	local new_sby = math.floor(yscroll)
	local sb_dx = 0
	local sb_dy = 0
	if spritebatchX[1] ~= nil then
		sb_dx = new_sbx - (spritebatchX[1] as integer)
	end
	if spritebatchY[1] ~= nil then
		sb_dy = new_sby - (spritebatchY[1] as integer)
	end

	if sb_dx ~= 0 or sb_dy ~= 0 then
		if sb_dx ~= 0 and not editormode then
			for currentx = lastrepeat+1+width, new_sbx+1+width do
				reachedx(currentx)
			end
		end

		generatespritebatch(0, 0)
	end

	if spritebatch_portal_catchup and not editormode then
		local i = 1
		while i <= players and (playerobjs[i].dead or playerobjs[i].remote) do
			i = i + 1
		end
		local fp = playerobjs[i]
		if fp then
			local x_ok = fp.x >= xscroll + scrollingleftcomplete - 1/16
				and fp.x <= xscroll + width - scrollingcomplete + 1/16
			local y_ok = fp.y - yscroll >= upscrollborder - 1/16
				and fp.y - yscroll <= height - downscrollborder + 1/16
			if x_ok and y_ok then
				spritebatch_portal_catchup = false
			end
		end
	end
	
	--portal update
	for _, v in pairs(portals) do
		v:update(dt)
	end
	
	--portal particles
	portalparticletimer = portalparticletimer + dt
	while portalparticletimer > portalparticletime do
		portalparticletimer = portalparticletimer - portalparticletime
		
		for _, pv in pairs(portals) do
			local p = pv as portal
			if p.facing1 and p.x1 and p.y1 then
				local x1: number = 0
				local y1: number = 0
				
				if p.facing1 == "up" then
					x1 = (p.x1 as number) + math.random(1, 30)/16-1
					y1 = (p.y1 as number)-1
				elseif p.facing1 == "down" then
					x1 = (p.x1 as number) + math.random(1, 30)/16-2
					y1 = p.y1 as number
				elseif p.facing1 == "left" then
					x1 = (p.x1 as number)-1
					y1 = (p.y1 as number) + math.random(1, 30)/16-2
				elseif p.facing1 == "right" then
					x1 = p.x1 as number
					y1 = (p.y1 as number) + math.random(1, 30)/16-1
				end
				
				table.insert(portalparticles, portalparticle:new(x1, y1, p.portal1color, p.facing1))
			end
			
			if p.facing2 ~= nil and p.x2 and p.y2 then
				local x2: number = 0
				local y2: number = 0
				
				if p.facing2 == "up" then
					x2 = (p.x2 as number) + math.random(1, 30)/16-1
					y2 = (p.y2 as number)-1
				elseif p.facing2 == "down" then
					x2 = (p.x2 as number) + math.random(1, 30)/16-2
					y2 = p.y2 as number
				elseif p.facing2 == "left" then
					x2 = (p.x2 as number)-1
					y2 = (p.y2 as number) + math.random(1, 30)/16-2
				elseif p.facing2 == "right" then
					x2 = p.x2 as number
					y2 = (p.y2 as number) + math.random(1, 30)/16-1
				end
				
				table.insert(portalparticles, portalparticle:new(x2, y2, p.portal2color, p.facing2))
			end
		end
	end
	
	local delete = portal_delete_scratch
	clear_scratch(delete)
	
	for i, v in pairs(portalparticles) do
		if (v as Entity):update(dt) == true then
			table.insert(delete, i)
		end
	end
	
	remove_indices_desc(portalparticles, delete)
	
	--PORTAL PROJECTILES
	clear_scratch(delete)
	
	for i, v in pairs(portalprojectiles) do
		if (v as Entity):update(dt) == true then
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
			if objects["bowser"][1] then
				temp.y = objects["bowser"][1].y+0.25
				temp.x = objects["bowser"][1].x-0.750
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
			local x, y = math.random(math.floor(xscroll) as integer, (math.floor(xscroll)+width) as integer), mapheight as integer
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
	for _, v in pairs(objects.player) do
		if not v.disableaiming then
			(v as mario):updateangle()
		end
	end

	if blackhole_fx.sync then
		(blackhole_fx.sync as function(number))(dt)
	end

	-- AE coalesce: flush spritebatch once per frame after all dirty marks.
	flush_spritebatch()
end

