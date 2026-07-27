--[[ Deterministic transcendentals for lockstep sim (F2).

SIN/ATAN tables are COMMITTED data (lib/dmath_lut_data.lua), generated once by
scripts/gen_dmath_lut.py — never filled via math.sin/atan at runtime.

dsin/dcos: 4096-point LUT + linear lerp using only + - * (IEEE-754 portable).
datan / datan2: committed atan LUT on [0,1] + octant reconstruct.

Draw paths may keep math.sin/cos/atan2. Sim paths (physics.convert, entity
motion that affects x/y/speed) should use these.

After F2: validate sim_hash on x86 vs ARM before F3 input-delay lockstep.
TODO F3: input delay window
TODO F4: start seed+build
TODO F5: delete snapshots
]]

local LUT = require("dmath_lut_data") as {string:any}
local N = (LUT.N as integer) or 4096
local ATAN_N = (LUT.ATAN_N as integer) or 4096
local SIN = LUT.SIN as {number}
local ATAN = LUT.ATAN as {number}

local TWO_PI = 6.283185307179586 -- 2*pi, committed literal
local PI = 3.141592653589793
local HALF_PI = 1.5707963267948966

local function wrap_two_pi(a: number): number
	local t = a % TWO_PI
	if t < 0 then
		t = t + TWO_PI
	end
	return t
end

local function dsin(a: number): number
	local t = wrap_two_pi(a)
	local u = t * (N as number) / TWO_PI
	local i = math.floor(u) as integer
	local f = u - (i as number)
	local i0 = i % N
	local i1 = (i0 + 1) % N
	local a0 = SIN[i0] or 0
	local a1 = SIN[i1] or 0
	return a0 + (a1 - a0) * f
end

local function dcos(a: number): number
	return dsin(a + HALF_PI)
end

-- atan(t) for t in [0,1] via LUT lerp
local function datan01(t: number): number
	if t <= 0 then
		return 0
	end
	if t >= 1 then
		return ATAN[ATAN_N - 1] or HALF_PI
	end
	local u = t * ((ATAN_N - 1) as number)
	local i = math.floor(u) as integer
	local f = u - (i as number)
	local a0 = ATAN[i] or 0
	local a1 = ATAN[i + 1] or a0
	return a0 + (a1 - a0) * f
end

-- atan(|y|/|x|) style for positive ratio; range [0, pi/2]
local function datan_abs(y: number, x: number): number
	if x == 0 then
		return HALF_PI
	end
	local ay = y
	local ax = x
	if ay < 0 then ay = -ay end
	if ax < 0 then ax = -ax end
	if ay > ax then
		return HALF_PI - datan01(ax / ay)
	end
	return datan01(ay / ax)
end

local function datan2(y: number, x: number): number
	if x == 0 and y == 0 then
		return 0
	end
	local a = datan_abs(y, x)
	if x >= 0 and y >= 0 then
		return a
	elseif x < 0 and y >= 0 then
		return PI - a
	elseif x < 0 and y < 0 then
		return -PI + a
	else
		return -a
	end
end

-- Alias matching math.atan(y,x) two-arg form used in Lua 5.3+
local function datan(y: number, x?: number): number
	if x == nil then
		return datan2(y, 1)
	end
	return datan2(y, x as number)
end

rawset(_G, "dsin", dsin)
rawset(_G, "dcos", dcos)
rawset(_G, "datan2", datan2)
rawset(_G, "datan", datan)

return {
	N = N,
	dsin = dsin,
	dcos = dcos,
	datan2 = datan2,
	datan = datan,
	TWO_PI = TWO_PI,
	PI = PI,
}
