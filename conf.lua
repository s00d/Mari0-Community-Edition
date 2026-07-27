-- Bootstrap package.path: Teal build/ + LuaRocks pure-Lua vendors in lib/.
do
	package.path = table.concat({
		"build/?.lua",
		"build/?/init.lua",
		"lib/?.lua",
		"lib/?/init.lua",
		package.path,
	}, ";")
end

function love.conf(t)
	t.title = "Mari0: Community Edition"
	t.author = "Stabyourself.net / Community"
	t.identity = "mari0_se"
	t.modules.physics = false
	-- Create window early so errhand/graphics never run headless (segfault guard).
	t.window = t.window or {}
	t.window.width = 800
	t.window.height = 600
	t.window.vsync = 1
	t.console = true
end
