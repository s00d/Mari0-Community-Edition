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

-- Flat legacy names for modules that live under build/ (dotted require only).
local banned_flat_requires = {
	"tilekey", "mathutil", "stringutil", "tableutil", "listutil", "maputil",
	"zones", "bounceutil", "globstate", "levelio", "spawnregistry",
	"physicslate", "physicsconvert", "physicsdir", "physicsemance",
	"physicscollision", "physicscheckrect", "physicsportal",
	"physicshandlegroup", "physicsupdate",
	"portalutil", "hatutil", "playerutil", "userectutil", "scrollutil",
	"updateutil", "menuutil", "enemyutil", "editorutil",
	"mario", "enemy", "menu", "editor", "gui", "rightclickmenu",
	"variables", "enemies", "characterloader", "musicloader", "notice",
	"quad", "tile", "scrollingscore", "scrollingtext",
	"levelscreen", "intro", "camera", "portal",
	"game", "game_load", "game_spawn", "game_portal", "game_update", "game_draw",
	"entity", "animation", "animationsystem", "animationguiline",
	"funnel",
	"laser",
	"laserdetector",
	"lightbridge",
	"emancipationgrill",
	"panel",
	"button",
	"door",
	"faithplate",
	"gel",
	"geldispenser",
	"cubedispenser",
	"pushbutton",
	"portalent",
	"portalparticle",
	"portalprojectile",
	"portalwall",
	"emancipateanimation",
	"emancipationfizzle",
	"pedestal",
	"groundlight",
	"platform",
	"platformspawner",
	"scaffold",
	"box",
	"spring",
	"vine",
	"bowser",
	"bulletbill",
	"fireball",
	"castlefire",
	"fire",
	"firework",
	"blockdebris",
	"bubble",
	"miniblock",
	"seesaw",
	"seesawplatform",
	"coinblockanimation",
	"itemanimation",
	"rainboom",
	"magic",
	"screenboundary",
	"ceilblocker",
	"checkpoint",
	"enemyspawner",
	"musicentity",
	"actionblock",
	"textentity",
	"andgate",
	"notgate",
	"orgate",
	"delayer",
	"squarewave",
	"rsflipflop",
	"walltimer",
	"wallindicator",
	"regiontrigger",
	"zgbooltrigger",
	"zginttrigger",
	"animationtrigger",
	"animatedtimer",
	"animatedbooltimer",
	"animatedtiletrigger",
	"animatedquad",
	"hatconfigs",
	"bighatconfigs",
	"customhats",
	"regiondrag",
	"dialogbox",
	"entitylistitem",
	"entitytooltip",
	"lobby",
	"onlinemenu",
}

local function scan_file(path, rel)
	local f = io.open(path, "r")
	if not f then
		return
	end
	local body = f:read("*a")
	f:close()
	for _, ban in ipairs(bans) do
		local line_no = 0
		for line in (body .. "\n"):gmatch("(.-)\n") do
			line_no = line_no + 1
			if line:find(ban.pattern) then
				local trimmed = line:match("^%s*(.*)")
				if trimmed and not trimmed:match("^%-%-") then
					check(ban.label .. " absent in " .. rel, false,
						"line " .. line_no .. " (" .. ban.note .. ")")
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
		if not line:find("/%.git/") and not line:find("/tests/") and not line:find("/build/")
			and not line:find("/legacy/") and not line:find("/dist/") then
			table.insert(out, line)
		end
	end
	p:close()
	return out
end

