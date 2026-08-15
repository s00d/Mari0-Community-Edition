--[[ Teal port of root funnel.lua ]]

rawset(_G, "funnel", rawget(_G, "funnel") or {})

local Core = require("assets.anim8_core")

function funnel.new(_: funnel, x: number, y: number, r: {any}): funnel
	local self = setmetatable({}, { __index = funnel }) as funnel
	self:init(x, y, r)
	return self
end

function funnel:init(x: number, y: number, r: any)
	self.cox = x
	self.coy = y
	self.dir = "right"
	self.r = {unpack(r as {any})}
	self.reverse = 1
	self.power = true
	self.firstupdate = true
	self.input1state = "off"
	self.input2state = "off"
	self.quad = 1
	
	self.timer = 0
	self.timer2 = 0
	
	self.objtable = {"player", "enemy", "box", "gel"}
	
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	self.speed = funnelspeed
	
	--Input list
	--DIRECTION
	if #self.r > 0 and self.r[1] ~= "link" then
		self.dir = self.r[1]
		table.remove(self.r, 1)
	end
	
	--SPEED
	if #self.r > 0 and self.r[1] ~= "link" and tonumber(self.r[1]) then
		self.speed = tonumber(self.r[1])
		table.remove(self.r, 1)
	end
	
	--DIRECTION
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			self.reverse = -1
		end
		table.remove(self.r, 1)
	end
	
	--POWER
	if #self.r > 0 and self.r[1] ~= "link" then
		if self.r[1] == "true" then
			self.power = false
		end
		table.remove(self.r, 1)
	end
	self:updaterange()
	
	self.animationtime = 3/self.speed-1/16
end

function funnel:link()
	while #self.r > 3 do
		for _, w in pairs(outputs) do
			for _, v in pairs(session.objects[w] as {any:Entity}) do
				if tonumber(self.r[3]) == v.cox and tonumber(self.r[4]) == v.coy then
					v:addoutput(self, self.r[2])
				end
			end
		end
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
	end
end

function funnel:update(dt: number)	
	if self.power then
		self.timer = self.timer + dt
		if self.timer > (self.animationtime as number) then
			self.timer = math.fmod(self.timer, (self.animationtime as number))
		end
		
		self.timer2 = self.timer2 + dt
		local ticked: boolean
		self.timer2, ticked = Core.tick_interval(self.timer2, dt, excursionbaseanimationtime)
		if ticked then
			if self.reverse == 1 then
				self.quad = (self.quad as number) + 1
				if (self.quad as number) > 8 then
					self.quad = 1
				end
			else
				self.quad = (self.quad as number) - 1
				if (self.quad as number) < 1 then
					self.quad = 8
				end
			end		
		end

		local x: number = 0
		local y: number = 0
		local width: number = 0
		local height: number = 0
		
		for _, v in pairs(self.funneltable as {any:Entity}) do
			if v.dir == "right" then
				x = v.x-1
				y = v.y-1
				width = v.rangex
				height = 2
			elseif v.dir == "left" then
				x = v.x+v.rangex
				y = v.y-1
				width = -v.rangex
				height = 2
			elseif v.dir == "up" then
				x = v.x-1
				y = v.y+v.rangey
				width = 2
				height = -v.rangey
			else
				x = v.x-1
				y = v.y-1
				width = 2
				height = v.rangey
			end
			
			if v.dir == "right" or v.dir == "left" then
				if v.timer < math.abs(v.rangex) then
					v.timer = v.timer + dt*funnelbuildupspeed
					if v.timer > math.abs(v.rangex) then
						v.timer = math.abs(v.rangex as number)
					end
				end
			else
				if v.timer < math.abs(v.rangey) then
					v.timer = v.timer + dt*funnelbuildupspeed
					if v.timer > math.abs(v.rangey) then
						v.timer = math.abs(v.rangey as number)
					end
				end
			end
			
			local rectcol = checkrect(x, y, width, height, self.objtable)
			
			for i = 1, #rectcol, 2 do
				local w = session.objects[rectcol[i]][rectcol[i+1]]
				w.speedx = 0
				w.speedy = 0
				
				if v.dir == "right" then
					w.speedx = (self.speed as number)*(self.reverse as number)
					
					local diff = (w.y+w.height/2)-y-1
					w.speedy = -diff*funnelforce
					
					if rectcol[i] == "player" and w.controlsenabled then
						if downkey(rectcol[i+1]) then
							w.speedy = funnelmovespeed
						elseif upkey(rectcol[i+1]) then
							w.speedy = w.speedy-funnelmovespeed
						end
					end
					
				elseif v.dir == "left" then
					w.speedx = -(self.speed as number)*(self.reverse as number)
					
					local diff = (w.y+w.height/2)-y-1
					w.speedy = -diff*funnelforce
					
					if rectcol[i] == "player" and w.controlsenabled then
						if downkey(rectcol[i+1]) then
							w.speedy = funnelmovespeed
						elseif upkey(rectcol[i+1]) then
							w.speedy = w.speedy-funnelmovespeed
						end
					end
					
				elseif v.dir == "up" then
					w.speedy = -(self.speed as number)*(self.reverse as number)
					
					local diff = (w.x+w.width/2)-x-1
					w.speedx = -diff*funnelforce
					
					if rectcol[i] == "player" and w.controlsenabled then
						if leftkey(rectcol[i+1]) then
							w.speedx = -funnelmovespeed
						elseif rightkey(rectcol[i+1]) then
							w.speedx = funnelmovespeed
						end
					end
					
				else
					w.speedy = (self.speed as number)*(self.reverse as number)
					
					local diff = (w.x+w.width/2)-x-1
					w.speedx = -diff*funnelforce
					
					if rectcol[i] == "player" and w.controlsenabled then
						if leftkey(rectcol[i+1]) then
							w.speedx = -funnelmovespeed
						elseif rightkey(rectcol[i+1]) then
							w.speedx = funnelmovespeed
						end
					end
				end
				
				w.funnel = true
				w.gravity = 0
				w.gravitydirection = math.pi/2
			end
		end
	end
