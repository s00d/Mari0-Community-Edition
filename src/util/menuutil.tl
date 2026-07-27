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


local function menu_mappack_title(name: any): string
	return string.sub(((name as string) or ""):lower(), 1, 17)
end
_G.menu_mappack_title = menu_mappack_title


local function menu_mappack_author_line(author: any): string
	return string.sub(("by " .. ((author as string) or "")):lower(), 1, 16)
end
_G.menu_mappack_author_line = menu_mappack_author_line


-- Three fixed-width description rows used by mappack list UI.
local function menu_mappack_desc_lines(desc: any): string, string, string
	local d = ((desc as string) or ""):lower()
	return string.sub(d, 1, 17), string.sub(d, 18, 34), string.sub(d, 35, 51)
end
_G.menu_mappack_desc_lines = menu_mappack_desc_lines

return {
	menu_parse_settings_text = menu_parse_settings_text,
	menu_mappack_title = menu_mappack_title,
	menu_mappack_author_line = menu_mappack_author_line,
	menu_mappack_desc_lines = menu_mappack_desc_lines,
}
