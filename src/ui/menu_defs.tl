--[[ Data-driven menu screens. Actions match menu_keypressed / menu_draw_title. ]]

global MENU_SCREENS: {string:{string:any}} = {}

global function menu_defs_bind()
	MENU_SCREENS.main = {
		title = "mari0",
		items = {
			{
				id = "continue",
				label = "continue game",
				visible = function(): boolean
					return continueavailable == true
				end,
				action = function()
					game_load(true)
				end,
			},
			{
				id = "newgame",
				label = "player game",
				action = function()
					selectworld()
				end,
			},
			{
				id = "editor",
				label = "level editor",
				action = function()
					editormode = true
					players = 1
					game_load()
				end,
			},
			{
				id = "mappacks",
				label = "select mappack",
				action = function()
					gamestate = "mappackmenu"
					mappacks()
				end,
			},
			{
				id = "options",
				label = "options",
				action = function()
					gamestate = "options"
				end,
			},
			{
				id = "online",
				label = "online play",
				action = function()
					onlinemenu_load()
				end,
			},
		},
		spinners = {
			{
				id = "players",
				label = "players",
				get = function(): string
					return tostring(players)
				end,
				dec = function()
					players = math.max(1, players - 1)
				end,
				inc = function()
					players = math.min(4, players + 1)
				end,
			},
		},
		back = function()
			love.event.quit()
		end,
	}
end
