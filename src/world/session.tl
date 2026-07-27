-- Session / world bag (Teal strangler).
-- Gradual replacement for naked globals; bind/push keep _G in sync.
-- `World` record shape lives in types/entities.d.tl (ambient / global_env_def).
-- .d.tl does not emit Lua, so bootstrap the runtime table here.


rawset(_G, "World", rawget(_G, "World") or {})

function World.new(): World
	local self = setmetatable({}, { __index = World }) as World
	self.map = {}
	self.objects = {}
	self.mapwidth = 0
	self.mapheight = 0
	self.xscroll = 0
	self.yscroll = 0
	self.mariotimer = 0
	self.gamestate = "intro"
	self.mappack = nil
	self.currentlevel = nil
	self.editormode = false
	self.paused = false
	return self
end

function World:bind_globals()
	self.map = (rawget(_G, "map") as {number:{number:{any}}}) or {}
	self.objects = (rawget(_G, "objects") as {string:{number:Entity}}) or {}
	self.mapwidth = (rawget(_G, "mapwidth") as integer) or 0
	self.mapheight = (rawget(_G, "mapheight") as integer) or 0
	self.xscroll = (rawget(_G, "xscroll") as number) or 0
	self.yscroll = (rawget(_G, "yscroll") as number) or 0
	self.mariotimer = (rawget(_G, "mariotimer") as number) or 0
	local gs = rawget(_G, "gamestate")
	if type(gs) == "string" then
		self.gamestate = gs
	end
	self.mappack = rawget(_G, "mappack") as string|nil
	self.currentlevel = rawget(_G, "currentlevel")
	self.editormode = rawget(_G, "editormode") and true or false
	self.paused = rawget(_G, "paused") and true or false
end

function World:push_globals()
	rawset(_G, "map", self.map)
	rawset(_G, "objects", self.objects)
	rawset(_G, "mapwidth", self.mapwidth)
	rawset(_G, "mapheight", self.mapheight)
	rawset(_G, "xscroll", self.xscroll)
	rawset(_G, "yscroll", self.yscroll)
	rawset(_G, "mariotimer", self.mariotimer)
	if self.gamestate then
		rawset(_G, "gamestate", self.gamestate)
	end
	if self.mappack ~= nil then
		rawset(_G, "mappack", self.mappack)
	end
	if self.currentlevel ~= nil then
		rawset(_G, "currentlevel", self.currentlevel)
	end
	rawset(_G, "editormode", self.editormode)
	rawset(_G, "paused", self.paused)
end

function World:set_scroll(x: number, y: number)
	self.xscroll = x
	self.yscroll = y
	rawset(_G, "xscroll", x)
	rawset(_G, "yscroll", y)
end

function World:set_map_size(w: integer, h: integer)
	self.mapwidth = w
	self.mapheight = h
	rawset(_G, "mapwidth", w)
	rawset(_G, "mapheight", h)
end

function World:set_gamestate(name: string)
	self.gamestate = name
	rawset(_G, "gamestate", name)
	local GS = rawget(_G, "Gamestate")
	if GS then
		((GS as Dyn)["set"] as function(any, string))(GS, name)
	end
end

return World
