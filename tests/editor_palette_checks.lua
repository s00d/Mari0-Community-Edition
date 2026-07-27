--[[ Registry-driven editor palettes coverage (no LÖVE). ]]

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

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	package.path,
}, ";")

-- Stub love.filesystem for enemy JSON listing
love = love or {}
love.filesystem = love.filesystem or {}
function love.filesystem.getDirectoryItems(path)
	local out = {}
	local dir = root .. "/" .. path
	local p = io.popen('ls "' .. dir .. '" 2>/dev/null')
	if not p then return out end
	for line in p:lines() do
		out[#out + 1] = line
	end
	p:close()
	return out
end

require("world.geltypes")
require("entities.marioforms")
local ok_w, Weapons = pcall(require, "weapons")
check("load weapons", ok_w, Weapons)

-- Minimal entitylist stub covering a few real names + require full list if available
entitylist = {
	{ t = "remove", category = "misc" },
	{ t = "spawn", category = "level markers" },
	{ t = "flag", category = "level markers" },
	{ t = "box", category = "portal elements" },
	{ t = "pipe", category = "level markers" },
	{ t = "" },
	{ t = "geldispenser", category = "portal elements", hidden = false },
}

require("ui.editor_palettes")

local p = build_palettes()

-- Every weapon in registry (except gel alias) appears
do
	local seen = {}
	for _, e in ipairs(p.weapons) do seen[e.id] = true end
	local missing = {}
	for id, _ in pairs(Weapons.registry) do
		if id ~= "gel" and not seen[id] then
			missing[#missing + 1] = id
		end
	end
	table.sort(missing)
	check("all weapons in palette", #missing == 0, table.concat(missing, ","))
	check("weapons sorted", p.weapons[1] and p.weapons[1].id <= p.weapons[#p.weapons].id)
end

-- Every gel def
do
	local seen = {}
	for _, e in ipairs(p.gels) do seen[e.id] = true end
	local missing = {}
	for id, _ in pairs(GEL_DEFS) do
		if not seen[id] then missing[#missing + 1] = tostring(id) end
	end
	check("all gels in palette", #missing == 0, table.concat(missing, ","))
end

-- Every non-empty entity
do
	local seen = {}
	for _, e in ipairs(p.entities) do seen[e.t] = true end
	local missing = {}
	for _, e in ipairs(entitylist) do
		if e.t and e.t ~= "" and not e.hidden and not seen[e.t] then
			missing[#missing + 1] = e.t
		end
	end
	check("all entities in palette", #missing == 0, table.concat(missing, ","))
end

-- Enemies from assets/enemies/*.json
do
	local json_names = {}
	for _, f in ipairs(love.filesystem.getDirectoryItems("assets/enemies/")) do
		if f:sub(-5) == ".json" then
			json_names[f:sub(1, -6):lower()] = true
		end
	end
	local seen = {}
	for _, e in ipairs(p.enemies) do seen[e.t] = true end
	local missing = {}
	for n in pairs(json_names) do
		if not seen[n] then missing[#missing + 1] = n end
	end
	table.sort(missing)
	check("enemy jsons in palette", #missing == 0, table.concat(missing, ","))
	check("enemies sorted", #p.enemies < 2 or p.enemies[1].t <= p.enemies[#p.enemies].t)
end

-- Forms
do
	local seen = {}
	for _, e in ipairs(p.forms) do seen[e.id] = true end
	local missing = {}
	for id in pairs(MARIO_FORMS) do
		if not seen[id] then missing[#missing + 1] = id end
	end
	check("all forms in palette", #missing == 0, table.concat(missing, ","))
end

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
