--[[ Stage 3: one register SoT + Gamestate.call dispatch (no app.states/*). ]]

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

local function read(rel)
	local f = io.open(root .. "/" .. rel, "r")
	if not f then
		return nil
	end
	local s = f:read("*a")
	f:close()
	return s
end

-- Stub domain globals before register captures them.
local stubs = {
	"intro_update", "intro_draw", "intro_keypressed", "intro_mousepressed",
	"menu_update", "menu_draw", "menu_keypressed", "menu_keyreleased",
	"menu_mousepressed", "menu_mousemoved", "menu_mousereleased",
	"menu_joystickpressed", "menu_joystickreleased", "menu_joystickaxis", "menu_joystickhat",
	"levelscreen_update", "levelscreen_draw",
	"game_update", "game_draw", "game_keypressed", "game_keyreleased",
	"game_textinput", "game_mousepressed", "game_mousereleased",
	"game_joystickpressed", "game_joystickreleased", "game_joystickaxis", "game_joystickhat",
	"ui_note_kbd", "playsound", "saveconfig", "enable_debugbinds",
	"sha1",
}
local calls = {}
for _, name in ipairs(stubs) do
	_G[name] = function(...)
		calls[#calls + 1] = { name, ... }
	end
end
_G.sha1 = function()
	return "never"
end
_G.konamihash = "never"
_G.konamitable = { "", "", "", "", "", "", "", "", "", "" }
_G.notice = { new = function() end }
_G.Net = {
	quit = function()
		calls[#calls + 1] = { "Net.quit" }
	end,
}
_G.pausemenuopen = false
_G.scale = 1
_G.width = 25

local GS = require("app.gamestate")
check("Gamestate.call exists", type(GS.call) == "function")

require("app.gamestate_register").register(GS)

local function has_events(state, events)
	local h = GS.handlers[state]
	if not h then
		return false, "missing handlers"
	end
	for _, ev in ipairs(events) do
		if type(h[ev]) ~= "function" then
			return false, "missing " .. ev
		end
	end
	return true
end

local ok, detail = has_events("intro", { "update", "draw", "keypressed", "mousepressed" })
check("intro handlers", ok, detail)
ok, detail = has_events("menu", {
	"update", "draw", "keypressed", "keyreleased", "mousepressed", "mousemoved",
	"mousereleased", "joystickpressed", "joystickreleased", "joystickaxis", "joystickhat",
})
check("menu full input", ok, detail)
ok, detail = has_events("mappackmenu", { "update", "draw", "keypressed", "mousepressed", "mousemoved" })
check("mappackmenu mouse move", ok, detail)
check("mappackmenu no joy", GS.handlers.mappackmenu.joystickpressed == nil)
ok, detail = has_events("onlinemenu", { "update", "draw", "keypressed", "mousepressed" })
check("onlinemenu key/mouse", ok, detail)
check("onlinemenu no mousemoved", GS.handlers.onlinemenu.mousemoved == nil)
ok, detail = has_events("options", {
	"update", "draw", "keypressed", "joystickpressed", "mousemoved",
})
check("options joy+mouse", ok, detail)
ok, detail = has_events("lobby", { "update", "draw", "keypressed" })
check("lobby handlers", ok, detail)
ok, detail = has_events("game", {
	"update", "draw", "keypressed", "keyreleased", "textinput",
	"mousepressed", "mousereleased", "mousemoved",
	"joystickpressed", "joystickreleased", "joystickaxis", "joystickhat",
})
check("game handlers", ok, detail)
ok, detail = has_events("levelscreen", { "update", "draw" })
check("levelscreen handlers", ok, detail)
check("no editor state registered", GS.handlers.editor == nil)

GS.set("intro")
calls = {}
GS.call("keypressed", "a")
check("call intro keypressed", #calls == 1 and calls[1][1] == "intro_keypressed")

GS.set("game")
calls = {}
GS.call("keypressed", "jump")
check("call game keypressed", #calls == 1 and calls[1][1] == "game_keypressed" and calls[1][2] == "jump")

GS.set("lobby")
calls = {}
GS.call("keypressed", "escape")
check("lobby escape Net.quit", #calls == 1 and calls[1][1] == "Net.quit")
calls = {}
GS.call("keypressed", "a")
local hit_menu = false
for _, c in ipairs(calls) do
	if c[1] == "menu_keypressed" then
		hit_menu = true
	end
end
check("lobby key no menu_keypressed", not hit_menu)

GS.set("onlinemenu")
calls = {}
GS.call("keypressed", "escape")
check("onlinemenu escape Net.quit", #calls == 1 and calls[1][1] == "Net.quit")

GS.set("menu")
check("in_menu_family menu", GS.in_menu_family() == true)
GS.set("game")
check("in_menu_family game false", GS.in_menu_family() == false)
GS.set("lobby")
check("in_menu_family lobby", GS.in_menu_family() == true)

local cb = read("src/app/love_callbacks.tl") or ""
check("callbacks use Gamestate.call", cb:find('Gamestate.call("keypressed"', 1, true) ~= nil)
check("callbacks dropped MENU_INPUT_STATES", cb:find("MENU_INPUT_STATES", 1, true) == nil)
check("callbacks dropped menu_input_active", cb:find("menu_input_active", 1, true) == nil)

local boot = read("src/app/boot.tl") or ""
check("boot requires gamestate_register", boot:find('require("app.gamestate_register")', 1, true) ~= nil)
check("boot dropped app.states", boot:find("app.states", 1, true) == nil)

local reg = read("src/app/gamestate_register.tl") or ""
check("register has menu asymmetries", reg:find("menu_konami_keypressed", 1, true) ~= nil)
check("register no editor state", reg:find('GS.register("editor"', 1, true) == nil)

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
