#!/usr/bin/env lua
--[[
  CLI: convert Mari0 1.6 packs from toconvert/ → mappacks/ (no LÖVE / no GUI).

  Usage:
    lua scripts/convert-mappack.lua [--all | PACK...] [--strict] [--src DIR] [--dst DIR]

  Examples:
    lua scripts/convert-mappack.lua --all
    lua scripts/convert-mappack.lua dlc_smb2J dlc_acid_trip --strict

  Never copies version.txt (packs with version.txt are hidden from the menu).
  Source packs belong in toconvert/; do not place 1.6 packs directly in mappacks/.
]]

local ROOT = arg[0]:match("^(.*)/scripts/convert%-mappack%.lua$") or "."
package.path = table.concat({
	ROOT .. "/build/?.lua",
	ROOT .. "/build/?/init.lua",
	ROOT .. "/lib/?.lua",
	ROOT .. "/lib/?/init.lua",
	package.path,
}, ";")

width = width or 25
height = height or 14

local function usage()
	io.stderr:write([[Usage: lua scripts/convert-mappack.lua [--all | PACK...] [--strict] [--src DIR] [--dst DIR]
]])
	os.exit(2)
end

local packs = {}
local strict = false
local src_root = ROOT .. "/toconvert"
local dst_root = ROOT .. "/mappacks"
local i = 1
while i <= #arg do
	local a = arg[i]
	if a == "--all" then
		-- filled after parse
		packs._all = true
	elseif a == "--strict" then
		strict = true
	elseif a == "--src" then
		i = i + 1
		src_root = arg[i] or usage()
	elseif a == "--dst" then
		i = i + 1
		dst_root = arg[i] or usage()
	elseif a == "-h" or a == "--help" then
		usage()
	elseif a:sub(1, 1) == "-" then
		io.stderr:write("unknown flag: " .. a .. "\n")
		usage()
	else
		table.insert(packs, a)
	end
	i = i + 1
end

require("core.stringutil")
require("core.tableutil")
require("app.variables")
require("world.levelio")
require("world.entity_remap")
require("world.mappack_convert")

local lfs_ok, lfs = pcall(require, "lfs")

local function list_dir(dir)
	local out = {}
	if lfs_ok then
		for name in lfs.dir(dir) do
			if name ~= "." and name ~= ".." then
				table.insert(out, name)
			end
		end
	else
		local p = io.popen('ls -1 "' .. dir:gsub('"', '\\"') .. '" 2>/dev/null')
		if p then
			for line in p:lines() do
				table.insert(out, line)
			end
			p:close()
		end
	end
	table.sort(out)
	return out
end

local function exists(path)
	local f = io.open(path, "rb")
	if f then
		f:close()
		return true
	end
	if lfs_ok then
		local attr = lfs.attributes(path)
		return attr ~= nil
	end
	-- directory probe
	local p = io.popen('test -e "' .. path:gsub('"', '\\"') .. '" && echo y')
	local ok = p and p:read("*l") == "y"
	if p then p:close() end
	return ok
end

local function is_dir(path)
	if lfs_ok then
		local attr = lfs.attributes(path)
		return attr and attr.mode == "directory"
	end
	local p = io.popen('test -d "' .. path:gsub('"', '\\"') .. '" && echo y')
	local ok = p and p:read("*l") == "y"
	if p then p:close() end
	return ok
end

local function mkdir_p(path)
	if path == "" or path == "." then return end
	if exists(path) then return end
	local parent = path:match("^(.*)/[^/]+$")
	if parent then mkdir_p(parent) end
	if lfs_ok then
		lfs.mkdir(path)
	else
		os.execute('mkdir -p "' .. path:gsub('"', '\\"') .. '"')
	end
end

local function read_file(path)
	local f = io.open(path, "rb")
	if not f then return nil end
	local data = f:read("*a")
	f:close()
	return data
end

local function write_file(path, data)
	local parent = path:match("^(.*)/[^/]+$")
	if parent then mkdir_p(parent) end
	local f, err = io.open(path, "wb")
	if not f then return nil, err end
	f:write(data)
	f:close()
	return true
end

local function remove_file(path)
	os.remove(path)
end

local fs = {
	list = list_dir,
	read = read_file,
	write = write_file,
	mkdir = mkdir_p,
	exists = exists,
	remove = remove_file,
}

if packs._all then
	packs = {}
	for _, name in ipairs(list_dir(src_root)) do
		if is_dir(src_root .. "/" .. name) and name:match("^dlc_") then
			table.insert(packs, name)
		end
	end
end

if #packs == 0 then
	io.stderr:write("no packs specified (use --all or PACK names)\n")
	usage()
end

-- Validate remaps once
local problems = validate_remap({
	enemy_json_exists = function(name)
		return exists(ROOT .. "/assets/enemies/" .. name .. ".json")
	end,
})
if #problems > 0 then
	for _, p in ipairs(problems) do
		io.stderr:write("remap: " .. p .. "\n")
	end
	if strict then
		os.exit(1)
	end
end

local failed = 0
for _, pack in ipairs(packs) do
	local src = src_root .. "/" .. pack
	local dst = dst_root .. "/" .. pack
	if not is_dir(src) then
		io.stderr:write("FAIL missing source " .. src .. "\n")
		failed = failed + 1
	else
		print("=== convert " .. pack .. " ===")
		local unknown_total = 0
		local stats, err = convert_mappack_fs(src, dst, fs, {
			strict = strict,
			on_unknown = function(id)
				unknown_total = unknown_total + 1
				io.stderr:write(string.format("WARN unknown entity id %d in %s\n", id, pack))
				return not strict
			end,
		})
		if err then
			io.stderr:write("FAIL " .. pack .. ": " .. tostring(err) .. "\n")
			failed = failed + 1
		else
			local ver = dst .. "/version.txt"
			if exists(ver) then
				io.stderr:write("FAIL " .. pack .. ": version.txt present in output (hidden from menu)\n")
				remove_file(ver)
				failed = failed + 1
			end
			print(string.format("OK  %s: %d levels, %d errors, unknown_ids=%d → %s",
				pack, stats.levels, #stats.errors, unknown_total, dst))
			for _, e in ipairs(stats.errors) do
				io.stderr:write("  level err: " .. e .. "\n")
				failed = failed + 1
			end
		end
	end
end

if failed > 0 then
	os.exit(1)
end
print("All packs converted.")
os.exit(0)
