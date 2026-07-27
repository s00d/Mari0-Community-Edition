--[[ Teal port of root customhats.lua ]]

--Not the hatloader mod.

global function loadhat(...: any): any
	local path = ...
	local s = love.filesystem.read(path as string)
	if not s then
		return
	end
	
	local s1 = strsplit(s, "|")
	
	if #s1 ~= 8 then
		return
	end
	
	if not love.filesystem.getInfo("hats/" .. s1[7] .. ".png") or not love.filesystem.getInfo("hats/" .. s1[8] .. ".png") then
		return
	end
	
	table.insert(hat, {x = tonumber(s1[1]) or 0, y = tonumber(s1[2]) or 0, height = tonumber(s1[3]) or 0, graphic = AssetStore.load_image("hats/" .. s1[7] .. ".png")})
	table.insert(bighat, {x = (tonumber(s1[4]) or 0) as number, y = (tonumber(s1[5]) or 0) as number, height = (tonumber(s1[6]) or 0) as number, graphic = AssetStore.load_image("hats/" .. s1[8] .. ".png")})
	
	hatcount = hatcount + 1
end

local files = love.filesystem.getDirectoryItems("hats")

for i, v in ipairs(files) do
	if string.sub(v, -3, -1) == "txt" then
		loadhat("hats/" .. v)
	end
end