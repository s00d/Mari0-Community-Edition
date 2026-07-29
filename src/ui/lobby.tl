--[[ Lobby UI: roster, chat, start/quit via Net API. ]]

local UiRunPreview = require("assets.ui_run_preview")

global function lobby_load()
	gamestate = "lobby"
	local char_name = mariocharacter[playerconfig] or mariocharacter[1] or "mario"
	UiRunPreview.attach_char(characters[char_name] or characters["mario"])
	guielements = {}
	guielements.chatentry = guielement:new("input", 4, 207, 43 + 7 / 8, sendchat, "", 43)
	guielements.sendbutton = guielement:new("button", 359, 207, "send", sendchat, 1)
	guielements.playerscroll = guielement:new("scrollbar", 389, 3, 104, 8, 50, 0)

	guielements.chatentry.inputting = true
	guielements.chatentry.timer = 0
	guielements.chatentry.cursorblink = true
	if love.keyboard and love.keyboard.setTextInput then
		pcall(function()
			love.keyboard.setTextInput(true)
		end)
	end
	if love.keyboard and love.keyboard.setKeyRepeat then
		pcall(function()
			love.keyboard.setKeyRepeat(true)
		end)
	end

	if Net.role() == "host" then
		guielements.startbutton = guielement:new("button", 4, 80, "start game", function()
			Net.start_match()
		end, 1)
	end
	guielements.quitbutton = guielement:new("button", 100, 80, "quit to menu", function()
		Net.quit()
		menu_load()
	end, 1)

	magicdns_timer = 0
	magicdns_delay = 30
end

global function lobby_update(dt: number)
	UiRunPreview.update(dt)

	if Net.role() == "host" and usemagic and magicdns_available and magicdns_available() then
		magicdns_timer = magicdns_timer + dt
		while magicdns_timer > magicdns_delay do
			magicdns_timer = magicdns_timer - magicdns_delay
			pcall(magicdns_keep)
		end
	end
end

global function lobby_draw()
	local peers = Net.peers()
	local chats = Net.chats()
	local scroll = guielements.playerscroll.value as number
	draw_panel(0, 0, 240, 112)

	love.graphics.setColor(1, 1, 1, 1)
	if usemagic and adjective and noun and adjective ~= "" and noun ~= "" then
		properprintbackground("magicdns: " .. adjective .. " " .. noun, 8 * scale, 98 * scale, true)
	end
	ui_set_color("status")
	properprintbackground("status: " .. tostring(Net.status()), 8 * scale, 6 * scale, true)
	ui_set_color("text")
	if Net.role() == "host" then
		properprintbackground("port " .. tostring(port or 7331), 8 * scale, 16 * scale, true)
		guielements.startbutton:draw()
	else
		properprintbackground("connected to host", 8 * scale, 16 * scale, true)
	end
	guielements.quitbutton:draw()

	love.graphics.setScissor(240 * scale, 0, 160 * scale, 112 * scale)

	local missingpixels = math.max(0, (#peers * 41 - 3) - 104)

	draw_panel(240, 0, 160, 112)

	love.graphics.translate(0, -missingpixels * scroll * scale)

	local y = 1
	local my_peers = peers
	for i = 1, #my_peers do
		local pl = my_peers[i]
		if pl.connected ~= false then
			local focus = i == 1 and Net.role() == "host" or false
			-- focus local: match by being first for host; clients use local nick match
			if tostring(pl.nick or "") == tostring(localnick or "") then
				focus = true
			end
			local ping: number|nil = nil
			if pl.ping and i > 1 then
				ping = round((pl.ping as number) * 1000)
			end
			drawplayercard(240, (y - 1) * 41 + 3, (pl.colors or mariocolors[1]) as {{number}}, (pl.hats or mariohats[1]) as {any}, tostring(pl.nick or "?"), ping, focus)
			y = y + 1
		end
	end

	love.graphics.translate(0, missingpixels * scroll * scale)
	guielements.playerscroll:draw()
	love.graphics.setScissor()

	draw_panel(0, 112, 400, 112)
	menu_draw_rule(8, 112, 384)

	guielements.chatentry:draw()
	guielements.sendbutton:draw()

	local chat_height = 0
	for i = #chats, math.max(1, #chats - 8), -1 do
		local pid = 0
		for j = 1, #my_peers do
			if my_peers[j].id == chats[i].id then
				pid = j
				break
			end
		end

		if pid ~= 0 then
			local nick = my_peers[pid].nick or "?"
			local colors = (my_peers[pid].colors or mariocolors[1]) as {{number}}
			local nick_background = {1, 1, 1}
			local adds: number = 0
			for c = 1, 3 do
				adds = adds + colors[1][c]
			end
			if adds / 3 > 40 then
				nick_background = {0, 0, 0}
			end
			love.graphics.setColor(unpack(colors[1]))
			properprintbackground(nick as string, 8 * scale, (196 - (chat_height * 10)) * scale, true, nick_background)
			love.graphics.setColor(1, 1, 1)
			properprint(":" .. tostring(chats[i].message or ""), (8 + (string.len(nick as string)) * 8) * scale, (196 - (chat_height * 10)) * scale)
			chat_height = chat_height + 1
		end
	end
	love.graphics.setColor(1, 1, 1, 1)
end

global function sendchat()
	if not guielements or not guielements.chatentry then
		return
	end
	Net.chat(tostring(guielements.chatentry.value or ""))
	guielements.chatentry.value = ""
	guielements.chatentry.cursorpos = 1
	guielements.chatentry.inputting = true
	guielements.chatentry.offset = 0
	if love.keyboard and love.keyboard.setTextInput then
		pcall(function()
			love.keyboard.setTextInput(true)
		end)
	end
end
