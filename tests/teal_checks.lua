--[[ Teal / AssetStore / Logger structural checks ]]

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

local function file_exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

check("build/app/logger.lua exists", file_exists(root .. "/build/app/logger.lua"))
check("build/app/gamestate.lua exists", file_exists(root .. "/build/app/gamestate.lua"))
check("build/world/session.lua exists", file_exists(root .. "/build/world/session.lua"))
check("build/net/init.lua exists", file_exists(root .. "/build/net/init.lua"))
check("build/net/schema.lua exists", file_exists(root .. "/build/net/schema.lua"))
check("build/net/sync.lua exists", file_exists(root .. "/build/net/sync.lua"))
check("build/net/match.lua exists", file_exists(root .. "/build/net/match.lua"))
check("build/assets/store.lua exists", file_exists(root .. "/build/assets/store.lua"))

local Logger = require("app.logger")
check("Logger.info", type(Logger.info) == "function")
check("Logger.debug", type(Logger.debug) == "function")
Logger.set_level("error")
Logger.debug("should be silent")
check("Logger loaded", Logger.level == "error")

local Store = require("assets.store")
local s = Store.new("stream")
check("AssetStore.new", s ~= nil)
s:register_image("title", "assets/assets/graphics/DEFAULT/title.png")
check("AssetStore register_image", s.images.title ~= nil)
check("AssetStore path", s.images.title.path:match("title%.png") ~= nil)
check("AssetStore restore_image_defaults", type(s.restore_image_defaults) == "function")
check("AssetStore restore_sound_defaults", type(s.restore_sound_defaults) == "function")
check("AssetStore.GRAPHICS prefix", Store.GRAPHICS == "assets/graphics/")
check("AssetStore.SOUNDS prefix", Store.SOUNDS == "assets/sounds/")

local GS = require("app.gamestate")
check("Gamestate.set", type(GS.set) == "function")
GS.set("menu")
check("Gamestate.get", GS.get() == "menu")

local World = require("world.session")
local w = World.new()
check("World.new", type(w.map) == "table" and w.mapwidth == 0)

-- Entities are Teal global records (no middleclass at runtime)
local Mario = require("entities.mario")
check("entities.mario loaded", Mario ~= nil)
check("entities.mario defines update phases", io.open(root .. "/src/entities/mario.tl"):read("*a"):find("function mario:update_controls") ~= nil)
local Enemy = require("entities.enemy")
check("entities.enemy loaded", Enemy ~= nil)
check("entities.enemy is global record", io.open(root .. "/types/records.d.tl"):read("*a"):find("global record enemy") ~= nil)
local Menu = require("ui.menu")
check("ui.menu ported", Menu and Menu.ported == true)
check("ui.editor exists", io.open(root .. "/src/ui/editor.tl") ~= nil)

-- Dotted Teal modules expose globals
require("core.tilekey")
check("tilekey module", type(tilekey) == "function" and tilekey(2, 3) == 2 * 65536 + 3)

require("world.zones")
local z = buildstartendzones({1, 10}, {5, 20})
check("zones module", #z == 2 and z[1][1] == 1 and z[1][2] == 5)

-- Prefer no newImage outside AssetStore in new Teal assets module
local store_src = assert(io.open(root .. "/src/assets/store.tl", "r")):read("*a")
check("store uses love.graphics.newImage", store_src:find("love%.graphics%.newImage") ~= nil)

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
