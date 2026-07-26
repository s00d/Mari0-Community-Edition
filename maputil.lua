-- Tiny map / range helpers (extracted from game.lua).

function inrange(i, a, b, include)
	if a > b then
		b, a = a, b
	end

	if include then
		if i >= a and i <= b then
			return true
		else
			return false
		end
	else
		if i > a and i < b then
			return true
		else
			return false
		end
	end
end

-- Uses globals mapwidth / mapheight (set by level load).
function inmap(x, y)
	if not x or not y then
		return false
	end
	if x >= 1 and x <= mapwidth and y >= 1 and y <= mapheight then
		return true
	else
		return false
	end
end
