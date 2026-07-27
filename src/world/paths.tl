--[[ Shared filesystem path helpers (Stage 2.3). ]]

require "world.levelio"

global function mappack_path(name: string): string
	return "mappacks/" .. name
end

global function mappack_level_path(mappack_name: string, world: number|string, level: number|string, sublevel?: number): string
	return mappack_path(mappack_name) .. "/" .. level_filename(world, level, sublevel) .. ".txt"
end

global function level_name(world: number|string, level: number|string, sublevel?: number): string
	return level_filename(world, level, sublevel)
end

return {
	mappack_path = mappack_path,
	mappack_level_path = mappack_level_path,
	level_name = level_name,
}
