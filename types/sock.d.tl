global record SockClient
	getIndex: function(SockClient): integer
	send: function(SockClient, string, any)
	disconnectLater: function(SockClient)
	disconnectNow: function(SockClient, integer|nil)
	disconnect: function(SockClient, integer|nil)
	setSerialization: function(SockClient, function(any): string, function(string): any)
	setSendMode: function(SockClient, string)
	resetSendSettings: function(SockClient)
	connect: function(SockClient)
	update: function(SockClient)
	on: function(SockClient, string, function(any))
end

global record SockServer
	update: function(SockServer)
	on: function(SockServer, string, function(any, SockClient))
	sendToAll: function(SockServer, string, any)
	sendToAllBut: function(SockServer, SockClient, string, any)
	setSerialization: function(SockServer, function(any): string, function(string): any)
	setSendMode: function(SockServer, string)
	resetSendSettings: function(SockServer)
	destroy: function(SockServer)
end

global record SockModule
	newServer: function(string, number, integer|nil): SockServer
	newClient: function(string, number): SockClient
end

local record sock
	newServer: function(string, number, integer|nil): SockServer
	newClient: function(string, number): SockClient
end

return sock
