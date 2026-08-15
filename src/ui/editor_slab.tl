--[[ Slab debug overlay for editor (palette experiments). Off unless editor_slab_debug. ]]

local record SlabModule
	BeginFrame: function()
	BeginWindow: function(string): boolean
	Text: function(string)
	EndWindow: function()
	EndFrame: function()
end

global function editor_slab_draw()
	if not editor_slab_debug then
		return
	end
	local slab = require("slab") as SlabModule
	slab.BeginFrame()
	if slab.BeginWindow("Editor") then
		slab.Text(string.format("map %dx%d  scroll %.1f,%.1f", session.mapwidth as integer, session.mapheight as integer, session.xscroll, session.yscroll))
		slab.EndWindow()
	end
	slab.EndFrame()
end
