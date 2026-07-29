global record HumpCamera
	x: number
	y: number
	scale: number
	lookAt: function(HumpCamera, ...: any): HumpCamera
	attach: function(HumpCamera, ...: any)
	detach: function(HumpCamera)
	shake: function(HumpCamera, ...: any)
	update: function(HumpCamera, number)
	zoomTo: function(HumpCamera, number): HumpCamera
	worldCoords: function(HumpCamera, number, number): number, number
	cameraCoords: function(HumpCamera, number, number): number, number
end

local record camera
	new: function(...: any): HumpCamera
end

return camera
