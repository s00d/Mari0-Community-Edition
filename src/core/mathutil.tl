local function round(num: number, idp?: number): number
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function getrainbowcolor(i: number): {number}
	local r: number = 0
	local g: number = 0
	local b: number = 0
	if i < 1 / 6 then
		r = 1
		g = i * 6
		b = 0
	elseif i >= 1 / 6 and i < 2 / 6 then
		r = (1 / 6 - (i - 1 / 6)) * 6
		g = 1
		b = 0
	elseif i >= 2 / 6 and i < 3 / 6 then
		r = 0
		g = 1
		b = (i - 2 / 6) * 6
	elseif i >= 3 / 6 and i < 4 / 6 then
		r = 0
		g = (1 / 6 - (i - 3 / 6)) * 6
		b = 1
	elseif i >= 4 / 6 and i < 5 / 6 then
		r = (i - 4 / 6) * 6
		g = 0
		b = 1
	else
		r = 1
		g = 0
		b = (1 / 6 - (i - 5 / 6)) * 6
	end
	return { r, g, b, 1 }
end

local function gradient(color1: {number}, color2: {number}, progress: number): {number}
	local ret: {number} = {}
	for i = 1, math.max(#color1, #color2) do
		local c1 = color1[i] or color2[i]
		local c2 = color2[i] or color1[i]
		ret[i] = c1 + (c2 - c1) * progress
	end
	return ret
end

_G.round = round
_G.getrainbowcolor = getrainbowcolor
_G.gradient = gradient

return {
	round = round,
	getrainbowcolor = getrainbowcolor,
	gradient = gradient,
}
