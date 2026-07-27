--[[ Post-boot _G guard: block undeclared global writes (reads deferred).
     Legitimate late writes use rawset(_G, key, value). ]]

local GlobalFreeze = {}

local allowed: {string: boolean} = {}
local installed = false

local function snapshot_globals()
	local g = _G as {string: any}
	for k, _ in pairs(g) do
		allowed[tostring(k)] = true
	end
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
