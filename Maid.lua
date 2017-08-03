local Maid = {}

function Maid.new()
	return setmetatable({{}}, Maid)
end

function Maid:__index(i)
	return Maid[i] or self[1][i]
end

function Maid:__newindex(i, v)
	local Tasks = self[1]
	if v == nil then -- Clear previous Task
		local Task = Tasks[i]
		if Task then
			local Type = typeof(Task)
			if Type == "RBXScriptConnection" then
				Task:Disconnect()
			elseif Type == "Instance" then
				Task:Destroy()
			end
		end
	elseif Tasks[i] then
		self[i] = nil -- Clear previous task
	end
	Tasks[i] = v
end

function Maid:GiveTask(Task)
	local n = #self[1] + 1
	self[1][n] = Task
	return n
end

function Maid:DoCleaning()
	local Tasks = self[1]
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

return Maid
