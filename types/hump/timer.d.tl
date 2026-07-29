local record TimerHandle
end

local record TimerModule
	update: function(TimerModule, number)
	after: function(TimerModule, number, function): TimerHandle
	every: function(TimerModule, number, function, integer|nil): TimerHandle
	during: function(TimerModule, number, function, function|nil): TimerHandle
	cancel: function(TimerModule, TimerHandle)
	clear: function(TimerModule)
	script: function(TimerModule, function)
	tween: {string: function}
end

return TimerModule
