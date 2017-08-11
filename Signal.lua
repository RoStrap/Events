-- @original Stravant

--[[
	class Signal
	
	Description:
		Lua-side duplication of the API of Events on Roblox objects. Needed for nicer
		syntax, and to ensure that for local events objects are passed by reference
		rather than by value where possible, as the BindableEvent objects always pass
		their signal arguments by value, meaning tables will be deep copied when that
		is almost never the desired behavior.
		
	API:
		void Fire(...)
			Fire the event with the given arguments.
			
		RbxScriptSignal/Connection Connect(Function handler)
			Connect a new handler to the event, returning a connection object that
			can be disconnected.
			
		<Variant> Wait()
			Wait for fire to be called, and return the arguments it was given.
			
		void Destroy()
			Disconnects all connected events to the signal and voids the signal as unusable.
--]]

local Signal = {}
Signal.__index = Signal

function Signal:Fire(...)
	self.BindData = {...}
	self.BindableEvent:Fire()
end

function Signal:Connect(func)
	if not func then error("connect(nil)", 2) end
	local Connection = self.BindableEvent.Event:Connect(function()
		func(unpack(self.BindData))
	end)
	self.Connections[#self.Connections + 1] = Connection
	return Connection
end

function Signal:Wait()
	self.BindableEvent.Event:Wait()
	return unpack(self.BindData or error("Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.", 2))
end

function Signal:Destroy()
	local Connections = self.Connections
	for a = 1, #Connections do
		Connections[a]:Disconnect()
	end
	self.BindableEvent:Destroy()
	self.BindData = nil
	self.BindableEvent = nil
	self.Connections = nil
end

function Signal.new()
	return setmetatable({
		BindableEvent = Instance.new("BindableEvent");
		Connections = {};
	}, Signal)
end

return Signal
