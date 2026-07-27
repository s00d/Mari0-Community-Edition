--[[
  Map SDK entry — literal source list (no plugin loader).
]]

local function script_dir()
	local src = debug.getinfo(1, "S").source
	if src:sub(1, 1) == "@" then
		return src:sub(2):match("^(.*)/") or "."
	end
	return "."
end

local DIR = script_dir()

local M = {
	ir = dofile(DIR .. "/ir.lua"),
	emit = dofile(DIR .. "/emit_mari0.lua"),
	tileset = dofile(DIR .. "/tileset.lua"),
	sources = {
		vglc = dofile(DIR .. "/sources/vglc.lua"),
		smb3dump = dofile(DIR .. "/sources/smb3dump.lua"),
	},
}

return M
