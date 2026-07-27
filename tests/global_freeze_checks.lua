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

if select("#", ...) > 0 then
	return failed
end
