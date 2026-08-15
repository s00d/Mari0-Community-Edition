--[[ Camera follow / autoscroll guards (no LÖVE window).

Regression: play-mode editor_load skip left minimapdragging nil; game_update
used `minimapdragging == false`, which is false when nil → camera frozen.
]]

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

local function read(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local body = f:read("*a")
	f:close()
	return body
end

-- Lua semantics that caused the bug
check("nil == false is false", (nil == false) == false)
check("not nil is true", (not nil) == true)

local function scroll_gate(autoscroll, minimapdragging)
	-- Must match game_update: allow scroll when dragging is unset/false
	return autoscroll and not minimapdragging
end

check("scroll when dragging nil (play skip)", scroll_gate(true, nil) == true)
check("scroll when dragging false", scroll_gate(true, false) == true)
check("no scroll when dragging true", scroll_gate(true, true) == false)
check("no scroll when autoscroll false", scroll_gate(false, false) == false)

local gu = read(root .. "/src/util/scroll_update.tl") or ""
check("scroll_update uses not minimapdragging", gu:find("not minimapdragging", 1, true) ~= nil)
check("scroll_update avoids == false on minimapdragging", gu:find("minimapdragging == false", 1, true) == nil)

local game_up = read(root .. "/src/app/game_update.tl") or ""
check("game_update delegates scroll_update", game_up:find("scroll_update(dt)", 1, true) ~= nil)

local gdw = read(root .. "/src/app/game_draw_world.tl") or ""
check("drawlevel_tiles uses world camera helpers", gdw:find("wpx(", 1, true) ~= nil)
check("drawlevel_tiles dropped xscrollfrac", gdw:find("xscrollfrac", 1, true) == nil)
check("scenedraw wraps world draw in world_camera_attach", gdw:find("world_camera_attach()", 1, true) ~= nil and gdw:find("drawlevel_tiles", 1, true) ~= nil)
check("scenedraw draws tile batches outside world camera", gdw:find("draw_tile_spritebatches()", 1, true) ~= nil and gdw:find("draw_tile_spritebatches_foreground()", 1, true) ~= nil)
local tsb = read(root .. "/src/world/tile_spritebatch.tl") or ""
check("tile batches use scroll draw offset", tsb:find("tile_spritebatch_draw_offset", 1, true) ~= nil and tsb:find("-session.xscroll", 1, true) ~= nil)
check("menu uses draw_world_tiles", (read(root .. "/src/ui/menu.tl") or ""):find("draw_world_tiles", 1, true) ~= nil)
check("game_draw_objects uses entity_draw_x", gdw:find("entity_draw_x", 1, true) ~= nil)

local wc = read(root .. "/src/util/world_camera.tl") or ""
check("world_camera has tile_draw_x", wc:find("function tile_draw_x", 1, true) ~= nil)
check("tile_draw_x attach-only (no scroll false-path)", wc:find("tile_x - session.xscroll", 1, true) == nil)
check("entity_draw_x attach-only (no scroll false-path)", wc:find("tile_x - session.xscroll", 1, true) == nil and wc:find("session.xscroll) * 16 * scale", 1, true) == nil)
check("no world_spritebatch_offset", wc:find("world_spritebatch_offset", 1, true) == nil)
check("no Dual-mode comment", wc:find("Dual-mode", 1, true) == nil)
check("world_camera has screen_to_tile_x", wc:find("screen_to_tile_x", 1, true) ~= nil)

local emg = read(root .. "/src/entities/emancipationgrill.tl") or ""
check("emancipationgrill dropped xscroll draw", emg:find("-xscroll", 1, true) == nil)
check("emancipationgrill uses screen_draw", emg:find("screen_draw_", 1, true) ~= nil)

local fx = read(root .. "/src/app/game_draw_effects.tl") or ""
local coin_block = fx:match("%-%-COINBLOCKanimation.-%-%-SCROLLING SCORE") or ""
check("coinblock uses tile_draw under attach", coin_block:find("tile_draw_x", 1, true) ~= nil)
check("coinblock dropped scroll math", coin_block:find("session.xscroll", 1, true) == nil)

local vine = read(root .. "/src/entities/vine.tl") or ""
check("vine draw no dual-mode branch", vine:find("if world_camera_drawing", 1, true) == nil)
check("vine scissor uses world_screen_y", vine:find("world_screen_y", 1, true) ~= nil)

local st = read(root .. "/src/entities/scrollingscore.tl") or ""
check("scrollingscore stores world tile x", st:find("xscroll", 1, true) == nil)

local mario = read(root .. "/src/entities/mario.tl") or ""
check("mario aim uses screen_to_tile", mario:find("screen_to_tile_x", 1, true) ~= nil)

local gg = read(root .. "/src/weapons/gravitygun.tl") or ""
check("gravitygun draw uses weapon_draw_xy", gg:find("weapon_draw_xy", 1, true) ~= nil)
check("gravitygun dropped local world_to_screen", gg:find("local function world_to_screen", 1, true) == nil)

local hs = read(root .. "/src/weapons/hookshot.tl") or ""
check("hookshot draw uses weapon_draw_xy", hs:find("weapon_draw_xy", 1, true) ~= nil)

local bh = read(root .. "/src/entities/blackhole.tl") or ""
check("blackhole draw uses weapon_draw_xy", bh:find("weapon_draw_xy", 1, true) ~= nil)

local aim = read(root .. "/src/weapons/aim.tl") or ""
check("aim cursor uses screen_to_tile", aim:find("screen_to_tile_x", 1, true) ~= nil)

local wc2 = read(root .. "/src/util/world_camera.tl") or ""
check("world_camera exports weapon_draw_xy", wc2:find("weapon_draw_xy", 1, true) ~= nil)

local ed = read(root .. "/src/ui/editor.tl") or ""
local play_skip = ed:match("function editor_load%(%)(.-)print%(\"Better editor")
check("editor_load play-mode body found", play_skip ~= nil)
if play_skip then
	check(
		"play-mode editor_load clears minimapdragging",
		play_skip:find("minimapdragging = false", 1, true) ~= nil
	)
	check("play-mode editor_load still early-returns", play_skip:find("if not editormode then", 1, true) ~= nil)
end

local loadlevel = read(root .. "/src/app/game_load_level.tl") or ""
check("loadlevel resets minimapdragging", loadlevel:find("minimapdragging = false", 1, true) ~= nil)
check("loadlevel resets autoscroll", loadlevel:find("autoscroll = true", 1, true) ~= nil)

local rt = read(root .. "/src/app/game_runtime_globals.tl") or ""
check("runtime globals init minimapdragging", rt:find("minimapdragging = false", 1, true) ~= nil)

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
