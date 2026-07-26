--[[
  Structural checks for game_draw / scenedraw / drawlevel phase split (no LÖVE).
  Locks named draw phases, orchestrator calls, portal scissors, editormode.
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

local f = assert(io.open(root .. "/game.lua", "r"))
local src = f:read("*a")
f:close()

local function extract_fn(name)
	local pat = "function " .. name .. "%b()\n(.-)\nfunction "
	local body = src:match(pat)
	if body then
		return body
	end
	-- last function before drawui alias or file region
	pat = "function " .. name .. "%b()\n(.-)\nend\n"
	return src:match(pat)
end

-- Prefer non-greedy until next top-level function
local function extract_top(name)
	local a, b = src:find("function " .. name .. "%b()\n")
	if not a then
		return nil
	end
	local rest = src:sub(b + 1)
	local body = rest:match("^(.-)\nfunction ")
	if not body then
		body = rest:match("^(.-)\ndrawui = ")
	end
	if not body then
		body = rest:match("^(.-)\nend\n")
		if body then
			body = body -- without final end
		end
	end
	return body
end

local phase_fns = {
	"drawlevel_tiles",
	"drawlevel",
	"game_draw_hud",
	"drawforeground",
	"game_draw_props",
	"game_draw_objects",
	"game_draw_fx",
	"scenedraw",
	"game_draw_seethrough_portals",
	"game_draw_player_markers",
	"game_draw_debug",
	"game_draw_pausemenu",
	"game_draw",
}

for _, name in ipairs(phase_fns) do
	check(name .. " exists", src:find("function " .. name .. "%b()", 1, false) ~= nil)
end

check("drawui alias", src:find("drawui = game_draw_hud") ~= nil)
check("no nested scenedraw", src:find("\tfunction scenedraw()") == nil)

local gd = extract_top("game_draw")
check("game_draw body", gd ~= nil)
if gd then
	local nlines = select(2, gd:gsub("\n", "\n")) + 1
	check("game_draw thin (<=120 lines)", nlines <= 120, tostring(nlines))
	check("gd calls seethrough", gd:find("game_draw_seethrough_portals%(%)") ~= nil)
	check("gd calls scenedraw", gd:find("scenedraw%(%)") ~= nil)
	check("gd calls markers", gd:find("game_draw_player_markers%(%)") ~= nil)
	check("gd calls debug", gd:find("game_draw_debug%(%)") ~= nil)
	check("gd calls pausemenu", gd:find("game_draw_pausemenu%(%)") ~= nil)
	check("gd editormode branch", gd:find("editormode") ~= nil and gd:find("editor_draw%(%)") ~= nil)
	check("gd no inline OBJECTS loop", gd:find("%-%-OBJECTS") == nil)
	check("gd no nested scenedraw def", gd:find("function scenedraw") == nil)
end

local sd = extract_top("scenedraw")
check("scenedraw body", sd ~= nil)
if sd then
	local nlines = select(2, sd:gsub("\n", "\n")) + 1
	check("scenedraw thin (<=30 lines)", nlines <= 30, tostring(nlines))
	check("sd drawlevel", sd:find("drawlevel%(%)") ~= nil)
	check("sd hud", sd:find("game_draw_hud%(%)") ~= nil)
	check("sd props", sd:find("game_draw_props%(%)") ~= nil)
	check("sd objects", sd:find("game_draw_objects%(%)") ~= nil)
	check("sd fx", sd:find("game_draw_fx%(%)") ~= nil)
	check("sd foreground", sd:find("drawforeground%(%)") ~= nil)
end

local dl = extract_top("drawlevel")
check("drawlevel calls tiles", dl and dl:find("drawlevel_tiles%(") ~= nil)
check("drawlevel keeps xtodraw", dl and dl:find("local xtodraw") ~= nil)

local tiles = extract_top("drawlevel_tiles")
check("tiles uses scrollutil", tiles and tiles:find("scroll_batch_offset") ~= nil)
check("tiles uses bounceutil", tiles and tiles:find("build_blockbounce_lookup") ~= nil)
check("tiles takes xtodraw arg", src:find("function drawlevel_tiles%(xtodraw, ytodraw%)") ~= nil)
check("tiles editormode branch", tiles and tiles:find("editormode") ~= nil)

local objs = extract_top("game_draw_objects")
check("objects portal scissors", objs and objs:find("insideportal") ~= nil and objs:find("setScissor") ~= nil)
check("objects stencil path", objs and objs:find("setStencilTest") ~= nil)
check("objects customscissor", objs and objs:find("customscissor") ~= nil)

local see = extract_top("game_draw_seethrough_portals")
check("seethrough calls scenedraw", see and see:find("scenedraw%(%)") ~= nil)
check("seethrough uses canvas", see and see:find("scenecanvas") ~= nil)

local hud = extract_top("game_draw_hud")
check("hud hides in editor", hud and hud:find("editormode == false") ~= nil)

-- main.lua: shaders wrap game_draw; early utils kept
local mf = assert(io.open(root .. "/main.lua", "r"))
local main = mf:read("*a")
mf:close()
check("main early stringutil", main:find('require%s+"stringutil"') ~= nil)
check("main early mathutil", main:find('require%s+"mathutil"') ~= nil)
check("main early tableutil", main:find('require%s+"tableutil"') ~= nil)
check("main shaders predraw before draw", main:find("shaders:predraw%(%)") ~= nil)
check("main shaders postdraw after draw", main:find("shaders:postdraw%(%)") ~= nil)
check("main calls game_draw", main:find("game_draw%(%)") ~= nil)

-- ordering: predraw ... game_draw ... postdraw
local pre = main:find("shaders:predraw%(%)")
local gdc = main:find("game_draw%(%)")
local post = main:find("shaders:postdraw%(%)")
check("predraw before game_draw", pre and gdc and pre < gdc)
check("postdraw after game_draw", post and gdc and gdc < post)

return failed
