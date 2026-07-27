--[[
  Spritebatch portal catch-up logic (no LÖVE).
  Guards incremental scroll path after portal teleport camera catch-up.
]]

local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

local function scroll_delta(new_sbx, new_sby, old_sbx, old_sby)
	local sb_dx, sb_dy = 0, 0
	if old_sbx ~= nil then
		sb_dx = new_sbx - old_sbx
	end
	if old_sby ~= nil then
		sb_dy = new_sby - old_sby
	end
	return sb_dx, sb_dy
end

local function incremental_scroll_allowed(scroll_dx, scroll_dy, portal_catchup, has_view)
	if portal_catchup then
		return false
	end
	return math.abs(scroll_dx) + math.abs(scroll_dy) == 1 and has_view
end

local function game_update_uses_full_rebuild(portal_catchup, sb_dx, sb_dy, has_x, has_y)
	if sb_dx == 0 and sb_dy == 0 then
		return false
	end
	if portal_catchup or not has_x or not has_y then
		return true
	end
	return not incremental_scroll_allowed(sb_dx, sb_dy, portal_catchup, true)
end

-- Portal catch-up often shifts both scroll floors in one frame after teleport.
do
	local dx, dy = scroll_delta(12, 8, 10, 5)
	check("both-axis scroll delta", dx == 2 and dy == 3)
	check("both-axis blocks incremental", not incremental_scroll_allowed(dx, dy, false, true))
	check("portal catchup blocks incremental", not incremental_scroll_allowed(1, 0, true, true))
	check("game_update full rebuild on portal catchup", game_update_uses_full_rebuild(true, 1, 0, true, true))
	check("game_update full rebuild on dual delta", game_update_uses_full_rebuild(false, dx, dy, true, true))
	check("game_update incremental on single tile", not game_update_uses_full_rebuild(false, 1, 0, true, true))
end

-- invalidate_spritebatch_after_portal_teleport contract (mock globals).
do
	spritebatch_view = { cached = true }
	spritebatch_orphan_slots = 42
	spritebatch_portal_catchup = false

	local function invalidate_spritebatch_after_portal_teleport()
		spritebatch_view = nil
		spritebatch_orphan_slots = 0
		spritebatch_portal_catchup = true
	end

	invalidate_spritebatch_after_portal_teleport()
	check("invalidate clears view cache", spritebatch_view == nil)
	check("invalidate resets orphan slots", spritebatch_orphan_slots == 0)
	check("invalidate sets portal catchup", spritebatch_portal_catchup == true)
end

return failed
