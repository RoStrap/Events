-- BindableEvent Wrapper
-- @original https://gist.github.com/Anaminus/afd813efc819bad8e560caea28942010

--[[
Work in progress

# Signal
API-compatible Roblox events.
Addresses two flaws in previous implementations:
- Held a reference to the last set of fired arguments.
- Arguments would be overridden if the signal was fired by a listener.
## Synopsis
	- signal = Signal(function, function)
		Returns a new signal. Receives optional constructor and destructor
		functions. The constructor is called when the number of
		listeners/threads becomes greater than 0. The destructor is called
		when then number of threads/listeners becomes 0. The destructor
		receives as arguments the values returned by the constructor.
	- Signal:Fire(...)
		Fire the signal, passing the arguments to each listener and waiting
		threads.
	- ... = Signal:Wait()
		Block the current thread until the signal is fired. Returns the
		arguments passed to Fire.
	- Signal:Destroy()
		Disconnects all listeners and becomes unassociated with currently
		blocked threads. The signal is still usable.
	- connection = SignalEvent:Connect(function)
		Sets a function to be called when the signal is fired. The listener
		function receives the arguments passed to Fire. Returns a
		SignalConnection.
	- SignalConnection:Disconnect()
		Disconnects the listener, causing it to no longer be called when the
		signal is fired.
	- bool = SignalConnection.Connected
		Whether the listener is connected.
]]

local function Destruct(self)
	if #self.Connections == 0 and self.Destructor and self.ConstructorData then
		self:Destructor(unpack(self.ConstructorData))
		self.ConstructorData = nil
	end
end

local PseudoConnection = {
	__index = {
		Connected = true;
	};
}

function PseudoConnection.__index:Disconnect()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end

	local Signal = self.Signal

	if Signal then
		self.Connected = false
		local Connections = Signal.Connections

		for i = 1, #Connections do
			if Connections[i] == self then
				table.remove(Connections, i)
				break
			end
		end

		self.Signal = Destruct(Signal)
	end
end

local Signal = {
	__index = {
		NextId = 0; -- Holds the next Arguments ID
		YieldingThreads = 0; -- Number of Threads waiting on the signal
	}
}

function Signal.__index:Connect(Function)
	if #self.Connections == 0 and self.Constructor and not self.ConstructorData then
		self.ConstructorData = {self:Constructor()}
	end

	local Connection = setmetatable({
		Signal = self;
		Connection = self.Bindable.Event:Connect(function(Id)
			local Arguments = self.Arguments[Id]
			local ThreadsRemaining = Arguments[1] - 1

			if ThreadsRemaining == 0 then
				self.Arguments[Id] = nil
			else
				Arguments[1] = ThreadsRemaining
			end

			Function(unpack(Arguments, 2))
		end);
	}, PseudoConnection)

	self.Connections[#self.Connections + 1] = Connection
	return Connection
end

function Signal.__index:Fire(...)
	local Id = self.NextId
	self.NextId = self.NextId + 1
	self.Arguments[Id] = {#self.Connections + self.YieldingThreads, ...}
	self.YieldingThreads = nil
	self.Bindable:Fire(Id)
end

function Signal.__index:Wait()
	self.YieldingThreads = self.YieldingThreads + 1
	local Id = self.Bindable.Event:Wait()
	local Arguments = self.Arguments[Id]
	local ThreadsRemaining = Arguments[1] - 1

	if Arguments[1] == 0 then
		self.Arguments[Id] = nil
	else
		Arguments[1] = ThreadsRemaining
	end

	return unpack(Arguments, 2)
end

function Signal.__index:Destroy()
	Destruct(self)

	self.Bindable = self.Bindable:Destroy()
	local Connections = self.Connections

	for i = #Connections, 1, -1 do
		local Connection = Connections[i]
		Connection.Connected = false
		Connection.Signal = nil
		Connection.Connection = nil
		Connections[i] = nil
	end

	self.YieldingThreads = nil
	self.Arguments = nil
	self.Connections = nil
	setmetatable(self, nil)
end

function Signal.new(Constructor, Destructor)
	return setmetatable({
		Bindable = Instance.new("BindableEvent"); -- Dispatches scheduler-compatible Threads
		Arguments = {}; -- Holds arguments for pending listener functions and Threads: [Id] = {#Connections + YieldingThreads, arguments}
		Connections = {}; -- SignalConnections connected to the signal
		Constructor = Constructor; -- Constructor function
		Destructor = Destructor; -- Destructor function
	}, Signal)
end

return Signal
		
