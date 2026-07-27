--[[ Incremental GC pacing for Love 12 / LuaJIT (and Lua 5.4+ host tests).

Root cause of the ~5s gameplay hitch: loadlevel called collectgarbage("collect")
*before* allocating the map/entities, which left a low GC threshold. Early
gameplay then piled debt until LuaJIT did a multi-second catch-up pause;
afterward incremental GC caused micro-stutters.

Fix: full collect only *after* load, tune pause/stepmul so cycles start early,
and spend a small fixed step budget once per rendered frame.
]]

local configured = false

-- Pause 110: begin a cycle after ~10% growth (LuaJIT default 200 = wait for 2×).
-- Stepmul 300: automatic steps reclaim faster so debt cannot explode.
local PAUSE = 110
local STEPMUL = 300
-- Per-frame manual step budget (LuaJIT: approximate KB of work).
local FRAME_STEP = 200

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
	collectgarbage("step", FRAME_STEP)
end

-- After a heavy load: one full collect of temporaries, then re-tune for play.
global function gcpace_after_load()
	collectgarbage("collect")
	gcpace_configure()
end

return {
	configure = gcpace_configure,
	step = gcpace_step,
	after_load = gcpace_after_load,
	PAUSE = PAUSE,
	STEPMUL = STEPMUL,
	FRAME_STEP = FRAME_STEP,
}
