--[[ Baton input + options.txt record format checks (no LÖVE). ]]

local root = ... or "."
local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	package.path,
}, ";")

controls = {
	[1] = {
		left = {"key:a"},
		right = {"key:d"},
		jump = {"key:space"},
		aimx = {"axis:5-"},
		aimy = {"axis:4-"},
	},
}
players = 1
playerobjs = {}
joystickdeadzone = 0.3
pausemenuopen = false
noupdate = false
mouseowner = 1

require("app.input_bindings")

check("binding_display key", binding_display("key:a") == "a")
check("binding_display button", binding_display("button:3") == "btn3")
check("binding_display hat", binding_display("hat:1l") == "hat1l")
check("binding_display space", binding_display("key:space") == "space")

check("INPUT_ACTIONS table", type(INPUT_ACTIONS) == "table")
local has_left = false
for i = 1, #INPUT_ACTIONS do
	if INPUT_ACTIONS[i] == "left" then
		has_left = true
	end
end
check("INPUT_ACTIONS includes left", has_left)

local editor_keys = {["ctrl+s"] = true, ["ctrl+c"] = true, escape = true}
for i = 1, #INPUT_ACTIONS do
	editor_keys[INPUT_ACTIONS[i]] = nil
end
local stray = 0
for k, v in pairs(editor_keys) do
	if v then
		stray = stray + 1
	end
end
check("editor keys not in INPUT_ACTIONS", stray == 3)

-- Wire format: `playercontrols/1 left=key:a,...` — first space splits name/payload; `:` only inside baton.
local line = "playercontrols/1 left=key:a|hat:1l,right=key:d,jump=key:space"
local sp = line:find(" ", 1, true)
local key = line:sub(1, sp - 1)
local payload = line:sub(sp + 1)
check("record name", key == "playercontrols/1")
local row = {}
for part in payload:gmatch("[^,]+") do
	local eq = part:find("=", 1, true)
	if eq then
		local name = part:sub(1, eq - 1)
		local val = part:sub(eq + 1)
		row[name] = {}
		if val ~= "" then
			for src in val:gmatch("[^|]+") do
				table.insert(row[name], src)
			end
		end
	end
end
check("payload left", row.left and row.left[1] == "key:a" and row.left[2] == "hat:1l")
check("payload jump", row.jump and row.jump[1] == "key:space")
check("payload right", row.right and row.right[1] == "key:d")

return failed
