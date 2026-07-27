--[[ Level transition hang guards (no LÖVE window).

Asserts structural fixes for: sync load without event pump, full GC on
transition, enemies reloaded every level, editor rebuilt in play mode.
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

-- keepalive module exists and exports pump
package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	package.path,
}, ";")

local ok_keep, Keep = pcall(require, "core.keepalive")
check("keepalive module loads", ok_keep)
if ok_keep then
	check("keepalive exports pump", type(Keep.pump) == "function" or type(keepalive_pump) == "function")
end

check("boot requires keepalive", (read(root .. "/src/app/boot.tl") or ""):find('require "core.keepalive"', 1, true) ~= nil)

-- loadlevel pumps between heavy chunks; no full collect fallback
local loadlevel_src = read(root .. "/src/app/game_load_level.tl") or ""
local loadlevel_fn = loadlevel_src:match("global function loadlevel.-return needs_to_be_saved")
check("loadlevel body found", loadlevel_fn ~= nil)
if loadlevel_fn then
	local pumps = 0
	for _ in loadlevel_fn:gmatch("keepalive_pump") do
		pumps = pumps + 1
	end
	check("loadlevel pumps keepalive (>=4)", pumps >= 4, "count=" .. tostring(pumps))
	check(
		"loadlevel no collectgarbage collect",
		loadlevel_fn:find('collectgarbage("collect")', 1, true) == nil
	)
	check("loadlevel calls gcpace_after_load", loadlevel_fn:find("gcpace_after_load", 1, true) ~= nil)
end

-- levelscreen defers load one frame
local ls = read(root .. "/src/ui/levelscreen.tl") or ""
check("levelscreen queues pending load", ls:find("queue_level_load", 1, true) ~= nil)
check("levelscreen arms before flush", ls:find("pending_level_armed", 1, true) ~= nil)
check("levelscreen does not call loadlevel in levelscreen_load body sync path", (function()
	-- levelscreen_load should queue, not call loadlevel( directly (except via flush helpers)
	local load_fn = ls:match("global function levelscreen_load(.-)\nend\n\nglobal function levelscreen_update")
	if not load_fn then
		return false
	end
	-- Direct loadlevel( in levelscreen_load is only OK inside flush via skiplevelscreen → flush_pending
	local direct = load_fn:find("loadlevel%(")
	local has_queue = load_fn:find("queue_level_load", 1, true) ~= nil
	local has_flush_skip = load_fn:find("flush_pending_level_load", 1, true) ~= nil
	return has_queue and has_flush_skip and (direct == nil)
end)())

-- enemies cache same mappack
local enemies = read(root .. "/src/entities/enemies.tl") or ""
check("enemies_load caches mappack", enemies:find("enemies_loaded_mappack", 1, true) ~= nil)
check("enemies_load early return same mappack", enemies:find("enemies_loaded_mappack == mappack", 1, true) ~= nil)

-- AssetStore path cache
local store = read(root .. "/src/assets/store.tl") or ""
check("AssetStore image_path_cache", store:find("image_path_cache", 1, true) ~= nil)
check("AssetStore clear_image_path_cache", store:find("clear_image_path_cache", 1, true) ~= nil)

-- editor_load skips play mode rebuild
local editor = read(root .. "/src/ui/editor.tl") or ""
local editor_load = editor:match("function editor_load%(%)(.-)\n\tprint%(\"Better editor")
check("editor_load play-mode early return", editor_load ~= nil and editor_load:find("if not editormode then", 1, true) ~= nil)

-- love.run guards present with isActive
local run = read(root .. "/src/app/love_run.tl") or ""
check("love.run checks isActive", run:find("isActive", 1, true) ~= nil)
check("love.run present inside active guard", (function()
	local present_at = run:find("love.graphics.present()", 1, true)
	local active_at = run:find("isActive", 1, true)
	return present_at and active_at and active_at < present_at
end)())

-- gcpace after_load must not full-collect
local gc = read(root .. "/src/core/gcpace.tl") or ""
local after = gc:match("global function gcpace_after_load%(%)(.-)\nend")
check("gcpace_after_load found", after ~= nil)
if after then
	check(
		"gcpace_after_load no full collect",
		after:find('collectgarbage("collect")', 1, true) == nil
	)
	check("gcpace_after_load uses step", after:find('collectgarbage("step"', 1, true) ~= nil)
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
