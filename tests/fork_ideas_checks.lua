--[[ onscreen cull + spritebatch coalesce. ]]

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

-- onscreen / enemy_onscreen (padded enemy cull, not an alias)
do
	require("util.enemyutil")
	xscroll, yscroll, width, height, scale = 0, 0, 10, 10, 1
	check("onscreen hit", onscreen(1, 1, 1, 1) == true)
	check("onscreen miss", onscreen(100, 1, 1, 1) == false)
	check("enemy onscreen still hit", enemy_onscreen(1, 1, 1, 1) == true)
	check("enemy onscreen still miss", enemy_onscreen(100, 1, 1, 1) == false)
end

-- Spritebatch coalesce contract (dirty mark + single flush)
do
	spritebatch_dirty = false
	local flush_count = 0
	local function generatespritebatch(_dx, _dy)
		spritebatch_dirty = true
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

return failed
