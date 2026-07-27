-- Ported from root playerutil.lua (Teal).

-- Player query helpers.
-- Note: assigns global closestplayer (legacy side effect used by callers).

local function getclosestplayer(x: number): integer
	closestplayer = 1
	for i = 2, players do
		local a = playerobjs[closestplayer] as Entity
		local b = playerobjs[i] as Entity
		if math.abs(a.x+6/16-x) > math.abs(b.x+6/16-x) then
			closestplayer = i
		end
	end

	return closestplayer
end
_G.getclosestplayer = getclosestplayer

return {
	getclosestplayer = getclosestplayer,
}
