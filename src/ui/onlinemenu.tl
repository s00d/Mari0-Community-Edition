--[[ Online menu: host/join. MagicDNS off by default; guarded against nil HTTP. ]]

global function onlinemenu_load()
	objects = nil
	mappack = "smb"

	gamestate = "onlinemenu"

	localnicks = {"littlepip", "velvet remedy", "calamity", "homage", "blackjack", "fallen glory", "p21", "rampage", "puppysmiles", "clover", "hired gun", "serenity"}
	if love.filesystem.getInfo("nickname.txt") then
		localnick = love.filesystem.read("nickname.txt") or localnicks[math.random(#localnicks)]
	else
		localnick = localnicks[math.random(#localnicks)]
	end

	guielements = {}
	guielements.nickentry = guielement:new("input", 5, 30, 14, nil, localnick, 14, 1)

	guielements.configdecrease = guielement:new("button", 192, 31, "{", configdecrease, 0)
	guielements.configincrease = guielement:new("button", 214, 31, "}", configincrease, 0)

	guielements.ipentry = guielement:new("input", 6, 87, 23, joingame, "127.0.0.1", 23, 1)
	guielements.portentry2 = guielement:new("input", 131, 145, 5, nil, "7331", 5, 1, true)

	guielements.portentry = guielement:new("input", 274, 87, 5, nil, "7331", 5, 1, true)

	-- MagicDNS disabled by default (Love 12 often lacks ssl/http).
	local magic_ok = magicdns_available and magicdns_available()
	guielements.magiccheckbox = guielement:new("checkbox", 220, 147, togglemagic, false)
	guielements.magiccheckbox.active = magic_ok ~= false

	guielements.hostbutton = guielement:new("button", 247, 199, "create game", creategame, 2)
	guielements.hostbutton.bordercolor = {1, 0, 0}
	guielements.hostbutton.bordercolorhigh = {1, 0.5, 0.5}

	guielements.joinbutton = guielement:new("button", 61, 199, "join game", joingame, 2)
	guielements.joinbutton.bordercolor = {0, 1, 0}
	guielements.joinbutton.bordercolorhigh = {0.5, 1, 0.5}

	runanimationtimer = 0
	runanimationframe = 1
	runanimationdelay = 0.1

	playerconfig = 1

	usemagic = false

	magictimer = 0
	magicdelay = 0.15
	magics = {}

	if not SERVER and not CLIENT then
		rawset(_G, "netstatus", "offline")
	end

	if love.keyboard and love.keyboard.setTextInput then
		pcall(function()
			love.keyboard.setTextInput(true)
		end)
	end
end

global function onlinemenu_update(dt: number)
	runanimationtimer = runanimationtimer + dt
	while runanimationtimer > runanimationdelay do
		runanimationtimer = runanimationtimer - runanimationdelay
		runanimationframe = runanimationframe - 1
		if runanimationframe == 0 then
			runanimationframe = 3
		end
	end

	magictimer = magictimer + dt
	while magictimer > magicdelay do
		magictimer = magictimer - magicdelay
		if checkmagic(guielements.ipentry.value as string) then
			table.insert(magics, magic:new())
		end
	end

	local delete: {integer} = {}

	for i, v in ipairs(magics) do
		if v:update(dt) == true then
			table.insert(delete, i)
		end
	end

	remove_indices_desc(magics, delete)

	localnick = guielements.nickentry.value as string
end

global function onlinemenu_draw()
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 3 * scale, 3 * scale, 394 * scale, 52 * scale)
	love.graphics.setColor(1, 1, 1)

	properprint("online play", 4 * scale, 5 * scale)

	properprint("your nick:", 4 * scale, 20 * scale)
	guielements.nickentry:draw()

	properprint("use config", 140 * scale, 20 * scale)
	properprint("number  " .. playerconfig, 140 * scale, 33 * scale)
	guielements.configdecrease:draw()
	guielements.configincrease:draw()

	drawplayercard(240, 10, mariocolors[playerconfig as integer], mariohats[playerconfig as integer], localnick)

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 3 * scale, 58 * scale, 196 * scale, 163 * scale)

	love.graphics.setColor(1, 1, 1)
	properprint("join game", 64 * scale, 60 * scale)

	properprint("address/magicdns", 36 * scale, 77 * scale)
	guielements.ipentry:draw()
	love.graphics.setColor(0.6, 0.6, 0.6)
	properprint("enter ip or hostname", 24 * scale, 107 * scale)
	properprint("to connect (lan/wan).", 28 * scale, 117 * scale)
	properprint("default port 7331", 40 * scale, 127 * scale)

	love.graphics.setColor(1, 1, 1)
	properprint("optional port:", 21 * scale, 148 * scale)
	guielements.portentry2:draw()

	love.graphics.setColor(0.6, 0.6, 0.6)
	properprint("udp port must match", 28 * scale, 162 * scale)
	properprint("the host port.", 48 * scale, 172 * scale)

	guielements.joinbutton:draw()

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 202 * scale, 58 * scale, 195 * scale, 163 * scale)

	love.graphics.setColor(1, 1, 1)
	properprint("host game", 260 * scale, 60 * scale)
	properprint("port", 280 * scale, 77 * scale)

	guielements.portentry:draw()

	love.graphics.setColor(0.6, 0.6, 0.6)
	properprint("forward udp port for", 218 * scale, 107 * scale)
	properprint("internet play. lan", 226 * scale, 117 * scale)
	properprint("works without that.", 222 * scale, 127 * scale)

	guielements.magiccheckbox:draw()
	love.graphics.setColor(1, 1, 1)
	properprint("use magicdns words", 230 * scale, 148 * scale)
	love.graphics.setColor(0.6, 0.6, 0.6)
	if magicdns_available and magicdns_available() then
		properprint("optional short words", 226 * scale, 162 * scale)
		properprint("instead of ip.", 250 * scale, 172 * scale)
	else
		properprint("unavailable (no http", 222 * scale, 162 * scale)
		properprint("/ssl) — use ip.", 242 * scale, 172 * scale)
	end

	guielements.hostbutton:draw()

	for _, v in ipairs(magics) do
		v:draw()
	end

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 3 * scale, 212 * scale, 394 * scale, 10 * scale)
	love.graphics.setColor(0.5, 1, 1)
	properprint("status: " .. tostring(netstatus or "offline"), 4 * scale, 213 * scale)
