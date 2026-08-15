--[[
  Gel helpers: nil init, id clamp, cleanse, pool cap (no LÖVE).
  Run: lua tests/gel_checks.lua
]]

local root = ...
if not root or root == "" then
	local info = debug.getinfo(1, "S").source
	if info:sub(1, 1) == "@" then
		root = info:sub(2):match("^(.*)/tests/gel_checks%.lua$") or "."
	else
		root = "."
	end
end

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	package.path,
}, ";")

local failed = 0
local function check(name, cond, detail)
	if cond then
		print("OK   " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (" — " .. tostring(detail)) or ""))
	end
end

-- Minimal stubs before requiring gel modules
objects = { gel = {} }
gel1img, gel2img, gel3img, gel4img = true, true, true, true
gelquad = { 1, 2, 3 }
gellifetime = 1.2
gelmaxspeed = 100

local ok_types, geltypes = pcall(require, "world.geltypes")
check("load world.geltypes", ok_types, geltypes)
if not ok_types then
	return failed
end

local ok_draw, geldraw = pcall(require, "util.geldraw")
check("load util.geldraw", ok_draw, geldraw)
if not ok_draw then
	return failed
end

-- 1) init_map_cell_gels leaves nil (truthy empty-table bug)
do
	local cell = {}
	init_map_cell_gels(cell)
	check("init gels nil", cell.gels == nil)
	check("init gelSides nil", cell.gelSides == nil)
	check("nil is falsy for draw guard", not cell.gelSides)
end

-- 2) gel id clamp
check("clamp 1", gel_clamp_id(1) == 1)
check("clamp 4", gel_clamp_id(4) == 4)
check("clamp 5 → 1", gel_clamp_id(5) == 1)
check("clamp 0 → 1", gel_clamp_id(0) == 1)
check("clamp nil → 1", gel_clamp_id(nil) == 1)
check("clamp '3'", gel_clamp_id("3") == 3)

-- 3) gel_has flags
check("bounce has", gel_has(1, "bounce") == true)
check("speed has", gel_has(2, "speed") == true)
check("cleanse has", gel_has(3, "cleanse") == true)
check("adhere has", gel_has(4, "adhere") == true)
check("nil gel_has", gel_has(nil, "bounce") == false)
check("bounce not speed", gel_has(1, "speed") == false)

-- 4) cleanse clears side; gelSides nil when empty
do
	local cell = {}
	map_cell_set_gel(cell, GEL_SIDE_TOP, GEL_BOUNCE)
	check("paint bounce allocates gelSides", cell.gelSides ~= nil)
	check("paint bounce id", map_cell_gel_id(cell, GEL_SIDE_TOP) == 1)
	map_cell_set_gel(cell, GEL_SIDE_TOP, GEL_CLEANSE)
	check("cleanse clears side", map_cell_gel_id(cell, GEL_SIDE_TOP) == nil)
	check("cleanse nils gelSides when empty", cell.gelSides == nil)
end

-- 5) no string gels write on map paint
do
	local cell = {}
	map_cell_set_gel(cell, GEL_SIDE_LEFT, GEL_SPEED)
	check("no string gels table on paint", cell.gels == nil)
	check("numeric side set", cell.gelSides[GEL_SIDE_LEFT] == 2)
end

-- 6) pool cap drops oldest
do
	objects.gel = {}
	for i = 1, 30 do
		objects.gel[i] = { id = i }
	end
	gel_pool_prepare()
	check("pool cap size", #objects.gel == GEL_POOL_MAX - 1 or #objects.gel < GEL_POOL_MAX,
		tostring(#objects.gel))
	-- prepare leaves room for one spawn (< MAX)
	check("pool under max", #objects.gel < GEL_POOL_MAX, tostring(#objects.gel))
	check("pool dropped oldest", objects.gel[1].id ~= 1, tostring(objects.gel[1] and objects.gel[1].id))
end

-- 7) empty gelSides draw is a no-op; world_draw_scale under attach
do
	local draws = 0
	local scales = {}
	local old_love = love
	love = {
		graphics = {
			draw = function(_img, _x, _y, _r, sx, sy)
				draws = draws + 1
				scales[#scales + 1] = { sx, sy }
			end,
		},
	}
	gelgroundimgs = { true, true, true, true }
	scale = 2
	world_draw_scale = function()
		return 1
	end
	local empty = {}
	draw_tile_gel_overlays(empty, 0, 0, 8, 8)
	check("empty sides no draws", draws == 0)
	draw_tile_gel_overlays({ [1] = 1 }, 0, 0, 8, 8)
	check("gel uses world_draw_scale not screen scale", draws == 1 and scales[1][1] == 1 and scales[1][2] == 1,
		tostring(scales[1] and scales[1][1]))
	love = old_love
end

-- 8) Gel pivot must land on tile CENTER (classic Mari0).
-- Batched tiles bake SMB letterbox: ((coy-1)*16 - 8). Gel draw Y is (coy-1)*16
-- with origin 8 — NOT tile_y_off again, or the overlay floats 8px above the block.
do
	tile_draw_x = function(tx)
		return math.floor(tx * 16)
	end
	tile_draw_y = function(ty, extra)
		return math.floor(ty * 16 + (extra or 0))
	end
	local cox, coy = 5, 10
	local tile_y_off = -8 -- mapmode_tile_y_off() in play mode
	local tile_top = tile_draw_y(coy - 1, tile_y_off)
	local tile_cx = tile_draw_x(cox - 1) + 8
	local tile_cy = tile_top + 8
	-- Correct call (extra=0): matches game_draw_world after fix
	local gel_x = tile_draw_x(cox - 0.5)
	local gel_y = tile_draw_y(coy - 1, 0)
	check("gel pivot x = tile center x", gel_x == tile_cx, string.format("gel=%s tile=%s", gel_x, tile_cx))
	check("gel pivot y = tile center y", gel_y == tile_cy, string.format("gel=%s tile=%s", gel_y, tile_cy))
	-- Regression: passing tile_y_off again lifts gel by 8
	local wrong_y = tile_draw_y(coy - 1, tile_y_off)
	check("tile_y_off on gel would float", wrong_y == tile_cy - 8 and wrong_y ~= gel_y,
		string.format("wrong=%s gel=%s", wrong_y, gel_y))

	local src = (function()
		local f = io.open(root .. "/src/app/game_draw_world.tl", "r")
		if not f then
			return ""
		end
		local body = f:read("*a")
		f:close()
		return body
	end)()
	local gel_lines = 0
	local bad_off = false
	local missing_zero = false
	for line in src:gmatch("[^\n]+") do
		if line:find("draw_tile_gel_overlays", 1, true) then
			gel_lines = gel_lines + 1
			if line:find("tile_y_off", 1, true) then
				bad_off = true
			end
			-- tile_draw_y(..., 0) before pivot args
			if not line:find("tile_draw_y%([^%)]+, 0%)", 1) then
				missing_zero = true
			end
		end
	end
	check("game_draw_world has gel overlay sites", gel_lines >= 2, tostring(gel_lines))
	check("game_draw_world gel never passes tile_y_off", not bad_off)
	check("game_draw_world gel tile_draw_y extra is 0", not missing_zero)
end

print(string.format("gel_checks: %d failure(s)", failed))
return failed
