--[[ GC pacing + offline singleplayer hitch guards (no LÖVE window). ]]

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

local function read(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local body = f:read("*a")
	f:close()
	return body
end

package.path = table.concat({
	root .. "/build/?.lua",
	root .. "/build/?/init.lua",
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	package.path,
}, ";")

-- Runtime: module loads and steps without error on host Lua.
local Gc = require("core.gcpace")
check("gcpace exports configure", type(Gc.configure) == "function" or type(gcpace_configure) == "function")
check("gcpace exports step", type(gcpace_step) == "function")
check("gcpace exports after_load", type(gcpace_after_load) == "function")

local ok_cfg = pcall(gcpace_configure)
check("gcpace_configure safe", ok_cfg)

local junk = {}
for i = 1, 2000 do
	junk[i] = { i, tostring(i), { i * 2 } }
end
junk = nil
local ok_step = pcall(gcpace_step)
check("gcpace_step safe after alloc", ok_step)

local ok_after = pcall(gcpace_after_load)
check("gcpace_after_load safe", ok_after)

-- after_load must not stop-the-world collect (source)
local gc_src = read(root .. "/src/core/gcpace.tl") or ""
local after_fn = gc_src:match("global function gcpace_after_load%(%)(.-)\nend")
check("gcpace_after_load source found", after_fn ~= nil)
if after_fn then
	check(
		"gcpace_after_load no full collect",
		after_fn:find('collectgarbage("collect")', 1, true) == nil
	)
end

-- Source: loadlevel must not full-collect at the start (sets low threshold).
local loadlevel_src = read(root .. "/src/app/game_load_level.tl") or ""
local loadlevel_fn = loadlevel_src:match("global function loadlevel.-return needs_to_be_saved")
check("loadlevel body found", loadlevel_fn ~= nil)
if loadlevel_fn then
	local head = loadlevel_fn:sub(1, 280)
	check(
		"loadlevel no early full collect",
		head:find('collectgarbage("collect")', 1, true) == nil,
		"early collect still present"
	)
	check(
		"loadlevel calls gcpace_after_load",
		loadlevel_fn:find("gcpace_after_load", 1, true) ~= nil
	)
end

-- Source: love.update paces GC once per frame, outside the physics while-loop.
local cb = read(root .. "/src/app/love_callbacks.tl") or ""
local update_fn = cb:match("function love%.update%(.-^end")
-- Fallback: crude slice from love.update to love.draw
if not update_fn then
	update_fn = cb:match("function love%.update.-function love%.draw")
end
check("love.update found", update_fn ~= nil)
if update_fn then
	check("love.update calls gcpace_step", update_fn:find("gcpace_step", 1, true) ~= nil)
	-- gcpace_step must appear after the physics while loop closes (after clear_debt).
	local after_debt = update_fn:match("LoveFrame%.clear_debt%(%).-gcpace_step")
	check("gcpace_step after physics loop", after_debt ~= nil)
	-- Must not sit inside the while LoveFrame.has_pending_step body before clear_debt.
	local before_debt = update_fn:match("while LoveFrame%.has_pending_step.-gcpace_step.-LoveFrame%.clear_debt")
	check("gcpace_step not inside physics while", before_debt == nil)
end

-- Boot wires configure at require time.
local boot = read(root .. "/src/app/boot.tl") or ""
check("boot requires gcpace", boot:find('require "core.gcpace"', 1, true) ~= nil)
check("boot calls gcpace_configure", boot:find("gcpace_configure()", 1, true) ~= nil)

-- Offline singleplayer: no MagicDNS / HTTP / full collect on the update hot path.
check(
	"love.update has no magicdns_keep",
	(cb:find("magicdns_keep", 1, true) or "") == ""
)
check(
	"love.update has no http.request",
	(cb:find("http.request", 1, true) or "") == ""
)
-- Full collect in love.draw only while recording screenshots (not gameplay).
local draw_fn = cb:match("function love%.draw.-function love%.keypressed") or ""
local collect_in_draw = draw_fn:find('collectgarbage("collect")', 1, true)
if collect_in_draw then
	local before = draw_fn:sub(1, collect_in_draw)
	check("draw collect gated by recording", before:find("if recording then", 1, true) ~= nil)
else
	check("draw collect gated by recording", true)
end

-- NullNet facade still the offline entry (no hidden UDP in love_callbacks).
check(
	"love_callbacks uses netplay_update facade",
	cb:find("netplay_update", 1, true) ~= nil
)
check(
	"love_callbacks does not require net.session",
	cb:find('require("net.session"', 1, true) == nil
		and cb:find('require "net.session"', 1, true) == nil
)

if select("#", ...) > 0 then
	return failed
end
os.exit(failed > 0 and 1 or 0)
