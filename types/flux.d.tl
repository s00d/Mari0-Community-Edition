global record FluxTween
	ease: function(FluxTween, ...: any): FluxTween
	oncomplete: function(FluxTween, ...: any): FluxTween
	delay: function(FluxTween, ...: any): FluxTween
	stop: function(FluxTween): FluxTween
end

global record FluxModule
	to: function(...: any): FluxTween
	update: function(number)
end

return FluxModule
