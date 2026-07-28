--[[
  Mari0 tiles.png property column helpers.

  PROP_ORDER matches src/world/quad.tl getquadprops (0-based row in 17th column).
]]

local M = {}

M.PROP_ORDER = {
	"collision", -- 0
	"invisible", -- 1
	"breakable", -- 2
	"coinblock", -- 3
	"coin", -- 4
	"notportalable", -- 5
	"slantupleft", -- 6
	"slantupright", -- 7
	"mirror", -- 8
	"grate", -- 9
	"platform", -- 10
	"water", -- 11
	"bridge", -- 12
	"spikesleft", -- 13
	"spikestop", -- 14
	"spikesright", -- 15
	"spikesbottom", -- 16
}

M.PROP_INDEX = {}
for i, name in ipairs(M.PROP_ORDER) do
	M.PROP_INDEX[name] = i - 1
end

-- SMB3 Foundry object-name → property vote weights.
-- Background Hills / bushes / clouds are scenery (walk-through), not terrain.
-- Solid hills are names like "Flat Land - Hilly", "Hilly Wall", "Hill Corner".
local DECORATIVE = {
	"background cloud", "background bush", "background coconut", "background aquatic",
	"background hills", "small background hills",
	"cloud background", "oval background", "swirly background", "starry background",
	"clouds a", "clouds b", "clouds c", "cloud-colored",
	"white mushrooms, flowers", "palm tree", "sets background",
	"blank background", "plain background", "background pillar",
	"wooden background", "ship background line", "background wooden",
	"background for pipe", "background like at bottom", "background used in",
	"background pyramid", "background mountain", "blue background",
	"castle room background", "dungeon background", "dark dungeon background",
	"underground background under", "black boss room", "gap",
	"msg_nothing", "porthole", "railing", "dungeon lamp", "dungeon window",
	"hot foot", "blue gear", "background pole", "bottom of background",
	"background pipe", "jelectro",
}

function M.classify(name)
	local n = string.lower(tostring(name or ""))
	local props = {}

	if n == "coins" or n:find("silver coins", 1, true) or n == "frozen coins" or n == "invisible coin" then
		props.coin = 1
		if n:find("invisible", 1, true) then
			props.invisible = 1
		end
		return props
	end

	for i = 1, #DECORATIVE do
		if n:find(DECORATIVE[i], 1, true) then
			return props
		end
	end

	if n:find("water", 1, true) and not n:find("underwater", 1, true) and not n:find("waterfall", 1, true) then
		props.water = 2
		props.collision = -2
		return props
	end
	if n:find("waterfall", 1, true) then
		props.water = 1
		props.collision = 1
		return props
	end
	if n:find("lava", 1, true) then
		props.spikestop = 1
		props.collision = -1
		return props
	end
	if n:find("?", 1, true) then
		props.collision = 3
		props.coinblock = 3
		return props
	end
	if n:find("brick", 1, true) then
		props.collision = 3
		props.breakable = 3
		return props
	end
	if n:find("spike", 1, true) then
		props.collision = 2
		props.spikestop = 2
		return props
	end
	if n:find("note block", 1, true) or n:find("cloud platform", 1, true) then
		props.collision = 2
		props.platform = 2
		return props
	end
	if n:find("platform", 1, true) and n:find("floating", 1, true) and not n:find("wire", 1, true) then
		props.collision = 2
		props.platform = 2
		return props
	end
	if n:find("platform", 1, true) and not n:find("wire", 1, true) then
		props.collision = 2
		props.platform = 2
		return props
	end

	props.collision = 2
	return props
end

function M.classify_at(name, dy, height)
	local n = string.lower(tostring(name or ""))
	if n:find("extends to ground", 1, true) and n:find("platform", 1, true) then
		if dy == 0 then
			return { collision = 2, platform = 2 }
		end
		return {}
	end
	return M.classify(name)
end

