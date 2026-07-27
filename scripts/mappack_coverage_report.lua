#!/usr/bin/env lua
--[[
  F3a coverage report: scan Mari0 1.6 level cells across packs, count entity indices,
  classify vs ENEMY_REMAP / VARIANT_REMAP / PASS_THROUGH.

  Usage:
    lua scripts/mappack_coverage_report.lua [DIR...]
  Default DIR: toconvert/ (all dlc_*) or --src path
]]

local ROOT = arg[0]:match("^(.*)/scripts/mappack_coverage_report%.lua$") or "."
package.path = table.concat({
	ROOT .. "/build/?.lua",
	ROOT .. "/build/?/init.lua",
	ROOT .. "/lib/?.lua",
	package.path,
}, ";")

width = width or 25
height = height or 14

require("core.stringutil")
require("core.tableutil")
require("app.variables")
require("world.entity_remap")

local function list_packs(dir)
	local out = {}
	local p = io.popen('ls -1 "' .. dir:gsub('"', '\\"') .. '" 2>/dev/null')
	if p then
		for line in p:lines() do
			table.insert(out, line)
		end
		p:close()
	end
	table.sort(out)
	return out
end

local roots = {}
if #arg == 0 then
	table.insert(roots, ROOT .. "/toconvert")
else
	for _, a in ipairs(arg) do
		table.insert(roots, a)
	end
end

local counts = {}
local per_pack = {}
local files = 0
local bad_height = {}

local function bump(t, k, n)
	t[k] = (t[k] or 0) + (n or 1)
end

for _, root in ipairs(roots) do
	for _, pack in ipairs(list_packs(root)) do
		local packdir = root .. "/" .. pack
		local levels = list_packs(packdir)
		per_pack[pack] = per_pack[pack] or {}
		for _, fname in ipairs(levels) do
			if fname:match("^%d+%-%d+") and fname:match("%.txt$") then
				files = files + 1
				local f = io.open(packdir .. "/" .. fname, "r")
				if f then
					local raw = f:read("*a")
					f:close()
					local cells = (strsplit(raw, ";")[1] or ""):gsub("\r", "")
					local mapsplit = strsplit(cells, ",")
					if #mapsplit % 15 ~= 0 then
						table.insert(bad_height, pack .. "/" .. fname .. " cells=" .. #mapsplit)
					end
					for _, cell in ipairs(mapsplit) do
						local bits = strsplit(cell, "-")
						if #bits >= 2 and bits[2] ~= "link" then
							local eid = tonumber(bits[2])
							if eid then
								bump(counts, eid)
								bump(per_pack[pack], eid)
							end
						end
					end
				end
			end
		end
	end
end

local handled, pass, hole = 0, 0, 0
local holes = {}

print("=== Mari0 1.6 entity coverage ===")
print(string.format("files=%d  unique_ids=%d  bad_height=%d", files, (function()
	local n = 0
	for _ in pairs(counts) do n = n + 1 end
	return n
end)(), #bad_height))
print("")
print(string.format("%4s  %-22s  %6s  %s", "id", "old_name", "count", "kind"))

local ids = {}
for id in pairs(counts) do table.insert(ids, id) end
table.sort(ids)

for _, id in ipairs(ids) do
	local name = OLD_ENTITY_NAMES[id] or "?"
	local kind = remap_kind(id)
	local c = counts[id]
	if kind == "enemy" or kind == "variant" then
		handled = handled + c
	elseif kind == "pass" then
		pass = pass + c
	else
		hole = hole + c
		table.insert(holes, id)
	end
	print(string.format("%4d  %-22s  %6d  %s", id, name, c, kind))
end

print("")
print(string.format("cells: remap=%d  pass_through=%d  UNHANDLED=%d", handled, pass, hole))
if #holes > 0 then
	print("unhandled ids: " .. table.concat(holes, ", "))
end
if #bad_height > 0 then
	print("bad height levels:")
	for _, b in ipairs(bad_height) do print("  " .. b) end
end

print("")
print("--- validate_remap ---")
local problems = validate_remap({
	enemy_json_exists = function(name)
		local f = io.open(ROOT .. "/assets/enemies/" .. name .. ".json", "r")
		if f then f:close() return true end
		return false
	end,
})
if #problems == 0 then
	print("OK remap tables (enemy JSON + CE slots)")
else
	for _, p in ipairs(problems) do print("PROBLEM " .. p) end
end

print("")
print("Note: VGLC smb2 import is superseded by dlc_smb2J (1.6→CE convert). Prefer smbl from VGLC only.")

if hole > 0 or #problems > 0 then
	os.exit(1)
end
os.exit(0)
