--[[ Stage 7: Slab DROP — vendor and debug glue must be gone. ]]

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

check("no lib/slab/init.lua", not exists("lib/slab/init.lua"))
check("no src/ui/editor_slab.tl", not exists("src/ui/editor_slab.tl"))
check("no types/slab.d.tl", not exists("types/slab.d.tl"))

local boot = read("src/app/boot.tl") or ""
check("boot dropped editor_slab", boot:find("editor_slab", 1, true) == nil)

local editor = read("src/ui/editor.tl") or ""
check("editor dropped editor_slab_draw", editor:find("editor_slab_draw", 1, true) == nil)

local vars = read("src/app/variables.tl") or ""
check("variables dropped editor_slab_debug", vars:find("editor_slab_debug", 1, true) == nil)

local vendor = read("scripts/vendor-libs") or ""
check("vendor-libs no flamendless/Slab", vendor:find("flamendless/Slab", 1, true) == nil)
check("vendor-libs no LIB/slab", vendor:find("LIB/slab", 1, true) == nil and vendor:find("$LIB/slab", 1, true) == nil)

local readme = read("lib/README.md") or ""
check("README no slab row", readme:find("`slab`", 1, true) == nil)

local types = read("types/game.d.tl") or ""
check("types no editor_slab_debug", types:find("editor_slab_debug", 1, true) == nil)
check("types no editor_slab_draw", types:find("editor_slab_draw", 1, true) == nil)

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