local files = list_files(root, {"lua", "frag", "tl"})
check("scanned source files", #files > 0, "count=" .. #files)

local hits_before = failed
for _, path in ipairs(files) do
	local rel = path:sub(#root + 2)
	scan_file(path, rel)
end
if failed == hits_before then
	check("no banned Love/GLSL APIs in source", true)
end

-- Root .lua allowlist only (entry + conf + teal config; rocks live in lib/)
do
	local allow = {
		["conf.lua"] = true,
		["tlconfig.lua"] = true,
		["main.lua"] = true,
	}
	local extra = 0
	local p = io.popen(string.format('find "%s" -maxdepth 1 -name "*.lua" -type f 2>/dev/null', root))
	if p then
		for path in p:lines() do
			local name = path:match("([^/]+)$")
			if name and not allow[name] then
				extra = extra + 1
				check("root lua allowlist", false, name .. " not allowed")
			end
		end
		p:close()
	end
	if extra == 0 then
		check("root .lua allowlist only", true)
	end
end

-- Ban new root files that are only `return require(...)` shims
do
	local shim_hits = 0
	local p = io.popen(string.format('find "%s" -maxdepth 1 -name "*.lua" -type f 2>/dev/null', root))
	if p then
		for path in p:lines() do
			local f = io.open(path, "r")
			if f then
				local body = f:read("*a")
				f:close()
				local stripped = body:gsub("%-%-[^\n]*", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
				if stripped and stripped:match("^return require%s*%(") then
					shim_hits = shim_hits + 1
					local name = path:match("([^/]+)$")
					check("no root shim re-export " .. name, false, "delete or inline dotted require")
				end
			end
		end
		p:close()
	end
	if shim_hits == 0 then
		check("no root return-require shim files", true)
	end
end

-- Ban flat require of ported modules in non-test sources
do
	local flat_hits = 0
	for _, path in ipairs(files) do
		local rel = path:sub(#root + 2)
		if rel:match("%.lua$") or rel:match("%.tl$") then
			local f = io.open(path, "r")
			if f then
				local body = f:read("*a")
				f:close()
				local line_no = 0
				for line in (body .. "\n"):gmatch("(.-)\n") do
					line_no = line_no + 1
					local trimmed = line:match("^%s*(.*)")
					if trimmed and not trimmed:match("^%-%-") then
						for _, name in ipairs(banned_flat_requires) do
							if trimmed:find('require%s*[\'"]' .. name .. '[\'"]') then
								flat_hits = flat_hits + 1
								check("no flat require \"" .. name .. "\"", false, rel .. ":" .. line_no)
							end
						end
					end
				end
			end
		end
	end
	if flat_hits == 0 then
		check("no flat requires of ported modules", true)
	end
end

-- newImage / newSource only in src/assets/** and app boot/load media helpers
local media_hits = 0
for _, path in ipairs(files) do
	local rel = path:sub(#root + 2)
	if rel:match("%.tl$") then
		local allowed = rel:match("^src/assets/") or rel == "src/app/boot.tl" or rel == "src/app/love_load.tl"
		if not allowed then
			local f = io.open(path, "r")
			if f then
				local body = f:read("*a")
				f:close()
				local line_no = 0
				for line in (body .. "\n"):gmatch("(.-)\n") do
					line_no = line_no + 1
					local trimmed = line:match("^%s*(.*)")
					if trimmed and not trimmed:match("^%-%-") then
						if trimmed:find("love%.graphics%.newImage") or trimmed:find("love%.audio%.newSource") then
							media_hits = media_hits + 1
							check("newImage/newSource only assets+boot+load", false, rel .. ":" .. line_no)
						end
					end
				end
			end
		end
	end
end
if media_hits == 0 then
	check("newImage/newSource confined to assets+boot+load", true)
end

-- Progress ratchets: FAIL if counts go UP; suggest lower max when count drops.
do
	local RATCHET = {
		{ pattern = "global function [%w_]+%(%.%.%.: any%)", max = 0, label = "untyped global function doors" },
		{ pattern = "global [%w_]+: function%(%.%.%.: any%)", max = 0, label = "ambient (...: any) doors" },
		{ pattern = " as any",                          max = 18, label = "as any" },
		{ pattern = "is {any}",                         max = 2,   label = "is {any} records" },
		{ pattern = "%): any%.%.%.",                    max = 2,   label = "any... returns" },
	}

	local bodies = {}
	for _, path in ipairs(list_files(root .. "/src", {"tl"})) do
		local f = io.open(path, "r")
		if f then
			bodies[#bodies + 1] = f:read("*a") or ""
			f:close()
		end
	end
	for _, path in ipairs(list_files(root .. "/types", {"tl"})) do
		local f = io.open(path, "r")
		if f then
			bodies[#bodies + 1] = f:read("*a") or ""
			f:close()
		end
	end
	local corpus = table.concat(bodies, "\n")

	for _, r in ipairs(RATCHET) do
		local count = 0
		for _ in corpus:gmatch(r.pattern) do
			count = count + 1
		end
		if count > r.max then
			check("ratchet " .. r.label, false, "count=" .. count .. " max=" .. r.max)
		else
			check("ratchet " .. r.label .. " <=" .. r.max, true)
			if count < r.max then
				print("NOTE ratchet " .. r.label .. ": count=" .. count .. " — lower max to " .. count)
			end
		end
	end
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
