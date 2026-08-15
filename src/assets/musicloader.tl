--[[ Teal port of root musicloader.lua — play/loop/pitch via ripple (tag music). ]]

require("assets.audio")
local ripple = require("ripple")

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
	local musicpaths = {"assets/sounds/", mappack_path(mappack) .. "/music/"}

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

	if not self.loaded[n] then
		local loaded, source = pcall(love.audio.newSource, filepath as string, MUSIC_SOURCE_TYPE)
		if loaded then
			local sound = ripple.newSound(source as Source, {
				loop = true,
				tags = { audio_tag_music },
			})
			sound.loop = true
			self.loaded[n] = sound
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

	if not self.loaded[n] and not self:load(n) then
		return
	end

	local sound = self.loaded[n] as RippleSound
	if sound and soundenabled then
		sound:stop()
		local inst = sound:play({ pitch = self.pitch, seek = 0 })
		if inst then
			inst.pitch = self.pitch
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

	local sound = self.loaded[n] as RippleSound
	if sound then
		sound:stop()
	end
end

function music:update(dt: number|nil)
	local d = dt or 0
	for _, raw in pairs(self.loaded) do
		local sound = raw as RippleSound
		sound:update(d)
		audio_ripple_set_pitch(sound, self.pitch)
	end
end

function music:setVolume(_)
	audio_apply_volumes()
end
