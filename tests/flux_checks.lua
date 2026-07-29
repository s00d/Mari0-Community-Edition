--[[ flux smoke: to/ease/update drives visual tween state ]]

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

local Flux = require("flux")

local obj = { x = 0, y = 0 }
Flux.to(obj, 0.1, { x = 10 }):ease("quadout")
Flux.update(0.05)
check("mid tween", obj.x > 0 and obj.x < 10, tostring(obj.x))
Flux.update(0.1)
check("complete near target", math.abs(obj.x - 10) < 1e-6, tostring(obj.x))

local open = { 0, 0 }
Flux.to(open, 1 / 15, { [1] = 1 }):ease("quadout")
Flux.update(1)
check("portal openscale analog", math.abs(open[1] - 1) < 1e-6, tostring(open[1]))

local shake = { amp = 0.5 }
Flux.to(shake, 0.2, { amp = 0 }):ease("expoout")
Flux.update(0.25)
check("screenshake decay", math.abs(shake.amp) < 1e-6, tostring(shake.amp))

local chain = { a = 0 }
Flux.to(chain, 0.05, { a = 1 }):ease("linear"):after(0.05, { a = 0 }):ease("linear")
Flux.update(0.06)
check("intro chain mid", chain.a > 0.5, tostring(chain.a))
Flux.update(0.1)
check("intro chain end", math.abs(chain.a) < 1e-5, tostring(chain.a))

return failed
