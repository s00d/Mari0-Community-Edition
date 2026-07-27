--[[
  Endless generator checks (no LÖVE): determinism, connectivity, cell copy
  isolation, arena dimensions, no bottom-row deadlock.
]]

local root = ... or "."
local failed = 0

width = width or 25
height = height or 14

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

require("core.stringutil")
require("app.variables")
require("world.levelio")
require("world.endless_gen")

-- name parse
do
	local n, e, k = endless_parse_room_name("hall_lr.txt")
	check("parse hall_lr name", n == "hall_lr")
	check("parse hall_lr exits", e.l and e.r and not e.u and not e.d)
	check("parse hall_lr kind", k == "normal")
	n, e, k = endless_parse_room_name("start_rd")
	check("parse start kind", k == "start" and e.r and e.d)
	n, e, k = endless_parse_room_name("end_lu.txt")
	check("parse end kind", k == "end" and e.l and e.u)
end

-- cell copy isolation
do
	local a = {1, "goomba", "x"}
	local b = endless_copy_cell(a)
	b[2] = "koopa"
	check("copy_cell isolates", a[2] == "goomba" and b[2] == "koopa")
	check("copy_cell length", #b == 3)
end

-- load templates from disk
local room_dir = root .. "/mappacks/endless/rooms"
local function list_dir(dir)
	local names = {}
	local p = io.popen('ls "' .. dir .. '"')
	if p then
		for line in p:lines() do names[#names + 1] = line end
		p:close()
	end
	return names
end
local function read_file(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local s = f:read("*a")
	f:close()
	return s
end

local templates = endless_load_templates(room_dir, read_file, list_dir(room_dir))
check("templates loaded", #templates >= 8, tostring(#templates))

local has_start, has_end, has_lrud = false, false, false
for _, t in ipairs(templates) do
	if t.kind == "start" then has_start = true end
	if t.kind == "end" then has_end = true end
	if t.name == "room_lrud" then has_lrud = true end
	check("room size " .. t.name, t.mapwidth == 16 and t.mapheight == 15,
		tostring(t.mapwidth) .. "x" .. tostring(t.mapheight))
end
check("has start room", has_start)
check("has end room", has_end)
check("has room_lrud fallback", has_lrud)

-- determinism
local cols, rows = 4, 3 -- smaller for speed; still exercises stitch
local a = endless_generate(42, templates, {cols = cols, rows = rows})
local b = endless_generate(42, templates, {cols = cols, rows = rows})
check("determinism same seed text", a.level_text == b.level_text)
check("determinism same dims", a.mapwidth == b.mapwidth and a.mapheight == b.mapheight)
check("arena width", a.mapwidth == cols * 16, tostring(a.mapwidth))
check("arena height", a.mapheight == rows * 15, tostring(a.mapheight))

local c = endless_generate(43, templates, {cols = cols, rows = rows})
check("different seed differs", a.level_text ~= c.level_text)

check("path connected", endless_path_connected(a.path))
check("no deadlock reaches bottom", endless_no_deadlock(a.path, rows))

-- stitch isolation: mutate generated cell, re-generate, original template intact
do
	local t0 = nil
	for _, t in ipairs(templates) do
		if t.name == "hall_lr" then t0 = t break end
	end
	if t0 then
		local before = t0.map[8][13][2]
		local g = endless_generate(7, templates, {cols = 3, rows = 2})
		-- mutate output
		g.map[1][1][1] = 999
		check("template tile unchanged after stitch mutate", t0.map[8][13][2] == before)
	else
		check("hall_lr present for isolation", false)
	end
end

-- default arena size smoke (may be slower)
local full = endless_generate(99, templates)
check("default arena 160x240", full.mapwidth == 160 and full.mapheight == 240,
	tostring(full.mapwidth) .. "x" .. tostring(full.mapheight))
check("full path connected", endless_path_connected(full.path))
check("full reaches bottom", endless_no_deadlock(full.path, 16))

-- optional micro-bench
local t0 = os.clock()
for i = 1, 5 do
	endless_generate(1000 + i, templates, {cols = 5, rows = 4})
end
local elapsed = os.clock() - t0
print(string.format("NOTE endless gen 5x(5x4 rooms): %.3fs", elapsed))
check("gen perf under 5s for 5 small maps", elapsed < 5, tostring(elapsed))

return failed
