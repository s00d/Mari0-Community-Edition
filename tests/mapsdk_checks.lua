--[[
  mapsdk IR + emit smoke tests.
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

local mapsdk = dofile(root .. "/scripts/mapsdk/init.lua")
local ir = mapsdk.ir.new({ source = "test" })
mapsdk.ir.set_size(ir, 4, 3, 1)
ir.tiles[1][3] = 2
ir.tiles[2][3] = 2
ir.tiles[3][3] = 2
ir.tiles[4][3] = 2
ir.spawn = { x = 1, y = 2 }
ir.finish = { x = 4, y = 2 }
ir.entities[#ir.entities + 1] = { x = 3, y = 2, name = "goomba" }

local ok, errs = mapsdk.ir.validate(ir, { require_spawn = true, require_finish = true })
check("ir validate", ok, table.concat(errs or {}, "; "))

local text = mapsdk.emit.emit(ir, { spriteset = 1 })
check("emit has height", text:sub(1, 1) == "3")
check("emit has RLE", text:find("·", 1, true) ~= nil or text:find("¤", 1, true) ~= nil)

-- fit_height pad from top
local ir2 = mapsdk.ir.new({})
mapsdk.ir.set_size(ir2, 2, 2, 1)
ir2.tiles[1][2] = 5
local okpad = mapsdk.ir.fit_height(ir2, 4, 1)
check("fit_height pad", okpad and ir2.height == 4 and ir2.tiles[1][4] == 5)

return failed
