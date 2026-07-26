-- Global bool/int helpers used by triggers, animations, enemies, text.

global function globoolSH(id, para): any --does everything relating to globools
--DOC: a simple function, unites four things that i'll be doing a lot with globools into a single, easy-to-use shorthand

if para == "flip" then
globools[id] = not globools[id] as any
elseif para == "true" then
globools[id] = true as any
elseif para == "false" then
globools[id] = false as any
end
if para ~= "check" then
	-- intentionally silent (was print spam every globool mutate)
end
return globools[id] or false --sanitise outputs so nil is never returned
end

global function globintSH(id, para, value): any --modifies global integers in an expandable set of ways
value = tonumber(value) or 0
globints[id] = globints[id] or 0
	if para == "set" then
		globints[id] = value
	elseif para == "add" then
		globints[id] = globints[id] + value
	elseif para == "subtract" then
		globints[id] = globints[id] - value
	end
return globints[id]
end

global function globintCH(id, para, value): any --checks global integers
value = tonumber(value) or 0
globints[id] = globints[id] or 0
	if globints[id] > value and para == "greater" then
		return true
	elseif globints[id] < value and para == "less" then
		return true
	elseif globints[id] == value and para == "equal" then
		return true
	else
		return false
	end
end
