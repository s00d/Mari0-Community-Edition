--[[ Deterministic RNG install checks (stub love.math). ]]

local failed = 0

local function check(name, cond, detail)
	if cond then
		print("OK  " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. detail) or ""))
	end
end

local saved_love = love
local saved_getenv = os.getenv

love = {
	math = {
		setRandomSeed = function(seed)
			math.randomseed(seed)
		end,
		random = function(a, b)
			if a and b then
				return math.random(a, b)
			elseif a then
				return math.random(a)
			end
			return math.random()
		end,
	},
}

os.getenv = function(name)
	if name == "MARI0_SEED" then
		return nil
	end
	return saved_getenv(name)
end

local Rng = require("core.rng")

do
	local seq = {}
	Rng.install(42)
	for _ = 1, 100 do
		seq[#seq + 1] = love.math.random()
	end
	local seq2 = {}
	Rng.install(42)
	for _ = 1, 100 do
		seq2[#seq2 + 1] = love.math.random()
	end
	for i = 1, 100 do
		if seq[i] ~= seq2[i] then
			check("seed 42 identical sequence x100", false, "diverged at " .. i)
			break
		end
		if i == 100 then
			check("seed 42 identical sequence x100", true)
		end
	end
end

do
	os.getenv = function(name)
		if name == "MARI0_SEED" then
			return "99"
		end
		return saved_getenv(name)
	end
	local s = Rng.install(nil)
	check("MARI0_SEED env honored", s == 99, tostring(s))
	os.getenv = function(name)
		if name == "MARI0_SEED" then
			return nil
		end
		return saved_getenv(name)
	end
end

love = saved_love
os.getenv = saved_getenv

if select("#", ...) > 0 then
	return failed
end
