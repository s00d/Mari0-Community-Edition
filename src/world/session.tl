-- Session bag (Teal strangler): game-flow fields only; level map/objects live in _G.
-- `World` record shape lives in types/entities.d.tl (ambient / global_env_def).


rawset(_G, "World", rawget(_G, "World") or {})

function World.new(): World
	local self = setmetatable({}, { __index = World }) as World
	self.mariotimer = 0
	self.gamestate = "intro"
	self.mappack = nil
	self.currentlevel = nil
	self.editormode = false
	self.paused = false
	return self
end

function World:sync_session_from_globals()
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

function World:set_scroll(x: number, y: number)
	rawset(_G, "xscroll", x)
	rawset(_G, "yscroll", y)
end

function World:set_map_size(w: integer, h: integer)
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