end

global function configdecrease()
	playerconfig = math.max(1, playerconfig - 1)
end

global function configincrease()
	playerconfig = math.min(4, playerconfig + 1)
end

global function togglemagic()
	if not (magicdns_available and magicdns_available()) then
		usemagic = false
		guielements.magiccheckbox.var = false
		notice.new("magicdns unavailable", notice.red)
		return
	end
	usemagic = not usemagic
	guielements.magiccheckbox.var = usemagic
end

global function checkmagic(s: string): boolean
	if not s then
		return false
	end
	return string.find(s, " ", 1, true) ~= nil
end

global function creategame()
	port = tonumber(guielements.portentry.value) or port
	localnick = guielements.nickentry.value as string
	love.filesystem.write("nickname.txt", localnick)
	server_load()
	if not SERVER then
		return
	end
	if usemagic then
		if not (magicdns_available and magicdns_available()) then
			usemagic = false
			notice.new("magicdns unavailable — hosting by ip", notice.red)
		else
			local adj, n = magicdns_make()
			adjective, noun = adj, n
			if adj == "" or n == "" then
				usemagic = false
				notice.new("magicdns make failed", notice.red)
			end
		end
	end
end

global function joingame()
	port = tonumber(guielements.portentry2.value) or port
	localnick = guielements.nickentry.value as string
	love.filesystem.write("nickname.txt", localnick)
	local s = guielements.ipentry.value as string
	if checkmagic(s) then
		if not (magicdns_available and magicdns_available()) then
			notice.new("magicdns unavailable — enter an ip", notice.red)
			return
		end
		usemagic = true
		local split = strsplit(s, " ")
		adjective, noun = split[1] or "", split[2] or ""
		if adjective == "" or noun == "" then
			notice.new("need two magicdns words", notice.red)
			return
		end
		local found_ip, found_port = magicdns_find(adjective, noun)

		if not found_ip or found_ip == "" then
			notice.new("magicdns not found", notice.red)
			return
		end
		ip = found_ip
		port = tonumber(found_port) or port
	else
		usemagic = false
		ip = s
	end

	client_load()
