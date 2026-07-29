global record FluxTween
	ease: function(FluxTween, ...: any): FluxTween
	oncomplete: function(FluxTween, ...: any): FluxTween
	delay: function(FluxTween, ...: any): FluxTween
end

local record flux
	to: function(...: any): FluxTween
	update: function(number)
end

return flux
