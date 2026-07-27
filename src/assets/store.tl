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

function AssetStore.load_image(path: string): Image|nil
	ensure_love()
	return love.graphics.newImage(path)
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