end

function funnel:draw()
	love.graphics.setColor(1, 1, 1)
	
	if self.power then
		local img: any = nil
		if self.reverse == 1 then
			img = excursionfunnelimg
			endimg = excursionfunnelendimg
		else
			img = excursionfunnel2img
			endimg = excursionfunnelend2img
		end
		
		for _, v in pairs(self.funneltable as {any:Entity}) do
			if v.dir == "right" then
				local progress = v.timer/v.rangex
				if self.reverse == 1 then
					love.graphics.setScissor(screen_draw_x(v.x - 1), screen_draw_y(v.y - 1.5), math.floor(v.rangex * progress * 16 * scale), math.floor(2 * 16 * scale))
				else
					love.graphics.setScissor(screen_draw_x(v.x - 1 + v.rangex * (1 - progress)), screen_draw_y(v.y - 1.5), math.floor(v.rangex * progress * 16 * scale), math.floor(2 * 16 * scale))
				end
				
				local x: number = 0
				for j = 0, math.ceil(v.rangex/3)+1 do
					x = tile_draw_x(v.x - 1 + (j - 1) * 3 + self.timer / (self.animationtime as number) * 3 * (self.reverse as number))
					love.graphics.draw(img, x, math.floor(tile_draw_y_raw(v.y - 1.5)), 0, world_draw_scale(), world_draw_scale())
				end
				
				love.graphics.draw(endimg, tile_draw_x(v.x + v.rangex - 1.5), math.floor(tile_draw_y_raw(v.y - 1)), 0, world_draw_scale(), world_draw_scale(), 8, 8)
				love.graphics.setScissor()
			elseif v.dir == "left" then
				local progress = v.timer/-v.rangex
				if self.reverse == 1 then
					love.graphics.setScissor(screen_draw_x(v.x + v.rangex - v.rangex * (1 - progress)), screen_draw_y(v.y - 1.5), math.floor(-v.rangex * progress * 16 * scale), math.floor(2 * 16 * scale))
				else
					love.graphics.setScissor(screen_draw_x(v.x + v.rangex), screen_draw_y(v.y - 1.5), math.floor(-v.rangex * progress * 16 * scale), math.floor(2 * 16 * scale))
				end
				
				for j = 0, math.ceil(-v.rangex/3)+1 do
					local x = tile_draw_x(v.x + v.rangex + (j - 1) * 3 - self.timer / (self.animationtime as number) * 3 * (self.reverse as number))
					love.graphics.draw(img, x, math.floor(tile_draw_y_raw(v.y - 1.5)), 0, world_draw_scale(), world_draw_scale())
				end
				
				love.graphics.draw(endimg, tile_draw_x(v.x + v.rangex + .5), math.floor(tile_draw_y_raw(v.y)), math.pi, world_draw_scale(), world_draw_scale(), 8, 8)
				love.graphics.setScissor()
			elseif v.dir == "up" then
				local progress = v.timer/-v.rangey
				if self.reverse == 1 then
					love.graphics.setScissor(screen_draw_x(v.x - 1), screen_draw_y(v.y + v.rangey - v.rangey * (1 - progress) - .5), math.floor(2 * 16 * scale), math.floor(-v.rangey * progress * 16 * scale))
				else
					love.graphics.setScissor(screen_draw_x(v.x - 1), screen_draw_y(v.y + v.rangey - .5), math.floor(2 * 16 * scale), math.floor(-v.rangey * progress * 16 * scale))
				end
				
				for j = 0, math.ceil(-v.rangey/3)+1 do
					local y = math.floor(tile_draw_y_raw(v.y + v.rangey - .5 + (j - 1) * 3 - self.timer / (self.animationtime as number) * 3 * (self.reverse as number)))
					love.graphics.draw(img, tile_draw_x(v.x + 1), y, math.pi/2, world_draw_scale(), world_draw_scale())
				end
				
				love.graphics.draw(endimg, tile_draw_x(v.x - .5), math.floor(tile_draw_y_raw(v.y + v.rangey)), -math.pi/2, world_draw_scale(), world_draw_scale(), 8, 8)
				love.graphics.setScissor()
			else
				local progress = v.timer/v.rangey
				if self.reverse == 1 then
					love.graphics.setScissor(screen_draw_x(v.x - 1), screen_draw_y(v.y - 1.5), math.floor(2 * 16 * scale), math.floor(v.rangey * progress * 16 * scale))
				else
					love.graphics.setScissor(screen_draw_x(v.x - 1), screen_draw_y(v.y - 1.5 + v.rangey * (1 - progress)), math.floor(2 * 16 * scale), math.floor(v.rangey * progress * 16 * scale))
				end
				
				for j = 0, math.ceil(v.rangey/3)+1 do
					local y = math.floor(tile_draw_y_raw(v.y - 1.5 + (j - 1) * 3 + self.timer / (self.animationtime as number) * 3 * (self.reverse as number)))
					love.graphics.draw(img, tile_draw_x(v.x + 1), y, math.pi/2, world_draw_scale(), world_draw_scale())
				end
				
				love.graphics.draw(endimg, tile_draw_x(v.x + .5), math.floor(tile_draw_y_raw(v.y + v.rangey - 2)), math.pi/2, world_draw_scale(), world_draw_scale(), 8, 8)
				love.graphics.setScissor()
			end
		end
	end
	
	love.graphics.setColor(1, 1, 1)
	if self.dir == "right" then
		love.graphics.draw(excursionbaseimg, excursionquad[self.quad as integer], tile_draw_x(self.cox-1), math.floor(tile_draw_y_raw(self.coy-1.5)), 0, world_draw_scale(), world_draw_scale())
	elseif self.dir == "left" then
		love.graphics.draw(excursionbaseimg, excursionquad[self.quad as integer], tile_draw_x(self.cox), math.floor(tile_draw_y_raw(self.coy+.5)), math.pi, world_draw_scale(), world_draw_scale())
	elseif self.dir == "up" then
		love.graphics.draw(excursionbaseimg, excursionquad[self.quad as integer], tile_draw_x(self.cox - 1), math.floor(tile_draw_y_raw(self.coy - .5)), -math.pi/2, world_draw_scale(), world_draw_scale())
	elseif self.dir == "down" then
		love.graphics.draw(excursionbaseimg, excursionquad[self.quad as integer], tile_draw_x(self.cox+1), math.floor(tile_draw_y_raw(self.coy-1.5)), math.pi/2, world_draw_scale(), world_draw_scale())
	end
