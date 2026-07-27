--[[ UI pointer coords + input mode (mouse vs keyboard).
     Minimal globals until a Ctx.ui bag exists — prefer Ctx.ui when added. ]]

-- "mouse" | "kbd" — mouse move selects under cursor; key/stick ignores hover until move
global ui_input_mode: string = "kbd"
global mouseui_x: number = 0
global mouseui_y: number = 0

-- Same fullscreen math as legacy love.mousepressed; returns scaled game pixels
-- (guielement hit space). Divide by `scale` for unscaled 400×224 layout units.
global function screen_to_ui(x: number, y: number): number, number
	if fullscreen then
		if fullscreenmode == "full" then
			x = x / (desktopsize.width / (width * 16 * scale))
			y = y / (desktopsize.height / (height * 16 * scale))
		else
			x = x / (touchfrominsidescaling / scale)
			y = y / (touchfrominsidescaling / scale) - touchfrominsidemissing / 2
		end
	end
	return x, y
end

global function ui_set_input_mode(mode: string)
	ui_input_mode = mode
end

global function ui_note_mouse_move(dx: number, dy: number, x: number, y: number): boolean
	if (math.abs(dx) + math.abs(dy)) < 1 then
		return false
	end
	local ux, uy = screen_to_ui(x, y)
	mouseui_x, mouseui_y = ux, uy
	ui_input_mode = "mouse"
	return true
end

global function ui_note_kbd()
	ui_input_mode = "kbd"
end
