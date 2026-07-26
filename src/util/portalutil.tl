-- Ported from root portalutil.lua (Teal).

-- Portal facing → second-tile offsets (duplicated across game/physics/mario).

-- Returns xplus, yplus for the "extra" portal block relative to facing.
local function portal_facing_offset(facing: any)
	if facing == "up" then
		return 1, 0
	elseif facing == "right" then
		return 0, 1
	elseif facing == "down" then
		return -1, 0
	elseif facing == "left" then
		return 0, -1
	end
	return 0, 0
end
_G.portal_facing_offset = portal_facing_offset


-- Both portal ends at once (common local unpack pattern).
local function portal_pair_offsets(facing1: any, facing2: any)
	local x1, y1 = portal_facing_offset(facing1)
	local x2, y2 = portal_facing_offset(facing2)
	return x1, y1, x2, y2
end
_G.portal_pair_offsets = portal_pair_offsets

return {
	portal_facing_offset = portal_facing_offset,
	portal_pair_offsets = portal_pair_offsets,
}
