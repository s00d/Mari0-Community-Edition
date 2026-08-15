--[[ Post-boot _G guard: block undeclared global writes (reads deferred).
     Writes allowed for: (1) keys in _G at install, (2) names declared in types/game.d.tl.
     Legitimate bypass: rawset(_G, key, value).
     Per-frame state belongs in module locals (see app.love_callbacks).
     World map/objects/scroll live on `session` (not mirrored to _G). ]]

local GlobalFreeze = {}

local allowed: {string: boolean} = {}
local installed = false

local module_root: string = (function(): string
	local info = debug.getinfo(1, "S").source
	if info:sub(1, 1) == "@" then
		local path = info:sub(2)
		local root = path:match("^(.*)/build/core/global_freeze%.lua$")
		if root then
			return root
		end
	end
	return "."
end)()

local function game_d_candidates(): {string}
	return {
		"types/game.d.tl",
		module_root .. "/types/game.d.tl",
	}
end

local function add_declared_globals_from_game_d()
	local body: string = nil
	for _, path in ipairs(game_d_candidates()) do
		local f = io.open(path, "r")
		if f then
			body = f:read("*a")
			f:close()
			break
		end
	end
	if not body then
		return
	end
	for line in (body .. "\n"):gmatch("(.-)\n") do
		local name = line:match("^global record ([%w_]+)")
		if not name then
			name = line:match("^global ([%w_]+)")
			if name == "record" or name == "type" or name == "function" then
				name = nil
			end
		end
		if name then
			allowed[name] = true
		end
	end
end

local function snapshot_globals()
	local g = _G as {string: any}
	for k, _ in pairs(g) do
		allowed[tostring(k)] = true
	end
	add_declared_globals_from_game_d()
end

function GlobalFreeze.is_installed(): boolean
	return installed
end

function GlobalFreeze.install_writes_only()
	if installed then
		return
	end
	installed = true
	snapshot_globals()
	setmetatable(_G, {
		__newindex = function(_t, k, v)
			local key = tostring(k)
			if not allowed[key] then
				error("undeclared global write: " .. key, 2)
			end
			rawset(_G, k, v)
		end,
	})
end

function GlobalFreeze.install_reads_and_writes()
	if installed then
		return
	end
	installed = true
	snapshot_globals()
	setmetatable(_G, {
		__newindex = function(_t, k, v)
			local key = tostring(k)
			if not allowed[key] then
				error("undeclared global write: " .. key, 2)
			end
			rawset(_G, k, v)
		end,
		__index = function(_t, k): any
			local key = tostring(k)
			if not allowed[key] then
				error("undeclared global read: " .. key, 2)
			end
			return nil
		end,
	})
end

function GlobalFreeze.uninstall()
	if not installed then
		return
	end
	installed = false
	allowed = {}
	setmetatable(_G, nil)
end

return GlobalFreeze
