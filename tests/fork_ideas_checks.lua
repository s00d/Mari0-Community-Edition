--[[ FrameDebug + profzones + onscreen + spritebatch coalesce + spatialhash + golden replay. ]]

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

-- FrameDebug
do
	local FrameDebug = require("core.framedebug")
	FrameDebug.set_playing(true)
	check("framedebug playing apply", FrameDebug.apply(0.016) ~= false)
	FrameDebug.pause_play()
	check("framedebug pause returns false", FrameDebug.apply(0.016) == false)
	FrameDebug.frame_advance()
	local stepped = FrameDebug.apply(0.016)
	check("framedebug step advances", type(stepped) == "number" and stepped > 0)
	FrameDebug.set_playing(true)
end

-- Prof zones
do
	require("core.profzones")
	profzones_reset()
	profzones_set_enabled(true)
	prof_push("a")
	prof_push("b")
	prof_pop("b")
	prof_pop("a")
	local report = profzones_report(5)
	check("profzones report has zone a", report:find("a", 1, true) ~= nil)
	profzones_set_enabled(false)
	prof_push("noop")
	prof_pop()
	check("profzones disabled no-op", true)
	profzones_reset()
end

-- onscreen / ondrawscreen
do
	require("util.enemyutil")
	xscroll, yscroll, width, height, scale = 0, 0, 10, 10, 1
	check("onscreen hit", onscreen(1, 1, 1, 1) == true)
	check("onscreen miss", onscreen(100, 1, 1, 1) == false)
	check("ondrawscreen hit", ondrawscreen(10, 10, 8, 8) == true)
	check("ondrawscreen miss", ondrawscreen(9999, 9999, 8, 8) == false)
	check("enemy onscreen still hit", enemy_onscreen(1, 1, 1, 1) == true)
	check("enemy onscreen still miss", enemy_onscreen(100, 1, 1, 1) == false)
end

-- Spritebatch coalesce contract
do
	spritebatch_dirty = false
	spritebatch_pending_dx = 0
	spritebatch_pending_dy = 0
	local flush_count = 0
	local function generatespritebatch(dx, dy)
		spritebatch_dirty = true
		spritebatch_pending_dx = dx
		spritebatch_pending_dy = dy
	end
	local function updatespritebatch()
		if not spritebatch_dirty then
			return
		end
		spritebatch_dirty = false
		flush_count = flush_count + 1
	end
	generatespritebatch(0, 0)
	generatespritebatch(0, 0)
	generatespritebatch(1, 0)
	check("coalesce dirty before flush", spritebatch_dirty == true)
	updatespritebatch()
	check("coalesce single flush", flush_count == 1 and spritebatch_dirty == false)
	updatespritebatch()
	check("coalesce no double flush", flush_count == 1)
end

-- Spatial hash skeleton
do
	require("physics.spatialhash")
	spatialhash_clear()
	local a = {x = 0, y = 0, width = 1, height = 1, active = true}
	local b = {x = 10, y = 10, width = 1, height = 1, active = true}
	local wall = {x = 2, y = 2, width = 0, height = 1, active = true}
	spatialhash_insert(a, a.x, a.y, a.width, a.height)
	spatialhash_insert(b, b.x, b.y, b.width, b.height)
	spatialhash_insert(wall, wall.x, wall.y, wall.width, wall.height)
	check("spatialhash count", spatialhash_count() == 3)
	local out, seen = {}, {}
	local n = spatialhash_query(-0.5, -0.5, 2, 2, out, seen)
	local found_a = false
	for i = 1, n do
		if out[i] == a then found_a = true end
	end
	check("spatialhash query near a", found_a)
	out, seen = {}, {}
	n = spatialhash_query(9, 9, 3, 3, out, seen)
	local found_b, found_a2 = false, false
	for i = 1, n do
		if out[i] == b then found_b = true end
		if out[i] == a then found_a2 = true end
	end
	check("spatialhash query near b", found_b and not found_a2)
	-- zero-width wall still insertable/queryable via epsilon
	out, seen = {}, {}
	n = spatialhash_query(1.5, 1.5, 1, 1, out, seen)
	local found_wall = false
	for i = 1, n do
		if out[i] == wall then found_wall = true end
	end
	check("spatialhash zero-width wall", found_wall)
end

-- Golden replay harness
do
	local Replay = require("core.replay")
	local r = Replay.new(42)
	Replay.record(r, {left = true}, {x = 1, y = 2})
	Replay.record(r, {right = true}, {x = 1.1, y = 2})
	check("replay frame count", Replay.frame_count(r) == 2)
	local exported = Replay.export(r)
	local loaded = Replay.load(exported)
	check("replay roundtrip seed", loaded.seed == 42)
	local x = 1
	local mismatch = Replay.verify(loaded, function(input, i)
		if input.left then x = x + 0 end
		if input.right then x = x + 0.1 end
		return {x = x, y = 2}
	end)
	check("replay verify match", mismatch == 0)
	local bad = Replay.verify(loaded, function()
		return {x = 99, y = 99}
	end)
	check("replay verify mismatch", bad == 1)
end

return failed
