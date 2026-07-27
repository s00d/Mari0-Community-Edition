-- Ported from root playerutil.lua (Teal).

-- Player query helpers.
-- Note: assigns global closestplayer (legacy side effect used by callers).

local function getclosestplayer(x: any): any
	closestplayer = 1 as any
	for i = 2, players do
		local a = playerobjs[closestplayer] as Entity
		local b = playerobjs[i] as Entity
		if math.abs(a.x+6/16-(x as number)) > math.abs(b.x+6/16-(x as number)) then
			closestplayer = i
		end
	end

	return closestplayer
end
_G.getclosestplayer = getclosestplayer

return {
	getclosestplayer = getclosestplayer,
}
