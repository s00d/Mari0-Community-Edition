--[[ Shared helpers for headless mappack QA (no LÖVE). ]]

local Common = {}

function Common.root_from(arg0)
	local root = arg0
	if not root or root == "" then
		local info = debug.getinfo(2, "S").source
		if info:sub(1, 1) == "@" then
			root = info:sub(2):match("^(.*)/tests/mappack_qa/") or "."
		else
			root = "."
		end
	end
	return root
end

function Common.pack_filter()
	local filter = "all"
	for i = 1, #(arg or {}) do
		local a = tostring(arg[i] or "")
		local p = a:match("^%-%-pack=(.+)$")
		if p and p ~= "" then
			filter = p
		end
	end
	return filter
end

function Common.check(state, name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		state.failed = state.failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

function Common.list_packs(root)
	local packs = {}
	local h = io.popen('ls -1 "' .. root .. '/mappacks" 2>/dev/null')
	if not h then
		return packs
	end
	for name in h:lines() do
		local path = root .. "/mappacks/" .. name
		local levels = Common.list_levels(root, name)
		-- Directory under mappacks/ with at least one N-M(_S).txt
		local dir_ok = io.open(path, "r")
		if dir_ok then
			dir_ok:close()
		end
		if #levels >= 1 then
			packs[#packs + 1] = name
		end
	end
	h:close()
	table.sort(packs)
	return packs
end

function Common.list_levels(root, pack)
	local levels = {}
	local path = root .. "/mappacks/" .. pack
	local h = io.popen('ls -1 "' .. path .. '" 2>/dev/null')
	if not h then
		return levels
	end
	for name in h:lines() do
		-- N-M.txt or N-M_S.txt (sublevels); skip settings.txt
		if name:match("^[%w]+%-%d+%.txt$") or name:match("^[%w]+%-%d+_%d+%.txt$") then
			levels[#levels + 1] = name:sub(1, -5) -- strip .txt
		end
	end
	h:close()
	table.sort(levels)
	return levels
end

function Common.read_level(root, pack, level_name)
	local path = root .. "/mappacks/" .. pack .. "/" .. level_name .. ".txt"
	local f = io.open(path, "r")
	if not f then
		return nil, "missing " .. path
	end
	local s = f:read("*a")
	f:close()
	return s, path
end

function Common.ensure_entitylist()
	if entitylist then
		return entitylist
	end
	_G.DEBUG = _G.DEBUG or false
	_G.love = _G.love or {}
	_G.love.filesystem = _G.love.filesystem or {
		getInfo = function()
			return nil
		end,
	}
	_G.AssetStore = _G.AssetStore or {
		load_image = function()
			return nil
		end,
	}
	require("world.entitylist")
	return entitylist
end

function Common.enemy_json_exists(root, name)
	local f = io.open(root .. "/assets/enemies/" .. name .. ".json", "r")
	if f then
		f:close()
		return true
	end
	return false
end

--- Walk every cell; callback(x, y, cell)
function Common.each_cell(parsed, fn)
	for x = 1, parsed.mapwidth do
		for y = 1, parsed.mapheight do
			fn(x, y, parsed.map[x][y])
		end
	end
end

--- Extract link targets from a cell: { {input, tx, ty}, ... }
function Common.cell_links(cell)
	local out = {}
	local i = 2
	while i <= #cell do
		if cell[i] == "link" then
			local input = cell[i + 1]
			local tx = tonumber(cell[i + 2])
			local ty = tonumber(cell[i + 3])
			if tx and ty then
				out[#out + 1] = { input = tostring(input or ""), tx = tx, ty = ty, at = i }
			end
			i = i + 4
		else
			i = i + 1
		end
	end
	return out
end

return Common
