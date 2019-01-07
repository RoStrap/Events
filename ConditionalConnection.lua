-- A class that wraps a connection, only staying connected if the condition is true
-- @author Evaera
-- Note: Calling :Connect() while already connected is ignored.

local ConditionalConnection = {}
ConditionalConnection.__index = ConditionalConnection

function ConditionalConnection.new(event, callback, conditionCallback)
	return setmetatable({
		ConditionCallback = conditionCallback or function() return true end;
		Callback = callback;
		Event = event;
		Connection = nil;
		Destroyed = false;
	}, ConditionalConnection)
end

function ConditionalConnection:Connect()
	if self.Connection or self.Destroyed then
		return
	end

	self.Connection = self.Event:Connect(function(...)
		if not self.ConditionCallback(self) then
			return self:Disconnect()
		end

		self.Callback(...)
	end)
end

function ConditionalConnection:Disconnect()
	if not self.Connection then
		return
	end

	self.Connection:Disconnect()
	self.Connection = nil
end

function ConditionalConnection:Destroy()
	self:Disconnect()
	self.Destroyed = true
end

return ConditionalConnection
