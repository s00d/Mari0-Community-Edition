--[[
  VGLC source adapter — wraps scripts/vglc/import.lua into mapsdk IR.
]]

local function script_dir()
	local src = debug.getinfo(1, "S").source
	if src:sub(1, 1) == "@" then
		return src:sub(2):match("^(.*)/") or "."
	end
	return "."
end

local DIR = script_dir()
local import = dofile(DIR .. "/../../vglc/import.lua")
local irmod = dofile(DIR .. "/../ir.lua")

local M = {}
M.import = import

function M.to_ir(rows, legend_name)
	local legend = legend_name == "smb2" and import.legend_smb2 or import.legend_smb
	local w = #rows[1]
	local h = #rows
	local ir = irmod.new({ source = "vglc", legend = legend_name or "smb" })
	irmod.set_size(ir, w, h, import.T.EMPTY)

	for y = 1, h do
		for x = 1, w do
			local ch = rows[y]:sub(x, x)
			local e = legend.map[ch]
			if e then
				ir.tiles[x][y] = e.tile or import.T.EMPTY
				if e.enemy then
					ir.entities[#ir.entities + 1] = { x = x, y = y, name = e.enemy }
				end
				if e.spawn then
					ir.spawn = { x = x, y = y }
				end
				if e.flag then
					ir.finish = { x = x, y = y }
				end
			end
		end
	end
	return ir
end

return M
