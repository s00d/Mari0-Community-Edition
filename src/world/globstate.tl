-- Global bool/int helpers used by triggers, animations, enemies, text.

global function globoolSH(...: any): any --does everything relating to globools
--DOC: a simple function, unites four things that i'll be doing a lot with globools into a single, easy-to-use shorthand
local id = (... as any)
local para = select(2, ...)
if para == "flip" then
globools[id as any] = not (globools[id as any] as boolean) as any
elseif para == "true" then
globools[id as any] = true as any
elseif para == "false" then
globools[id as any] = false as any
end
if para ~= "check" then
	-- intentionally silent (was print spam every globool mutate)
end
return globools[id as any] or false --sanitise outputs so nil is never returned
end

global function globintSH(...: any): any --modifies global integers in an expandable set of ways
local id = ...
local para = select(2, ...)
local value: any = select(3, ...)
value = tonumber(value as any) or 0
globints[id as any] = globints[id as any] or 0
	if para == "set" then
		globints[id as any] = value
	elseif para == "add" then
		globints[id as any] = (globints[id as any] as number) + (value as number)
	elseif para == "subtract" then
		globints[id as any] = (globints[id as any] as number) - (value as number)
	end
return globints[id as any]
end

global function globintCH(...: any): any --checks global integers
local id = ...
local para = select(2, ...)
local value: any = select(3, ...)
value = tonumber(value as any) or 0
globints[id as any] = globints[id as any] or 0
	if (globints[id as any] as number) > (value as number) and para == "greater" then
		return true
	elseif (globints[id as any] as number) < (value as number) and para == "less" then
		return true
	elseif globints[id as any] == value and para == "equal" then
		return true
	else
		return false
	end
end
