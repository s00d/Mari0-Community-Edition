-- Ported from root menuutil.lua (Teal).

-- Tiny pure menu helpers (mappack settings / list text). No UI rewrite.

-- Parse settings.txt body → name, author, description (nil if absent).
local function menu_parse_settings_text(s: any): any, any, any
	local name: any = nil
	local author: any = nil
	local description: any = nil
	local ss = s as string|nil
	if not ss or #ss == 0 then
		return name, author, description
	end
	local lines = strsplit(ss, "\n")
	for j = 1, #lines do
		local s2 = strsplit(lines[j], "=")
		if s2[1] == "name" then
			name = s2[2]
		elseif s2[1] == "author" then
			author = s2[2]
		elseif s2[1] == "description" then
			description = s2[2]
		end
	end
	return name, author, description
end
_G.menu_parse_settings_text = menu_parse_settings_text


local function menu_mappack_title(name: any, maxc: any): string
	local n = math.floor(tonumber(maxc as any) or 17)
	if n < 1 then n = 1 end
	return string.sub(((name as string) or ""):lower(), 1, n)
end
_G.menu_mappack_title = menu_mappack_title


local function menu_mappack_author_line(author: any, maxc: any): string
	local n = math.floor(tonumber(maxc as any) or 16)
	if n < 1 then n = 1 end
	return string.sub(("by " .. ((author as string) or "")):lower(), 1, n)
end
_G.menu_mappack_author_line = menu_mappack_author_line


-- Description rows clipped to panel width (chars).
local function menu_mappack_desc_lines(desc: any, maxc: any): string, string, string, string
	local w = math.floor(tonumber(maxc as any) or 15)
	if w < 1 then w = 1 end
	local d = ((desc as string) or ""):lower()
	return string.sub(d, 1, w), string.sub(d, w + 1, w * 2), string.sub(d, w * 2 + 1, w * 3), string.sub(d, w * 3 + 1, w * 4)
end
_G.menu_mappack_desc_lines = menu_mappack_desc_lines

return {
	menu_parse_settings_text = menu_parse_settings_text,
	menu_mappack_title = menu_mappack_title,
	menu_mappack_author_line = menu_mappack_author_line,
	menu_mappack_desc_lines = menu_mappack_desc_lines,
}
