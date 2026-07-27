-- Deterministic physics group iteration order (matches game_load_level init).

PHYSICS_GROUP_ORDER = {
	"player",
	"portalwall",
	"tile",
	"vine",
	"box",
	"door",
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
	"enemy",
	"screenboundary",
}

global function physics_group_keys_sorted(w: {any: any}): {any}
	local keys: {any} = {}
	for k in pairs(w) do
		keys[#keys + 1] = k
	end
	table.sort(keys, function(a, b): boolean
		local ta = type(a)
		local tb = type(b)
		if ta ~= tb then
			return ta < tb
		end
		if ta == "number" then
			return (a as number) < (b as number)
		end
		return tostring(a) < tostring(b)
	end)
	return keys
end
