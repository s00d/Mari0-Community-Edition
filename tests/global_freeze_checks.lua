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
	-- game_load globals must be snapshotted before freeze (init_game_runtime_globals)
	local root = select(1, ...) or "."
	local function read_file(path)
		local f = io.open(path, "r")
		if not f then
			return nil
		end
		local body = f:read("*a")
		f:close()
		return body
	end
	local function collect_global_assigns(body, stop_pattern, top_level_only)
		local assigns = {}
		local section = body
		if stop_pattern then
			section = body:match(stop_pattern) or ""
		end
		for line in (section .. "\n"):gmatch("(.-)\n") do
			local name
			if top_level_only then
				name = line:match("^\t([%w_]+)%s*=")
				if name and line:match("^\t\t") then
					name = nil
				end
			else
				name = line:match("^%s*([%w_]+)%s*=")
			end
			if name and not line:match("^%s*local ") then
				assigns[name] = true
			end
			local raw_name = line:match('rawset%(_G, "([%w_]+)"')
			if raw_name then
				assigns[raw_name] = true
			end
		end
		return assigns
	end
	local game_load_body = read_file(root .. "/src/app/game_load_level.tl") or ""
	local game_load_fn = game_load_body:match('global function game_load%([^)]*%)(.-)\nend\n\n%-%- Draw') or ""
	local game_load_globals = collect_global_assigns(game_load_fn)
	local init_body = read_file(root .. "/src/app/game_runtime_globals.tl") or ""
	local init_fn = init_body:match("global function init_game_runtime_globals%(%)(.-)\nend") or ""
	local init_globals = collect_global_assigns(init_fn)
	local missing_runtime = {}
	for name in pairs(game_load_globals) do
		if not init_globals[name] then
			table.insert(missing_runtime, name)
		end
	end
	table.sort(missing_runtime)
	if #missing_runtime == 0 then
		check("game_load globals initialized before freeze", true)
	else
		for _, name in ipairs(missing_runtime) do
			check("game_load global pre-init: " .. name, false, "add to init_game_runtime_globals")
		end
	end
	local loadlevel_fn = game_load_body:match("global function loadlevel%([^)]*%): boolean(.-)\nend\n\nglobal function startlevel") or ""
	local loadlevel_globals = collect_global_assigns(loadlevel_fn, nil, true)
	local game_d_path = root .. "/types/game.d.tl"
	local declared_globals = {}
	do
		local f = io.open(game_d_path, "r")
		if f then
			local body = f:read("*a")
			f:close()
			for g in body:gmatch("global ([%w_]+)") do
				declared_globals[g] = true
			end
		end
	end
	local missing_loadlevel = {}
	for name in pairs(loadlevel_globals) do
		if declared_globals[name] and not init_globals[name] then
			table.insert(missing_loadlevel, name)
		end
	end
	table.sort(missing_loadlevel)
	if #missing_loadlevel == 0 then
		check("loadlevel globals initialized before freeze", true)
	else
		for _, name in ipairs(missing_loadlevel) do
			check("loadlevel global pre-init: " .. name, false, "add to init_game_runtime_globals")
		end
	end
	local nil_inits = {}
	for line in (init_fn .. "\n"):gmatch("(.-)\n") do
		local name = line:match("^%s*([%w_]+)%s*=%s*nil%s*$")
		if name then
			table.insert(nil_inits, name)
		end
		local raw_nil = line:match('rawset%(_G, "([%w_]+)", nil%)')
		if raw_nil then
			table.insert(nil_inits, raw_nil)
		end
	end
	table.sort(nil_inits)
	if #nil_inits == 0 then
		check("init_game_runtime_globals has no nil assignments", true)
	else
		for _, name in ipairs(nil_inits) do
			check("init nil removes freeze key: " .. name, false, "use false or {} instead of nil")
		end
	end
end

do
	-- Declared globals in game.d.tl are allowed even when absent from _G snapshot
	local GlobalFreeze = require("core.global_freeze")
	GlobalFreeze.install_writes_only()
	local ok_typo, err_typo = pcall(function()
		_G._gf_test_typo_xyz = 1
	end)
	check("freeze blocks undeclared typo global", not ok_typo and tostring(err_typo):find("undeclared global write"), tostring(err_typo))

	local ok_blacktime, err_blacktime = pcall(function()
		_G.blacktime = 1.5
	end)
	check("freeze allows game.d.tl global blacktime", ok_blacktime and _G.blacktime == 1.5, tostring(err_blacktime))

	local ok_levelscreen, err_levelscreen = pcall(function()
		_G.levelscreentimer = 0
		_G.sublevelscreen_level = 1
		_G.livesleft = false
		_G.coinframe = 1
	end)
	check("freeze allows levelscreen globals from game.d.tl", ok_levelscreen
		and _G.levelscreentimer == 0
		and _G.sublevelscreen_level == 1
		and _G.livesleft == false
		and _G.coinframe == 1, tostring(err_levelscreen))

	rawset(_G, "mariotimer", 0)
	local ok_reassign, err_reassign = pcall(function()
		_G.mariotimer = 1
	end)
	local ok_nil, err_nil = pcall(function()
		_G.mariotimer = nil
	end)
	local ok_after_nil, err_after_nil = pcall(function()
		_G.mariotimer = 2
	end)
	check("freeze allows declared global reassignment", ok_reassign, tostring(err_reassign))
	check("freeze allows declared global cleared to nil", ok_nil, tostring(err_nil))
	check("freeze allows write after nil clear", ok_after_nil, tostring(err_after_nil))

	local ok_map, err_map = pcall(function()
		_G.map = {}
	end)
	check("freeze blocks removed world global map", not ok_map and tostring(err_map):find("undeclared global write"), tostring(err_map))

	GlobalFreeze.uninstall()
	rawset(_G, "blacktime", nil)
	rawset(_G, "levelscreentimer", nil)
	rawset(_G, "sublevelscreen_level", nil)
	rawset(_G, "livesleft", nil)
	rawset(_G, "coinframe", nil)
	rawset(_G, "mariotimer", nil)
end

do
	local root = select(1, ...) or "."
	local path = root .. "/src/app/game_update.tl"
	local f = io.open(path, "r")
	local ok = false
	if f then
		local body = f:read("*a")
		f:close()
		local section = body:match("portal particles(.-)PORTAL PROJECTILES")
		-- Scratch reuse is fine; must remain a function-local binding (not a global write).
		ok = section ~= nil and (
			section:find("local delete = {}", 1, true) ~= nil
			or section:find("local delete = portal_delete_scratch", 1, true) ~= nil
		)
	end
	check("game_update portal delete is local", ok)
end

if select("#", ...) > 0 then
	return failed
end