end

magicdns_validresponses = {"MADE", "KEPT", "REMOVED", "FOUND", "NOTFOUND", "ERROR"}

global function magicdns_available(): boolean
	if http_is_stub then
		return false
	end
	if not http or not http.request then
		return false
	end
	return true
end

local function magicdns_request(url: string): string|nil
	if not magicdns_available() then
		return nil
	end
	local ok, result = pcall(function(): any
		local body = http.request(url)
		return body
	end)
	if not ok or result == nil then
		return nil
	end
	if type(result) ~= "string" then
		return nil
	end
	return result as string
end

global function magicdns_make(): string, string
	http.PORT = port
	local s = magicdns_request("http://dns.stabyourself.net/MAKE/" .. tostring(magicdns_identity) .. "/" .. tostring(magicdns_session) .. "/" .. tostring(port))
	if not s then
		usemagic = false
		return "", ""
	end
	local dns_parts = strsplit(s, "/")
	magicdns_error(dns_parts)

	if dns_parts[1] == "MADE" then
		return string.lower(dns_parts[2] or ""), string.lower(dns_parts[3] or "")
	end
	print("MAGICDNS MAKE FAILED")
	usemagic = false
	return "", ""
end

global function magicdns_keep()
	if not usemagic then
		return
	end
	if not magicdns_available() then
		return
	end
	local s = magicdns_request("http://dns.stabyourself.net/KEEP/" .. tostring(magicdns_identity) .. "/" .. tostring(magicdns_session))
	if not s then
		return
	end
	local dns_parts = strsplit(s, "/")
	magicdns_error(dns_parts)
	if dns_parts[1] ~= "KEPT" then
		print("MAGICDNS KEEP FAILED! RETURNED: " .. s)
	elseif dns_parts[2] and dns_parts[2] ~= "" then
		print("MAGICDNS EXTERNAL PORT KNOWN = " .. dns_parts[2])
	end
end

global function magicdns_remove()
	if not usemagic then
		return
	end
	if not magicdns_available() then
		return
	end
	local s = magicdns_request("http://dns.stabyourself.net/REMOVE/" .. tostring(magicdns_identity) .. "/" .. tostring(magicdns_session))
	if not s then
		return
	end
	local dns_parts = strsplit(s, "/")
	magicdns_error(dns_parts)
	if dns_parts[1] ~= "REMOVED" then
		print("MAGICDNS REMOVE FAILED! RETURNED: " .. s)
	end
end

global function magicdns_find(adj: string, dns_noun: string): string, string, string
	if not magicdns_available() then
		return "", "", ""
	end
	local s = magicdns_request("http://dns.stabyourself.net/FIND/" .. tostring(magicdns_identity) .. "/" .. string.upper(adj) .. "/" .. string.upper(dns_noun))
	if not s then
		return "", "", ""
	end

	local dns_parts = strsplit(s, "/")
	magicdns_error(dns_parts)
	if dns_parts[1] == "FOUND" then
		return dns_parts[2] or "", dns_parts[3] or "", dns_parts[4] or ""
	end
	return "", "", ""
end

global function magicdns_error(dns_parts: {string}): boolean
	if not dns_parts or #dns_parts == 0 then
		return true
	end
	if dns_parts[1] == "ERROR" then
		print("MAGICDNS ERROR: " .. tostring(dns_parts[2]))
		return true
	elseif not tablecontains(magicdns_validresponses, dns_parts[1]) then
		print("MAGICDNS: nonstandard response: " .. tostring(dns_parts[1]))
		return true
	end
	return false
end
