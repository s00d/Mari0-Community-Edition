--[[ CLI: regenerate local smb3 mappack from dump.

  lua scripts/smb3/build.lua [dump_dir] [out_dir]

  Prefers Python builder (Pillow) for tiles.png property column.
]]

local dump = arg[1] or "/Users/s00d/Downloads/FireShot/smb3/dump"
local out = arg[2] or "mappacks/smb3"

local root
do
	local info = debug.getinfo(1, "S").source
	if info:sub(1, 1) == "@" then
		root = info:sub(2):match("^(.*)/scripts/smb3/") or "."
	else
		root = "."
	end
end

local cmd = string.format(
	'python3 "%s/scripts/mapsdk/build_smb3.py" --dump "%s" --out "%s"',
	root, dump, out
)
print(cmd)
local ok = os.execute(cmd)
if ok == true or ok == 0 then
	print("OK — play locally; do not commit mappacks/smb3")
	os.exit(0)
end
os.exit(1)
