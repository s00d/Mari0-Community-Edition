--[[ Stage 6: STI DROP — vendor and stubs must be gone. ]]

local root = ... or "."
local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

local function exists(rel)
	local f = io.open(root .. "/" .. rel, "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function read(rel)
	local f = io.open(root .. "/" .. rel, "r")
	if not f then
		return nil
	end
	local s = f:read("*a")
	f:close()
	return s
end

check("no lib/sti/init.lua", not exists("lib/sti/init.lua"))
check("no src/world/sti_runtime.tl", not exists("src/world/sti_runtime.tl"))
check("no types/sti.d.tl", not exists("types/sti.d.tl"))

local boot = read("src/app/boot.tl") or ""
check("boot dropped sti_runtime", boot:find("sti_runtime", 1, true) == nil)

local vendor = read("scripts/vendor-libs") or ""
check("vendor-libs no Simple-Tiled-Implementation", vendor:find("Simple-Tiled-Implementation", 1, true) == nil)
check("vendor-libs no lib/sti mkdir", vendor:find('"$LIB/sti"', 1, true) == nil and vendor:find("lib/sti", 1, true) == nil)
check("vendor-libs no sti clone block", vendor:find("/sti/", 1, true) == nil)

local readme = read("lib/README.md") or ""
check("README no sti row", readme:find("`sti`", 1, true) == nil)

local types = read("types/game.d.tl") or ""
check("types no sti_available", types:find("sti_available", 1, true) == nil)
check("types no sti_try_load_map", types:find("sti_try_load_map", 1, true) == nil)

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
