-- Global bool/int helpers used by triggers, animations, enemies, text.

local function glob_key(id: any): string
	return tostring(id)
end

global function globoolSH(id: any, para: any): boolean
--DOC: a simple function, unites four things that i'll be doing a lot with globools into a single, easy-to-use shorthand
local key = glob_key(id)
if para == "flip" then
globools[key] = not globools[key]
elseif para == "true" then
globools[key] = true
elseif para == "false" then
globools[key] = false
end
if para ~= "check" then
	-- intentionally silent (was print spam every globool mutate)
end
return globools[key] or false --sanitise outputs so nil is never returned
end

global function globintSH(id: any, para: any, value?: any): number
local num: number = tonumber(value) or 0
local key = glob_key(id)
globints[key] = globints[key] or 0
	if para == "set" then
		globints[key] = num
	elseif para == "add" then
		globints[key] = globints[key] + num
	elseif para == "subtract" then
		globints[key] = globints[key] - num
	end
return globints[key]
end

global function globintCH(id: any, para: any, value: any): boolean
local num: number = tonumber(value) or 0
local key = glob_key(id)
globints[key] = globints[key] or 0
	if globints[key] > num and para == "greater" then
		return true
	elseif globints[key] < num and para == "less" then
		return true
	elseif globints[key] == num and para == "equal" then
		return true
	else
		return false
	end
end
