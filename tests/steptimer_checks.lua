--[[ Steptimer / bullet-time structural checks (no LÖVE). ]]

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

local function read_src(rel)
	local f = io.open(root .. "/" .. rel, "r")
	if not f then
		return ""
	end
	local body = f:read("*a") or ""
	f:close()
	return body
end

local frame = read_src("src/app/love_frame.tl")
local callbacks = read_src("src/app/love_callbacks.tl")
local game_update = read_src("src/app/game_update.tl")

check("callbacks caps physics steps", callbacks:find("max_physics_steps") ~= nil)
check("frame discards steptimer debt", frame:find("steptimer = 0") ~= nil)
check("callbacks scales steptimer by speed", callbacks:find("frame_dt %* speed") ~= nil or callbacks:find("frame_dt%s*%*%s*speed") ~= nil)
check("frame keeps steptimer module-local", frame:find("local steptimer") ~= nil)
check("callbacks has no global realdt write", not callbacks:find("realdt%s*="))
check("callbacks has no global skipupdate write", not callbacks:find("skipupdate%s*="))
check("game_update does not scale dt by speed", not game_update:find("dt%s*=%s*dt%s*%*%s*speed"))

if select("#", ...) > 0 then
	return failed
end
