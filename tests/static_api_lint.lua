--[[
  Static lint: ban removed/broken Love APIs and old GLSL identifiers.
  Returns failure count when invoked from tests/run.lua.
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

local bans = {
	{pattern = "love%.filesystem%.exists%s*%(", label = "love.filesystem.exists", note = "use getInfo"},
	{pattern = "love%.graphics%.drawq%s*%(", label = "love.graphics.drawq", note = "use draw"},
	{pattern = "%f[%w]gl_TexCoord%f[%W]", label = "gl_TexCoord", note = "use VaryingTexCoord"},
	{pattern = "%f[%w]texture2D%f[%W]", label = "texture2D", note = "use Texel"},
}

local function scan_file(path, rel)
	local f = io.open(path, "r")
	if not f then
		return
	end
	local body = f:read("*a")
	f:close()
	-- Skip polyfill definition that wraps exists for Love < 11
	if rel == "main.lua" then
		body = body:gsub("function love%.filesystem%.getInfo.-end", "")
	end
	for _, ban in ipairs(bans) do
		local line_no = 0
		for line in (body .. "\n"):gmatch("(.-)\n") do
			line_no = line_no + 1
			if line:find(ban.pattern) then
				local trimmed = line:match("^%s*(.*)")
				if trimmed and not trimmed:match("^%-%-") then
					-- Love < 11 polyfill in main.lua may call exists
					if ban.label == "love.filesystem.exists" and rel == "main.lua" then
						-- ok
					else
						check(ban.label .. " absent in " .. rel, false,
							"line " .. line_no .. " (" .. ban.note .. ")")
					end
				end
			end
		end
	end
end

local function list_files(dir, exts)
	local out = {}
	local cmd
	if package.config:sub(1, 1) == "\\" then
		cmd = string.format('dir /s /b "%s\\*.*"', dir:gsub("/", "\\"))
	else
		local pats = {}
		for _, e in ipairs(exts) do
			table.insert(pats, string.format('-name "*.%s"', e))
		end
		cmd = string.format('find "%s" \\( %s \\) -type f 2>/dev/null', dir, table.concat(pats, " -o "))
	end
	local p = io.popen(cmd)
	if not p then
		return out
	end
	for line in p:lines() do
		if not line:find("/%.git/") and not line:find("/tests/") then
			table.insert(out, line)
		end
	end
	p:close()
	return out
end

local files = list_files(root, {"lua", "frag"})
check("scanned source files", #files > 0, "count=" .. #files)

local hits_before = failed
for _, path in ipairs(files) do
	local rel = path:sub(#root + 2)
	scan_file(path, rel)
end
if failed == hits_before then
	check("no banned Love/GLSL APIs in source", true)
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
