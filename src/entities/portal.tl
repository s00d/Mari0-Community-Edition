--[[ Teal port of root portal.lua ]]

rawset(_G, "portal", rawget(_G, "portal") or {})

local function portal_dyn(self: portal): {string:any}
	return self as {string:any}
end

function portal.new(_: portal, number: any, c1: any, c2: any): portal
	local self = setmetatable({}, { __index = portal }) as portal
	self:init(number, c1, c2)
	return self
end

function portal:init(number: any, c1: any, c2: any)	
	self.number = number as number
	self.portal1color = (c1 or {60 / 255, 188 / 255, 252 / 255}) as {number}
	self.portal2color = (c2 or {232 / 255, 130 / 255, 30 / 255}) as {number}
	self.animationtimer = 0
	self.portalframe = 1
	self.openscale = {0, 0}
	
	self.x1, self.y1, self.facing1, self.x2, self.y2, self.facing2 = false, false, false, false, false, false
end

function portal:createportal(i: number, cox: any, coy: any, side: any, tendency: any)
	if cox and tendency then
		moveoutportal(i)
	
		--remove the portal temporarily so that it doesn't obstruct itself
		local oldx: number|boolean
		local oldy: number|boolean
		local oldfacing: any
		if i == 1 then
			oldx, oldy, oldfacing = self.x1 as number|boolean, self.y1 as number|boolean, self.facing1
			self.x1, self.y1 = false, false
		else
			oldx, oldy, oldfacing = self.x2 as number|boolean, self.y2 as number|boolean, self.facing2
			self.x2, self.y2 = false, false
		end
		
		local newx, newy = getportalposition(i, cox as number, coy as number, side, tendency)
		
		if newx and (newx ~= oldx or newy ~= oldy or side ~= oldfacing) then
			if i == 1 then
				self.x1 = newx as number|boolean
				self.y1 = newy as number|boolean
				self.facing1 = side
			else
				self.x2 = newx as number|boolean
				self.y2 = newy as number|boolean
				self.facing2 = side
			end
	
			--physics
			--Recreate old hole
			if oldfacing == "up" then	
				modifyportaltiles(oldx, oldy, 1, 0, self, i, "add")
			elseif oldfacing == "down" then	
				modifyportaltiles(oldx, oldy, -1, 0, self, i, "add")
			elseif oldfacing == "left" then	
				modifyportaltiles(oldx, oldy, 0, -1, self, i, "add")
			elseif oldfacing == "right" then	
				modifyportaltiles(oldx, oldy, 0, 1, self, i, "add")
			end
			
			local otheri = 1
			if i == 1 then
				otheri = 2
			end
			
			if oldx == false then --Remove blocks from other portal
				local x: any
				local y: any
				local side: any
				if otheri == 1 then
					side = self.facing1
					x, y = self.x1, self.y1
				else
					side = self.facing2
					x, y = self.x2, self.y2
				end
					
				if side == "up" then
					modifyportaltiles(x, y, 1, 0, self, otheri, "remove")
				elseif side == "down" then
					modifyportaltiles(x, y, -1, 0, self, otheri, "remove")
				elseif side == "left" then
					modifyportaltiles(x, y, 0, -1, self, otheri, "remove")
				elseif side == "right" then
					modifyportaltiles(x, y, 0, 1, self, otheri, "remove")
				end
			end
			
			if i == 1 then
				playsound("portal1open")
			else
				playsound("portal2open")
			end
			
			modifyportalwalls()
			updateranges()
			self.openscale[i as integer] = 0
		else
			--recreate the temporarily removed portal
			local d = portal_dyn(self)
			d["x" .. i], d["y" .. i] = oldx, oldy
		end
	end
end

function portal:removeportal(i: number)
	local d = portal_dyn(self)
	if d["x" .. i] then
		moveoutportal(i)
		local otheri = 1
		if i == 1 then
			otheri = 2
		end
		
		if d["facing" .. i] == "up" then	
			modifyportaltiles(d["x" .. i], d["y" .. i], 1, 0, self, i, "add")
		elseif d["facing" .. i] == "down" then	
			modifyportaltiles(d["x" .. i], d["y" .. i], -1, 0, self, i, "add")
		elseif d["facing" .. i] == "left" then	
			modifyportaltiles(d["x" .. i], d["y" .. i], 0, -1, self, i, "add")
		elseif d["facing" .. i] == "right" then	
			modifyportaltiles(d["x" .. i], d["y" .. i], 0, 1, self, i, "add")
		end
		
		if d["x" .. otheri] then
			if d["facing" .. otheri] == "up" then	
				modifyportaltiles(d["x" .. otheri], d["y" .. otheri], 1, 0, self, otheri, "add")
			elseif d["facing" .. otheri] == "down" then	
				modifyportaltiles(d["x" .. otheri], d["y" .. otheri], -1, 0, self, otheri, "add")
			elseif d["facing" .. otheri] == "left" then	
				modifyportaltiles(d["x" .. otheri], d["y" .. otheri], 0, -1, self, otheri, "add")
			elseif d["facing" .. otheri] == "right" then	
				modifyportaltiles(d["x" .. otheri], d["y" .. otheri], 0, 1, self, otheri, "add")
			end
		end
		
		d["x" .. i] = false
		d["y" .. i] = false
		d["facing" .. i] = false
		
		modifyportalwalls()
		for j = 1, 6 do
			objects["portalwall"][self.number .. "-" .. i .. "-" .. j] = nil
		end
		updateranges()
	end
end

function portal:update(dt: number)
	self.animationtimer = self.animationtimer + dt
	while self.animationtimer > portalanimationdelay do
		self.animationtimer = 0
		self.portalframe = self.portalframe + 1
		if self.portalframe > portalanimationcount then
			self.portalframe = 1
		end
	end
	
	for i = 1, 2 do
		self.openscale[i as integer] = math.min(1, self.openscale[i as integer]+dt*15)
	end
end

function portal:draw()
	local d = portal_dyn(self)
	for i = 1, 2 do
		if d["x" .. i] ~= false then
			local px = d["x" .. i] as number
			local py = d["y" .. i] as number
			--Standard values "up"
			local rotation: number = 0
			local offsetx, offsety = 16, -3
			if d["facing" .. i] == "right" then
				rotation = math.pi/2
				offsetx, offsety = 11, 8
			elseif d["facing" .. i] == "down" then
				rotation = math.pi
				offsetx, offsety = 0, 3
			elseif d["facing" .. i] == "left" then
				rotation = math.pi*1.5
				offsetx, offsety = 5, -8
			end
			
			local _ = 100
			if self.x2 and self.x1 then
				--portal glow
				love.graphics.setColor(1, 1, 1, (80 - math.abs(self.portalframe-3)*10)/255)
				love.graphics.draw(portalglowimg, math.floor(((px-1-xscroll)*16+offsetx)*scale), math.floor(((py-yscroll-1)*16+offsety)*scale), rotation, scale*self.openscale[i as integer], scale, 16, 20)
				love.graphics.setColor(1, 1, 1, 1)
			end
			
			local pcol = d["portal" .. i .. "color"] as {number}
			love.graphics.setColor(pcol[1], pcol[2], pcol[3], pcol[4] or 1)
			love.graphics.draw(portalimg, portalquad[self.portalframe as integer], math.floor(((px-1-xscroll)*16+offsetx)*scale), math.floor(((py-yscroll-1)*16+offsety)*scale), rotation, scale*self.openscale[i as integer], scale, 16, 8)
		end
	end
end
