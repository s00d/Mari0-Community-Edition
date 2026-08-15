--[[ Stage 5: one RippleSound play path (no dual .source+.ripple, no tag_ui). ]]

local root = ... or "."
local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

local function read(rel)
	local f = io.open(root .. "/" .. rel, "r")
	if not f then
		return nil
	end
	local s = f:read("*a")
	f:close()
	return s
end

check("lib/ripple.lua exists", io.open(root .. "/lib/ripple.lua") ~= nil)
check("types/ripple.d.tl exists", io.open(root .. "/types/ripple.d.tl") ~= nil)

local vendor = read("scripts/vendor-libs") or ""
check("vendor-libs fetches ripple", vendor:find("ripple.lua", 1, true) ~= nil)

_G.volumesfx = 0.5
_G.volumemusic = 0.25
_G.love = {
	audio = {
		setVolume = function(v)
			_G._master_vol = v
		end,
	},
}

require("assets.audio")
check("tag_music exists", audio_tag_music ~= nil and type(audio_tag_music.volume) == "number")
check("tag_sfx exists", audio_tag_sfx ~= nil)
check("no tag_ui export", _G.audio_tag_ui == nil)
check("no audio_tag_ui global", _G.audio_tag_ui == nil)

audio_apply_volumes()
check("master volume forced to 1", _G._master_vol == 1)
check("sfx tag volume", math.abs(audio_tag_sfx.volume - 0.5) < 1e-9)
check("music tag volume", math.abs(audio_tag_music.volume - 0.25) < 1e-9)

_G.volumesfx = 0.8
_G.volumemusic = 0.1
audio_apply_volumes()
check("global audio_apply_volumes", math.abs(audio_tag_sfx.volume - 0.8) < 1e-9)

local audio_src = read("src/assets/audio.tl") or ""
check("audio dropped tag_ui", audio_src:find("tag_ui", 1, true) == nil)
check("audio has stopsound", audio_src:find("function stopsound", 1, true) ~= nil)
check("audio has sound_duration", audio_src:find("function sound_duration", 1, true) ~= nil)
check("audio bind writes .sound", audio_src:find("sound = audio_wrap_sfx", 1, true) ~= nil)
check("audio no entry.ripple", audio_src:find("entry.ripple", 1, true) == nil)
check("audio no entry.source", audio_src:find("entry.source", 1, true) == nil)

local ml = read("src/assets/musicloader.tl") or ""
check("musicloader requires ripple", ml:find('require("ripple")', 1, true) ~= nil)
check("musicloader uses ripple.newSound", ml:find("ripple.newSound", 1, true) ~= nil)
check("musicloader uses audio_ripple_set_pitch", ml:find("audio_ripple_set_pitch", 1, true) ~= nil)
check("musicloader no private _instances", ml:find("_instances", 1, true) == nil)

local playsound_src = read("src/app/game_load_objects.tl") or ""
local playsound_fn = playsound_src:match("global function playsound.-^global function")
	or playsound_src:match("global function playsound.-^end\n\nglobal function")
	or ""
if playsound_fn == "" then
	-- fallback: window around playsound
	local i = playsound_src:find("global function playsound", 1, true) or 1
	playsound_fn = playsound_src:sub(i, i + 800)
end
check("playsound uses entry.sound", playsound_fn:find("entry.sound", 1, true) ~= nil)
check("playsound no source:play fallback", playsound_fn:find("source:play", 1, true) == nil)
check("playsound no ripple else branch", playsound_fn:find("entry.ripple", 1, true) == nil)

local mario = read("src/entities/mario.tl") or ""
check("mario no scorering.source", mario:find('soundlist["scorering"].source', 1, true) == nil)
check("mario no planemode.source", mario:find('soundlist["planemode"].source', 1, true) == nil)
check("mario no levelend.source", mario:find('soundlist["levelend"].source', 1, true) == nil)
check("mario no castleend.source", mario:find('soundlist["castleend"].source', 1, true) == nil)
check("mario uses stopsound", mario:find('stopsound("scorering")', 1, true) ~= nil
	and mario:find('stopsound("planemode")', 1, true) ~= nil)
check("mario uses sound_duration", mario:find('sound_duration("levelend")', 1, true) ~= nil
	and mario:find('sound_duration("castleend")', 1, true) ~= nil)

local intro = read("src/ui/intro.tl") or ""
check("intro uses stopsound stab", intro:find('stopsound("stab")', 1, true) ~= nil)
check("intro no stab.source", intro:find('soundlist["stab"].source', 1, true) == nil)

local menu = read("src/ui/menu.tl") or ""
check("menu no dual setVolume(volumesfx)", menu:find("love.audio.setVolume( volumesfx )", 1, true) == nil)
check("menu uses audio_apply_volumes", menu:find("audio_apply_volumes()", 1, true) ~= nil)

local input = read("src/app/input_bindings.tl") or ""
check("input no love.audio.setVolume(volumesfx)", input:find("love.audio.setVolume(volumesfx)", 1, true) == nil)
check("input uses audio_apply_volumes", input:find("audio_apply_volumes()", 1, true) ~= nil)

local boot = read("src/app/boot.tl") or ""
check("boot requires assets.audio", boot:find('require "assets.audio"', 1, true) ~= nil)
check("boot calls audio_bind_sfx with source", boot:find("audio_bind_sfx(v, src as Source", 1, true) ~= nil)
check("boot no soundlist.source assign", boot:find("soundlist[v].source", 1, true) == nil)

local types = read("types/game.d.tl") or ""
check("SoundEntry has sound field", types:find("sound: RippleSound", 1, true) ~= nil)
check("SoundEntry no source field", types:find("record SoundEntry") ~= nil)
do
	local a, b = types:find("global record SoundEntry")
	local c = types:find("end", a)
	local block = types:sub(a, c)
	check("SoundEntry block no .source", block:find("source:", 1, true) == nil)
	check("SoundEntry block no .ripple", block:find("ripple:", 1, true) == nil)
	check("types no audio_tag_ui", types:find("audio_tag_ui", 1, true) == nil)
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
