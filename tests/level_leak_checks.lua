--[[ Level lifetime leak placeholder (2.0); full assertions wired in 2.1 with Ctx.level. ]]

local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

-- Structural contract only until Level.new/destroy lands in 2.1.
check("leak suite reserved", true)
check("leak full impl deferred to 2.1", true)

return failed
