--[[ Scan UI / menu string literals against Mari0 bitmap font charset.
     Font glyphs must match src/app/love_load.tl fontglyphs.
     Direction tokens _dirN only allow N=1..6 (directions.png).
     Run: lua tests/font_charset_checks.lua   or via tests/run.lua
]]

local root = ... or "."
local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

-- Keep in sync with love_load.tl fontglyphs=
local FONTGLYPHS = '0123456789abcdefghijklmnopqrstuvwxyz.:/,"C-_A* !{}\'()+=><#%'
local ALLOWED = {}
for i = 1, #FONTGLYPHS do
	ALLOWED[FONTGLYPHS:sub(i, i)] = true
end
ALLOWED["|"] = true -- properprint newline

local DIR_MIN, DIR_MAX = 1, 6

local function scan_string(s, where, issues)
	local i = 1
	local n = #s
	while i <= n do
		if s:sub(i, i + 3) == "_dir" and s:sub(i + 4, i + 4):match("%d") then
			local d = tonumber(s:sub(i + 4, i + 4))
			if not d or d < DIR_MIN or d > DIR_MAX then
				issues[#issues + 1] = string.format("%s: bad _dir%d in %q", where, d or -1, s)
			end
			i = i + 5
		else
			local b = s:byte(i)
			if b >= 0x80 then
				issues[#issues + 1] = string.format("%s: non-ASCII byte 0x%02X in %q", where, b, s)
				-- skip UTF-8 sequence
				local extra = (b >= 0xF0 and 3) or (b >= 0xE0 and 2) or (b >= 0xC0 and 1) or 0
				i = i + 1 + extra
			else
				local ch = s:sub(i, i)
				if not ALLOWED[ch] then
					issues[#issues + 1] = string.format("%s: unsupported %q (U+%04X) in %q", where, ch, b, s)
				end
				i = i + 1
			end
		end
	end
end

-- Extract "..." string literals after print/notice/footer call sites (best-effort).

local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local data = f:read("*a")
	f:close()
	return data
end

local function list_tl(dir)
	local out = {}
	local cmd = string.format('find %q -name "*.tl" -type f 2>/dev/null', dir)
	local p = io.popen(cmd)
	if p then
		for line in p:lines() do
			out[#out + 1] = line
		end
		p:close()
	end
	return out
end

local issues = {}

-- Prefer src; fall back to build if src missing.
local ui_root = root .. "/src/ui"
local net_root = root .. "/src/net"
local app_root = root .. "/src/app"
local files = {}
for _, d in ipairs({ ui_root, net_root }) do
	for _, f in ipairs(list_tl(d)) do
		files[#files + 1] = f
	end
end
-- love_load / session status strings that hit the HUD
for _, name in ipairs({ "love_load.tl", "main_util_misc.tl" }) do
	local p = app_root .. "/" .. name
	if read_file(p) then
		files[#files + 1] = p
	end
end

check("found UI teal sources", #files > 0, "no .tl under src/ui")

local function unescape_tl_string(s)
	-- Teal/Lua source escapes inside "...": \" \\ \n etc.
	s = s:gsub("\\([\\\"'ntr])", function(c)
		if c == "n" then
			return "\n"
		elseif c == "t" then
			return "\t"
		elseif c == "r" then
			return "\r"
		end
		return c
	end)
	return s
end

-- Find double-quoted string at pos (pos points at opening "). Returns value, end_index.
local function read_quoted(body, pos)
	if body:sub(pos, pos) ~= '"' then
		return nil, pos
	end
	local i = pos + 1
	local n = #body
	local buf = {}
	while i <= n do
		local ch = body:sub(i, i)
		if ch == "\\" and i < n then
			buf[#buf + 1] = body:sub(i, i + 1)
			i = i + 2
		elseif ch == '"' then
			return unescape_tl_string(table.concat(buf)), i
		else
			buf[#buf + 1] = ch
			i = i + 1
		end
	end
	return nil, pos
end

local function extract_after_prefix(body, prefix_pat, kind, found)
	local pos = 1
	while true do
		local s, e = body:find(prefix_pat, pos)
		if not s then
			break
		end
		-- skip whitespace after match, then expect "
		local i = e + 1
		while body:sub(i, i):match("%s") do
			i = i + 1
		end
		local val, endpos = read_quoted(body, i)
		if val then
			if kind == "notice.new" then
				val = val:lower()
			end
			found[#found + 1] = { val, kind }
			pos = endpos + 1
		else
			pos = e + 1
		end
	end
end

local function extract_strings(body)
	local found = {}
	-- footers: text = "..."
	do
		local pos = 1
		while true do
			local s, e = body:find('footer%s*=%s*{', pos)
			if not s then
				break
			end
			local close = body:find("}", e)
			if not close then
				break
			end
			local chunk = body:sub(e, close)
			local ts, te = chunk:find('text%s*=%s*"')
			if ts then
				local val = read_quoted(chunk, te)
				if val then
					found[#found + 1] = { val, "footer" }
				end
			end
			pos = close + 1
		end
	end
	extract_after_prefix(body, "properprint%s*%(%s*", "properprint", found)
	extract_after_prefix(body, "properprintbackground%s*%(%s*", "properprintbackground", found)
	extract_after_prefix(body, "notice%.new%s*%(%s*", "notice.new", found)
	extract_after_prefix(body, "set_status%s*%(%s*", "set_status", found)
	-- menu_draw_footer(x, y, "text") — third arg; scan each call's opening paren region
	do
		local pos = 1
		while true do
			local s, e = body:find("menu_draw_footer%s*%(", pos)
			if not s then
				break
			end
			local depth, i = 1, e + 1
			local n = #body
			local args = {}
			local cur = {}
			while i <= n and depth > 0 do
				local ch = body:sub(i, i)
				if ch == '"' then
					local val, endpos = read_quoted(body, i)
					if val then
						args[#args + 1] = val
						i = endpos + 1
					else
						i = i + 1
					end
				elseif ch == "(" then
					depth = depth + 1
					i = i + 1
				elseif ch == ")" then
					depth = depth - 1
					i = i + 1
				else
					i = i + 1
				end
			end
			if args[1] then
				found[#found + 1] = { args[#args], "menu_draw_footer" }
			end
			pos = i
		end
	end
	-- guielement:new("button", x, y, "label"
	do
		local pos = 1
		while true do
			local s, e = body:find('guielement:new%s*%(%s*"button"', pos)
			if not s then
				break
			end
			-- skip two commas then quoted label
			local i = e + 1
			local commas = 0
			local n = #body
			while i <= n and commas < 2 do
				if body:sub(i, i) == "," then
					commas = commas + 1
				end
				i = i + 1
			end
			while body:sub(i, i):match("%s") do
				i = i + 1
			end
			local val = read_quoted(body, i)
			if val then
				found[#found + 1] = { val, "guielement label" }
			end
			pos = e + 1
		end
	end
	return found
end

for _, path in ipairs(files) do
	local body = read_file(path)
	if body then
		local rel = path:gsub("^" .. root:gsub("(%W)", "%%%1") .. "/?", "")
		for _, pair in ipairs(extract_strings(body)) do
			scan_string(pair[1], rel .. " [" .. pair[2] .. "]", issues)
		end
	end
end

-- Live layout footers (compiled / require path)
package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	package.path,
}, ";")

local layout_ok, layout_err = pcall(function()
	require("core.stringutil")
	require("ui.menu_layout")
	local mains = {
		menu_layout_main({ items = { { id = "a", label = "a" } } }),
		menu_layout_mappack({ visible_count = 1, scroll = 0 }),
		menu_layout_options_rows(3),
	}
	for _, lay in ipairs(mains) do
		local ft = lay.footer and lay.footer.text
		if ft then
			scan_string(ft, "menu_layout runtime footer", issues)
		end
	end
end)

if not layout_ok then
	-- build/ may be stale before teal-build; still report scan issues
	print("WARN menu_layout require skipped: " .. tostring(layout_err))
else
	check("menu_layout footers load", true)
end

if #issues == 0 then
	check("UI strings vs fontglyphs+_dir1..6", true)
else
	for _, msg in ipairs(issues) do
		print("FAIL " .. msg)
	end
	failed = failed + #issues
	check("UI strings vs fontglyphs+_dir1..6", false, #issues .. " issue(s)")
end

-- Self-check: known bad tokens detected
do
	local probe = {}
	scan_string("_dir8 tabs", "probe", probe)
	scan_string("hello — world", "probe", probe)
	scan_string("test@cursor", "probe", probe)
	check("detector catches _dir8", #probe >= 1)
	check("detector catches unicode/at", #probe >= 3, tostring(#probe))
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
