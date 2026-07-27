--[[
  Intermediate representation for map converters.
  IR: tiles[x][y], entities[], spawn, finish, meta
]]

local M = {}

function M.new(meta)
	return {
		tiles = {}, -- [x][y] = tile_id (1-based x/y)
		entities = {}, -- {x=, y=, name=, args=?}
		spawn = nil, -- {x=, y=}
		finish = nil, -- {x=, y=}
		meta = meta or {},
		width = 0,
		height = 0,
	}
end

function M.set_size(ir, w, h, fill)
	ir.width = w
	ir.height = h
	fill = fill or 1
	for x = 1, w do
		ir.tiles[x] = {}
		for y = 1, h do
			ir.tiles[x][y] = fill
		end
	end
end

function M.validate(ir, opts)
	opts = opts or {}
	local errs = {}

	if not ir.width or not ir.height or ir.width < 1 or ir.height < 1 then
		errs[#errs + 1] = "missing width/height"
	else
		local cells = 0
		for x = 1, ir.width do
			if not ir.tiles[x] then
				errs[#errs + 1] = "missing column " .. x
				break
			end
			for y = 1, ir.height do
				local t = ir.tiles[x][y]
				if t == nil then
					errs[#errs + 1] = string.format("missing tile %d,%d", x, y)
				elseif opts.max_tile and t > opts.max_tile then
					errs[#errs + 1] = string.format("tile %d out of range at %d,%d", t, x, y)
				end
				cells = cells + 1
			end
		end
		if cells ~= ir.width * ir.height and #errs == 0 then
			errs[#errs + 1] = "mw*mh mismatch"
		end
	end

	if opts.require_spawn and not ir.spawn then
		errs[#errs + 1] = "missing spawn"
	end
	if opts.require_finish and not ir.finish then
		errs[#errs + 1] = "missing finish"
	end

	if opts.known_enemies then
		for _, e in ipairs(ir.entities) do
			if e.name and not opts.known_enemies[e.name] then
				errs[#errs + 1] = "unknown enemy " .. tostring(e.name)
			end
		end
	end

	return #errs == 0, errs
end

--- Crop/pad height to target from the TOP only (keep bottom).
-- Asserts trimmed top rows are empty (fill tile) when cutting.
function M.fit_height(ir, target, empty_tile)
	empty_tile = empty_tile or 1
	local h = ir.height
	if h == target then
		return true
	end
	if h < target then
		local pad = target - h
		local newtiles = {}
		for x = 1, ir.width do
			newtiles[x] = {}
			for y = 1, pad do
				newtiles[x][y] = empty_tile
			end
			for y = 1, h do
				newtiles[x][y + pad] = ir.tiles[x][y]
			end
		end
		ir.tiles = newtiles
		ir.height = target
		if ir.spawn then
			ir.spawn.y = ir.spawn.y + pad
		end
		if ir.finish then
			ir.finish.y = ir.finish.y + pad
		end
		for _, e in ipairs(ir.entities) do
			e.y = e.y + pad
		end
		return true
	end

	-- cut from top
	local cut = h - target
	for y = 1, cut do
		for x = 1, ir.width do
			local t = ir.tiles[x][y]
			if t ~= empty_tile and t ~= 0 then
				return false, string.format("non-empty tile at top row %d col %d (id %s)", y, x, tostring(t))
			end
		end
	end
	local newtiles = {}
	for x = 1, ir.width do
		newtiles[x] = {}
		for y = 1, target do
			newtiles[x][y] = ir.tiles[x][y + cut]
		end
	end
	ir.tiles = newtiles
	ir.height = target
	local function adj(p)
		if p then
			p.y = p.y - cut
		end
	end
	adj(ir.spawn)
	adj(ir.finish)
	for _, e in ipairs(ir.entities) do
		e.y = e.y - cut
	end
	return true
end

return M
