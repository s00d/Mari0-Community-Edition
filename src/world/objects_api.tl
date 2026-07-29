--[[ Thin helpers over global objects — same storage, less string noise. ]]

global OBJ_PLAYER = "player"
global OBJ_ENEMY = "enemy"
global OBJ_DOOR = "door"
global OBJ_BOWSER = "bowser"

global function obj_group(name: string): {any:Entity}
	return objects[name] as {any:Entity}
end

global function obj_insert(name: string, e: Entity)
	table.insert(obj_group(name), e)
end

global function obj_each_group(name: string, fn: function(Entity))
	for _, e in pairs(obj_group(name)) do
		fn(e)
	end
end

global function obj_draw_group(name: string)
	for _, e in pairs(obj_group(name)) do
		e:draw()
	end
end
