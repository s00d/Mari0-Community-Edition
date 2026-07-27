-- Ported from root hatutil.lua (Teal).

-- Hat offset selection for mario draw (pure given char tables + fireanimationtime global).

local function gethatoffset(char: Character, graphic: any, animationstate: any, runframe: any, jumpframe: any, climbframe: any, swimframe: any, underwater: any, infunnel: any, fireanimationtimer: any, ducking: any): {number}|nil
	local hatoffset: {number}|nil
	local anims = char.animations
	local nogun = char.nogunanimations
	if graphic == anims or graphic == nogun then
		if not char.hatoffsets then
			return nil
		end

		local ho = char.hatoffsets
		if infunnel then
			hatoffset = (ho["jumping"] as {any})[jumpframe as integer] as {number}
		elseif underwater and (animationstate == "jumping" or animationstate == "falling") then
			hatoffset = (ho["swimming"] as {any})[swimframe as integer] as {number}
		elseif animationstate == "jumping" then
			hatoffset = (ho["jumping"] as {any})[jumpframe as integer] as {number}
		elseif animationstate == "running" or animationstate == "falling" then
			hatoffset = (ho["running"] as {any})[runframe as integer] as {number}
		elseif animationstate == "climbing" then
			hatoffset = (ho["climbing"] as {any})[climbframe as integer] as {number}
		end
	else
		if not char.bighatoffsets then
			return nil
		end
		local bho = char.bighatoffsets
		-- Underwater swim offsets must win over jumping (operator precedence used to pick jumping).
		if infunnel then
			hatoffset = (bho["jumping"] as {any})[jumpframe as integer] as {number}
		elseif underwater and (animationstate == "jumping" or animationstate == "falling") then
			hatoffset = (bho["swimming"] as {any})[swimframe as integer] as {number}
		elseif animationstate == "jumping" and not ducking then
			hatoffset = (bho["jumping"] as {any})[jumpframe as integer] as {number}
		elseif ducking then
			hatoffset = bho["ducking"] as {number}
		elseif (fireanimationtimer as number) < fireanimationtime then
			hatoffset = bho["fire"] as {number}
		else
			if animationstate == "running" or animationstate == "falling" then
				hatoffset = (bho["running"] as {any})[runframe as integer] as {number}
			elseif animationstate == "climbing" then
				hatoffset = (bho["climbing"] as {any})[climbframe as integer] as {number}
			end
		end
	end

	if not hatoffset then
		if graphic == anims or graphic == nogun then
			hatoffset = char.hatoffsets[animationstate as string] as {number}
		else
			hatoffset = char.bighatoffsets[animationstate as string] as {number}
		end
	end

	return hatoffset
end
_G.gethatoffset = gethatoffset

return {
	gethatoffset = gethatoffset,
}
