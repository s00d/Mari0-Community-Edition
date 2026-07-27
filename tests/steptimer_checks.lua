--[[ Steptimer behavior checks via app.love_frame (no LÖVE). ]]

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

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	package.path,
}, ";")

local LoveFrame = require("app.love_frame")
local cost = 1 / 60

LoveFrame.clear_debt()
check("begin_update default", LoveFrame.begin_update() == true)
LoveFrame.add_time(cost * 2)
check("try_step consumes debt", LoveFrame.try_step(cost) == true)
check("partial debt remains", LoveFrame.has_pending_step(cost) == true)
check("second step", LoveFrame.try_step(cost) == true)
check("debt cleared", LoveFrame.has_pending_step(cost) == false)

LoveFrame.add_time(cost)
LoveFrame.request_skip_update()
check("skip discards next frame", LoveFrame.begin_update() == false)
check("debt zero after skip", LoveFrame.has_pending_step(cost) == false)

if select("#", ...) > 0 then
	return failed
end
