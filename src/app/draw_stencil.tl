--[[ Love 12 stencil helpers (setStencilMode). Replaces stencil + setStencilTest. ]]

global function with_mask(maskfn: function(), drawfn: function(), inverted?: boolean)
	love.graphics.setStencilMode("draw", 1)
	maskfn()
	if inverted then
		love.graphics.setStencilMode("test", 0)
	else
		love.graphics.setStencilMode("test", 1)
	end
	drawfn()
	love.graphics.setStencilMode()
end

global function begin_mask(maskfn: function(), inverted?: boolean)
	love.graphics.setStencilMode("draw", 1)
	maskfn()
	if inverted then
		love.graphics.setStencilMode("test", 0)
	else
		love.graphics.setStencilMode("test", 1)
	end
end

global function end_mask()
	love.graphics.setStencilMode()
end
