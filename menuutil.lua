-- Tiny pure menu helpers (mappack settings / list text). No UI rewrite.

-- Parse settings.txt body → name, author, description (nil if absent).
function menu_parse_settings_text(s)
	local name, author, description
	if not s or #s == 0 then
		return name, author, description
	end
	local lines = s:split("\n")
	for j = 1, #lines do
		local s2 = lines[j]:split("=")
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

function menu_mappack_title(name)
	return string.sub((name or ""):lower(), 1, 17)
end

function menu_mappack_author_line(author)
	return string.sub(("by " .. (author or "")):lower(), 1, 16)
end

-- Three fixed-width description rows used by mappack list UI.
function menu_mappack_desc_lines(desc)
	desc = (desc or ""):lower()
	return string.sub(desc, 1, 17), string.sub(desc, 18, 34), string.sub(desc, 35, 51)
end
