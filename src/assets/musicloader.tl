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
	local n = name as string
	local filepath = getfilepath(n)
	if not filepath then
		print(string.format("can't load music %q: can't find file!", n))
		return false
	end
	
	if not self.loaded[filepath as string] then
		local loaded, source = pcall(love.audio.newSource, filepath as string, MUSIC_SOURCE_TYPE)
		if loaded then
			-- all music should loop
			(source as Source):setLooping(true)
			(source as Source):setPitch(self.pitch)
			self.loaded[n] = source as Source
		else
			print(string.format("can't load music %q: can't create source!", filepath as string))
			return false
		end
	end
	
	return true
end

function music:play(name: any, fast: any)
	local n = name as string
	if fast then
		local newname = n:sub(0, -5) .. "-fast" .. n:sub(-4)
		if getfilepath(newname) then
			n = newname
		end
	end
	
	-- try to load source from disk if it hasn't been loaded already
	if not self.loaded[n] and not self:load(n) then
		return
	end
	
	if self.loaded[n] then
		if soundenabled then
			self.loaded[n]:stop()
			self.loaded[n]:seek(0)
			self.loaded[n]:setVolume(volumemusic or 1)
			self.loaded[n]:play()
		end
	end
end

function music:stop(name: any, fast: any)
	local n = name as string
	if fast then
		local newname = n:sub(0, -5) .. "-fast" .. n:sub(-4)
		if getfilepath(newname) then
			n = newname
		end
	end
	
	if self.loaded[n] then
		self.loaded[n]:stop()
		self.loaded[n]:seek(0)
	end
end

function music:update()
	for filepath, source in pairs(self.loaded) do
		source:setPitch(self.pitch)
	end
end

function music:setVolume(n)
	for i, v in pairs(self.loaded) do
		v:setVolume(volumemusic or 1)
	end
end
