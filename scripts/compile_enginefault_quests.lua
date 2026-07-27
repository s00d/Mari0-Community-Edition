#!/usr/bin/env lua
--[[
  Compile mappacks/enginefault/quests.lua → animations/*.json
  Plus intro / joke animations for Act 1.

  Usage: lua scripts/compile_enginefault_quests.lua
]]

local root = ...
if not root or root == "" then
	local info = debug.getinfo(1, "S").source
	if info:sub(1, 1) == "@" then
		root = info:sub(2):match("^(.*)/scripts/compile_enginefault_quests%.lua$") or "."
	else
		root = "."
	end
end

package.path = table.concat({
	root .. "/lib/?.lua",
	root .. "/lib/?/init.lua",
	root .. "/?.lua",
	package.path,
}, ";")

local JSON = require("dkjson")

local quests_path = root .. "/mappacks/enginefault/quests.lua"
local chunk, err = loadfile(quests_path)
if not chunk then
	io.stderr:write("FAIL load quests: " .. tostring(err) .. "\n")
	os.exit(1)
end
local QUESTS = chunk()
if type(QUESTS) ~= "table" then
	-- file may set global QUESTS
	QUESTS = _G.QUESTS
end
assert(type(QUESTS) == "table", "QUESTS missing")

local outdir = root .. "/mappacks/enginefault/animations"
os.execute('mkdir -p "' .. outdir .. '"')

local function write_anim(name, anim)
	local path = outdir .. "/" .. name .. ".json"
	local f = assert(io.open(path, "w"))
	f:write(JSON.encode(anim, { indent = true }) .. "\n")
	f:close()
	print("wrote " .. path)
end

local function compile_quest(q)
	local anims = {}
	local step_key = q.id .. "_step"

	-- Step 0→1: approach compiler (playerxgreater) on quest level
	local s0 = q.steps[1]
	if s0 and s0.flag then
		anims[#anims + 1] = {
			name = q.id .. "_talk1",
			triggers = { { "playerxgreater", tostring(q.talk_x or 9.5) } },
			conditions = {
				{ "worldequals", tostring(q.world or 1) },
				{ "levelequals", tostring(q.leveln or 2) },
				{ "ifint", step_key, "equal", "0" },
			},
			actions = {
				{ "dotoint", step_key, "set", "1" },
				{ "dotobool", s0.flag, "true" },
				{ "dialogbox", s0.desc, "compiler" },
				{ "dialogbox", "TICKET #4471 opened. reproduce the floor bug.", "compiler" },
			},
		}
	end

	-- Fall counter: playerygreater near bottom on 1-2
	anims[#anims + 1] = {
		name = q.id .. "_fall",
		triggers = { { "playerygreater", "13" } },
		conditions = {
			{ "worldequals", tostring(q.world or 1) },
			{ "levelequals", tostring(q.leveln or 2) },
			{ "ifint", step_key, "equal", "1" },
			{ "ifbool", "q4471_fall_gate", "false" },
		},
		actions = {
			{ "dotoint", "q4471_falls", "add", "1" },
			{ "dotobool", "q4471_fall_gate", "true" },
			{ "dialogbox", "fall logged. (gc will reset gate next mapload)", "tracker" },
		},
	}

	-- Reset fall gate on mapload so each visit can count
	anims[#anims + 1] = {
		name = q.id .. "_fall_reset",
		triggers = { { "mapload" } },
		conditions = {
			{ "worldequals", tostring(q.world or 1) },
			{ "levelequals", tostring(q.leveln or 2) },
		},
		actions = {
			{ "dotobool", "q4471_fall_gate", "false" },
		},
	}

	-- When falls >= need, advance to step 2
	local s1 = q.steps[2]
	if s1 and s1.int then
		anims[#anims + 1] = {
			name = q.id .. "_falls_done",
			triggers = { { "whenintis", s1.int, "greater", tostring((s1.need or 3) - 1) } },
			conditions = {
				{ "ifint", step_key, "equal", "1" },
			},
			actions = {
				{ "dotoint", step_key, "set", "2" },
				{ "dialogbox", s1.desc .. " — DONE. return to Compiler.", "tracker" },
			},
		}
	end

	-- Return talk → complete
	local s2 = q.steps[3]
	if s2 and s2.flag then
		anims[#anims + 1] = {
			name = q.id .. "_talk2",
			triggers = { { "playerxgreater", tostring(q.talk_x or 9.5) } },
			conditions = {
				{ "worldequals", tostring(q.world or 1) },
				{ "levelequals", tostring(q.leveln or 2) },
				{ "ifint", step_key, "equal", "2" },
			},
			actions = {
				{ "dotoint", step_key, "set", "3" },
				{ "dotobool", s2.flag, "true" },
				{ "dotobool", q.id .. "_done", "true" },
				{ "dialogbox", s2.desc, "compiler" },
			},
		}
	end

	-- Reward
	local reward_actions = {
		{ "dotobool", q.id .. "_paid", "true" },
	}
	if q.reward and q.reward.weapon then
		reward_actions[#reward_actions + 1] = { "giveweapon", q.reward.weapon }
	end
	if q.reward and q.reward.points then
		reward_actions[#reward_actions + 1] = { "addpoints", tostring(q.reward.points) }
	end
	reward_actions[#reward_actions + 1] = {
		"dialogbox",
		(q.title or q.id) .. " — " .. (q.joke or "WONTFIX"),
		"tracker",
	}

	anims[#anims + 1] = {
		name = q.id .. "_reward",
		triggers = { { "whenboolis", q.id .. "_done", "true" } },
		conditions = {
			{ "ifbool", q.id .. "_paid", "false" },
		},
		actions = reward_actions,
	}

	return anims
end

-- Intro / joke animations (Act 1)
local extras = {
	{
		name = "intro_1_1",
		triggers = { { "mapload" } },
		conditions = {
			{ "worldequals", "1" },
			{ "levelequals", "1" },
			{ "ifbool", "ef_intro_seen", "false" },
		},
		actions = {
			{ "dotobool", "ef_intro_seen", "true" },
			{ "dialogbox", "ENGINE FAULT build " .. tostring(os.time() % 10000) .. ". you are tester #4.", "tracker" },
			{ "dialogbox", "testers 1-3 are still compiling. breakable blocks ahead. ignore the signs.", "tracker" },
		},
	},
	{
		name = "joke_sign_1_1",
		triggers = { { "playerxgreater", "11" } },
		conditions = {
			{ "worldequals", "1" },
			{ "levelequals", "1" },
			{ "ifbool", "ef_sign_a", "false" },
		},
		actions = {
			{ "dotobool", "ef_sign_a", "true" },
			{ "dialogbox", "SIGN A: do NOT break these blocks", "sign" },
		},
	},
	{
		name = "joke_sign_1_1b",
		triggers = { { "playerxgreater", "17" } },
		conditions = {
			{ "worldequals", "1" },
			{ "levelequals", "1" },
			{ "ifbool", "ef_sign_b", "false" },
		},
		actions = {
			{ "dotobool", "ef_sign_b", "true" },
			{ "dialogbox", "SIGN B: only breakable blocks are real. SIGN A is deprecated.", "sign" },
		},
	},
	{
		name = "intro_1_3",
		triggers = { { "mapload" } },
		conditions = {
			{ "worldequals", "1" },
			{ "levelequals", "3" },
		},
		actions = {
			{ "dialogbox", "CHAMBER: memleak stress. hard cap 60 — we learned that the hard way.", "tracker" },
		},
	},
}

local n = 0
for _, q in ipairs(QUESTS) do
	for _, anim in ipairs(compile_quest(q)) do
		n = n + 1
		local name = anim.name or ("quest_" .. n)
		anim.name = nil
		write_anim(name, anim)
	end
end

for _, anim in ipairs(extras) do
	local name = anim.name
	anim.name = nil
	write_anim(name, anim)
end

print(string.format("compiled %d quest(s) + extras → %s", #QUESTS, outdir))
