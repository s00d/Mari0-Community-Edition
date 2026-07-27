--[[ Level serialization facade (Stage 2.4). ]]

local Io = {}

function Io.parse_tiles(raw: string): LevelTilesParse|nil, string|nil
	return level_parse_tiles_only(raw)
end

function Io.serialize_tiles(m: {number:{number:MapCell}}, cm: {number:{number:any}}, mw: number, mh: number, v: integer): string
	return level_serialize_maptiles(m, cm, mw, mh, v)
end

function Io.detect_version(raw: string): integer
	return level_detect_format_version(raw)
end

return Io
