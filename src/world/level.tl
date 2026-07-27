--[[ Level-lifetime state: map, objects, scroll, sprite batches, teardown hooks.
     Replaces manual zeroing on loadlevel; syncs to _G during transition. ]]

local Ctx = require("core.ctx")

rawset(_G, "Level", rawget(_G, "Level") or {})

local function fresh_objects(): {string:{any:Entity}}, {Entity}
	local objects: {string:{any:Entity}} = {}
	local playerobjs: {Entity} = {}
	objects["player"] = playerobjs
	objects["portalwall"] = {}
	objects["tile"] = {}
	objects["vine"] = {}
	objects["box"] = {}
	objects["door"] = {}
	objects["button"] = {}
	objects["groundlight"] = {}
	objects["wallindicator"] = {}
	objects["animatedtiletrigger"] = {}
	objects["delayer"] = {}
	objects["walltimer"] = {}
	objects["notgate"] = {}
	objects["rsflipflop"] = {}
	objects["orgate"] = {}
	objects["andgate"] = {}
	objects["musicentity"] = {}
	objects["enemyspawner"] = {}
	objects["squarewave"] = {}
	objects["lightbridge"] = {}
	objects["lightbridgebody"] = {}
	objects["faithplate"] = {}
	objects["laser"] = {}
	objects["laserdetector"] = {}
	objects["gel"] = {}
	objects["geldispenser"] = {}
	objects["cubedispenser"] = {}
	objects["pushbutton"] = {}
	objects["fireball"] = {}
	objects["platform"] = {}
	objects["platformspawner"] = {}
	objects["castlefire"] = {}
	objects["castlefirefire"] = {}
	objects["bowser"] = {}
	objects["spring"] = {}
	objects["seesawplatform"] = {}
	objects["ceilblocker"] = {}
	objects["funnel"] = {}
	objects["panel"] = {}
	objects["scaffold"] = {}
	objects["regiontrigger"] = {}
	objects["zgbooltrigger"] = {}
	objects["zginttrigger"] = {}
	objects["animationtrigger"] = {}
	objects["checkpoints"] = {}
	objects["portalent"] = {}
	objects["actionblock"] = {}
	objects["enemy"] = {}
	return objects, playerobjs
end

function Level.new(): Level
	local objects, playerobjs = fresh_objects()
	local self = setmetatable({}, { __index = Level }) as Level
	self.map = {}
	self.coinmap = {}
	self.objects = objects
	self.playerobjs = playerobjs
	self.mapwidth = 0
	self.mapheight = 0
	self.xscroll = 0
	self.yscroll = 0
	self.ylookmodifier = 0
	self.portals = {}
	self.teardown = {}
	self.smbspritebatch = nil
	self.smbspritebatchfront = nil
	self.portalspritebatch = nil
	self.portalspritebatchfront = nil
	return self
end

function Level:on_destroy(fn: function)
	table.insert(self.teardown, fn)
end

function Level:destroy()
	for i = 1, #self.teardown do
		self.teardown[i]()
	end
	self.teardown = {}
	self.map = {}
	self.coinmap = {}
	self.objects = {}
	self.playerobjs = {}
	self.portals = {}
	self.smbspritebatch = nil
	self.smbspritebatchfront = nil
	self.portalspritebatch = nil
	self.portalspritebatchfront = nil
	if Ctx.level == self then
		Ctx.level = nil
	end
end

function Level:push_globals()
	rawset(_G, "map", self.map)
	rawset(_G, "coinmap", self.coinmap)
	rawset(_G, "objects", self.objects)
	rawset(_G, "playerobjs", self.playerobjs)
	rawset(_G, "mapwidth", self.mapwidth)
	rawset(_G, "mapheight", self.mapheight)
	rawset(_G, "xscroll", self.xscroll)
	rawset(_G, "yscroll", self.yscroll)
	rawset(_G, "ylookmodifier", self.ylookmodifier)
	rawset(_G, "portals", self.portals)
	if self.smbspritebatch then
		rawset(_G, "smbspritebatch", self.smbspritebatch)
	end
	if self.smbspritebatchfront then
		rawset(_G, "smbspritebatchfront", self.smbspritebatchfront)
	end
	if self.portalspritebatch then
		rawset(_G, "portalspritebatch", self.portalspritebatch)
	end
	if self.portalspritebatchfront then
		rawset(_G, "portalspritebatchfront", self.portalspritebatchfront)
	end
end

function Level:pull_globals()
	self.map = (rawget(_G, "map") as {number:{number:{any}}}) or self.map
	self.coinmap = (rawget(_G, "coinmap") as {number:{number:boolean}}) or self.coinmap
	self.objects = (rawget(_G, "objects") as {string:{any:Entity}}) or self.objects
	self.playerobjs = (rawget(_G, "playerobjs") as {Entity}) or self.playerobjs
	self.mapwidth = (rawget(_G, "mapwidth") as integer) or self.mapwidth
	self.mapheight = (rawget(_G, "mapheight") as integer) or self.mapheight
	self.xscroll = (rawget(_G, "xscroll") as number) or self.xscroll
	self.yscroll = (rawget(_G, "yscroll") as number) or self.yscroll
	self.ylookmodifier = (rawget(_G, "ylookmodifier") as number) or self.ylookmodifier
	self.portals = (rawget(_G, "portals") as {any}) or self.portals
	self.smbspritebatch = rawget(_G, "smbspritebatch") as SpriteBatch|nil
	self.smbspritebatchfront = rawget(_G, "smbspritebatchfront") as SpriteBatch|nil
	self.portalspritebatch = rawget(_G, "portalspritebatch") as SpriteBatch|nil
	self.portalspritebatchfront = rawget(_G, "portalspritebatchfront") as SpriteBatch|nil
end

-- Replace level-lifetime globals with a fresh Level (destroys previous).
global function level_reset_ctx(): Level
	local prev = Ctx.level
	if prev ~= nil then
		local old = prev as Level
		old:destroy()
	end
	local lvl = Level.new()
	Ctx.level = lvl
	lvl:push_globals()
	return lvl
end

return Level
