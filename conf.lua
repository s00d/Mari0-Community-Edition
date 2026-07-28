-- Bootstrap package.path: Teal build/ + LuaRocks pure-Lua vendors in lib/.
-- Also mirror into love.filesystem require path: package.path alone is CWD-relative
-- and fails inside .love archives / when Love is launched with a non-game cwd.
local REQUIRE_PATH_EXTRA = "build/?.lua;build/?/init.lua;lib/?.lua;lib/?/init.lua"
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
	t.highdpi = true
	t.graphics = t.graphics or {}
	t.graphics.renderers = {"metal", "vulkan", "opengl"}
	t.modules.physics = false
	-- Create window early so errhand/graphics never run headless (segfault guard).
	t.window = t.window or {}
	t.window.width = 800
	t.window.height = 600
	t.window.displayindex = 1
	t.window.vsync = 1
	t.console = true

	-- Love searches getRequirePath() via love.filesystem (not package.path).
	if love and love.filesystem and love.filesystem.setRequirePath then
		local cur = love.filesystem.getRequirePath() or "?.lua;?/init.lua"
		if not cur:find("build/%?", 1, false) then
			love.filesystem.setRequirePath(cur .. ";" .. REQUIRE_PATH_EXTRA)
		end
	end
end
