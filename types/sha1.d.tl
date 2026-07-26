-- Ambient defs for LuaRocks sha1 0.5 (kikito/sha.lua vendored as lib/sha1.lua).
-- Module is callable: sha1(msg) == sha1.sha1(msg)

local record sha1
	_VERSION: string
	_URL: string
	_DESCRIPTION: string
	_LICENSE: string
	sha1: function(string): string
	binary: function(string): string
	hmac: function(string, string): string
	hmac_binary: function(string, string): string
	metamethod __call: function(sha1, string): string
end

return sha1
