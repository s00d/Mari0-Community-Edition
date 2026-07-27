--[[ Central asset registry (Teal).
     Defaults live under assets/graphics/DEFAULT and assets/sounds/.
     Record type: types/entities.d.tl (AssetStore).
]]

rawset(_G, "AssetStore", rawget(_G, "AssetStore") or {})

-- Static path prefixes (also copied onto instances in new).
AssetStore.ROOT = "assets/"
AssetStore.GRAPHICS = "assets/graphics/"
AssetStore.SOUNDS = "assets/sounds/"
AssetStore.SHADERS = "assets/shaders/"
AssetStore.CHARACTERS = "assets/characters/"
AssetStore.ENEMIES = "assets/enemies/"

function AssetStore.new(music_type: string|nil): AssetStore
	local self = setmetatable({}, { __index = AssetStore }) as AssetStore
	self.images = {}
	self.sounds = {}
	self.music_type = music_type or "stream"
	self.ROOT = AssetStore.ROOT
	self.GRAPHICS = AssetStore.GRAPHICS
	self.SOUNDS = AssetStore.SOUNDS
	self.SHADERS = AssetStore.SHADERS
	self.CHARACTERS = AssetStore.CHARACTERS
	self.ENEMIES = AssetStore.ENEMIES
	return self
end

local function ensure_love()
	assert(love and love.graphics and love.audio, "AssetStore requires LÖVE runtime")
end

function AssetStore:register_image(id: string, path: string)
	self.images[id] = {
		path = path,
		kind = "image",
		object = nil,
		default_path = path,
	}
end

function AssetStore:register_sound(id: string, path: string)
	self.sounds[id] = {
		path = path,
		kind = "sound",
		object = nil,
		default_path = path,
	}
end

function AssetStore:get_image(id: string): Image
	ensure_love()
	local e = self.images[id]
	if not e then
		error("AssetStore: unknown image id '" .. id .. "'")
	end
	if not e.object then
		e.object = love.graphics.newImage(e.path)
	end
	return e.object as Image
end

function AssetStore:get_sound(id: string): Source
	ensure_love()
	local e = self.sounds[id]
	if not e then
		error("AssetStore: unknown sound id '" .. id .. "'")
	end
	if not e.object then
		e.object = love.audio.newSource(e.path, self.music_type)
	end
	return e.object as Source
end

function AssetStore:override_image(id: string, path: string)
	local e = self.images[id]
	if not e then
		self:register_image(id, path)
		e = self.images[id]
	end
	e.path = path
	e.object = nil
end

function AssetStore:override_sound(id: string, path: string)
	local e = self.sounds[id]
	if not e then
		self:register_sound(id, path)
		e = self.sounds[id]
	end
	e.path = path
	e.object = nil
end

function AssetStore:restore_image_defaults()
	for _, e in pairs(self.images) do
		e.path = e.default_path
		e.object = nil
	end
end

function AssetStore:restore_sound_defaults()
	for _, e in pairs(self.sounds) do
		e.path = e.default_path
		e.object = nil
	end
end

function AssetStore:restore_defaults()
	self:restore_image_defaults()
	self:restore_sound_defaults()
end

function AssetStore:export_image_globals(ids: {string})
	for _, id in ipairs(ids) do
		rawset(_G, id .. "img", self:get_image(id))
	end
end

-- mappack → character folder → DEFAULT graphics chain (disk path, no LÖVE object).
function AssetStore:resolve_path(filename: string, mappack_dir: string, character_dir: string|nil): string
	if love and love.filesystem.getInfo(mappack_dir .. "/" .. filename) then
		return mappack_dir .. "/" .. filename
	end
	if character_dir and love.filesystem.getInfo(character_dir .. "/" .. filename) then
		return character_dir .. "/" .. filename
	end
	return AssetStore.GRAPHICS .. "DEFAULT/" .. filename
end

function AssetStore:resolve_image_data(filename: string, mappack_dir: string, character_dir: string|nil): ImageData
	ensure_love()
	return love.image.newImageData(self:resolve_path(filename, mappack_dir, character_dir))
end

function AssetStore:release_scope(scope: string)
	if scope == "mappack" then
		self:restore_image_defaults()
	end
end

-- Path → Image cache: enemies_load / mappack assets used to newImage every level
-- transition (GPU upload storm → Love 12 Metal hang until focus cycle).
local image_path_cache: {string: Image} = {}

function AssetStore.load_image(path: string): Image|nil
	ensure_love()
	local cached = image_path_cache[path]
	if cached then
		return cached
	end
	local img = love.graphics.newImage(path)
	if img then
		image_path_cache[path] = img
	end
	return img
end

function AssetStore.clear_image_path_cache()
	image_path_cache = {}
end

function AssetStore.load_image_data(imagedata: ImageData): Image|nil
	ensure_love()
	return love.graphics.newImage(imagedata)
end

function AssetStore.load_sound(path: string, source_type: string): Source|nil
	ensure_love()
	return love.audio.newSource(path, source_type)
end

return AssetStore