--- Vote props for (object_set, tile_id) from dump level JSON tables.
-- levels: array of decoded level dicts with objects[] + tilemap[][]
-- returns map key "os:tid" -> { prop = score, ... }
function M.derive_tile_props(levels)
	local votes = {}

	local function bump(os_, tid, prop, w)
		local key = os_ .. ":" .. tid
		local row = votes[key]
		if not row then
			row = {}
			votes[key] = row
		end
		row[prop] = (row[prop] or 0) + w
	end

	for _, data in ipairs(levels) do
		local os_ = data.object_set
		local tm = data.tilemap
		if os_ and tm then
			for _, o in ipairs(data.objects or {}) do
				local r = o.rendered
				if r and o.name then
					local x0, y0, w, h = r.x or 0, r.y or 0, r.w or 0, r.h or 0
					for dy = 0, h - 1 do
						local props = M.classify_at(o.name, dy, h)
						for dx = 0, w - 1 do
							local y, x = y0 + dy, x0 + dx
							local row = tm[y + 1] -- Lua 1-based if converted; also accept 0-based via raw
							if not row and tm[y] then
								row = tm[y]
							end
							if row then
								local tid = row[x + 1] or row[x]
								if tid then
									tid = tid % 256
									if tid ~= 0 then
										for prop, weight in pairs(props) do
											if weight > 0 then
												bump(os_, tid, prop, weight)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- Resolve to boolean props (platform needs a strong vote — shared tile ids).
	local out = {}
	for key, scores in pairs(votes) do
		local props = {}
		local collision_score = scores.collision or 0
		for prop, score in pairs(scores) do
			if score > 0 and prop ~= "coin" then
				local keep = true
				if prop == "platform" and collision_score > 0 and score < collision_score * 0.5 then
					keep = false
				end
				if keep then
					props[prop] = true
				end
			end
		end
		if collision_score > 0 then
			props.collision = true
		end
		if (scores.coin or 0) > 0 and collision_score <= 0 then
			props.coin = true
		end
		out[key] = props
	end
	return out, votes
end

--- solid_bottom ratio among tiles that solid-classified objects painted on bottom rows.
-- Assert solid_bottom / total > min_ratio (default 0.90).
function M.validate_props(levels, props_map, min_ratio)
	min_ratio = min_ratio or 0.90
	local solid_bottom, total = 0, 0

	for _, data in ipairs(levels) do
		if data.header and not data.header.is_vertical and data.tilemap then
			local os_ = data.object_set
			local tm = data.tilemap
			local h = #tm
			-- support 0-based python-style arrays passed through as-is length
			local bottom_y = h - 1
			if tm[h] then
				bottom_y = h -- 1-based
			end

			for _, o in ipairs(data.objects or {}) do
				local cls = M.classify(o.name or "")
				if (cls.collision or 0) > 0 and o.rendered then
					local r = o.rendered
					local y1 = (r.y or 0) + (r.h or 0) - 1
					-- only cells on the bottommost map row
					local map_h = data.header.height or h
					if y1 >= map_h - 1 then
						for dx = 0, (r.w or 0) - 1 do
							local x = (r.x or 0) + dx
							local row = tm[map_h] or tm[map_h - 1]
							if row then
								local tid = row[x + 1] or row[x]
								if tid and tid % 256 ~= 0 then
									tid = tid % 256
									total = total + 1
									local p = props_map[os_ .. ":" .. tid]
									if p and p.collision then
										solid_bottom = solid_bottom + 1
									end
								end
							end
						end
					end
				end
			end
		end
	end

	local ratio = total > 0 and (solid_bottom / total) or 0
	return ratio >= min_ratio, ratio, solid_bottom, total
end

--- Count collision flags in a Mari0 17-stride tiles.png via raw RGBA byte buffer.
-- img_w, img_h, get_alpha(x,y) -> 0..255
function M.count_collision_flags(img_w, img_h, get_alpha)
	local cols = math.floor(img_w / 17)
	local rows = math.floor(img_h / 17)
	local n = 0
	for ty = 0, rows - 1 do
		for tx = 0, cols - 1 do
			local a = get_alpha(tx * 17 + 16, ty * 17)
			if a > 127 then
				n = n + 1
			end
		end
	end
	return n, cols * rows
end

return M
