--[[ Teal port of root musicloader.lua ]]

music = ({
	loaded = {},
	pitch = 1,
	list = {
		"overworld.ogg",
		"underground.ogg",
		"castle.ogg",
		"underwater.ogg",
		"starmusic.ogg",
	},
	list_fast = {
		"overworld-fast.ogg",
		"underground-fast.ogg",
		"castle-fast.ogg",
		"underwater-fast.ogg",
		"starmusic-fast.ogg",
	},
} as MusicPlayer)


global function getfilepath(name: any): any
	local musicpaths = {"assets/sounds/", "mappacks/" .. mappack .. "/music/"}
	
	for i = 1, #musicpaths do
		if love.filesystem.getInfo(musicpaths[i] .. (name as string), "file") then
			return musicpaths[i] .. (name as string)
		end
	end
	return nil
end

function music:load(name: any): boolean
	local filepath = getfilepath(name)
	if not filepath then
		print(string.format("can't load music %q: can't find file!", name))
		return false
	end
	
	if not self.loaded[filepath] then
		local loaded, source = pcall(love.audio.newSource, filepath, MUSIC_SOURCE_TYPE)
		if loaded then
			-- all music should loop
			source:setLooping(true)
			source:setPitch(self.pitch)
			self.loaded[name] = source
		else
			print(string.format("can't load music %q: can't create source!", filepath))
			return false
		end
	end
	
	return true
end

function music:play(name: any, fast: any)
	if fast then
		local ns = name as string
		local newname = ns:sub(0, -5) .. "-fast" .. ns:sub(-4)
		if getfilepath(newname) then
			name = newname
		end
	end
	
	-- try to load source from disk if it hasn't been loaded already
	if not self.loaded[name] and not self:load(name) then
		return
	end
	
	if self.loaded[name] then
		if soundenabled then
			self.loaded[name]:stop()
			self.loaded[name]:seek(0)
			self.loaded[name]:setVolume(volumemusic or 1)
			self.loaded[name]:play()
		end
	end
end

function music:stop(name: any, fast: any)
	if fast then
		local ns = name as string
		local newname = ns:sub(0, -5) .. "-fast" .. ns:sub(-4)
		if getfilepath(newname) then
			name = newname
		end
	end
	
	if self.loaded[name] then
		self.loaded[name]:stop()
		self.loaded[name]:seek(0)
	end
end

function music:update(): any...
	for filepath, source in pairs(self.loaded) do
		source:setPitch(self.pitch)
	end
end

function music:setVolume(n)
	for i, v in pairs(self.loaded) do
		v:setVolume(volumemusic or 1)
	end
end
