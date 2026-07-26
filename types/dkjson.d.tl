-- Ambient defs for dkjson 2.10 (LuaRocks / lib/dkjson.lua). Pure Lua; Love-safe.
-- See http://dkolf.de/dkjson-lua/

local record DkjsonState
	indent: boolean|string|nil
	level: integer|nil
	buffer: {string}|nil
	bufferlen: integer|nil
	tables: {any:boolean}|nil
	keyorder: {any}|nil
	exception: function(string, any, DkjsonState|nil, string): string|nil
end

local record dkjson
	version: string
	null: any
	-- encode(value [, state]): string
	encode: function(any, DkjsonState|nil): string
	-- decode(str [, pos [, nullval]]): value, pos
	decode: function(string, integer|nil, any|nil): any, integer|nil
	quotestring: function(string): string
	addnewline: function(DkjsonState)
	encodeexception: function(string, any, DkjsonState|nil, string): string
	use_lpeg: function(): dkjson
end

return dkjson
