-- Player query helpers.
-- Note: assigns global closestplayer (legacy side effect used by callers).

function getclosestplayer(x)
	closestplayer = 1
	for i = 2, players do
		if math.abs(objects["player"][closestplayer].x+6/16-x) > math.abs(objects["player"][i].x+6/16-x) then
			closestplayer = i
		end
	end

	return closestplayer
end
