--[[ Post-boot _G write guard (no LÖVE). ]]

local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

do
	local GlobalFreeze = require("core.global_freeze")
	rawset(_G, "_gf_test_declared", 1)
	GlobalFreeze.install_writes_only()

	local ok_write, err_write = pcall(function()
		_G._gf_test_declared = 2
	end)
	check("allows declared global write", ok_write and _G._gf_test_declared == 2, tostring(err_write))

	local ok_new, err_new = pcall(function()
		_G._gf_test_undeclared_new = 1
	end)
	check("blocks undeclared global write", not ok_new and tostring(err_new):find("undeclared global write"), tostring(err_new))

	local ok_raw = pcall(function()
		rawset(_G, "_gf_test_raw_bypass", 9)
	end)
	check("rawset bypasses guard", ok_raw and _G._gf_test_raw_bypass == 9)

	rawset(_G, "_gf_test_declared", nil)
	rawset(_G, "_gf_test_raw_bypass", nil)
	GlobalFreeze.uninstall()
end

do
	local GlobalFreeze = require("core.global_freeze")
	check("is_installed false before install", not GlobalFreeze.is_installed())
	GlobalFreeze.install_writes_only()
	check("is_installed true after install", GlobalFreeze.is_installed())
	GlobalFreeze.uninstall()
end

do
	local GlobalFreeze = require("core.global_freeze")
	local LoveFrame = require("app.love_frame")
	rawset(_G, "targetdt", 1 / 60)
	rawset(_G, "speed", 1)
	rawset(_G, "gamestate", "menu")
	GlobalFreeze.install_writes_only()

	local ok_skip, err_skip = pcall(function()
		LoveFrame.request_skip_update()
	end)
	check("love_frame skip request under freeze", ok_skip, tostring(err_skip))
	check("love_frame skip consumes on begin_update", not LoveFrame.begin_update())

	local ok_realdt, err_realdt = pcall(function()
		_G.realdt = 1 / 60
	end)
	check("realdt global write blocked after freeze", not ok_realdt and tostring(err_realdt):find("undeclared global write"), tostring(err_realdt))

	GlobalFreeze.uninstall()
	rawset(_G, "targetdt", nil)
	rawset(_G, "speed", nil)
	rawset(_G, "gamestate", nil)
end

do
	-- game entry paths: tab-indented global writes must be declared in game.d.tl
	local root = select(1, ...) or "."
	local game_d_path = root .. "/types/game.d.tl"
	local f = io.open(game_d_path, "r")
	local declared = {}
	if f then
		local body = f:read("*a")
		f:close()
		for g in body:gmatch("global ([%w_]+)") do
			declared[g] = true
		end
	end
	local entry_files = {
		"src/app/game_load_level.tl",
		"src/app/game_spawn.tl",
		"src/app/game_update.tl",
		"src/app/game_load_objects.tl",
		"src/world/levelio.tl",
		"src/world/spawnregistry.tl",
		"src/ui/levelscreen.tl",
	}
	local function collect_locals(body)
		local locals = {}
		for line in (body .. "\n"):gmatch("(.-)\n") do
			for name in line:gmatch("local ([%w_]+)") do
				locals[name] = true
			end
		end
		return locals
	end
	local missing = {}
	for _, rel in ipairs(entry_files) do
		local path = root .. "/" .. rel
		local ef = io.open(path, "r")
		if ef then
			local body = ef:read("*a")
			ef:close()
			local file_locals = collect_locals(body)
			for line in (body .. "\n"):gmatch("(.-)\n") do
				local name = line:match("^\t([%w_]+)%s*=")
				if name and not line:match("^\tlocal ") and not file_locals[name]
					and not line:match("^%s*" .. name .. "%s*=%s*" .. name) then
					if not declared[name] then
						missing[name] = missing[name] or {}
						table.insert(missing[name], rel)
					end
				end
			end
		end
	end
	local count = 0
	for name, locs in pairs(missing) do
		count = count + 1
		check("game entry global declared: " .. name, false, table.concat(locs, ", "))
	end
	if count == 0 then
		check("game entry globals declared in game.d.tl", true)
	end
end

do
	-- game_update portal-particle cleanup must not write undeclared global delete
	local root = select(1, ...) or "."
	local path = root .. "/src/app/game_update.tl"
	local f = io.open(path, "r")
	local ok = false
	if f then
		local body = f:read("*a")
		f:close()
		local section = body:match("portal particles(.-)PORTAL PROJECTILES")
		ok = section ~= nil and section:find("local delete = {}") ~= nil
	end
	check("game_update portal delete is local", ok)
end

if select("#", ...) > 0 then
	return failed
end
