--[[ hump.camera draw context: world tile coords, no per-draw xscroll/yscroll. ]]

local CameraMod = require("hump.camera")
local cam: HumpCamera|nil = nil

global world_camera_drawing = false

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
	c:lookAt((xscroll + width / 2) * 16, (yscroll + height / 2) * 16 + yoff)
end

global function editor_camera_sync()
	world_camera_sync()
end

global function world_camera_attach()
	world_camera_sync()
	world_camera_drawing = true
	ensure():attach(0, 0, width * 16 * scale, height * 16 * scale, true)
end

global function world_camera_detach()
	ensure():detach()
	world_camera_drawing = false
end

-- Tile units → world pixels (camera scale applied in attach).
global function wpx(tile_x: number): number
	return math.floor(tile_x * 16)
end

global function wpy(tile_y: number): number
	return math.floor(tile_y * 16)
end

global function world_spritebatch_offset(scroll: number): number
	if world_camera_drawing then
		return world_batch_offset(scroll)
	end
	return scroll_batch_offset(scroll)
end

global function world_viewport_w(): number
	return width * 16 * scale
end

global function world_viewport_h(): number
	return height * 16 * scale
end

global function world_batch_offset(scroll: number): number
	return math.floor(scroll) * 16 - math.floor(math.fmod(scroll, 1) * 16)
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

-- Dual-mode: screen-space scroll math when detached, world pixels when attached.
global function tile_draw_x(tile_x: number): number
	if world_camera_drawing then
		return math.floor(tile_x * 16)
	end
	return math.floor((tile_x - xscroll) * 16 * scale)
end

global function tile_draw_y(tile_y: number, extra_px: number): number
	if world_camera_drawing then
		return math.floor(tile_y * 16 + extra_px)
	end
	local yoff = (yoffset or 0) * 16
	return math.floor(((tile_y - yscroll) * 16 + yoff + extra_px) * scale)
end

global function tile_draw_y_raw(tile_y: number): number
	if world_camera_drawing then
		return tile_y * 16
	end
	local yoff = (yoffset or 0) * 16
	return ((tile_y - yscroll) * 16 + yoff) * scale
end

global function world_draw_scale(): number
	if world_camera_drawing then
		return 1
	end
	return scale
end

global function world_flip_scale(sign: number): number
	if world_camera_drawing then
		return sign
	end
	return sign * scale
end

global function entity_draw_x(tile_x: number, offset_px: number): number
	if world_camera_drawing then
		return math.floor(tile_x * 16 + offset_px)
	end
	return math.floor(((tile_x - xscroll) * 16 + offset_px) * scale)
end

global function entity_draw_y(tile_y: number, offset_px: number): number
	if world_camera_drawing then
		return math.floor(tile_y * 16 - offset_px)
	end
	return math.floor(((tile_y - yscroll) * 16 - offset_px) * scale)
end

global function screen_draw_x(tile_x: number): number
	if world_camera_drawing then
		return world_screen_x(tile_x)
	end
	return tile_draw_x(tile_x)
end

global function screen_draw_y(tile_y: number): number
	if world_camera_drawing then
		return world_screen_y(tile_y)
	end
	return tile_draw_y_raw(tile_y)
end

-- Screen pixels → map tile units (for aim / logic outside draw).
global function screen_to_tile_x(screen_px: number): number
	return xscroll + screen_px / (16 * scale)
end

global function screen_to_tile_y(screen_px: number): number
	return yscroll + (screen_px - (yoffset or 0) * scale) / (16 * scale)
end

global function world_screen_px_x(world_px: number): number
	return world_camera_screen_x(world_px)
end

global function world_screen_px_y(world_py: number): number
	return world_camera_screen_y(world_py)
end

-- Weapon overlays (beams/trails/VFX) drawn inside world_camera_attach.
-- Legacy screen path kept the -0.5 Y fudge; world path uses entity coords as-is.
global function weapon_draw_xy(tile_x: number, tile_y: number): number, number
	if world_camera_drawing then
		return entity_draw_x(tile_x, 0), entity_draw_y(tile_y, 0)
	end
	local sc = scale or 1
	return math.floor((tile_x - xscroll) * 16 * sc), math.floor((tile_y - yscroll - 0.5) * 16 * sc)
end
