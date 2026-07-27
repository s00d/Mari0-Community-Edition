--[[ Incremental GC pacing for Love 12 / LuaJIT (and Lua 5.4+ host tests).

Root cause of the ~5s gameplay hitch: loadlevel called collectgarbage("collect")
*before* allocating the map/entities, which left a low GC threshold. Early
gameplay then piled debt until LuaJIT did a multi-second catch-up pause;
afterward incremental GC caused micro-stutters.

Full collect *during* level transition also freezes the main thread with no
event pump (hang until minimize/restore on Love 12 + Metal). Prefer a large
incremental step + boosted per-frame steps instead.
]]

local configured = false
local boost_frames = 0

-- Pause 110: begin a cycle after ~10% growth (LuaJIT default 200 = wait for 2×).
-- Stepmul 300: automatic steps reclaim faster so debt cannot explode.
local PAUSE = 110
local STEPMUL = 300
-- Per-frame manual step budget (LuaJIT: approximate KB of work).
local FRAME_STEP = 200
-- After level load: larger steps for a short window instead of stop-the-world.
local BOOST_FRAMES = 45
local BOOST_STEP = 800
local AFTER_LOAD_STEP = 4000

global function gcpace_configure()
	-- LuaJIT / Lua 5.1 API
	pcall(collectgarbage, "setpause", PAUSE)
	pcall(collectgarbage, "setstepmul", STEPMUL)
	-- Lua 5.4+ / 5.5: incremental(pause, stepmul[, stepsize]) — typed loosely for Teal.
	local cg = collectgarbage as function(...: any): any
	pcall(cg, "incremental", PAUSE, STEPMUL)
	configured = true
end

-- Once per rendered frame — never inside the physics substep loop.
global function gcpace_step()
	if not configured then
		gcpace_configure()
	end
	local budget = FRAME_STEP
	if boost_frames > 0 then
		budget = BOOST_STEP
		boost_frames = boost_frames - 1
	end
	collectgarbage("step", budget)
end

-- After a heavy load: reclaim without a full stop-the-world collect, then boost.
global function gcpace_after_load()
	collectgarbage("step", AFTER_LOAD_STEP)
	gcpace_configure()
	boost_frames = BOOST_FRAMES
end

return {
	configure = gcpace_configure,
	step = gcpace_step,
	after_load = gcpace_after_load,
	PAUSE = PAUSE,
	STEPMUL = STEPMUL,
	FRAME_STEP = FRAME_STEP,
	BOOST_FRAMES = BOOST_FRAMES,
	BOOST_STEP = BOOST_STEP,
	AFTER_LOAD_STEP = AFTER_LOAD_STEP,
}
