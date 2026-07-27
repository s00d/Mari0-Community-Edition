--[[
  Mari0 1.6 mappack source — intentionally NOT an IR adapter.

  1.6 levels are already Mari0 tile/entity text (comma cells + semicolon options).
  Converting them is text→text via world.mappack_convert.convert_level_text /
  scripts/convert-mappack.lua (toconvert/ → mappacks/, never copy version.txt).

  mapsdk IR (tiles grid + entities) adds little here and would re-encode the same
  cells. Use mapsdk IR for VGLC/smb3 dumps; use mappack_convert for dlc_* packs.

  Coverage: lua scripts/mappack_coverage_report.lua
  Convert:  lua scripts/convert-mappack.lua --all
  In-game:  mappack menu → Tab → toconvert list → Enter

  SMB2J: prefer dlc_smb2J over VGLC smb2 import.
]]

return {
	kind = "text_to_text",
	module = "world.mappack_convert",
	cli = "scripts/convert-mappack.lua",
	supersedes_vglc = { "smb2" },
}
