-- Ported from root menuutil.lua (Teal).

-- Tiny pure menu helpers (mappack settings / list text). No UI rewrite.

-- Parse settings.txt body → name, author, description (nil if absent).
local function menu_parse_settings_text(s: any): any
	local name, author, description
	if not s or #s == 0 then
		return name, author, description
	end
	local lines = strsplit(s, "\n")
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


local function menu_mappack_title(name: any): any
	return string.sub((name or ""):lower(), 1, 17)
end
_G.menu_mappack_title = menu_mappack_title


local function menu_mappack_author_line(author: any): any
	return string.sub(("by " .. (author or "")):lower(), 1, 16)
end
_G.menu_mappack_author_line = menu_mappack_author_line


-- Three fixed-width description rows used by mappack list UI.
local function menu_mappack_desc_lines(desc: any): any
	desc = (desc or ""):lower()
	return string.sub(desc, 1, 17), string.sub(desc, 18, 34), string.sub(desc, 35, 51)
end
_G.menu_mappack_desc_lines = menu_mappack_desc_lines

return {
	menu_parse_settings_text = menu_parse_settings_text,
	menu_mappack_title = menu_mappack_title,
	menu_mappack_author_line = menu_mappack_author_line,
	menu_mappack_desc_lines = menu_mappack_desc_lines,
}
