--[[ Guard: hump integration must not re-introduce pointless wrapper layers. ]]

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

local function exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

check("no game_flow.tl", not exists(root .. "/src/app/game_flow.tl"))
check("no game_spawn_timers.tl", not exists(root .. "/src/app/game_spawn_timers.tl"))
check("no app/camera.tl duplicate", not exists(root .. "/src/app/camera.tl"))

local boot = read(root .. "/src/app/boot.tl") or ""
check("boot skips app.camera", boot:find('require "app.camera"', 1, true) == nil)
check("boot skips game_flow", boot:find('require "app.game_flow"', 1, true) == nil)
check("boot skips game_spawn_timers", boot:find('require "app.game_spawn_timers"', 1, true) == nil)

local scroll = read(root .. "/src/util/scroll_update.tl") or ""
check("scroll_update has no camera mirror", scroll:find("hump_camera_ensure", 1, true) == nil)

local boot = read(root .. "/src/app/boot.tl") or ""
check("boot inlines HumpTimer", boot:find('require "hump.timer"', 1, true) ~= nil or boot:find('require%("hump.timer"%)', 1, true) ~= nil)
check("no hump_compat.tl", not exists(root .. "/src/core/hump_compat.tl"))
check("no game_portal facade", not exists(root .. "/src/app/game_portal.tl"))
check("no ui_input facade", not exists(root .. "/src/app/ui_input.tl"))

return failed
