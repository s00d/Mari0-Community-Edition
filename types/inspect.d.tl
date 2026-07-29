-- kikito/inspect.lua
local record inspect
	metamethod __call: function(inspect, value: any, options?: {string:any}): string
end

return inspect
