--[[ Level lifetime leak checks via Ctx.level (no LÖVE). ]]

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

local Ctx = require("core.ctx")
local Level = require("world.level")

do
	local a = Level.new()
	a.map[1] = { { 99 } }
	a.objects["box"] = { { tag = "level-a" } }
	Ctx.level = a
	a:push_globals()
	local map_ref = map
	local box_ref = objects["box"]

	level_reset_ctx()
	check("new level new map table", map ~= map_ref)
	check("new level new objects table", objects["box"] ~= box_ref)
	check("old map not aliased in ctx", Ctx.level.map ~= map_ref)
	check("old box table not in new level", Ctx.level.objects["box"] ~= box_ref)
	check("teardown cleared old refs", #a.map == 0 and a.objects["box"] == nil)
end

do
	local destroyed = false
	local lvl = Level.new()
	Ctx.level = lvl
	lvl:on_destroy(function()
		destroyed = true
	end)
	lvl:destroy()
	check("on_destroy runs", destroyed)
	check("destroy clears ctx.level", Ctx.level == nil)
end

return failed
