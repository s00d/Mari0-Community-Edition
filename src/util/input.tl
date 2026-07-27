--[[ Thin input facade (Stage 2.4); hot paths migrate incrementally. ]]

local Input = {}

function Input.pressed(player: integer, action: string): boolean
	if controls and controls[player] and controls[player][action] then
		return checkkey(controls[player][action])
	end
	return false
end

return Input
