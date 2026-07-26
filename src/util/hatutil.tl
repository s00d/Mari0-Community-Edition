-- Ported from root hatutil.lua (Teal).

-- Hat offset selection for mario draw (pure given char tables + fireanimationtime global).

local function gethatoffset(char: any, graphic: any, animationstate: any, runframe: any, jumpframe: any, climbframe: any, swimframe: any, underwater: any, infunnel: any, fireanimationtimer: any, ducking: any)
	local hatoffset
	if graphic == char.animations or graphic == char.nogunanimations then
		if not char.hatoffsets then
			return
		end

		if infunnel then
			hatoffset = char.hatoffsets["jumping"][jumpframe]
		elseif underwater and (animationstate == "jumping" or animationstate == "falling") then
			hatoffset = char.hatoffsets["swimming"][swimframe]
		elseif animationstate == "jumping" then
			hatoffset = char.hatoffsets["jumping"][jumpframe]
		elseif animationstate == "running" or animationstate == "falling" then
			hatoffset = char.hatoffsets["running"][runframe]
		elseif animationstate == "climbing" then
			hatoffset = char.hatoffsets["climbing"][climbframe]
		end
	else
		if not char.bighatoffsets then
			return
		end
		-- Underwater swim offsets must win over jumping (operator precedence used to pick jumping).
		if infunnel then
			hatoffset = char.bighatoffsets["jumping"][jumpframe]
		elseif underwater and (animationstate == "jumping" or animationstate == "falling") then
			hatoffset = char.bighatoffsets["swimming"][swimframe]
		elseif animationstate == "jumping" and not ducking then
			hatoffset = char.bighatoffsets["jumping"][jumpframe]
		elseif ducking then
			hatoffset = char.bighatoffsets["ducking"]
		elseif fireanimationtimer < fireanimationtime then
			hatoffset = char.bighatoffsets["fire"]
		else
			if animationstate == "running" or animationstate == "falling" then
				hatoffset = char.bighatoffsets["running"][runframe]
			elseif animationstate == "climbing" then
				hatoffset = char.bighatoffsets["climbing"][climbframe]
			end
		end
	end

	if not hatoffset then
		if graphic == char.animations or graphic == char.nogunanimations then
			hatoffset = char.hatoffsets[animationstate]
		else
			hatoffset = char.bighatoffsets[animationstate]
		end
	end

	return hatoffset
end
_G.gethatoffset = gethatoffset

return {
	gethatoffset = gethatoffset,
}
