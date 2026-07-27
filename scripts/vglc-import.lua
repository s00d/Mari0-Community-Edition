#!/usr/bin/env lua
--[[
  CLI: convert TheVGLC smb2 / smbl into Mari0 mappacks.

  Usage:
    lua scripts/vglc-import.lua \
      --smb2 /path/to/TheVGLC/smb2 \
      --smbl /path/to/TheVGLC/smbl \
      --out-smb2 mappacks/smb2 \
      --out-smbl mappacks/smbl
]]

local function script_root()
	local src = debug.getinfo(1, "S").source
	if src:sub(1, 1) == "@" then
		local path = src:sub(2)
		return path:match("^(.*)/scripts/vglc%-import%.lua$") or "."
	end
	return "."
end

local ROOT = script_root()
package.path = ROOT .. "/?.lua;" .. ROOT .. "/scripts/?.lua;" .. package.path

local import = dofile(ROOT .. "/scripts/vglc/import.lua")

local args = {
	smb2 = nil,
	smbl = nil,
	out_smb2 = ROOT .. "/mappacks/smb2",
	out_smbl = ROOT .. "/mappacks/smbl",
}

local i = 1
while i <= #arg do
	local a = arg[i]
	if a == "--smb2" then
		i = i + 1
		args.smb2 = arg[i]
	elseif a == "--smbl" then
		i = i + 1
		args.smbl = arg[i]
	elseif a == "--out-smb2" then
		i = i + 1
		args.out_smb2 = arg[i]
	elseif a == "--out-smbl" then
		i = i + 1
		args.out_smbl = arg[i]
	elseif a == "-h" or a == "--help" then
		print("see script header")
		os.exit(0)
	else
		io.stderr:write("unknown arg: " .. tostring(a) .. "\n")
		os.exit(1)
	end
	i = i + 1
end

if not args.smb2 and not args.smbl then
	io.stderr:write("need --smb2 and/or --smbl\n")
	os.exit(1)
end

if args.smbl then
	print("=== import smbl ===")
	import.import_smbl(args.smbl, args.out_smbl)
end

if args.smb2 then
	print("=== import smb2 ===")
	import.import_smb2(args.smb2, args.out_smb2)
end

print("done")
