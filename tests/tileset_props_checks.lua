--[[
  tileset_props_checks: tracked mappacks with tiles.png must have collision flags.
  Local gitignored smb3 is checked if present on disk.
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

-- Minimal PNG IHDR + IDAT reader via love-less approach: shell out to python
local function count_collision_png(path)
	-- Escape for a Python single-quoted string
	local escaped = path:gsub("\\", "\\\\"):gsub("'", "\\'")
	local cmd = string.format(
		[[python3 -c 'from PIL import Image; im=Image.open("%s").convert("RGBA"); w,h=im.size; print(sum(1 for ty in range(h//17) for tx in range(w//17) if im.getpixel((tx*17+16,ty*17))[3]>127))']],
		escaped
	)
	local f = io.popen(cmd)
	if not f then
		return nil
	end
	local out = f:read("*a")
	f:close()
	return tonumber((out or ""):match("(%d+)"))
end

local function pack_has_tiles(pack)
	local p = root .. "/mappacks/" .. pack .. "/tiles.png"
	local f = io.open(p, "r")
	if f then
		f:close()
		return p
	end
	return nil
end

-- Tracked mappacks (not smb3 — ROM-derived, gitignored)
local tracked = { "smb", "smb2", "smbl", "portal" }
for _, pack in ipairs(tracked) do
	local p = pack_has_tiles(pack)
	if p then
		local n = count_collision_png(p)
		check(pack .. " tiles.png collision>0", n ~= nil and n > 0, tostring(n))
	else
		print("SKIP " .. pack .. " (no tiles.png)")
	end
end

-- smb3 local-only: if present, must also have collision
local smb3 = pack_has_tiles("smb3")
if smb3 then
	local n = count_collision_png(smb3)
	check("smb3 (local) tiles.png collision>0", n ~= nil and n > 0, tostring(n))
else
	print("SKIP smb3 (not on disk — regenerate via scripts/mapsdk/build_smb3.py)")
end

-- mapsdk classify smoke
package.path = root .. "/scripts/?.lua;" .. root .. "/scripts/?/init.lua;" .. package.path
local ok, mapsdk = pcall(dofile, root .. "/scripts/mapsdk/init.lua")
check("mapsdk loads", ok, tostring(mapsdk))
if ok then
	local props = mapsdk.tileset.classify("Flat Ground")
	check("classify Flat Ground solid", (props.collision or 0) > 0)
	local anti = mapsdk.tileset.classify("Background Clouds")
	check("classify Background Clouds anti", (anti.collision or 0) < 0)
	local hills = mapsdk.tileset.classify("Background Hills A")
	check("classify Background Hills solid", (hills.collision or 0) > 0)

	local smb3src = mapsdk.sources.smb3dump
	check("bonus naming 1-1_1", smb3src.level_filename({
		world = 1, name = "Level 1 Bonus", id = "1-9_level_1_bonus_area"
	}) == "1-1_1")
	check("main naming 1-1", smb3src.level_filename({
		world = 1, name = "Level 1", id = "1-1"
	}) == "1-1")
end

return failed
