global record BitserModule
	dumps: function(any): string
	loads: function(string): any
end

local record bitser
	dumps: function(any): string
	loads: function(string): any
end

return bitser
