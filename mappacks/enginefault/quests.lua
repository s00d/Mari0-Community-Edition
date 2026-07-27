-- ENGINE FAULT quest definitions.
-- Compile with: lua scripts/compile_enginefault_quests.lua
-- Output: mappacks/enginefault/animations/*.json

QUESTS = {
	{
		id = "q_ticket_4471",
		title = "TICKET #4471: player falls through floor",
		giver = "compiler",
		level = "1-2",
		world = 1,
		leveln = 2,
		-- talk_x: playerxgreater near COMPILER textentity
		talk_x = 9.5,
		steps = {
			{ flag = "q4471_seen", desc = "talk to the Compiler" },
			{ int = "q4471_falls", need = 3, desc = "fall through the floor 3 times (known issue)" },
			{ flag = "q4471_fixed", desc = "return to the Compiler" },
		},
		reward = { weapon = "freezeray", points = 5000 },
		joke = "closed as WONTFIX",
	},
}

return QUESTS
