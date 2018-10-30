--[[
	A ReplicatedValue is a server-authoritative value which is replicated across
	the network. The client can request the value if it doesn't have it yet, and
	then will receive updates when it changes.

	The reason to use this over normal Value objects is because you can represent
	complex data structures with a ReplicatedValue, whereas ValueBase objects are
	limited to one primitive value.

	Constructors:
	- getFor
	- waitFor
	- new

	Methods:
	- Set
	- Get
	- Update
	- Bind
	- Destroy
	- AddHook
	- GetPropertyChangedSignal

	Properties:
	- Name
	- Scope
	- Value
	- Initialized
	- IsDestroyed

	Events:
	- Changed
	- Destroyed

	Hooks:
	- BeforeInvoke: Runs before the client requests the value from the server
	- BeforeGet: Runs before the value is returned with :Get() (local machine only)

	TODO:
	- A way for clients to ask for changes to be made?
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Signal = Resources:LoadLibrary("Signal")
local Janitor = Resources:LoadLibrary("Janitor")

local IsServer = RunService:IsServer()
local RemoteFunction = Resources:GetRemoteFunction("ReplicatedValue")
local RemoteEvent = Resources:GetRemoteEvent("ReplicatedValue")

local ReplicatedValue = {}
ReplicatedValue.__index = ReplicatedValue

local Values = setmetatable({}, {
	__index = function(self, k)
		self[k] = {}
		return self[k]
	end
})

--- Gets a named value. Lowercase because constructors are conventionally lowercase in Roblox
function ReplicatedValue.getFor(name, scope, initalValue)
	assert(type(name) == "string", "Bad argument #1 to ReplicatedValue.getFor: name must be a string")

	scope = scope or "default"

	local value = ReplicatedValue.new(name, scope)
	Values[name][scope] = value

	if IsServer then
		value.Changed:Connect(function(newValue)
			RemoteEvent:FireAllClients(name, scope, "CHANGE", newValue)
		end)

		value.Destroyed:Connect(function()
			RemoteEvent:FireAllClients(name, scope, "DESTROY")
		end)

		if initalValue ~= nil then
			value:Set(initalValue)
		end
	end

	return value
end

--- Waits for a value from the server to be set.
-- If used on the server, returns the value instantly.
function ReplicatedValue.waitFor(...)
	local value = ReplicatedValue.getFor(...)

	if IsServer then -- Return instantly if on server, so this can be used on both
		return value
	end

	while value:Get() == nil do
		value.Changed:Wait()
	end

	return value
end

--- Instantiates a new ReplicatedValue
function ReplicatedValue.new(name, scope)
	local self = setmetatable({
		Name = name;
		Scope = scope;
		Value = nil;
		Changed = Signal.new();
		Destroyed = Signal.new();
		Janitor = Janitor.new();
		Initialized = false;
		IsDestroyed = false;
		Hooks = {};
	}, ReplicatedValue)

	self.Janitor:Add(function()
		if rawget(Values, self.Name) then
			Values[self.Name][self.Scope] = nil
		end

		if not self.IsDestroyed then
			self:Destroy(true)
		end
	end)
	self.Janitor:Add(self.Changed)
	self.Janitor:Add(self.Destroyed)

	if typeof(scope) == "Instance" then
		self.Janitor:LinkToInstance(scope)
	end

	return self
end

local function checkDestroy(self)
	assert(not self.IsDestroyed, "Cannot call methods on a destroyed ReplicatedValue", 3)
end

local function setInternal(self, value)
	self.Value = value
	self.Initialized = true
	self.Changed:Fire(value)
end

--- Sets the value.
function ReplicatedValue:Set(...)
	checkDestroy(self)
	assert(IsServer, "ReplicatedValue.Set may only be used from the server.")

	setInternal(self, ...)
end

--- Updates the value to the return value from a callback, which is given the current value.
function ReplicatedValue:Update(callback)
	checkDestroy(self)

	self:Set(callback(self:Get()))
end

--- Retrieves the current value.
function ReplicatedValue:Get()
	checkDestroy(self)

	self:RunHooks("BeforeGet")

	if self.Initialized then
		return self.Value
	elseif not IsServer then
		local value = RemoteFunction:InvokeServer(self.Name, self.Scope)
		self.Initialized = true
		setInternal(self, value)
		return value
	end
end

--- Binds a function to this value, which gets called immediately and then
-- whenever the value changes thereafter
function ReplicatedValue:Bind(callback, selfArg)
	checkDestroy(self)

	local function doCallback(...)
		if selfArg then
			return callback(selfArg, ...)
		else
			return callback(...)
		end
	end

	self.Changed:Connect(doCallback)
	doCallback(self:Get())
end

--- Destroys this ReplicatedValue
function ReplicatedValue:Destroy(skipCleanup)
	self.Destroyed:Fire()
	self.IsDestroyed = true

	if not skipCleanup then
		self.Janitor:Cleanup()
	end
end

--- Adds a hook to be run later.
function ReplicatedValue:AddHook(name, callback)
	if self.Hooks[name] == nil then
		self.Hooks[name] = {}
	end

	table.insert(self.Hooks[name], callback)
end

--- Runs a hook of a specific type.
function ReplicatedValue:RunHooks(name)
	if self.Hooks[name] ~= nil then
		for _, hook in next, self.Hooks[name] do
			hook(self.Value)
		end
	end
end

local function getNestedValue(object, propertyPath)
	local value = object
	for _, field in next, propertyPath do
		value = value[field]

		if value == nil then
			return
		end
	end

	return value
end
function ReplicatedValue:GetPropertyChangedSignal(...)
	local propertyPath = {...}
	local lastValue = getNestedValue(self:Get(), propertyPath)

	local signal = Signal.new()
	self.Janitor:Add(signal)

	self.Changed:Connect(function(newFullValue)
		local newValue = getNestedValue(newFullValue, propertyPath)
		if newValue ~= lastValue then
			signal:Fire(newValue, lastValue)
			lastValue = newValue
		end
	end)

	return signal
end

if IsServer then
	function RemoteFunction.OnServerInvoke(_, name, scope)
		if type(name) ~= "string" or scope == nil then return end

		if rawget(Values, name) and Values[name][scope] then
			local value = Values[name][scope]
			value:RunHooks("BeforeInvoke")
			return value.Value
		end
	end
else
	RemoteEvent.OnClientEvent:Connect(function(name, scope, action, value)
		if rawget(Values, name) and Values[name][scope] then
			if action == "CHANGE" then
				return setInternal(Values[name][scope], value)
			elseif action == "DESTROY" then
				Values[name][scope]:Destroy()
			end
		end
	end)
end

return ReplicatedValue
