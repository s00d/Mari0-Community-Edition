--[[ Ripple audio: one SoundEntry.sound play path; tags music + sfx. ]]

local ripple = require("ripple")

local tag_music = ripple.newTag()
local tag_sfx = ripple.newTag()

_G.audio_tag_music = tag_music
_G.audio_tag_sfx = tag_sfx

local function audio_apply_volumes()
	if love and love.audio and love.audio.setVolume then
		love.audio.setVolume(1)
	end
	tag_sfx.volume = volumesfx or 1
	tag_music.volume = volumemusic or 1
end
_G.audio_apply_volumes = audio_apply_volumes

local function ripple_foreach_instance(rs: RippleSound, fn: function(RippleInstance))
	local insts = (rs as {string:any})._instances
	if type(insts) ~= "table" then
		return
	end
	for _, inst in ipairs(insts as {RippleInstance}) do
		fn(inst)
	end
end

local function audio_ripple_set_pitch(rs: RippleSound, pitch: number)
	ripple_foreach_instance(rs, function(inst: RippleInstance)
		inst.pitch = pitch
	end)
end
_G.audio_ripple_set_pitch = audio_ripple_set_pitch

local function source_duration(source: Source): number
	local ok, dur = pcall(function(): number
		return (source as SoundSource):getDuration()
	end)
	if ok and type(dur) == "number" then
		return dur as number
	end
	return 0
end

local function audio_wrap_sfx(source: Source, opts: {string:any}|nil): RippleSound
	local options: {string:any} = { tags = { tag_sfx } }
	if opts ~= nil then
		local o = opts as {string:any}
		if o.volume ~= nil then
			options.volume = o.volume
		end
		if o.loop ~= nil then
			options.loop = o.loop
		end
		local sound = ripple.newSound(source, options)
		if o.loop then
			sound.loop = true
		end
		return sound
	end
	return ripple.newSound(source, options)
end

-- Bind Love Source into soundlist[id].sound (sole play object).
local function audio_bind_sfx(id: string, source: Source|nil, opts: {string:any}|nil)
	if source == nil then
		return
	end
	local prev = soundlist[id]
	local last: number = 0
	if prev and prev.lastplayed ~= nil then
		last = prev.lastplayed
	end
	soundlist[id] = {
		sound = audio_wrap_sfx(source, opts),
		lastplayed = last,
		duration = source_duration(source),
	}
end
_G.audio_bind_sfx = audio_bind_sfx

local function sound_playing(id: string): boolean
	local entry = soundlist[id]
	if not entry or not entry.sound then
		return false
	end
	local playing = false
	ripple_foreach_instance(entry.sound, function(inst: RippleInstance)
		if not inst:isStopped() then
			playing = true
		end
	end)
	return playing
end
_G.sound_playing = sound_playing

local function stopsound(id: string)
	local entry = soundlist[id]
	if entry and entry.sound then
		entry.sound:stop()
	end
end
_G.stopsound = stopsound

local function sound_duration(id: string): number
	local entry = soundlist[id]
	if not entry then
		return 0
	end
	return entry.duration or 0
end
_G.sound_duration = sound_duration

local function audio_set_pitch(p: number)
	local pitch = p
	if music then
		music.pitch = pitch
	end
	if soundlist then
		for _, entry in pairs(soundlist) do
			if entry.sound then
				audio_ripple_set_pitch(entry.sound, pitch)
			end
		end
	end
end
_G.audio_set_pitch = audio_set_pitch

-- Rebind loop/portal SFX opts after default Sources are loaded.
local function audio_bind_loop_portal_defaults()
	audio_bind_sfx("scorering", defaultsoundslist["scorering"] as Source, { loop = true })
	audio_bind_sfx("planemode", defaultsoundslist["planemode"] as Source, { loop = true })
	audio_bind_sfx("portal1open", defaultsoundslist["portal1open"] as Source, { volume = 0.3 })
	audio_bind_sfx("portal2open", defaultsoundslist["portal2open"] as Source, { volume = 0.3 })
	audio_bind_sfx("portalenter", defaultsoundslist["portalenter"] as Source, { volume = 0.3 })
	audio_bind_sfx("portalfizzle", defaultsoundslist["portalfizzle"] as Source, { volume = 0.3 })
end
_G.audio_bind_loop_portal_defaults = audio_bind_loop_portal_defaults
