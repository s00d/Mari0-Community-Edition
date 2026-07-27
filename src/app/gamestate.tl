--[[ Lightweight gamestate dispatcher (Teal).
     Legacy code still uses global `gamestate` string; this module
     tracks handlers and provides a typed entry point for migration.
]]

local Gamestate = {
	current = "intro" as string,
	handlers = {} as {string:{string:function}},
}

function Gamestate.register(name: string, handlers: {string:function})
	Gamestate.handlers[name] = handlers
end

function Gamestate.set(name: string)
	if type(name) ~= "string" then
		error("Gamestate.set expects string, got " .. type(name), 2)
	end
	Gamestate.current = name
	rawset(_G, "gamestate", name)
end

function Gamestate.get(): string
	local g = rawget(_G, "gamestate")
	if type(g) == "string" then
		Gamestate.current = g as string
	end
	return Gamestate.current
end

function Gamestate.update(dt: number)
	local name = Gamestate.get()
	local h = Gamestate.handlers[name]
	if h and h.update then
		h.update(dt)
	end
end

function Gamestate.draw()
	local name = Gamestate.get()
	local h = Gamestate.handlers[name]
	if h and h.draw then
		h.draw()
	end
end

_G.Gamestate = Gamestate as GamestateModule

return Gamestate
