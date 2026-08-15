--[[
  Headless mappack QA: inventory → parse → entity ids → link graph (+ Acid Trip audit).
  Run via tests/run.lua or: lua tests/mappack_qa/run.lua
  Filter: --pack=dlc_acid_trip | --pack=all
]]

local root = ...
if not root or root == "" then
	local info = debug.getinfo(1, "S").source
	if info:sub(1, 1) == "@" then
		root = info:sub(2):match("^(.*)/tests/mappack_qa/run%.lua$") or "."
	else
		root = "."
	end
end

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	root .. "/?.lua",
	root .. "/?/init.lua",
	package.path,
}, ";")

width = width or 25
height = height or 14

require("core.stringutil")
require("app.variables")
require("world.levelio")

local Common = require("tests.mappack_qa.common")
local inventory = require("tests.mappack_qa.inventory")
local parse_smoke = require("tests.mappack_qa.parse_smoke")
local entity_smoke = require("tests.mappack_qa.entity_smoke")
local link_graph = require("tests.mappack_qa.link_graph")
local acid_trip = require("tests.mappack_qa.acid_trip_1_1")

local state = { failed = 0 }
local pack_filter = Common.pack_filter()

print("-- mappack_qa filter=" .. pack_filter .. " --")

local packs = inventory.run(root, state, pack_filter)
parse_smoke.run(root, state, packs)
entity_smoke.run(root, state, packs)
link_graph.run(root, state, packs)

-- Always run Acid Trip audit (independent of --pack filter) when pack exists
acid_trip.run(root, state)

print(string.format("mappack_qa failures: %d", state.failed))
return state.failed