end

function funnel:updaterange()
	self.funneltable = {}
	
	local dir = self.dir
	local startx, starty = self.cox, self.coy
	local rangex, rangey = 0, 0
	local x, y = self.cox, self.coy
	
	local firstcheck = true
	local quit = false
	local collision = false
	
	while x >= 1 and x <= session.mapwidth and y >= 1 and y <= session.mapheight and not collision and (x ~= startx or y ~= starty or dir ~= self.dir or firstcheck == true) and quit == false do
		firstcheck = false
		
		if dir == "right" then
			x = x + 1
			rangex = rangex + 1
		elseif dir == "left" then
			x = x - 1
			rangex = rangex - 1
		elseif dir == "up" then
			y = y - 1
			rangey = rangey - 1
		elseif dir == "down" then
			y = y + 1
			rangey = rangey + 1
		end
		
		--check if current block is a portal
		local opp = "left"
		if dir == "left" then
			opp = "right"
		elseif dir == "up" then
			opp = "down"
		elseif dir == "down" then
			opp = "up"
		end
		
		local portalx: any = nil
		local portaly: any = nil
		local portalfacing: any = nil
		local infacing: any = nil
		local portalrealx: any = nil
		local portalrealy: any = nil
		local portal2realx: any = nil
		local portal2realy: any = nil
		local _gp = {getPortal(x, y, opp)}
		portalx, portaly, portalfacing, infacing, portalrealx, portalrealy, portal2realx, portal2realy = _gp[1], _gp[2], _gp[3], _gp[4], _gp[5], _gp[6], _gp[7], _gp[8]
		
		if portalx ~= false and ((dir == "left" and infacing == "right") or (dir == "right" and infacing == "left") or (dir == "up" and infacing == "down") or (dir == "down" and infacing == "up")) then
			--check if complete entry
			local pass = true
			if dir == "right" then
				if y ~= (portal2realy as number)-1 then
					pass = false
				end
			elseif dir == "left" then
				if y ~= portal2realy then
					pass = false
				end
			elseif dir == "up" then
				if x ~= (portal2realx as number)-1 then
					pass = false
				end
			elseif dir == "down" then
				if x ~= portal2realx then
					pass = false
				end
			end
			
			if pass then
				local dummy = {dir=dir, x=x-rangex, y=y-rangey, rangex=rangex, rangey=rangey, timer=0}
				
				table.insert(self.funneltable as {any}, dummy)
				
				x, y = portalrealx as number, portalrealy as number
			
				dir = portalfacing
				
				if dir == "down" then
					x = x-1
				elseif dir == "left" then
					y = y-1
				end
				
				rangex, rangey = 0, 0
				
				if dir == "right" then
					x = (portalx as number) + 1
				elseif dir == "left" then
					x = (portalx as number) - 1
					rangex = 0
				elseif dir == "up" then
					y = (portaly as number) - 1
				elseif dir == "down" then
					y = (portaly as number) + 1
				end
			end
		end
		
		--doors
		for _, v in pairs(session.objects["door"] as {any:Entity}) do
			if v.active then
				local secondx, secondy = x, y
				if dir == "right" then
					secondy = secondy + 1
				elseif dir == "left" then
					secondy = secondy + 1
				elseif dir == "up" then
					secondx = secondx + 1
				elseif dir == "down" then
					secondx = secondx + 1
				end
				if v.dir == "ver" then
					if (x == v.cox or secondx == v.cox) and ((y == v.coy or y == v.coy-1) or (secondy == v.coy or secondy == v.coy-1)) then
						quit = true
					end
				elseif v.dir == "hor" then
					if (y == v.coy or secondy == v.coy) and ((x == v.cox or x == v.cox+1) or (secondx == v.cox or secondx == v.cox+1)) then
						quit = true
					end
				end
			end
		end
		
		--get collision for next while
		if dir == "up" or dir == "down" then
			if not inmap(x+1, y) or (tilequads[session.map[x][y][1]]:getproperty("collision", x, y) and tilequads[session.map[x][y][1]]:getproperty("grate", x, y) == false) or
			(tilequads[session.map[x+1][y][1]]:getproperty("collision", x+1, y) and tilequads[session.map[x+1][y][1]]:getproperty("grate", x+1, y) == false) then
				collision = true
			end
		else
			if not inmap(x, y+1) or (tilequads[session.map[x][y][1]]:getproperty("collision", x, y) and tilequads[session.map[x][y][1]]:getproperty("grate", x, y) == false) or
			(tilequads[session.map[x][y+1][1]]:getproperty("collision", x, y+1) and tilequads[session.map[x][y+1][1]]:getproperty("grate", x, y+1) == false) then
				collision = true
			end
		end
	end
	
	if rangex ~= 0 or rangey ~= 0 then
		local dummy = {dir=dir, x=x-rangex, y=y-rangey, rangex=rangex, rangey=rangey, timer=0}
		
		table.insert(self.funneltable as {any}, dummy)
		
		if not self.lastblock or (self.lastblock[1] == x+rangex and self.lastblock[2] == y+rangey) then
			for _, v in pairs(self.funneltable as {any:Entity}) do
				v.timer = (math.abs(v.rangex as number)+math.abs(v.rangey as number)) as number
			end
		end	
		
		self.lastblock = {x+rangex, y+rangey}
	end
end

function funnel:input(t: any, input: any)
	if input == "reverse" then
		if t == "on" and self.input1state == "off" then
			self.reverse = -(self.reverse as number)
		elseif t == "off" and self.input1state == "on" then
			self.reverse = -(self.reverse as number)
		elseif t == "toggle" then
			self.reverse = -(self.reverse as number)
		end
		
		self.input1state = t
		
		for _, v in pairs(self.funneltable as {any:Entity}) do
			v.timer = 0
		end
	elseif input == "power" then
		if t == "on" and self.input2state == "off" then
			self.power = not self.power
		elseif t == "off" and self.input2state == "on" then
			self.power = not self.power
		elseif t == "toggle" then
			self.power = not self.power
		end
		
		self.input2state = t
	end
end