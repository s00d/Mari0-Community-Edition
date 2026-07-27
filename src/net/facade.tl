--[[ Sole app entry for networking.

Offline: ActiveNet is NullNet — empty update, no UDP/JSON/alloc on the hot path.
Online: session activates a live impl; net_quit / reset restores NullNet.

Game code (love_callbacks) must only call Net.update / netplay_update via this module.
]]

local record NetImpl
	update: function(dt: number)
	get_status: function(): string
	in_match: function(): boolean
	is_active: function(): boolean
end

-- Shared empty functions — never allocate per frame.
local function null_update(_dt: number)
end

local function null_status(): string
	return "offline"
end

local function null_false(): boolean
	return false
end

local NullNet: NetImpl = {
	update = null_update,
	get_status = null_status,
	in_match = null_false,
	is_active = null_false,
}

local active: NetImpl = NullNet

local function activate(impl: NetImpl)
	if impl == nil then
		active = NullNet
		return
	end
	active = impl
end

local function deactivate()
	active = NullNet
end

local function is_null(): boolean
	return active == NullNet
end

local function current(): NetImpl
	return active
end

--------------------------------------------------------------------------
-- Globals used by love_callbacks / UI / tests
--------------------------------------------------------------------------

global function netplay_update(dt: number)
	active.update(dt)
end

global function net_get_status(): string
	return active.get_status()
end

global function net_in_match(): boolean
	return active.in_match()
end

global function net_is_active(): boolean
	return active.is_active()
end

-- Table form for require("net.facade") callers.
local Net = {
	NullNet = NullNet,
	activate = activate,
	deactivate = deactivate,
	is_null = is_null,
	current = current,
	update = netplay_update,
	get_status = net_get_status,
	in_match = net_in_match,
	is_active = net_is_active,
}

return Net
