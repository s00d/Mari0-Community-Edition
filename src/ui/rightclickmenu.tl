--[[ Ported from root rightclickmenu.lua. ]]

rawset(_G, "rightclickmenu", rawget(_G, "rightclickmenu") or {})

function rightclickmenu.new(_: rightclickmenu, x: number, y: number, elements: any, tx: any, ty: any): rightclickmenu
	local self = setmetatable({}, { __index = rightclickmenu }) as rightclickmenu
	self:init(x, y, elements, tx, ty)
	return self
end

rightclickwidth = 110
rightclickcellheight = 9
rightclickcellspacing = 2

rightclickelementslist = {"scrollbar", "input", "checkbox", "directionbuttons", "submenu", "regionselect"}

function rightclickmenu:init(x: number, y: number, elements: any, tx: any, ty: any)
	self.elements = elements as {any}
	self.x = x
	self.y = y
	
	self.tx = tx
	self.ty = ty
	
	--keep menu in window
	if self.x + rightclickwidth > width*16 then
		self.x = width*16 - rightclickwidth
	end
	
	if self.y + ((rightclickcellheight+rightclickcellspacing)*#self.elements+1) > height*16 then
		self.y = height*16 - ((rightclickcellheight+rightclickcellspacing)*#self.elements+1)
	end
	
	self.t = {}
	self.variables = {}
	local actuali = 1
	for i = 1, #self.elements do
		local v = self.elements[i] as RightClickVar
		local set = false
		local variablesadd = {}
		if v.t == "text" then
			table.insert(self.t, guielement:new(v.t, self.x, self.y+2+(rightclickcellheight+rightclickcellspacing)*(i-1), v.value))
			table.insert(self.variables, v)
			
		elseif v.t == "button" then
			table.insert(self.t, guielement:new(v.t, self.x, self.y+(rightclickcellheight+rightclickcellspacing)*(i-1), v.value, nil, nil, nil, nil, rightclickwidth-3))
			table.insert(self.variables, v)
			
		elseif v.t == "linkbutton" then
			table.insert(self.t, guielement:new("button", self.x, self.y+(rightclickcellheight+rightclickcellspacing)*(i-1), v.value, rightclickmenu.linkcallback, nil, {nil, self, v.link, false}, nil, rightclickwidth-14))
			table.insert(self.t, guielement:new("button", self.x+rightclickwidth-11, self.y+(rightclickcellheight+rightclickcellspacing)*(i-1), "x", rightclickmenu.linkcallback, nil, {nil, self, v.link, true}, nil, 8))
			(self.t[#self.t] as guielement).textcolor = {0.8, 0, 0}
			table.insert(self.variables, v)
			
		elseif v.t == "regionselect" then
			table.insert(self.t, guielement:new("button", self.x, self.y+(rightclickcellheight+rightclickcellspacing)*(i-1), v.value, rightclickmenu.regioncallback, nil, {nil, self, v.region}, nil, rightclickwidth-3))
			table.insert(self.variables, v)
			
		elseif v.t == "scrollbar" then
			local current: number = 0
			local cell = map[tx as number][ty as number][actuali+2]
			if string.sub(cell as string, 1, 1) == "m" then
				current = -(tonumber(string.sub(cell as string, 2)) or 0)
			else
				current = tonumber(cell as string) or 0
			end
			
			table.insert(self.t, guielement:new(v.t, self.x+1, self.y+1+(rightclickcellheight+rightclickcellspacing)*(i-1), rightclickwidth-2, 33, rightclickcellheight, current, "hor", true, v.min, v.max, v.step))
			set = true
			local scrollel = self.t[#self.t] as guielement
			scrollel.backgroundcolor = {0, 0, 0, 1}
			
		elseif v.t == "input" then
			local default = v.default
			if map[tx as number][ty as number][actuali+2] then
				default = map[tx as number][ty as number][actuali+2]
			end
			table.insert(self.t, guielement:new(v.t, self.x, self.y+(rightclickcellheight+rightclickcellspacing)*(i-1), rightclickwidth/8-5/8, nil, default, v.max))
			set = true
			
		elseif v.t == "checkbox" then
			local start = false
			if map[tx as number][ty as number][actuali+2] == "true" then
				start = true
			end
			table.insert(self.t, guielement:new(v.t, self.x+1, self.y+1+(rightclickcellheight+rightclickcellspacing)*(i-1), nil, start, v.text))
			set = true
			
		elseif v.t == "directionbuttons" then
			local j = 0
			local dirbtns: {guielement} = {}
			
			for k = 1, 6 do
				local dir: string = "hor"
				if k == 1 then
					dir = "hor"
				elseif k == 2 then
					dir = "ver"
				elseif k == 3 then
					dir = "left"
				elseif k == 4 then
					dir = "up"
				elseif k == 5 then
					dir = "right"
				elseif k == 6 then
					dir = "down"
				end
				
				if (v as Dyn)[dir] then
					table.insert(dirbtns, guielement:new("button", self.x+j*12, self.y+(rightclickcellheight+rightclickcellspacing)*(i-1), "_dir" .. k, rightclickmenu.directioncallback, nil, {nil, self, #self.t+1, dir}, nil, rightclickcellheight-1))
					j = j + 1
					
					if map[tx as number][ty as number][actuali+2] == dir then
						dirbtns[#dirbtns].bordercolor = {1, 0, 0}
						dirbtns[#dirbtns].bordercolorhigh = {1, 0.5, 0.5}
						
						
						variablesadd["value"] = dir
					end				
				end
			end
			
			table.insert(self.t, dirbtns)
			set = true
			
		elseif v.t == "submenu" then
		
			local values: {any} = {}
			if type(v.entries) == "function" then
				values = (v.entries as function(): {any})()
			else
				values = v.entries as {any}
			end
			
			local start = map[tx as number][ty as number][actuali+2]
			
			if v.actualvalue then
				for i, w in pairs(values as {any:any}) do
					if w == start then
						start = i
					end
				end
			end
			
			if not tonumber(start) then
				start = 1
			end
			
			table.insert(self.t, guielement:new(v.t, self.x, self.y+(rightclickcellheight+rightclickcellspacing)*(i-1), 12.5, v.width or 6, values, start))
			(self.t[#self.t] as {string:any}).actualvalue = v.actualvalue
			set = true
			
		end
		
		if set then
			actuali = actuali + 1
			table.insert(self.variables, v)
			
			for j, k in pairs(variablesadd) do
				(self.variables[#self.variables] as {string:any})[j as string] = k
			end
		end
		
		-- Skip empty spacer entries that do not create a GUI element
		if #self.t > 0 and self.t[#self.t] then
			(self.t[#self.t] as guielement).active = true
		end
	end
end

function rightclickmenu:update(dt: number): any...
	for i = 1, #self.t do
		local entry = self.t[i] as Dyn
		if type(entry[1]) == "table" then
			local arr = entry as {guielement}
			for j = 1, #arr do
				arr[j]:update(dt)
			end
		else
			(entry as guielement):update(dt)
		end
	end
end

function rightclickmenu:draw()
	love.graphics.setColor(0.2, 0.2, 0.2, 0.7*rightclicka)
	--background
	love.graphics.rectangle("fill", self.x*scale, self.y*scale, rightclickwidth*scale, ((rightclickcellheight+rightclickcellspacing)*#self.elements+1)*scale)
	
	for i, v in pairs(self.t as {any:any}) do
		local entry = self.t[i] as Dyn
		if type(entry[1]) == "table" then
			local arr = entry as {guielement}
			for j = 1, #arr do
				arr[j]:draw(rightclicka)
			end
		else
			(entry as guielement):draw(rightclicka)
		end
	end
end

function rightclickmenu:mousepressed(x: any, y: any, button: any): boolean
	local r = false
	for i = 1, #self.t do
		local entry = self.t[i] as Dyn
		if type(entry[1]) == "table" then
			local arr = entry as {guielement}
			for j = 1, #arr do
				if arr[j]:click(x as number, y as number, button) then
					r = true
				end
			end
		else
			if (entry as guielement):click(x as number, y as number, button) then
				r = true
			end
		end
	end
	
	if r then
		return true
	end
	
	if (x as number) < self.x*scale or (x as number) >= (self.x+rightclickwidth)*scale or (y as number) < self.y*scale or (y as number) > (self.y+(rightclickcellheight+rightclickcellspacing)*#self.elements+1)*scale then
		return false
	end
	
	return true
end

function rightclickmenu:mousereleased(x: any, y: any, button: any)
	for i = 1, #self.t do
		local entry = self.t[i] as Dyn
		if type(entry[1]) == "table" then
			local arr = entry as {guielement}
			for j = 1, #arr do
				arr[j]:unclick(x as number, y as number, button)
			end
		else
			(entry as guielement):unclick(x as number, y as number, button)
		end
	end
end

function rightclickmenu:keypressed(key: any)
	for i = 1, #self.t do
		local el = self.t[i] as guielement
		if el.type then
			if el:keypress(key as string) then
				return
			end
		end
	end
end

function rightclickmenu:textinput(text: any)
	for i = 1, #self.t do
		local el = self.t[i] as guielement
		if el.type then
			if el:textinput(text as string) then
				return
			end
		end
	end
end

function rightclickmenu:linkcallback(self: rightclickmenu, t: any, rem: any)
	if rem then
		removelink(self.tx, self.ty, t)
	else
		startlinking(self.tx, self.ty, t)
	end
end

function rightclickmenu:regioncallback(self: rightclickmenu, t: any)
	startregion(self.tx, self.ty, t)
end

function rightclickmenu:directioncallback(self: rightclickmenu, y: any, x: any)
	local arr = self.t[y as integer] as {guielement}
	for i = 1, #arr do
		arr[i].bordercolor = {0.5, 0.5, 0.5}
		arr[i].bordercolorhigh = {1, 1, 1}
	end
	
	for i = 1, #arr do
		if arr[i].arguments[4] == x then
			arr[i].bordercolor = {1, 0, 0}
			arr[i].bordercolorhigh = {1, 0.5, 0.5}
			break
		end
	end
	
	self.variables[y as integer].value = x
end

return { ported = true }
