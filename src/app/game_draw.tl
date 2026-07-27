--[[ game_draw orchestrator — phases in game_draw_{world,hud,effects} ]]
require "app.game_draw_hud"
require "app.game_draw_effects"
require "app.game_draw_world"

global function game_draw()
	if not objects then return end
	if firstpersonview and firstpersonrotate then
		local xtranslate = width/2*16*scale
		local ytranslate = height/2*16*scale
		love.graphics.translate(xtranslate, ytranslate)
		love.graphics.rotate(-playerobjs[1].rotation/2)
		love.graphics.translate(-xtranslate, -ytranslate)
	end
	
	local ww, hh = love.window.getMode()
	currentscissor = {0, 0, ww, hh}
	--This is just silly
	if earthquake > 0 and #(rainbooms as {any}) > 0 then
		local colortable = {{242 / 255, 111 / 255, 51 / 255}, {251 / 255, 244 / 255, 174 / 255}, {95 / 255, 186 / 255, 76 / 255}, {29 / 255, 151 / 255, 212 / 255}, {101 / 255, 45 / 255, 135 / 255}, {238 / 255, 64 / 255, 68 / 255}}
		for i = 1, backgroundstripes do
			local r, g, b = unpack(colortable[(math.fmod(i-1, 6)+1) as integer])
			local a = earthquake/rainboomearthquake
			
			love.graphics.setColor(r, g, b, a)
			
			local alpha = math.rad((i/backgroundstripes + math.fmod(sunrot/5, 1)) * 360)
			local point1 = {width*8*scale+300*scale*math.cos(alpha), 112*scale+300*scale*math.sin(alpha)}
			
			local alpha = math.rad(((i+1)/backgroundstripes + math.fmod(sunrot/5, 1)) * 360)
			local point2 = {width*8*scale+300*scale*math.cos(alpha), 112*scale+300*scale*math.sin(alpha)}
			
			love.graphics.polygon("fill", width*8*scale, 112*scale, point1[1], point1[2], point2[1], point2[2])
		end
	end
	
	love.graphics.setColor(1, 1, 1, 1)
	--tremoooor!
	if earthquake > 0 then
		tremorx = (math.random()-.5)*2*earthquake
		tremory = (math.random()-.5)*2*earthquake
		
		love.graphics.translate(round(tremorx), round(tremory))
	end
	
	love.graphics.setColor(1, 1, 1, 1)
	
	
	--THIS IS WHERE MAP DRAWING AND SHIT BEGINS
	
	if players == 1 and seethroughportals then
		game_draw_seethrough_portals()
	else
		scenedraw()
	end
	
	love.graphics.setColor(1, 1, 1, 1)
	
	game_draw_player_markers()
	
	game_draw_debug()
	
	for _, v in pairs(dialogboxes) do
		v:draw()
	end
	
	if earthquake > 0 then
		love.graphics.translate(-round(tremorx), -round(tremory))
	end
	
	if editormode then
		editor_draw()
	end
	
	--speed gradient
	if bullettime and speed < 1 then
		love.graphics.setColor(1, 1, 1, 1-speed)
		love.graphics.draw(gradientimg, 0, 0, 0, scale, scale)
	end
	
	if yoffset < 0 then
		love.graphics.translate(0, -yoffset*scale)
	end
	love.graphics.translate(0, yoffset*scale)
	
	if testlevel then
		love.graphics.setColor(1, 0, 0)
		properprint("testing level - press esc to return to editor", 0, 0)
	end
	
	
	--pause menu
	if pausemenuopen then
		game_draw_pausemenu()
	end

	if metroidmapopen and metroidmap_draw then
		metroidmap_draw()
	end
end
