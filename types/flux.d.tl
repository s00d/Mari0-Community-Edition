global record FluxTween
	ease: function(FluxTween, string): FluxTween
	oncomplete: function(FluxTween, function()): FluxTween
	onstart: function(FluxTween, function()): FluxTween
	onupdate: function(FluxTween, function()): FluxTween
	delay: function(FluxTween, number): FluxTween
	after: function(FluxTween, ...: any): FluxTween
	stop: function(FluxTween)
end

global record FluxModule
	to: function(...: any): FluxTween
	update: function(number)
end

return FluxModule
