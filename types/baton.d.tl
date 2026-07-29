global record BatonInput
	update: function(BatonInput)
	down: function(BatonInput, string): boolean
	pressed: function(BatonInput, string): boolean
	released: function(BatonInput, string): boolean
	get: function(BatonInput, string): number
end

local record baton
	new: function(...: any): BatonInput
end

return baton
