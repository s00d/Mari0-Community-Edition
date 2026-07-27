--[[
  Structural checks for game_draw / scenedraw / drawlevel phase split (no LÖVE).
  Locks named draw phases, orchestrator calls, portal scissors, editormode.
  Phases live in game_draw_{world,hud,effects}.tl; facade is game_draw.tl.
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

local function read(path)
	local f = assert(io.open(path, "r"))
	local body = f:read("*a")
	f:close()
	return body
end

local src = table.concat({
	read(root .. "/src/app/game_draw.tl"),
	"\n",
	read(root .. "/src/app/game_draw_world.tl"),
	"\n",
	read(root .. "/src/app/game_draw_hud.tl"),
	"\n",
	read(root .. "/src/app/game_draw_effects.tl"),
}, "")
local boot_src = read(root .. "/src/app/boot.tl")
local update_src = read(root .. "/src/app/game_update.tl")
local facade = read(root .. "/src/app/game_draw.tl")

local function extract_top(name)
	-- Match "function name(...)" even with Teal return types after ")".
	local a, b = src:find("function " .. name .. "%b()")
	if not a then
		return nil
	end
	local rest = src:sub(b + 1):gsub("^:[^\n]*", "", 1)
	local body = rest:match("^\n?(.-)\nglobal function ")
	if not body then
		body = rest:match("^\n?(.-)\nfunction ")
	end
	if not body then
		body = rest:match("^\n?(.-)\ndrawui = ")
	end
	if not body then
		body = rest:match("^\n?(.-)\nend\n")
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
check("boot requires game_draw", boot_src:find('require%s+"app%.game_draw"') ~= nil)
check("boot requires game_update", boot_src:find('require%s+"app%.game_update"') ~= nil)
check("no root game.lua", io.open(root .. "/game.lua", "r") == nil)
check("game_update exists in teal", update_src:find("function game_update%(") ~= nil)
check("boot.tl exists", io.open(root .. "/src/app/boot.tl", "r") ~= nil)
check("facade requires world", facade:find('require%s+"app%.game_draw_world"') ~= nil)
check("facade requires hud", facade:find('require%s+"app%.game_draw_hud"') ~= nil)
check("facade requires effects", facade:find('require%s+"app%.game_draw_effects"') ~= nil)

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
check("tiles takes xtodraw arg", tiles and tiles:find("local xtodraw, ytodraw") ~= nil)
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

-- main.lua / love_callbacks: shaders wrap game_draw; early utils via boot
local main = read(root .. "/main.lua")
local cbs = read(root .. "/src/app/love_callbacks.tl")
local boot = read(root .. "/src/app/boot.tl")
check("main uses app.boot or love_run", main:find('require%s+"app%.boot"') ~= nil or main:find('require%s+"app%.love_run"') ~= nil)
check("main early stringutil via boot or core", main:find('require%s+"core%.stringutil"') ~= nil or main:find('app%.boot') ~= nil or main:find('app%.love_run') ~= nil)
check("main early mathutil via boot or core", main:find('require%s+"core%.mathutil"') ~= nil or main:find('app%.boot') ~= nil or main:find('app%.love_run') ~= nil)
check("main early tableutil via boot or core", main:find('require%s+"core%.tableutil"') ~= nil or main:find('app%.boot') ~= nil or boot:find("setup_core_helpers") ~= nil)
check("callbacks shaders predraw before draw", cbs:find("shaders:predraw%(%)") ~= nil)
check("callbacks shaders postdraw after draw", cbs:find("shaders:postdraw%(%)") ~= nil)
check("callbacks calls game_draw", cbs:find("game_draw%(%)") ~= nil or cbs:find("Gamestate%.draw%(%)") ~= nil)

local pre = cbs:find("shaders:predraw%(%)")
local gdc = cbs:find("game_draw%(%)") or cbs:find("Gamestate%.draw%(%)")
local post = cbs:find("shaders:postdraw%(%)")
check("predraw before game_draw", pre and gdc and pre < gdc)
check("postdraw after game_draw", post and gdc and gdc < post)

return failed
