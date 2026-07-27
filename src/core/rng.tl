--[[ Deterministic RNG bootstrap wrapping love.math. ]]

local Rng = {}

local function resolve_seed(seed: number|nil): number
	if seed ~= nil then
		return seed
	end
	local env = os.getenv("MARI0_SEED")
	if env and env ~= "" then
		local parsed = tonumber(env)
		if parsed then
			return parsed
		end
	end
	return os.time()
end

function Rng.install(seed: number|nil): number
	local s = resolve_seed(seed)
	love.math.setRandomSeed(s)
	for _ = 1, 2 do
		love.math.random()
	end
	return s
end

return Rng
