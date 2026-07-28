--[[ Teal port of root dialogbox.lua ]]

rawset(_G, "dialogbox", rawget(_G, "dialogbox") or {})

-- Bottom gap so floor characters stay visible under the box (was flush to screen edge).
local BOX_HEIGHT = 45
local MARGIN = 4
local BOTTOM_GAP = 52
local LINE_HEIGHT = 10

function dialogbox.new(_: dialogbox, text: any, speaker: any): dialogbox
	local self = setmetatable({}, { __index = dialogbox }) as dialogbox
	self:init(text, speaker)
	return self
end

function dialogbox:init(text: any, speaker: any)
	self.text = string.lower(text as string)
	self.textsplit = strsplit(self.text, " ")
	self.speaker = string.lower(speaker as string)
	self.timer = 0
	self.curchar = 0
	self.chartimer = 0
	
	self.lifetime = 5
	self.chardelay = 0.05
	--initialize prefixes
	self.hasaprefix = false
	for n, i in pairs(self.textsplit as {any:any}) do
		local prefix = string.sub(i as string,1,3)
		if  prefix == "db:" then
			print(i)
			(self.textsplit as {any:any})[n] = string.sub(i as string,4)
			self.hasaprefix = true
		elseif prefix == "gb:" then
			print(i, "bool")
			(self.textsplit as {any:any})[n] = globoolSH(string.sub(i as string,4), "check")
			self.hasaprefix = true
		elseif prefix == "gi:" then
			print(i, "int")
			(self.textsplit as {any:any})[n] = globints[string.sub(i as string,4)] or "uninit"
			self.hasaprefix = true
		elseif prefix == "bi:" then
			print(i, "g_")
			(self.textsplit as {any:any})[n] = tostring((_G as Dyn)[string.sub(i as string,4)] or "typo")
			self.hasaprefix = true
		elseif prefix == "bb:" then
			local splitup = strsplit(string.sub(i as string,4), "/")
				if globoolSH(splitup[1], "check") then
					(self.textsplit as {any:any})[n] = splitup[2]
				else
					(self.textsplit as {any:any})[n] = splitup[2]
				end
			self.hasaprefix = true
		end
	end
	if self.hasaprefix then
	self.text = table.concat(self.textsplit as {string}, " ")
	end
	
	--initialize colors
	local curcolor: {any} = {255, 255, 255}
	local i = 1
	self.textcolors = {}
	while i <= #self.text do
		if string.sub(self.text, i, i) == "%" then
			local j = i
			repeat
				j = j + 1
			until string.sub(self.text, j, j) == "%" or j > #self.text
			
			curcolor = strsplit(string.sub(self.text, i+1, j-1), ",") as {number}
			
			--take out that string
			self.text = string.sub(self.text, 1, i-1) .. string.sub(self.text, j+1)
		else
			(self.textcolors as {any:any})[i] = {tonumber(curcolor[1]) / DISK_COLOR_MAX, tonumber(curcolor[2]) / DISK_COLOR_MAX, tonumber(curcolor[3]) / DISK_COLOR_MAX}
			i = i + 1
		end
		
		
	end
end

function dialogbox:update(dt: number): boolean
	if self.curchar < #self.text then
		self.chartimer = self.chartimer + dt
		while self.chartimer > self.chardelay do
			self.curchar = self.curchar + 1
			self.chartimer = self.chartimer - self.chardelay
		end
	else
		self.timer = self.timer + dt
		if self.timer > self.lifetime then
			return true
		end
	end
end

-- Word-aware layout: map each visible character index → (col, row). Avoids mid-word breaks like "BLOCK\\nS".
local function layout_lines(text: string, charsx: integer): {integer:{integer}}, integer
	local pos: {integer:{integer}} = {}
	local row, col = 1, 1
	local i = 1
	local n = #text
	while i <= n do
		if col > charsx then
			row = row + 1
			col = 1
		end
		-- try to place next word if at start of word
		if (i == 1 or string.sub(text, i - 1, i - 1) == " ") and string.sub(text, i, i) ~= " " then
			local j = i
			while j <= n and string.sub(text, j, j) ~= " " do
				j = j + 1
			end
			local wlen = j - i
			if col > 1 and col + wlen - 1 > charsx then
				row = row + 1
				col = 1
			end
		end
		pos[i] = { col, row }
		col = col + 1
		i = i + 1
	end
	return pos, row
end

function dialogbox:draw()
	local boxheight = BOX_HEIGHT
	local margin = MARGIN
	local bottom_gap = BOTTOM_GAP
	local lineheight = LINE_HEIGHT
	local box_top = height * 16 - boxheight - margin - bottom_gap

	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.rectangle("fill", scale * margin, box_top * scale, (width * 16 - margin * 2) * scale, boxheight * scale)
	love.graphics.setColor(1, 1, 1)
	drawrectangle(5, box_top + 1, (width * 16 - margin * 2 - 2), boxheight - 2)
	
	local availablepixelsx = width*16-margin*2-6
	local availablepixelsy = boxheight-5
	
	local charsx = math.floor(availablepixelsx / 8)
	local charsy = math.floor(availablepixelsy / lineheight)

	local layout = layout_lines(self.text, charsx)
	
	for i = 1, self.curchar do
		local cell = (layout as {integer:{integer}})[i as integer]
		if cell then
			local x = cell[1]
			local y = cell[2]
			
			if y <= charsy then
				love.graphics.setColor((self.textcolors as {any:any})[i])
				properprint(string.sub(self.text, i as integer, i as integer), math.floor((7+(x-1)*8)*scale), math.floor((box_top+4+(y-1)*lineheight)*scale), nil)
			else
				--abort!
				self.curchar = #self.text
			end
		end
	end
	
	if self.speaker then
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.rectangle("fill", scale*margin, (box_top-10)*scale, (5+#self.speaker*8)*scale, 10*scale)
		
		love.graphics.setColor(self.color or {232/255, 130/255, 30/255})
		properprint(self.speaker, (margin+2)*scale, (box_top-9)*scale)
	end
end
