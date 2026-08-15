--[[ Level-lifetime state: map, objects, scroll, sprite batches.
     reset_level_state() clears via Session (SoT). ]]

OBJECT_GROUP_KEYS = {
	"player",
	"portalwall",
	"tile",
	"vine",
	"box",
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
	"blackhole",
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
	local s = rawget(_G, "session")
	if s ~= nil then
		(s as World):reset_level()
		return
	end
	-- Tests without a Session instance: create one so callers share SoT.
	require("world.session")
	local WorldMod = rawget(_G, "World") as World
	local session = WorldMod.new()
	rawset(_G, "session", session)
	session:reset_level()
end
