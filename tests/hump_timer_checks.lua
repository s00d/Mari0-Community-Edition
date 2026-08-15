--[[ hump.timer smoke: after/every via compat instance ]]

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
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	package.path,
}, ";")

local TimerMod = require("hump.timer")
local timer = TimerMod.new()

local after_fired = false
timer:after(0.05, function()
	after_fired = true
end)

local every_count = 0
timer:every(0.02, function()
	every_count = every_count + 1
end, 3)

timer:update(0.03)
check("after not yet", after_fired == false)
check("every first tick", every_count == 1)

timer:update(0.03)
check("after fired", after_fired == true)
check("every second tick", every_count == 2)

timer:update(0.1)
check("every capped at 3", every_count == 3)

-- Default module instance: dot call, not colon (colon passes module table as delay/dt).
local mod_after = false
TimerMod.after(0.01, function()
	mod_after = true
end)
TimerMod.update(0.02)
check("module.after via dot call", mod_after == true)

return failed
