--[[ Level-lifetime globals: map, objects, scroll, sprite batches.
     reset_level_state() replaces manual zeroing on loadlevel. ]]

OBJECT_GROUP_KEYS = {
	"player",
	"portalwall",
	"tile",
	"vine",
	"box",
	"iceblock",
	"door",
	"gatedoor",
	"abilitypickup",
	"button",
	"groundlight",
	"wallindicator",
	"animatedtiletrigger",
	"delayer",
	"walltimer",
	"notgate",
	"rsflipflop",
	"orgate",
	"andgate",
	"musicentity",
	"enemyspawner",
	"squarewave",
	"lightbridge",
	"lightbridgebody",
	"faithplate",
	"laser",
	"laserdetector",
	"gel",
	"geldispenser",
	"cubedispenser",
	"pushbutton",
	"fireball",
	"bomb",
	"gravityball",
	"hook",
	"platform",
	"platformspawner",
	"castlefire",
	"castlefirefire",
	"bowser",
	"spring",
	"seesawplatform",
	"ceilblocker",
	"funnel",
	"panel",
	"scaffold",
	"regiontrigger",
	"zgbooltrigger",
	"zginttrigger",
	"animationtrigger",
	"checkpoints",
	"portalent",
	"actionblock",
	"donut",
	"powblock",
	"flipblock",
	"belt",
	"longfire",
	"smallspring",
	"collectable",
	"camerastop",
	"enemy",
}

global function fresh_objects(): {string:{any:Entity}}, {Entity}
	local objects: {string:{any:Entity}} = {}
	local playerobjs: {Entity} = {}
	for i = 1, #OBJECT_GROUP_KEYS do
		local key = OBJECT_GROUP_KEYS[i]
		if key == "player" then
			objects[key] = playerobjs
		else
			objects[key] = {}
		end
	end
	return objects, playerobjs
end

global function reset_level_state()
	local objects, playerobjs = fresh_objects()
	rawset(_G, "map", {})
	rawset(_G, "coinmap", {})
	rawset(_G, "objects", objects)
	rawset(_G, "playerobjs", playerobjs)
	rawset(_G, "mapwidth", 0)
	rawset(_G, "mapheight", 0)
	rawset(_G, "xscroll", 0)
	rawset(_G, "yscroll", 0)
	rawset(_G, "ylookmodifier", 0)
	rawset(_G, "portals", {})
	rawset(_G, "smbspritebatch", nil)
	rawset(_G, "smbspritebatchfront", nil)
	rawset(_G, "portalspritebatch", nil)
	rawset(_G, "portalspritebatchfront", nil)
end
