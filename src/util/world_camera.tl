--[[ hump.camera draw context: world tile → world pixels (call only under attach). ]]

local CameraMod = require("hump.camera")
local cam: HumpCamera|nil = nil

local function ensure(): HumpCamera
	if not cam then
		cam = (CameraMod as function(...: any): HumpCamera)(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
	end
	return cam as HumpCamera
end

global function world_camera_sync()
	local c = ensure()
	c:zoomTo(scale)
	local yoff = (yoffset or 0) * 16
	c:lookAt((session.xscroll + width / 2) * 16, (session.yscroll + height / 2) * 16 + yoff)
end

global function world_camera_attach()
	world_camera_sync()
	ensure():attach(0, 0, width * 16 * scale, height * 16 * scale, true)
end

global function world_camera_detach()
	ensure():detach()
end

global function world_viewport_w(): number
	return width * 16 * scale
end

global function world_viewport_h(): number
	return height * 16 * scale
end

global function world_camera_screen_x(world_px: number): number
	local c = ensure()
	local vw, vh = world_viewport_w(), world_viewport_h()
	return (c:cameraCoords(world_px, 0, 0, 0, vw, vh))
end

global function world_camera_screen_y(world_py: number): number
	local c = ensure()
	local vw, vh = world_viewport_w(), world_viewport_h()
	local _, sy = c:cameraCoords(0, world_py, 0, 0, vw, vh)
	return sy
end

global function world_screen_x(tile_x: number): number
	return world_camera_screen_x(math.floor(tile_x * 16))
end

global function world_screen_y(tile_y: number): number
	return world_camera_screen_y(math.floor(tile_y * 16))
end

-- Attach-only helpers (no scroll/scale false-path).
global function tile_draw_x(tile_x: number): number
	return math.floor(tile_x * 16)
end

global function tile_draw_y(tile_y: number, extra_px: number): number
	return math.floor(tile_y * 16 + extra_px)
end

global function tile_draw_y_raw(tile_y: number): number
	return tile_y * 16
end

global function world_draw_scale(): number
	return 1
end

global function world_flip_scale(sign: number): number
	return sign
end

global function entity_draw_x(tile_x: number, offset_px: number): number
	return math.floor(tile_x * 16 + offset_px)
end

global function entity_draw_y(tile_y: number, offset_px: number): number
	return math.floor(tile_y * 16 - offset_px)
end

-- Scissors / HUD (tile → screen via camera).
global function screen_draw_x(tile_x: number): number
	return world_screen_x(tile_x)
end

global function screen_draw_y(tile_y: number): number
	return world_screen_y(tile_y)
end

global function screen_to_tile_x(screen_px: number): number
	return session.xscroll + screen_px / (16 * scale)
end

global function screen_to_tile_y(screen_px: number): number
	return session.yscroll + (screen_px - (yoffset or 0) * scale) / (16 * scale)
end

-- Weapon overlays under world_camera_attach.
global function weapon_draw_xy(tile_x: number, tile_y: number): number, number
	return entity_draw_x(tile_x, 0), entity_draw_y(tile_y, 0)
end
