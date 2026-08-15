--[[ Test-only bridge: bare map/objects/scroll reads/writes hit session.
     Production has no _G mirrors (Wave D). Headless suites still assign globals. ]]

local SESSION_KEYS = {
	map = true,
	coinmap = true,
	objects = true,
	playerobjs = true,
	mapwidth = true,
	mapheight = true,
	xscroll = true,
	yscroll = true,
	ylookmodifier = true,
	portals = true,
	enemiesspawned = true,
}

local Bridge = {}

local function ensure_session()
	local s = rawget(_G, "session")
	if s then
		return s
	end
	require("world.level")
	local World = require("world.session")
	s = World.new()
	rawset(_G, "session", s)
	return s
end

function Bridge.install()
	ensure_session()
	setmetatable(_G, {
		__index = function(_t, k)
			if SESSION_KEYS[tostring(k)] then
				return ensure_session()[k]
			end
			return nil
		end,
		__newindex = function(_t, k, v)
			local key = tostring(k)
			if SESSION_KEYS[key] then
				ensure_session()[key] = v
				return
			end
			rawset(_G, k, v)
		end,
	})
end

function Bridge.uninstall()
	setmetatable(_G, nil)
end

return Bridge
