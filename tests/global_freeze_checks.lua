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

if select("#", ...) > 0 then
	return failed
end
