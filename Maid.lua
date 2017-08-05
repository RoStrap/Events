-- Object for managing Cleanup
local Maid = {}

-- Maid[key] = (function)            Adds a function to call at cleanup
-- Maid[key] = (Instance)            Adds an Object to be Destroyed at cleanup
-- Maid[key] = (RBXScriptConnection) Adds a connection to be Disconnected at cleanup
-- Maid[key] = (Maid)                Maids can act as an event connection, allowing a Maid to have other maids to clean up.
-- Maid[key] = nil                   Removes a named task. This cleans up the previous Maid[key]


--- Generates a new Maid object
-- @return Maid
function Maid.new()
	return setmetatable({_Tasks = {}}, Maid)
end

--- Gives the Maid a Task to perform at cleanup, incremented by 1
-- @param Variant Task An object to be Destroyed, a Connection to be Disconnected, or function/callable table to be called
-- @returns the index the Task was placed at
function Maid:GiveTask(Task)
	local n = #self._Tasks + 1
	self._Tasks[n] = Task
	return n
end

--- Makes the Maid clean up when the instance is destroyed
-- @param Instance Instance The Instance the Maid will wait for to be Destroyed
--[[
function Maid:LinkToInstance(Instance)
	self:GiveTask(Instance.AncestryChanged:Connect(function(Object, Parent)
		if Parent == nil then
			self:DoCleaning()
		end
	end))
end
--]]

--- Cleans up the Tasks assigned to the Maid
-- This Disconnects RBXScriptConnections, Destroys Instances, and calls Functions/callable Tables
function Maid:DoCleaning()
	local Tasks = self._Tasks
	for Name, Task in next, Tasks do
		local Type = typeof(Task)
		if Type == "RBXScriptConnection" then
			Task:Disconnect()
		elseif Type == "Instance" then
			Task:Destroy()
		else
			Task()
		end
		Tasks[Name] = nil
	end
end
Maid.Disconnect = Maid.DoCleaning
Maid.Destroy = Maid.DoCleaning
Maid.__call = Maid.DoCleaning

--- Internal __index metamethod
function Maid:__index(i)
	return Maid[i] or self._Tasks[i]
end

--- Internal __newindex metamethod
function Maid:__newindex(i, v)
	local Tasks = self._Tasks
	local Task = Tasks[i]
	if Task or v == nil then -- Clear previous Task
		local Type = typeof(Task)
		if Type == "RBXScriptConnection" then
			Task:Disconnect()
		elseif Type == "Instance" or getmetatable(Task) == Maid then
			Task:Destroy()
		end
	end
	Tasks[i] = v
end

return Maid
