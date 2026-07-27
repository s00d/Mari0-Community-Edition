--[[ Pure session FSM — no sockets, no JSON. Shared by host+client paths. ]]

local S = {
	offline = "offline",
	hosting = "hosting",
	connecting = "connecting",
	connected = "connected",
	in_match = "in_match",
	error = "error",
}

-- Allowed transitions (from -> set of to).
local ALLOWED: {string:{string:boolean}} = {
	offline = { hosting = true, connecting = true, error = true },
	hosting = { in_match = true, offline = true, error = true },
	connecting = { connected = true, offline = true, error = true },
	connected = { in_match = true, offline = true, error = true },
	in_match = { offline = true, error = true },
	error = { offline = true },
}

local function can_transition(from: string, to: string): boolean
	local row = ALLOWED[from]
	if not row then
		return false
	end
	return row[to] == true
end

local function transition(from: string, to: string): string|nil
	if can_transition(from, to) then
		return to
	end
	return nil
end

-- Map internal role+flags to FSM label (for tests / debugging).
local function classify(role: string, status: string, in_match: boolean): string
	if in_match then
		return S.in_match
	end
	if role == "idle" then
		if status == "error" or (type(status) == "string" and status:sub(1, 6) == "error:") then
			return S.error
		end
		return S.offline
	end
	if role == "host" then
		return S.hosting
	end
	if role == "client" then
		if status == "connecting…" or status == "connecting..." then
			return S.connecting
		end
		return S.connected
	end
	return S.offline
end

return {
	S = S,
	ALLOWED = ALLOWED,
	can_transition = can_transition,
	transition = transition,
	classify = classify,
}
