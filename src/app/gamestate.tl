--[[ Lightweight gamestate dispatcher (Teal).
     Legacy code still uses global `gamestate` string.
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

function Gamestate.is(name: string): boolean
	return Gamestate.get() == name
end

function Gamestate.in_menu_family(): boolean
	local g = Gamestate.get()
	return g == "menu" or g == "mappackmenu" or g == "onlinemenu" or g == "options" or g == "lobby"
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

-- Dispatch optional input/lifecycle events from love_callbacks.
function Gamestate.call(event: string, ...: any)
	local name = Gamestate.get()
	local h = Gamestate.handlers[name]
	if not h then
		return
	end
	local fn = h[event]
	if fn then
		(fn as function(...: any): any)(...)
	end
end

_G.Gamestate = Gamestate as GamestateModule

return Gamestate
