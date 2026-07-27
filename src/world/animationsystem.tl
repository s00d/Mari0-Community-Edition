--[[ Teal port of root animationsystem.lua ]]

global function animationsystem_load()
	animationtriggerfuncs = {}
	animations = {}
	
	local dir = love.filesystem.getDirectoryItems("mappacks/" .. mappack .. "/animations")
	
	for i = 1, #dir do
		if string.sub(dir[i], -4) == "json" then
			table.insert(animations, animation:new("mappacks/" .. mappack .. "/animations/" .. dir[i], dir[i]))
		end
	end
end

global function animationsystem_update(dt: number)
	if not editormode then
		for _, v in ipairs(animations) do
			local anim = v as Dyn
			(anim["update"] as function(any, any))(v, dt)
		end
	end
end

global function animationsystem_draw()
	if not editormode then
		for _, v in ipairs(animations) do
			local anim = v as Dyn
			(anim["draw"] as function(any))(v)
		end
	end
end
