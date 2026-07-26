--[[
  Structural checks for mario:update phase split (no LÖVE).
  Locks that named phase methods exist, are called from update,
  and invincible animation still falls through (no early return).
]]

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

local f = assert(io.open(root .. "/src/entities/mario.tl", "r"))
local src = f:read("*a")
f:close()

local function extract_fn(name)
	local pat = "function mario:" .. name .. "%(dt%)\n(.-)\nfunction mario:"
	local body = src:match(pat)
	return body
end

local update_body = extract_fn("update")
check("mario:update exists", update_body ~= nil)

local phase_methods = {
	"update_raccoon_effects",
	"update_star",
	"update_animation",
	"update_funnels",
	"update_vine",
	"update_springs",
	"update_world_pickups",
	"update_replay",
	"update_gravity",
	"update_fire_animation",
	"update_controls",
	"update_drains",
}

for _, name in ipairs(phase_methods) do
	check("mario:" .. name .. " exists", src:find("function mario:" .. name .. "%(dt%)", 1, false) ~= nil)
	check("update calls " .. name, update_body and update_body:find("self:" .. name .. "%(dt%)", 1, false) ~= nil)
end

-- zones are gated by controlsenabled: called from controls, not update
check("mario:update_zones exists", src:find("function mario:update_zones%(dt%)", 1, false) ~= nil)
check("update does not call zones directly", update_body and not update_body:find("self:update_zones%(dt%)", 1, false))

local controls = extract_fn("update_controls")
check("update_controls exists body", controls ~= nil)
if controls then
	check("controls calls zones", controls:find("self:update_zones%(dt%)", 1, false) ~= nil)
	check("controls gate controlsenabled", controls:find("self%.controlsenabled") ~= nil)
	check("controls pipe returns true", select(2, controls:gsub("return true", "")) >= 2)
	check("controls returns false", controls:find("return false") ~= nil)
	check("controls has duck", controls:find("self:duck") ~= nil)
	check("controls has pit death", controls:find('die%("pit"%)') ~= nil)
	check("controls has flag", controls:find("self:flag%(%)") ~= nil)
	check("zones not inlined in controls", not controls:find("firestartx"))
end

local zones = extract_fn("update_zones")
check("update_zones exists body", zones ~= nil)
if zones then
	check("zones firestart", zones:find("firestartx") ~= nil)
	check("zones flyingfish", zones:find("flyingfish") ~= nil)
	check("zones bulletbill", zones:find("bulletbill") ~= nil)
	check("zones lakito", zones:find("lakitoend") ~= nil)
end

local drains = extract_fn("update_drains")
check("drains has setquad", drains and drains:find("self:setquad%(%)") ~= nil)
check("setquad not inline in update", update_body and not update_body:find("self:setquad%(%)"))

-- invincible must not return true (falls through into rest of update)
local anim = extract_fn("update_animation")
check("update_animation exists", anim ~= nil)
if anim then
	local inv = anim:match('self%.animation == "invincible".-elseif self%.animation == "grow1"')
	check("invincible fallthrough preserved", inv ~= nil and not inv:find("return true"))
	check("update_animation returns false", anim:find("return false") ~= nil)
	check("pipedown returns true", anim:find('animation == "pipedown".-return true') ~= nil)
	check("death returns true", anim:find('animation == "death".-return true') ~= nil)
end

-- vine / springs early-exit contract
local vine = extract_fn("update_vine")
check("update_vine exists body", vine ~= nil)
if vine then
	check("vine returns true on vine", vine:find("return true") ~= nil)
	check("vine returns false off vine", vine:find("return false") ~= nil)
	check("vine not inline in update", update_body and not update_body:find("%-%-vine controls"))
end

local springs = extract_fn("update_springs")
check("update_springs exists body", springs ~= nil)
if springs then
	check("springs returns true on spring", springs:find("return true") ~= nil)
	check("springs returns false off spring", springs:find("return false") ~= nil)
	check("springs not inline in update", update_body and not update_body:find("%-%-springs"))
end

local funnels = extract_fn("update_funnels")
check("funnels clears funnel flag", funnels and funnels:find("self%.funnel = false") ~= nil)
check("funnels not inline in update", update_body and not update_body:find("%-%-Funnels"))

local pickups = extract_fn("update_world_pickups")
check("pickups has coins", pickups and pickups:find("%-%-coins") ~= nil)
check("pickups has mazegate", pickups and pickups:find("%-%-mazegate") ~= nil)
check("pickups has axe", pickups and pickups:find("%-%-axe") ~= nil)
check("coins not inline in update", update_body and not update_body:find("%-%-coins"))

check("Tailwag not inline in update", update_body and not update_body:find("%-%-Tailwag!"))
check("star timer not inline in update", update_body and not update_body:find("self%.startimer < mariostarduration"))
check("animationS not inline in update", update_body and not update_body:find("%-%-animationS"))
check("controlsenabled not inline in update", update_body and not update_body:find("controlsenabled"))
check("drains comment not inline in update", update_body and not update_body:find("%-%-drains"))

-- thin orchestrator: update body stays small
if update_body then
	local nlines = 1
	for _ in update_body:gmatch("\n") do
		nlines = nlines + 1
	end
	check("update is thin orchestrator (<80 lines)", nlines < 80, tostring(nlines))
end

-- early-return orchestration order
if update_body then
	local i_funnel = update_body:find("self:update_funnels%(dt%)")
	local i_vine = update_body:find("self:update_vine%(dt%)")
	local i_spring = update_body:find("self:update_springs%(dt%)")
	local i_pick = update_body:find("self:update_world_pickups%(dt%)")
	local i_ctrl = update_body:find("self:update_controls%(dt%)")
	local i_drain = update_body:find("self:update_drains%(dt%)")
	check("order funnel < vine < springs < pickups < controls < drains",
		i_funnel and i_vine and i_spring and i_pick and i_ctrl and i_drain
			and i_funnel < i_vine and i_vine < i_spring and i_spring < i_pick
			and i_pick < i_ctrl and i_ctrl < i_drain)
end

return failed
