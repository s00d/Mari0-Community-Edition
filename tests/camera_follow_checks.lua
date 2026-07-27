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

local gu = read(root .. "/src/app/game_update.tl") or ""
check("game_update uses not minimapdragging", gu:find("not minimapdragging", 1, true) ~= nil)
check("game_update avoids == false on minimapdragging", gu:find("minimapdragging == false", 1, true) == nil)

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
