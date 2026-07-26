--[[ Logger for Mari0 CE (Teal).
     Levels: error, warn, info, debug. Debug gated by global debugprints.
]]

local Logger: LoggerModule = {
	level = "info",
	info = nil as function(...: any),
	debug = nil as function(...: any),
	warn = nil as function(...: any),
	error = nil as function(...: any),
	set_level = nil as function(string),
}

local ORDER: {string:integer} = {
	error = 1,
	warn = 2,
	info = 3,
	debug = 4,
}

local function should_log(level: string): boolean
	local want = ORDER[level] or 3
	local have = ORDER[Logger.level] or 3
	if level == "debug" then
		if debugprints == false then
			return false
		end
		if want > have then
			return false
		end
	end
	return want <= have
end

local function emit(level: string, ...: any)
	if not should_log(level) then
		return
	end
	local n = select("#", ...)
	local parts: {string} = {}
	for i = 1, n do
		parts[i] = tostring(select(i, ...))
	end
	print("[" .. level .. "] " .. table.concat(parts, "\t"))
end

function Logger.set_level(level: string)
	if ORDER[level] then
		Logger.level = level
	end
end

function Logger.error(...: any)
	emit("error", ...)
end

function Logger.warn(...: any)
	emit("warn", ...)
end

function Logger.info(...: any)
	emit("info", ...)
end

function Logger.debug(...: any)
	emit("debug", ...)
end

return Logger
